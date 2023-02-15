// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import { AppStorage, LibAppStorage } from "./LibAppStorage.sol";
import { IERC20 } from '@openzeppelin/contracts/interfaces/IERC20.sol';
import { GPv2SafeERC20 } from "./external/GPv2SafeERC20.sol";

library LibTreasury {
    using GPv2SafeERC20 for IERC20;

    /// @notice Emitted when the backing reserve of an asset is updated.
    ///
    /// @param  asset           The asset being backed.
    /// @param  amount          The amount of backing assets.
    event BackingReserveUpdated(address asset, int256 amount);

    /// @notice Emitted when the unactive redemption allowance of an account is updated.
    /// @notice Accounts that request to mint unactive tokens directly can freely convert back.
    ///
    /// @param  account The updated account.
    /// @param  asset   The asset that is being backed.
    /// @param  amount  The amount the asset is being backed by.
    event UnactiveRedemptionAllowanceUpdated(address account, address asset, int256 amount);

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
    ) internal returns (int256) {
        AppStorage storage s = LibAppStorage.diamondStorage();

        s.backingReserve[asset] += amount;
        emit BackingReserveUpdated(asset, amount);

        return s.backingReserve[asset];
    }

    /// @notice Adjusts the unactive redemption allowance of a given account for a particular asset.
    ///
    /// @param  asset   The asset which has the allowance (e.g., USDST).
    /// @param  account The account which has the allowance updated.
    /// @param  amount  The added allowance amount.
    function _adjustUnactiveRedemptionAllowance(
        address asset,
        address account,
        int256  amount
    ) internal returns (int256) {
        AppStorage storage s = LibAppStorage.diamondStorage();

        s.unactiveRedemptionAllowance[account][asset] += amount;
        emit UnactiveRedemptionAllowanceUpdated(account, asset, amount);

        return s.unactiveRedemptionAllowance[account][asset];
    }

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