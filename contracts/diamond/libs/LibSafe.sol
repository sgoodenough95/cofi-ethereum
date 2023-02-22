// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import { VaultParams, AppStorage, LibAppStorage } from "./LibAppStorage.sol";
import { IERC4626 } from ".././interfaces/IERC4626.sol";
import 'hardhat/console.sol';

library LibSafe {

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

    /// @notice Internal function for opening a Safe.
    ///
    /// @param  amount      The amount of activeAssets to deposit.
    /// @param  depositFrom The account to deposit from.
    /// @param  store       The Safe Store contract to store activeAssets.
    _open(
        uint256 amount,
        address depositFrom,
        address store   // Can add 'depositEnabled' to Safe Store contract.
    ) internal {
        AppStorage storage s = LibAppStorage.diamondStorage();

        IERC4626(store).deposit(amount, address(this), depositFrom);
        asset = IERC4626(store).asset();

        s.safe[msg.sender][s.safeIndex[msg.sender]].store   = store;
        s.safe[msg.sender][s.safeIndex[msg.sender]].credit  = s.creditAsset[asset];
        s.safe[msg.sender][s.safeIndex[msg.sender]].bal     = amount;
        // Leave debt at 0 (?) Account can have more credit if receiving credit transfer.
        s.safe[msg.sender][s.safeIndex[msg.sender]].status  = 1;

        emit SafeOpened(msg.sender, s.safeIndex[msg.sender], store, amount);

        s.safeIndex[msg.sender] += 1;
    }

    _deposit(
        uint256 amount,
        address depositFrom
        uint32  index
    ) internal {
        AppStorage storage s = LibAppStorage.diamondStorage();

        shares = IERC4626(store).deposit(amount, address(this), depositFrom);

        s.safe[msg.sender][s.safeIndex[msg.sender]].bal += shares;

        emit SafeDeposit(msg.sender, index, amount);
    }

    _transfer(
        uint256 amount,
        address recipient,
        uint32  fromIndex,
        uint32  toIndex
    ) internal {
        AppStorage storage s = LibAppStorage.diamondStorage();

        shares = IERC4626(s.safe[recipient][toIndex].store).previewDeposit(amount);

        s.safe[msg.sender][fromIndex].bal   -= shares;
        s.safe[recipient][toIndex].bal      += shares;

        emit SafeTransfer(msg.sender, fromIndex, recipient, toIndex, amount);
    }

    // _isSafeActive(
    //     address account,
    //     uint32  index
    // ) internal view returns (uint8) {

    //     return s.safe[account][index].status;
    // }
}