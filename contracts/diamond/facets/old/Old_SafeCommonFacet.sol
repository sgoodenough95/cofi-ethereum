// // SPDX-License-Identifier: MIT
// pragma solidity 0.8.19;

// /**
//     █▀▀ ▀▀█▀▀ █▀▀█ █▀▀█ 
//     ▀▀█ ░░█░░ █░░█ █▄▄█ 
//     ▀▀▀ ░░▀░░ ▀▀▀▀ ▀░░▀

//     @author stoa.money
//     @title  Safe Facet
//     @notice User-operated functions for managing Safes.
//  */

// import { Safe, VaultParams, Modifiers } from '../libs/LibAppStorage.sol';
// import { LibToken } from '../libs/LibToken.sol';
// import { LibTreasury } from '../libs/LibTreasury.sol';
// import { LibVault } from '../libs/LibVault.sol';
// import { LibSafe } from '../libs/LibSafe.sol';
// import { IERC4626 } from ".././interfaces/IERC4626.sol";

// contract SafeFacet is Modifiers {

//     /// @notice Opens a Safe with activeAssets already held by the account.
//     ///
//     /// @param  amount      The amount of activeAssets to deposit.
//     /// @param  activeAsset The address of the activeAsset.
//     function openActive(
//         uint256 amount,
//         address activeAsset
//     )   external
//         minDeposit(amount, activeAsset)
//     {
//         LibSafe._open(amount, msg.sender, s.primeStore[activeAsset]);
//     }

//     /// @notice Deposits an activeAsset to an existing Safe.
//     ///
//     /// @param  amount      The amount of activeAssets to deposit.
//     /// @param  recipient   The owner of the recipient Safe.
//     /// @param  index       The Safe ID.
//     function depositActive(
//         uint256 amount,
//         address depositFrom,
//         address recipient,
//         uint32  index
//     )   external
//         minDeposit(amount, IERC4626(s.safe[recipient][index].store).asset())
//         activeSafe(recipient, index)
//     {
//         LibSafe._deposit(amount, depositFrom, recipient, index);
//     }

//     function withdrawActive(
//         uint256 amount,
//         address recipient,
//         uint32  index
//     )   external
//         minWithdraw(amount, IERC4626(s.safe[msg.sender][index].store).asset())
//         activeSafe(msg.sender, index)
//     {
//         (uint256 maxWithdraw, ) = LibSafe._getMaxWithdraw(msg.sender, index);

//         require(amount <= maxWithdraw, 'SafeFacet: Insufficient allowance');

//         LibSafe._withdraw(amount, recipient, index);
//     }

//     function transfer(
//         uint256 amount,
//         address recipient,
//         uint32  fromIndex,
//         uint32  toIndex
//     )   external
//         minWithdraw(amount, IERC4626(s.safe[msg.sender][fromIndex].store).asset())
//         activeSafe(msg.sender, fromIndex)
//     {
//         (uint256 maxWithdraw, ) = LibSafe._getMaxWithdraw(msg.sender, fromIndex);

//         require(amount <= maxWithdraw, 'SafeFacet: Insufficient allowance');

//         uint256 shares = IERC4626(s.safe[msg.sender][fromIndex].store).previewDeposit(amount);

//         LibSafe._adjustBal(-int256(shares), msg.sender, fromIndex);

//         require(
//             LibSafe._isReceivable(s.safe[msg.sender][fromIndex].store, recipient, toIndex) == 1,
//             'SafeFacet: Target Safe not valid'
//         );
//         LibSafe._adjustBal(int256(shares), recipient, toIndex);
//     }

//     function borrow(
//         uint256 amount,
//         address recipient,
//         uint32  index
//     )   external
//         minWithdraw(amount, s.safe[msg.sender][index].creditAsset)
//         activeSafe(msg.sender, index)
//     {
//         (uint256 maxBorrow, uint256 origFee) = LibSafe._getMaxBorrow(msg.sender, index);

//         require(amount <= maxBorrow, 'SafeFacet: Insufficient credit');

//         IERC4626 vault = IERC4626(s.safe[msg.sender][index].store);

//         // Convert assets to shares to adjust Safe params.
//         uint256 creditShares    = vault.previewDeposit(amount);
//         uint256 origFeeShares   = vault.previewDeposit(origFee);

//         LibSafe._adjustCredit(-int256(creditShares), msg.sender, index);
//         LibSafe._adjustBal(-int256(origFeeShares), msg.sender, index);

//         // Update backing reserve only applies to direct mints.

//         LibToken._mint(s.safe[msg.sender][index].creditAsset, recipient, amount);

//         /**
//             LOAN CALC STEPS:

//             1. User opens Safe with 10,000 USD. Has "2,500" credits.
//             2. Alice can see that her maxBorrow is 2,487.5 credits.
//             3. Alice calls borrow(2,487.5, Alice's wallet, 0).
//             4* Alice's credit is now 12.5.
//             5* Alice's maxBorrow is now 12.5-(12.5*0.05%)=12.4375.

//             If Alice's maxBorrow < minWithdraw, display maxBorrow as 0.
//          */

//         s.origFeesCollected[s.safe[msg.sender][index].store] += origFeeShares;
//     }

//     function repay(
//         uint256 amount,
//         address depositFrom,
//         address recipient,
//         uint32  index
//     )   external
//         minDeposit(amount, s.safe[recipient][index].creditAsset)
//         activeSafe(recipient, index)
//     {
//         LibToken._burn(s.safe[recipient][index].creditAsset, depositFrom, amount);

//         uint256 shares = IERC4626(s.safe[recipient][index].store).previewDeposit(amount);

//         LibSafe._adjustCredit(int256(shares), recipient, index);
//     }

//     function repayWithInput(
//         uint256 amount,
//         address asset,
//         address depositFrom,
//         address recipient,
//         uint32  index
//     )   external
//         minDeposit(amount, asset)
//         activeSafe(recipient, index)
//     {

//     }

//     /// @notice Frees up collateral by backing wild credit with balance taken from owner.
//     /// @notice Allows user to access collateral if they choose not to repay loan.
//     ///
//     /// @param  amount  The amount of creditAssets to back. If greater than debt then full debt amount.
//     /// @param  index   The Safe to liquidate (full or partial).
//     function liquidate(
//         uint256 amount,
//         uint32  index
//     )   external
//         activeSafe(msg.sender, index)
//     {
//         (uint256 maxWithdraw, uint256 baseCredit) = LibSafe._getMaxWithdraw(msg.sender, index);

//         require(maxWithdraw < s.safe[msg.sender][index].bal, 'SafeFacet: Nothing to liquidate');

//         uint256 debt = baseCredit - s.safe[msg.sender][index].credit;

//         uint256 shares = IERC4626(s.safe[msg.sender][index].store).previewDeposit(amount);

//         shares = shares > debt ? debt : shares;

//         // Secure collateral to back outstanding credit. Leave out liquidation fee, at least for now.
//         LibSafe._adjustBal(-int256(shares), msg.sender, index);

//         uint256 assets = IERC4626(s.safe[msg.sender][index].store).redeem(shares, address(this), address(this));

//         LibTreasury._adjustBackingReserve(IERC4626(s.safe[msg.sender][index].store).asset(), int256(assets));
//     }

//     function getSafe(
//         address account,
//         uint32  index
//     ) external view returns (Safe memory) {

//         return s.safe[account][index];
//     }
// }