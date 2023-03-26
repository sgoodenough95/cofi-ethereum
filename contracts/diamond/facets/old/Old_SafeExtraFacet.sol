// // SPDX-License-Identifier: MIT
// pragma solidity 0.8.19;

// /**
//     █▀▀ ▀▀█▀▀ █▀▀█ █▀▀█ 
//     ▀▀█ ░░█░░ █░░█ █▄▄█ 
//     ▀▀▀ ░░▀░░ ▀▀▀▀ ▀░░▀

//     @author stoa.money
//     @title  Safe Extra Facet
//     @notice Added functionality for Safes.
//     @notice Likely to be deployed as first diamond cut operation.
//  */

// import { Safe, VaultParams, Modifiers } from '../libs/LibAppStorage.sol';
// import { LibToken } from '../libs/LibToken.sol';
// import { LibSafe } from '../libs/LibSafe.sol';
// import { IERC4626 } from ".././interfaces/IERC4626.sol";

// contract SafeExtraFacet is Modifiers {

//     /// @notice Deposits an activeAsset to a non-existent Safe.
//     /// @notice recipient can only claim once created an eligible Safe.
//     ///
//     /// @param  amount      The amount of activeAssets to deposit.
//     /// @param  asset       The activeAsset to deposit.
//     /// @param  depositFrom The account to deposit assets from.
//     /// @param  recipient   The account eliglble to claim assets.
//     function depositActiveClaim(
//         uint256 amount,
//         address asset,
//         address depositFrom,
//         address recipient
//     )   external
//         minDeposit(amount, asset)
//     {
//         uint256 shares =
//             IERC4626(s.primeStore[asset]).deposit(amount, address(this), depositFrom);

//         s.pendingBal[recipient][s.primeStore[asset]] += shares;
//     }

//     /// @notice Deposits a creditAsset to a non-existent Safe.
//     /// @notice recipient can only claim once created an eligible Safe.
//     ///
//     /// @param  amount      The amount of creditAssets.
//     /// @param  asset       The creditAsset to deposit.
//     /// @param  depositFrom The account to deposit assets from.
//     /// @param  recipient   The account eligble to claim assets.
//     function depositCreditClaim(
//         uint256 amount,
//         address asset,
//         address depositFrom,
//         address recipient
//     )   external
//         minDeposit(amount, asset)
//     {
//         LibToken._burn(asset, depositFrom, amount);

//         uint256 shares = IERC4626(s.primeStore[asset]).previewDeposit(amount);

//         s.pendingCredit[recipient][asset] += shares;
//     }

//     /// @notice Provides functionality for transferring to a Safe that does not yet exist.
//     /// @notice Target recipient can claim their pending balance at a future point in time.
//     /// @dev    recipient can still be an active user. Not specifying Safe means they have to claim.
//     ///
//     /// @param  amount      The amount of activeAssets to transfer.
//     /// @param  recipient   The recipient (current or future).
//     /// @param  fromIndex   The Safe ID to transfer from.
//     function transferToNonExistent(
//         uint256 amount,
//         address recipient,
//         uint32  fromIndex
//     )   external
//         minWithdraw(amount, IERC4626(s.safe[msg.sender][fromIndex].store).asset())
//         activeSafe(msg.sender, fromIndex)
//     {
//         (uint256 maxWithdraw, ) = LibSafe._getMaxWithdraw(msg.sender, fromIndex);

//         require(amount <= maxWithdraw, 'SafeFacet: Insufficient allowance');

//         uint256 shares = IERC4626(s.safe[msg.sender][fromIndex].store).previewDeposit(amount);

//         LibSafe._adjustBal(-int256(shares), msg.sender, fromIndex);

//         s.pendingBal[recipient][s.safe[msg.sender][fromIndex].store] += shares;
//     }

//     function transferCredit(
//         uint256 amount,
//         address recipient,
//         uint32  fromIndex,
//         uint32  toIndex
//     )   external
//         minWithdraw(amount, IERC4626(s.safe[msg.sender][fromIndex].store).asset())
//         activeSafe(msg.sender, fromIndex)
//     {
//         (uint256 maxBorrow, uint256 origFee) = LibSafe._getMaxBorrow(msg.sender, fromIndex);

//         // Check has free credit
//         require(amount <= maxBorrow, 'SafeFacet: Insufficient allowance');

//         IERC4626 vault = IERC4626(s.safe[msg.sender][fromIndex].store);

//         // Convert assets to shares to adjust Safe params.
//         uint256 creditShares    = vault.previewDeposit(amount);
//         uint256 origFeeShares   = vault.previewDeposit(origFee);

//         // Reduce credit and bal of sender.
//         LibSafe._adjustCredit(-int256(creditShares), msg.sender, fromIndex);
//         LibSafe._adjustBal(-int256(origFeeShares), msg.sender, fromIndex);

//         // Increase credit of recipient, depending on if the Safe is eligible.
//         if (
//             s.safe[recipient][toIndex].status != 1 ||
//             // Check if sender and receiver Safes share same creditAsset.
//             s.creditAsset[IERC4626(s.safe[msg.sender][fromIndex].store).asset()] !=
//                 s.creditAsset[IERC4626(s.safe[recipient][toIndex].store).asset()]
//         )   // Increase pending credit claim if recipient Safe not compatible.
//             s.pendingCredit[recipient][s.safe[msg.sender][fromIndex].creditAsset] += creditShares;
//         else
//             LibSafe._adjustCredit(int256(creditShares), recipient, toIndex);
//     }

//     function claimBal(
//         address asset,
//         uint32  index
//     )   external
//         activeSafe(msg.sender, index)
//     {
//         require(
//             s.pendingBal[msg.sender][asset] > 0,
//             'SafeFacet: Invalid bal claim'
//         );

//         require(
//             asset == s.safe[msg.sender][index].store,
//             'SafeFacet: Asset mismatch for bal claim'
//         );

//         s.safe[msg.sender][index].bal += s.pendingBal[msg.sender][asset];

//         emit LibSafe.SafeBalUpdated(msg.sender, index, int256(s.pendingBal[msg.sender][asset]));

//         s.pendingBal[msg.sender][asset] = 0;
//     }

//     function claimCredit(
//         address asset,
//         uint32  index
//     )   external
//         activeSafe(msg.sender, index)
//     {
//         require(
//             s.pendingCredit[msg.sender][asset] > 0,
//             'SafeFacet: Invalid credit claim'
//         );

//         require(
//             asset == s.safe[msg.sender][index].creditAsset,
//             'SafeFacet: Asset mismatch for credit claim'
//         );

//         s.safe[msg.sender][index].credit += s.pendingCredit[msg.sender][asset];

//         emit LibSafe.SafeCreditUpdated(msg.sender, index, int256(s.pendingCredit[msg.sender][asset]));

//         s.pendingCredit[msg.sender][asset] = 0;
//     }

//     function getPendingBal(
//         address asset,
//         address account
//     ) external view returns (uint256) {

//         return s.pendingBal[account][asset];
//     }

//     function getPendingCredit(
//         address asset,
//         address account
//     ) external view returns (uint256) {

//         return s.pendingCredit[account][asset];
//     }
// }
