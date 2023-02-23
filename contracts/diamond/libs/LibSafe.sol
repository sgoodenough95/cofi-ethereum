// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import { VaultParams, AppStorage, LibAppStorage } from "./LibAppStorage.sol";
import { PercentageMath } from "./external/PercentageMath.sol";
import { IERC4626 } from ".././interfaces/IERC4626.sol";
import 'hardhat/console.sol';

library LibSafe {
    using PercentageMath for uint256;

    /// @notice Emitted when a new Safe is opened.
    ///
    /// @param  account The account opening the Safe.
    /// @param  index   The Safe index.
    /// @param  store   The Safe Store contract holding activeAssets.
    /// @param  amount  The amount of activeAssets deposited.
    event SafeOpened(address account, uint32 index, address store, uint256 amount);

    /// @notice Emitted when a Safe deposit operation is executed.
    ///
    /// @param  account The account depositing to the Safe.
    /// @param  index   The Safe index.
    /// @param  amount  The amount of activeAssets deposited.
    event SafeDeposit(address account, uint32 index, uint256 amount);

    /// @notice Emitted when a Safe transfer operation is executed.
    ///
    /// @param  from        The owner of the outgoing Safe transfer.
    /// @param  fromIndex   The Safe ID of the outgoing transfer.
    /// @param  to          The owner of the recipient Safe.
    /// @param  toIndex     The Safe ID of the recipient Safe.
    /// @param  amount      The amount of activeAssets transferred.
    event SafeTransfer(address from, uint32 fromIndex, address to, uint32 toIndex, uint256 amount);

    /// @notice Emitted when a Safe balance change operation is executed.
    ///
    /// @param  account The account of the Safe.
    /// @param  index   The Safe ID.
    /// @param  amount  The balance change amount.
    event SafeBalUpdated(address account, uint32 index, int256 amount);

    /// @notice Emitted when a Safe credit change operation is executed.
    ///
    /// @param  account The account of the Safe.
    /// @param  index   The Safe ID.
    /// @param  amount  The credit change amount.
    event SafeCreditUpdated(address account, uint32 index, int256 amount);

    /// @notice Internal function for opening a Safe.
    ///
    /// @param  amount      The amount of activeAssets to deposit.
    /// @param  depositFrom The account to deposit from.
    /// @param  store       The Safe Store contract to store activeAssets.
    function _open(
        uint256 amount,
        address depositFrom,
        address store   // Can add 'depositEnabled' to Safe Store contract.
    ) internal {
        AppStorage storage s = LibAppStorage.diamondStorage();

        uint256 shares  = IERC4626(store).deposit(amount, address(this), depositFrom);
        address asset   = IERC4626(store).asset();

        s.safe[msg.sender][s.safeIndex[msg.sender]].store       = store;
        s.safe[msg.sender][s.safeIndex[msg.sender]].creditAsset = s.creditAsset[asset];
        s.safe[msg.sender][s.safeIndex[msg.sender]].bal         = shares;
        s.safe[msg.sender][s.safeIndex[msg.sender]].credit      = amount.percentMul(s.LTV[asset]);
        s.safe[msg.sender][s.safeIndex[msg.sender]].status      = 1;

        emit SafeOpened(msg.sender, s.safeIndex[msg.sender], store, amount);

        s.safeIndex[msg.sender] += 1;
    }

    function _deposit(
        uint256 amount,
        address depositFrom,
        uint32  index
    ) internal {
        AppStorage storage s = LibAppStorage.diamondStorage();

        uint256 shares =
            IERC4626(s.safe[msg.sender][index].store).deposit(amount, address(this), depositFrom);

        s.safe[msg.sender][s.safeIndex[msg.sender]].bal += shares;

        emit SafeDeposit(msg.sender, index, amount);
    }

    function _transfer(
        uint256 amount,
        address recipient,
        uint32  fromIndex,
        uint32  toIndex
    ) internal {
        AppStorage storage s = LibAppStorage.diamondStorage();

        uint256 shares = IERC4626(s.safe[recipient][toIndex].store).previewDeposit(amount);

        s.safe[msg.sender][fromIndex].bal -= shares;
        s.safe[recipient][toIndex].bal += shares;

        emit SafeTransfer(msg.sender, fromIndex, recipient, toIndex, amount);
    }

    function _adjustBal(
        int256  amount,
        address account,
        uint32  index
    ) internal {
        AppStorage storage s = LibAppStorage.diamondStorage();

        if (amount >= 0) s.safe[account][index].bal += LibAppStorage.abs(amount);
        else s.safe[account][index].bal -= LibAppStorage.abs(amount);

        emit SafeBalUpdated(account, index, amount);
    }

    function _adjustCredit(
        int256  amount,
        address account,
        uint32  index
    ) internal {
        AppStorage storage s = LibAppStorage.diamondStorage();

        if (amount >= 0) s.safe[account][index].credit += LibAppStorage.abs(amount);
        else s.safe[account][index].credit -= LibAppStorage.abs(amount);

        emit SafeCreditUpdated(account, index, amount);
    }

    /// @notice Returns the origination fee incurred for a given borrow operation.
    ///
    /// @param  asset   The asset to borrow.
    /// @param  amount  The amount of assets to borrow.
    function _getOrigFee(
        address asset,
        uint256 amount
    ) internal view returns (uint256) {
        AppStorage storage s = LibAppStorage.diamondStorage();

        return amount.percentMul(s.origFee[asset]);
    }

    function _getMaxBorrow(
        address account,
        uint32  index
    ) internal view returns (uint256, uint256) {
        AppStorage storage s = LibAppStorage.diamondStorage();

        return (
            s.safe[account][index].credit -
                s.safe[account][index].credit.percentMul(s.origFee[s.safe[account][index].creditAsset]),
            s.safe[account][index].credit.percentMul(s.origFee[s.safe[account][index].creditAsset])
        );
    }

    // _isSafeActive(
    //     address account,
    //     uint32  index
    // ) internal view returns (uint8) {

    //     return s.safe[account][index].status;
    // }
}