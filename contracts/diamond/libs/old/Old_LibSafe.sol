// // SPDX-License-Identifier: MIT
// pragma solidity 0.8.19;

// import { VaultParams, AppStorage, LibAppStorage } from "./LibAppStorage.sol";
// import { PercentageMath } from "./external/PercentageMath.sol";
// import { IERC4626 } from ".././interfaces/IERC4626.sol";
// import 'hardhat/console.sol';

// library LibSafe {
//     using PercentageMath for uint256;

//     /// @notice Emitted when a new Safe is opened.
//     ///
//     /// @param  account The account opening the Safe.
//     /// @param  asset   The asset opened with.
//     /// @param  amount  The amount of assets deposited.
//     event SafeOpened(address account, address asset, uint256 amount);

//     /// @notice Emitted when a Safe deposit operation is executed.
//     ///
//     /// @param  account The account depositing to the Safe.
//     /// @param  asset   The asset deposited.
//     /// @param  amount  The amount of assets deposited.
//     event SafeDeposit(address account, address asset, uint256 amount);

//     /// @notice Emitted when a Safe withdraw operation is executed.
//     ///
//     /// @param  account The Safe owner.
//     /// @param  asset   The asset withdrawn.
//     /// @param  amount  The amount of assets withdrawn.
//     event SafeWithdraw(address account, address asset, uint256 amount);

//     /// @notice Emitted when a Safe balance change operation is executed.
//     ///
//     /// @param  account The account of the Safe.
//     /// @param  asset   The Safe collateral asset (used for identification).
//     /// @param  amount  The balance change amount.
//     event SafeBalUpdated(address account, address asset, int256 amount);

//     /// @notice Emitted when a Safe credit change operation is executed.
//     ///
//     /// @param  account The account of the Safe.
//     /// @param  asset   The Safe collateral asset (used for identification).
//     /// @param  amount  The credit change amount.
//     event SafeCreditUpdated(address account, address asset, int256 amount);

//     // /// @notice Emitted when credits are issued from a Safe.
//     // ///
//     // /// @param  account The account initiating the borrow.
//     // /// @param  index   The Safe ID.
//     // /// @param  amount  The amount borrowed (in ASSETS, not shares).
//     // /// @param  fee     The origination fee captured (in activeAssets).
//     // event Borrow(address account, uint32 index, uint256 amount, uint256 fee);

//     // /// @notice Emitted when credits are returned to a Safe.
//     // ///
//     // /// @param  account The account being repaid.
//     // /// @param  index   The Safe ID.
//     // /// @param  amount  The amount repaid (in ASSETS, not shares).
//     // event Repay(address account, uint32 index, uint256 amount);

//     /// @notice Internal function for opening a Safe.
//     ///
//     /// @param  amount      The amount of shares (e.g., yvDAI) to deposit.
//     /// @param  store       The Safe Store contract to store shares.
//     function _open(
//         uint256 amount,
//         address depositFrom,
//         address store  // Can add 'depositEnabled' to Safe Store contract.
//     ) internal {
//         AppStorage storage s = LibAppStorage.diamondStorage();

//         // E.g., yvUSDC = IERC4626(vyvUSDC).asset().
//         address asset   = IERC4626(store).asset();        

//         s.safe[msg.sender][asset].bal =
//             IERC4626(store).deposit(amount, address(this), depositFrom);

//         s.safe[msg.sender][asset].owner         = msg.sender;
//         s.safe[msg.sender][asset].collateral    = asset;
//         s.safe[msg.sender][asset].status        = 1;

//         emit SafeOpened(msg.sender, asset, amount);
//     }

//     /// @notice Used for updating credit to reflect the most recent LTV change.
//     ///
//     /// @param  account The account to check credit for.
//     /// @param  asset   The collateral asset of the Safe (e.g., yvUSDC).
//     function _pokeCredit(
//         address account,
//         address asset
//     ) internal returns (uint256) {
//         AppStorage storage s = LibAppStorage.diamondStorage();

//         // FIX: Will forever update credit to full amount.
//         s.safe[account][asset].credit =
//             s.safe[account][asset].bal.percentMul(s.LTV[asset]);

//         return s.safe[account][asset].credit;
//     }

//     function _deposit(
//         uint256 amount,
//         address depositFrom,
//         address recipient,
//         address store
//     ) internal {
//         AppStorage storage s = LibAppStorage.diamondStorage();

//         s.safe[recipient][IERC4626(store).asset()].bal += 
//             IERC4626(store).deposit(amount, address(this), depositFrom);

//         emit SafeDeposit(msg.sender, IERC4626(store).asset(), amount);
//     }

//     /// @dev    Require _getMaxWithdraw() (and by extension, _pokeCredit()) is called first.
//     /// @param  amount      The amount of activeAssets to withdraw.
//     /// @param  recipient   The receiver of the activeAssets.
//     /// @param  index       The Safe ID to withdraw from.
//     function _withdraw(
//         uint256 amount,
//         address recipient,
//         uint32  index
//     ) internal returns (uint256 assets) {
//         AppStorage storage s = LibAppStorage.diamondStorage();

//         uint256 shares = IERC4626(s.safe[recipient][index].store).previewDeposit(amount);

//         assets = IERC4626(s.safe[recipient][index].store).redeem(shares, recipient, address(this));

//         s.safe[msg.sender][s.safeIndex[msg.sender]].bal -= shares;

//         emit SafeWithdraw(msg.sender, index, amount, recipient);
//     }

//     /// @notice Internal function to update the balance of a Safe.
//     ///
//     /// @param  amount  The amount to adjust by, denominated in SHARES (not assets).
//     /// @param  account The account to adjust balance for.
//     /// @param  asset   The Safe collateral (used to identify the Safe).
//     function _adjustBal(
//         int256  amount,
//         address account,
//         address asset
//     ) internal {
//         AppStorage storage s = LibAppStorage.diamondStorage();

//         if (amount > 0) s.safe[account][asset].bal += LibAppStorage.abs(amount);
//         else s.safe[account][asset].bal -= LibAppStorage.abs(amount);

//         emit SafeBalUpdated(account, asset, amount);
//     }

//     /// @notice Internal function to update the credit of a Safe.
//     ///
//     /// @param  amount  The amount to adjust by, denominated in SHARES (not assets).
//     /// @param  account The account to adjust credit for.
//     /// @param  asset   The Safe collateral (used to identify the Safe).
//     function _adjustCredit(
//         int256  amount,
//         address account,
//         address asset
//     ) internal {
//         AppStorage storage s = LibAppStorage.diamondStorage();

//         if (amount >= 0) s.safe[account][asset].credit += LibAppStorage.abs(amount);
//         else s.safe[account][asset].credit -= LibAppStorage.abs(amount);

//         emit SafeCreditUpdated(account, asset, amount);
//     }

//     /// @notice Returns the origination fee incurred for a given borrow operation.
//     /// @dev    May instead track with Events / simply accrue fees to an account (?)
//     ///
//     /// @param  asset   The asset to borrow.
//     /// @param  amount  The amount of assets to borrow.
//     function _getOrigFee(
//         address asset,
//         uint256 amount
//     ) internal view returns (uint256) {
//         AppStorage storage s = LibAppStorage.diamondStorage();

//         return amount.percentMul(s.origFee[asset]);
//     }

//     /// @notice Returns the available (borrowable) credit for a given Safe.
//     ///
//     /// @param  account The Safe owner.
//     /// @param  asset   The Safe collateral asset.
//     function _getAvailCredit(
//         address account,
//         address asset
//     ) internal returns (uint256, uint256) {
//         AppStorage storage s = LibAppStorage.diamondStorage();

//         // Updates credit to most recent LTV change.
//         _pokeCredit(account, asset);

//         uint256 credit = IERC4626(s.safeStore[asset])
//             .previewRedeem(s.safe[account][asset].credit);
//         uint256 fee     = credit.percentMul(s.origFee[s.creditAsset[asset]]);

//         // Returns assets (not shares).
//         return (credit - fee, fee);
//     }

//     /// @notice Gets the max credit for a Safe irrespective of debt.
//     ///
//     /// @param  account The Safe owner.
//     /// @param  asset   The Safe collateral asset.
//     function _getMaxCredit(
//         address account,
//         address asset
//     ) internal returns (uint256) {
//         AppStorage storage s = LibAppStorage.diamondStorage();

//         return IERC4626(s.safeStore[asset]).previewRedeem(
//             s.safe[account][asset].bal.percentMul(s.LTV[asset])
//         );
//     }

//     /// @notice Function for retrieving maxWithdraw. Dictates limits on withdrawals/transfers/borrows.
//     /// @dev    Pokes credit, therefore not a view. maxWithdraw can be deduced off-chain to show user beforehand.
//     ///
//     /// @param  account The Safe owner.
//     /// @param  index   The Safe ID.
//     function _getMaxWithdraw(
//         address account,
//         uint32  index
//     ) internal returns (uint256, uint256) {
//         AppStorage storage s = LibAppStorage.diamondStorage();

//         _pokeCredit(account, index);

//         uint256 baseCredit =
//             s.safe[account][index].bal.percentMul(
//                 s.LTV[IERC4626(s.safe[msg.sender][index].store).asset()]
//             );
        
//         if (baseCredit <= s.safe[account][index].credit) return (s.safe[account][index].bal, baseCredit);

//         // Convert LTV to CR. E.g., 10,000 / 2_500 * 10,000 = 400%.
//         return (
//             s.safe[account][index].bal - s.safe[account][index].credit.percentMul(
//                 10_000 / s.LTV[IERC4626(s.safe[msg.sender][index].store).asset()] * 10_000
//             ),
//             baseCredit
//         );
//     }

//     function _isOpenEnabled() internal 

//     function _adjustLTV(
//         address asset,
//         uint256 LTV
//     ) internal {
//         AppStorage storage s = LibAppStorage.diamondStorage();

//         s.LTV[asset] = LTV;
//     }
// }