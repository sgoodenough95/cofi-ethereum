// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import { AppStorage, LibAppStorage } from "./LibAppStorage.sol";
import { IERC20 } from '@openzeppelin/contracts/interfaces/IERC20.sol';
import { GPv2SafeERC20 } from "./external/GPv2SafeERC20.sol";
import 'hardhat/console.sol';

library LibTreasury {
    using GPv2SafeERC20 for IERC20;

    /// @notice Emitted when the backing reserve of an asset is updated.
    ///
    /// @param  asset   The asset being backed.           
    /// @param  amount  The amount of backing assets.
    event BackingReserveUpdated(address asset, int256 amount);

    /// @notice Emitted when the creditRedeemAllowance of an account is updated.
    /// @notice Accounts that request to mint creditAssets directly can freely convert back.
    ///
    /// @param  account The updated account.
    /// @param  asset   The asset that is being backed.
    /// @param  amount  The amount the asset is being backed by.
    event CreditRedeemAllowanceUpdated(address account, address asset, int256 amount);

    /// @notice Emitted when an amount of reserve surplus is claimed of a backing asset.
    ///
    /// @param  amount  The amount claimed.
    /// @param  asset   The asset claimed.
    event ReserveSurplusClaimed(uint256 amount, address asset);

    /// @notice Adjusts the backing reserve of a particular asset by a backing asset (e.g., backing USDST with USDSTA).
    ///
    /// @param  asset           The asset being backed.
    /// @param  amount          The amount of backing assets.
    function _adjustBackingReserve(
        address asset,
        int256  amount
    ) internal returns (uint256) {
        AppStorage storage s = LibAppStorage.diamondStorage();

        if (amount >= 0) s.backingReserve[asset] += LibAppStorage.abs(amount);
        
        else s.backingReserve[asset] -= LibAppStorage.abs(amount);

        emit BackingReserveUpdated(asset, amount);

        return s.backingReserve[asset];
    }

    /// @notice Adjusts the creditRedeemAllowance of a given account for a particular asset.
    ///
    /// @param  asset   The creditAsset which has the allowance (e.g., cUSDST).
    /// @param  account The account which has the allowance updated.
    /// @param  amount  The added allowance amount.
    function _adjustCreditRedeemAllowance(
        address asset,
        address account,
        int256  amount
    ) internal returns (uint256) {
        AppStorage storage s = LibAppStorage.diamondStorage();

        if (amount >= 0) s.creditRedeemAllowance[account][asset] += LibAppStorage.abs(amount);
        else s.creditRedeemAllowance[account][asset] -= LibAppStorage.abs(amount);

        emit CreditRedeemAllowanceUpdated(account, asset, amount);

        return s.creditRedeemAllowance[account][asset];
    }

    // FIX
    function _claimReserveSurplus(
        address asset,
        uint256 amount
    ) internal {
        AppStorage storage s = LibAppStorage.diamondStorage();

        uint256 surplus =
            IERC20(asset).balanceOf(address(this)) - uint256(s.backingReserve[asset]);

        amount = amount > surplus ? surplus : amount;

        IERC20(asset).safeTransfer(msg.sender, surplus);
        emit ReserveSurplusClaimed(amount, asset);
    }
}