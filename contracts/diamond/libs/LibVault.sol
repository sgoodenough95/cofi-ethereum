// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import { AppStorage, LibAppStorage } from "./LibAppStorage.sol";
import { IERC4626 } from ".././interfaces/IERC4626.sol";
import 'hardhat/console.sol';

library LibVault {

    /// @notice Emitted when a wrap operation is executed.
    ///
    /// @param  amount      The amount of underlyingAssets wrapped.
    /// @param  depositFrom The account which supplied the underlyingAssets.
    /// @param  vault       The ERC4626 Vault.
    /// @param  shares      The amount of shares minted.
    event Wrap(uint256 amount, address depositFrom, address vault, uint256 shares);

    /// @notice Emitted when an unwrap operation is executed.
    ///
    /// @param  amount      The amount of fiAssets redeemed.
    /// @param  shares      The amount of shares burned.
    /// @param  vault       The ERC4626 Vault.
    /// @param  assets      The amount of underlyingAssets received from the Vault.
    /// @param  recipient   The recipient of the underlyingAssets.
    event Unwrap(uint256 amount, uint256 shares, address vault, uint256 assets, address recipient);

    /// @notice Wraps an underlyingAsset into shares via a Vault.
    /// @dev    Shares reside at the Diamond at all times.
    ///
    /// @param  amount      The amount of underlyingAssets to wrap.
    /// @param  vault       The ERC4626 Vault.
    /// @param  depositFrom The account to wrap underlyingAssets from.
    function _wrap(
        uint256 amount,
        address vault,
        address depositFrom
    ) internal returns (uint256 shares) {

        shares = IERC4626(vault).deposit_(amount, address(this), depositFrom);
        emit Wrap(amount, depositFrom, vault, shares);
    }

    /// @notice Unwraps shares into underlyingAssets via the relevant Vault.
    ///
    /// @param  amount      The amount of fiAssets to redeem (target 1:1 correlation to underlyingAssets).
    /// @param  vault       The ERC4626 Vault.
    /// @param  recipient   The recipient of the underlyingAssets.
    function _unwrap(
        uint256 amount,
        address vault,
        address recipient
    ) internal returns (uint256 assets) {

        // Retrieve the corresponding number of shares for the amount of fiAssets provided.
        uint256 shares = IERC4626(vault).previewDeposit(amount);

        assets = IERC4626(vault).redeem(shares, recipient, address(this));
        emit Unwrap(amount, shares, vault, assets, recipient);
    }

    function _getAssets(
        uint256 shares,
        address vault
    ) internal view returns (uint256 assets) {

        assets = IERC4626(vault).previewRedeem(shares);
    }

    function _getShares(
        uint256 assets,
        address vault
    ) internal view returns (uint256 shares) {

        shares = IERC4626(vault).previewDeposit(assets);
    }

    /// @notice Gets total value of Diamond's holding of shares from the relevant Vault.
    function _totalValue(
        address vault
    ) internal view returns (uint256 assets) {

        assets = IERC4626(vault).maxWithdraw(address(this));
    }
}