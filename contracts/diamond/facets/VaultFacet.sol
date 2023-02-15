// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

/**
    █▀▀ ▀▀█▀▀ █▀▀█ █▀▀█ 
    ▀▀█ ░░█░░ █░░█ █▄▄█ 
    ▀▀▀ ░░▀░░ ▀▀▀▀ ▀░░▀

    @author stoa.money
    @title  Vault Facet
    @notice User-operated functions for interacting with supported vaults.
 */

import { VaultParams, Modifiers } from "../libs/LibAppStorage.sol";
import { LibToken } from "../libs/LibToken.sol";
import { LibVault } from "../libs/LibVault.sol";
import { LibTreasury } from "../libs/LibTreasury.sol";
import { IStoa } from "../interfaces/IStoa.sol";

contract VaultFacet is Modifiers {

    /// @notice Converts an accepted inputAsset into an activeAsset (e.g., USDC to USDSTA).
    ///
    /// @param  amount      The amount of inputAssets to deposit.
    /// @param  vault       The address of the vault.
    /// @param  depositFrom The address to deposit inputAssets from.
    /// @param  recipient   The recipient of the activeAssets.
    function inputToActiveVault(
        uint256 amount,
        address vault,
        address depositFrom,
        address recipient
    ) external minDeposit(amount, vault) returns (uint256 mintAfterFee) {

        VaultParams memory _vault = s.vaultParams[vault];

        require(_vault.enabled != 1, "VaultFacet: Vault disabled");

        require(LibToken._isMintEnabled(_vault.active) != 1, "VaultFacet: Mint disabled");

        uint256 shares = LibVault._wrap(amount, vault, depositFrom);

        uint256 assets = LibVault._getAssets(shares, vault);

        uint256 fee = LibToken._getMintFee(_vault.active, assets);
        mintAfterFee = assets - fee;

        LibToken._mint(_vault.active, recipient, mintAfterFee);

        if (fee > 0) {
           LibToken._mint(_vault.active, s.feeCollector, fee);
            emit LibToken.MintFeeCaptured(_vault.active, fee); 
        }
    }

    /// @notice Converts an accepted inputAsset into an activeAsset (e.g., USDC to USDSTA).
    /// @notice Mints a backing asset to Stoa (e.g., USDSTA).
    ///
    /// @param  amount      The amount of inputAssets to deposit.
    /// @param  vault       The address of the vault.
    /// @param  depositFrom The account to deposit inputAssets from.
    /// @param  recipient   The recipient of the unactiveAssets.
    function inputToUnactiveVault(
        uint256 amount,
        address vault,
        address depositFrom,
        address recipient
    ) external minDeposit(amount, vault) returns (uint256 mintAfterFee) {

        VaultParams memory _vault = s.vaultParams[vault];

        require(_vault.enabled != 1, "VaultFacet: Vault disabled");

        require(LibToken._isMintEnabled(_vault.unactive) != 1, "VaultFacet: Mint disabled");

        uint256 shares = LibVault._wrap(amount, vault, depositFrom);

        uint256 assets = LibVault._getAssets(shares, vault);

        uint256 fee = LibToken._getMintFee(_vault.unactive, assets);
        mintAfterFee = assets - fee;

        LibToken._mint(s.backingAsset[_vault.unactive], address(this), mintAfterFee);

        LibTreasury._adjustBackingReserve(
            s.backingAsset[_vault.unactive],
            int256(mintAfterFee)
        );

        LibToken._mint(_vault.unactive, recipient, mintAfterFee);

        LibTreasury._adjustUnactiveRedemptionAllowance(
            _vault.unactive,
            depositFrom,
            int256(mintAfterFee)
        );

        if (fee > 0) {
           LibToken._mint(s.backingAsset[_vault.unactive], s.feeCollector, fee);
            emit LibToken.MintFeeCaptured(s.backingAsset[_vault.unactive], fee); 
        }
    }

    /// @notice Redeems an activeAsset for an inputAsset.
    ///
    /// @param  amount      The amount of activeAssets to redeem.
    /// @param  vault       The address of the vault.
    /// @param  depositFrom The account to deposit activeAssets from.
    /// @param  recipient   The recipient of the inputAssets.
    function redeemActiveVault(
        uint256 amount,
        address vault,
        address depositFrom,
        address recipient
    ) external minDeposit(amount, vault) returns (uint256 burnAfterFee) {

        VaultParams memory _vault = s.vaultParams[vault];

        require(_vault.enabled != 1, "VaultFacet: Vault disabled");

        LibToken._transferFrom(_vault.active, amount, depositFrom, s.feeCollector);

        uint256 fee = LibToken._getRedeemFee(_vault.active, amount);
        burnAfterFee = amount - fee;

        LibToken._burn(_vault.active, s.feeCollector, burnAfterFee);
        if (fee > 0) {
            emit LibToken.RedeemFeeCaptured(_vault.active, fee);
        }

        LibVault._unwrap(amount, vault, recipient);
    }

    /// @notice Redeems an unactiveAsset for an inputAsset.
    ///
    /// @param  amount      The amount of unactiveAssets to redeem.
    /// @param  vault       The address of the vault.
    /// @param  depositFrom The account to deposit unactiveAssets from.
    /// @param  recipient   The recipient of the inputAssets.
    function redeemUnactiveVault(
        uint256 amount,
        address vault,
        address depositFrom,
        address recipient
    ) external minDeposit(amount, vault) returns (uint256 burnAfterFee) {

        VaultParams memory _vault = s.vaultParams[vault];

        require(_vault.enabled != 1, "VaultFacet: Vault disabled");

        LibToken._burn(_vault.unactive, depositFrom, amount);

        uint256 fee = LibToken._getRedeemFee(_vault.unactive, amount);
        burnAfterFee = amount - fee;

        LibToken._burn(_vault.active, address(this), amount);

        LibVault._unwrap(amount, vault, recipient);

        LibTreasury._adjustUnactiveRedemptionAllowance(
            _vault.unactive,
            depositFrom,
            int256(amount) * -1
        );

        LibTreasury._adjustBackingReserve(
            s.backingAsset[_vault.unactive],
            int256(amount) * -1
        );
        if (fee > 0) {
            // Redeem fee captured in the (previously backing) activeAsset.
            emit LibToken.RedeemFeeCaptured(_vault.active, fee);
        }
    }

    function getVault(
        address vault
    ) external view returns (VaultParams memory) {

        return s.vaultParams[vault];
    }
}