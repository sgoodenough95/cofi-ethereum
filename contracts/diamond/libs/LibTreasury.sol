// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import { AppStorage, LibAppStorage } from "./LibAppStorage.sol";
import { IERC20 } from '@openzeppelin/contracts/interfaces/IERC20.sol';
import { IERC4626 } from ".././interfaces/IERC4626.sol";
import { GPv2SafeERC20 } from "./external/GPv2SafeERC20.sol";
import 'hardhat/console.sol';

library LibTreasury {
    using GPv2SafeERC20 for IERC20;

    /// @notice Emitted when the backing reserve of a fiAsset is updated.
    ///
    /// @param  vault   The backing vault.         
    /// @param  amount  The amount of backing assets.
    event BackingReserveUpdated(address vault, int256 amount);

    // /// @notice Emitted when an amount of reserve surplus is claimed of a backing asset.
    // ///
    // /// @param  amount  The amount claimed.
    // /// @param  asset   The asset claimed.
    // event ReserveSurplusClaimed(uint256 amount, address asset);

    /// @notice Adjusts the backing of a fiAsset by a given share token (e.g., COFI => yvDAI).
    ///
    /// @param  vault   The backing asset (always a share token, e.g., yvDAI).
    /// @param  amount  The amount of backing assets (denominated in assets, not shares, e.g., DAI).
    function _adjustBacking(
        address vault,
        int256  amount
    )   internal
        returns (uint256)
    {
        AppStorage storage s = LibAppStorage.diamondStorage();

        if (amount >= 0) s.backing[vault] += LibAppStorage.abs(amount);
        
        else s.backing[vault] -= LibAppStorage.abs(amount);

        emit BackingReserveUpdated(vault, amount);

        return s.backing[vault];
    }

    // /// @notice Admin function for claiming funds that are not held as backing.
    // ///
    // /// @param  asset   The backing reserve of the asset (e.g., USDST).
    // /// @param  amount  The amount to claim. If above surplus then transfers entire surplus.
    // function _claimReserveSurplus(
    //     address asset,
    //     uint256 amount
    // ) internal {
    //     AppStorage storage s = LibAppStorage.diamondStorage();

    //     uint256 surplus =
    //         IERC20(asset).balanceOf(address(this)) - uint256(s.backingReserve[asset]);

    //     amount = amount > surplus ? surplus : amount;

    //     IERC20(asset).safeTransfer(msg.sender, amount);
    //     emit ReserveSurplusClaimed(amount, asset);
    // }
}