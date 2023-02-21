// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import { AppStorage, LibAppStorage } from "./LibAppStorage.sol";
import { IERC20 } from '@openzeppelin/contracts/interfaces/IERC20.sol';
import { GPv2SafeERC20 } from "./external/GPv2SafeERC20.sol";
import 'hardhat/console.sol';

library LibTreasury {
    using GPv2SafeERC20 for IERC20;

    /// @notice Emitted when the backing reserve of an asset is updated.
    ///
    /// @param  asset   The asset being backed.
    /// @param  add     Indicates if amount is added or subtracted.            
    /// @param  amount  The amount of backing assets.
    event BackingReserveUpdated(address asset, uint8 add, uint256 amount);

    /// @notice Emitted when the creditRedeemAllowance of an account is updated.
    /// @notice Accounts that request to mint creditAssets directly can freely convert back.
    ///
    /// @param  account The updated account.
    /// @param  asset   The asset that is being backed.
    /// @param  add     Indicates if amount is added or subtracted.
    /// @param  amount  The amount the asset is being backed by.
    event CreditRedeemAllowanceUpdated(address account, address asset, uint8 add, uint256 amount);

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
        uint256 amount,
        uint8   add
    ) internal returns (uint256) {  // (?) USDSC -> USDST -> 1,000.
        AppStorage storage s = LibAppStorage.diamondStorage();

        if (add == 1) s.backingReserve[asset] += amount;
        else s.backingReserve[asset] -= amount;
        emit BackingReserveUpdated(asset, add, amount);

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
        uint256 amount,
        uint8   add
    ) internal returns (uint256) {
        AppStorage storage s = LibAppStorage.diamondStorage();

        if (add == 1) s.creditRedeemAllowance[account][asset] += amount;
        else s.creditRedeemAllowance[account][asset] -= amount;
        emit CreditRedeemAllowanceUpdated(account, asset, add, amount);

        return s.creditRedeemAllowance[account][asset];
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