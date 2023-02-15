// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import { VaultParams, AppStorage, LibAppStorage } from "./LibAppStorage.sol";
import { IERC4626 } from ".././interfaces/IERC4626.sol";

library LibVault {

    /// @notice Emitted when a wrap operation is executed.
    ///
    /// @param  amount      The amount of inputAssets wrapped.
    /// @param  depositFrom The account which supplied the inputAssets.
    /// @param  vault       The wrapped inputAsset.
    /// @param  shares      The amount of share tokens issued.
    event Wrap(uint256 amount, address depositFrom, address vault, uint256 shares);

    /// @notice Emitted when an unwrap operation is executed.
    ///
    /// @param  amount      The requested amount of inputAssets to receive.
    /// @param  shares      The amount of share tokens, calculated through convertToShares(amount).
    /// @param  vault       The vault holding inputAssets.
    /// @param  assets      The actual amount of inputAssets received.
    /// @param  recipient   The recipient of the inputAssets.
    event Unwrap(uint256 amount, uint256 shares, address vault, uint256 assets, address recipient);

    // /// @notice Indicates if an operation failed due to the address provided not signifying an enabled vault.
    // ///
    // /// @param  vault   The address of the vault.
    // error VaultDisabled(address vault);

    // /// @notice Indicates if a vault migration failed (e.g., due to a reduction in assets).
    // ///
    // /// @param  vault   The address of the new vault.
    // error VaultMigrationFailed(address vault);

    /// @notice Wraps an inputAsset into share tokens issued by a vault.
    /// @dev    Stoa holds the share tokens issued by the vault.
    ///
    /// @param  amount      The amount of inputAssets to wrap.
    /// @param  vault       The vault to wrap inputAssets for.
    /// @param  depositFrom The account to wrap inputAssets from.
    function _wrap(
        uint256 amount,
        address vault,
        address depositFrom
    ) internal returns (uint256 shares) {

        shares = IERC4626(vault).deposit(amount, address(this), depositFrom);
        emit Wrap(amount, depositFrom, vault, shares);
    }

    /// @notice Unwraps share tokens into inputAssets.
    /// @dev    Stoa holds the share tokens.
    ///
    /// @param  amount      The requested amount of inputAssets to receive. May slightly differ to assets received.
    /// @param  vault       The vault to unwrap from.
    /// @param  recipient   The recipient of the inputAssets.
    function _unwrap(
        uint256 amount,
        address vault,
        address recipient
    ) internal returns (uint256 assets) {

        uint256 shares = IERC4626(vault).convertToShares(amount);

        assets = IERC4626(vault).redeem(shares, recipient, address(this));
        emit Unwrap(amount, shares, vault, assets, recipient);
    }

    function _unwrapShares(
        uint256 shares,
        address vault,
        address recipient
    ) internal returns (uint256 assets) {

        assets = IERC4626(vault).redeem(shares, recipient, address(this));
        emit Unwrap(0, shares, vault, assets, recipient);
    }

    function _getAssets(
        uint256 shares,
        address vault
    ) internal view returns (uint256 assets) {

        assets = IERC4626(vault).convertToAssets(shares);
    }

    /// @notice Gets total value of Stoa's holding of shares from vault.
    function _totalValue(
        address vault
    ) internal view returns (uint256 assets) {

        assets = IERC4626(vault).maxWithdraw(address(this));
    }
}