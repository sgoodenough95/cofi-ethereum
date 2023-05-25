// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import { AppStorage, LibAppStorage } from "./LibAppStorage.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { IERC4626 } from ".././interfaces/IERC4626.sol";

/*//////////////////////////////////////////////////////////////
                    PARTNER INTERFACES
//////////////////////////////////////////////////////////////*/

import ".././interfaces/beefy/ISwap.sol";

import 'hardhat/console.sol';

library LibVault {

    /*//////////////////////////////////////////////////////////////
                            PARTNER ADDRESSES
    //////////////////////////////////////////////////////////////*/

    ISwap internal constant HOPUSDCLP = ISwap(0x10541b07d8Ad2647Dc6cD67abd4c03575dade261);

    /*//////////////////////////////////////////////////////////////
                                EVENTS
    //////////////////////////////////////////////////////////////*/

    /// @notice Emitted when a wrap operation is executed.
    ///
    /// @param  amount      The amount of underlyingAssets wrapped.
    /// @param  depositFrom The account which supplied the underlyingAssets.
    /// @param  vault       The ERC4626 Vault.
    /// @param  shares      The amount of shares minted.
    event Wrap(uint256 amount, address indexed depositFrom, address indexed vault, uint256 shares);

    /// @notice Emitted when an unwrap operation is executed.
    ///
    /// @param  amount      The amount of fiAssets redeemed.
    /// @param  shares      The amount of shares burned.
    /// @param  vault       The ERC4626 Vault.
    /// @param  assets      The amount of underlyingAssets received from the Vault.
    /// @param  recipient   The recipient of the underlyingAssets.
    event Unwrap(uint256 amount, uint256 shares, address indexed vault, uint256 assets, address indexed recipient);

    /// @notice Emitted when a vault migration is executed.
    ///
    /// @param  fiAsset     The fiAsset to migrate underlyingAssets for.
    /// @param  oldVault    The vault migrated from.
    /// @param  newVault    The vault migrated to.
    /// @param  oldAssets   The amount of assets pre-migration.
    /// @param  newAssets   The amount of assets post-migration.
    event VaultMigration(address indexed fiAsset, address indexed oldVault, address indexed newVault, uint256 oldAssets, uint256 newAssets);

    /*//////////////////////////////////////////////////////////////
                                VIEWS
    //////////////////////////////////////////////////////////////*/

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

    /*//////////////////////////////////////////////////////////////
                            STATE CHANGE
    //////////////////////////////////////////////////////////////*/

    function _approve(
        address vault,
        uint256 assets
    ) internal {

        SafeERC20.safeApprove(IERC20(IERC4626(vault).asset()), vault, assets);
    }

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

        shares = IERC4626(vault).deposit(amount, address(this));
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
        uint256 shares = IERC4626(vault).previewDeposit(amount);    // Need to convert from USDC to USDC-LP

        assets = IERC4626(vault).redeem(shares, recipient, address(this));
        emit Unwrap(amount, shares, vault, assets, recipient);
    }

    /*//////////////////////////////////////////////////////////////
                        PARTNER INTEGRATION
    //////////////////////////////////////////////////////////////*/

    function _toPrime_HOPUSDCLP(
        address fiAsset,
        uint256 amount
    ) internal returns (uint256 assets) {
        AppStorage storage s = LibAppStorage.diamondStorage();

        uint256[] memory amounts = new uint256[](2);
        amounts[0] = amount;
        SafeERC20.safeApprove(IERC20(s.underlying[fiAsset]), address(HOPUSDCLP), amount);
        assets = HOPUSDCLP.addLiquidity(amounts, 0, block.timestamp + 30 seconds);
    }

    function _toUnderlying_HOPUSDCLP(
        address fiAsset,
        uint256 amount
    ) internal returns (uint256 assets) {
        AppStorage storage s = LibAppStorage.diamondStorage();

        address _asset = IERC4626(s.vault[fiAsset]).asset();
        console.log(_asset);

        SafeERC20.safeApprove(IERC20(IERC4626(s.vault[fiAsset]).asset()), address(HOPUSDCLP), amount);
        assets = HOPUSDCLP.removeLiquidityOneToken(
            amount,
            0,
            0,
            block.timestamp + 30 seconds
        );
    }

    function _convertToUnderlying_HOPUSDCLP(
        uint256 amount
    ) internal view returns (uint256 assets) {

        assets = HOPUSDCLP.calculateRemoveLiquidityOneToken(address(this), amount, 0);
    }

    function _convertToPrime_HOPUSDCLP(
        uint256 amount
    ) internal view returns (uint256 assets) {

        uint256[] memory amounts = new uint256[](2);
        amounts[0] = amount;
        assets = HOPUSDCLP.calculateTokenAmount(address(this), amounts, false);
    }
}