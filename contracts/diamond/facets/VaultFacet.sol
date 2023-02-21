// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

/**
    █▀▀ ▀▀█▀▀ █▀▀█ █▀▀█ 
    ▀▀█ ░░█░░ █░░█ █▄▄█ 
    ▀▀▀ ░░▀░░ ▀▀▀▀ ▀░░▀

    @author stoa.money
    @title  Vault Facet
    @notice User-operated functions for interacting with supported vaults.
    @dev    TO-DO: Enable support for multiple vaults.
 */

import { VaultParams, Modifiers } from "../libs/LibAppStorage.sol";
import { LibToken } from "../libs/LibToken.sol";
import { LibVault } from "../libs/LibVault.sol";
import { LibTreasury } from "../libs/LibTreasury.sol";
import { IStoa } from "../interfaces/IStoa.sol";

contract VaultFacet is Modifiers {

    /// @notice Converts an accepted inputAsset into an activeAsset (e.g., USDC to USDFI).
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
    )
        external
        minDeposit(amount, s.vaultParams[vault].input)
        returns (uint256 mintAfterFee)
    {
        VaultParams memory _vault = s.vaultParams[vault];

        require(_vault.enabled == 1, "VaultFacet: Vault disabled");

        require(LibToken._isMintEnabled(_vault.active) == 1, "VaultFacet: Mint disabled");

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

    /// @notice Converts an accepted inputAsset into a creditAsset (e.g., USDC to USDSC).
    /// @notice Mints a backing asset to Stoa (e.g., USDFI).
    /// @notice Recall caller does not get yield exposure to activeAsset.
    /// @notice Motivation therefore is to offer credit on vault to begin with.
    /// @dev    May later remove when direct minting of credit via Exchange is live.
    ///
    /// @param  amount      The amount of inputAssets to deposit.
    /// @param  vault       The address of the vault.
    /// @param  depositFrom The account to deposit inputAssets from.
    /// @param  recipient   The recipient of the creditAssets.
    function inputToCreditVault(
        uint256 amount,
        address vault,
        address depositFrom,
        address recipient
    )
        external
        minDeposit(amount, s.vaultParams[vault].input)
        returns (uint256 mintAfterFee)
    {
        VaultParams memory _vault = s.vaultParams[vault];

        require(_vault.enabled == 1, "VaultFacet: Vault disabled");

        require(LibToken._isMintEnabled(_vault.credit) == 1, "VaultFacet: Mint disabled");

        uint256 shares = LibVault._wrap(amount, vault, depositFrom);

        uint256 assets = LibVault._getAssets(shares, vault);

        uint256 fee = LibToken._getMintFee(_vault.credit, assets);
        mintAfterFee = assets - fee;

        /**
            STEPS FOR ISSUING CREDIT

            1.  Obtain backing asset.
            1.  Increase the backing reserve.
            2.  Mint credit to the recipient.
            3.  Increase credit redemption allowance.
         */

        // (1)
        LibToken._mint(s.primeVaultBacking[_vault.credit], address(this), amount);

        // Capture 'fee' amount of USDST (as amount - fee is serving as backing).
        // Admin can claim at a future point to redeem fees [activeAssets].
        if (fee > 0) emit LibToken.MintFeeCaptured(s.primeVaultBacking[_vault.credit], fee);

        // (2)
        LibTreasury._adjustBackingReserve(
            s.primeVaultBacking[_vault.credit],
            mintAfterFee,
            1
        );

        // (3)
        LibToken._mint(_vault.credit, recipient, mintAfterFee);

        // (4)
        LibTreasury._adjustCreditRedeemAllowance(
            _vault.credit,
            depositFrom,
            mintAfterFee,
            1
        );
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
    )
        external
        minWithdraw(amount, s.vaultParams[vault].active)
        returns (uint256 burnAfterFee) 
    {
        VaultParams memory _vault = s.vaultParams[vault];

        require(_vault.enabled == 1, "VaultFacet: Vault disabled");

        LibToken._transferFrom(_vault.active, amount, depositFrom, s.feeCollector);

        uint256 fee = LibToken._getRedeemFee(_vault.active, amount);
        burnAfterFee = amount - fee;

        LibToken._burn(_vault.active, s.feeCollector, burnAfterFee);
        if (fee > 0) {
            emit LibToken.RedeemFeeCaptured(_vault.active, fee);
        }

        LibVault._unwrap(amount, vault, recipient);
    }

    /// @notice Redeems a creditAsset for an inputAsset.
    ///
    /// @param  amount      The amount of creditAssets to redeem.
    /// @param  vault       The address of the vault.
    /// @param  depositFrom The account to deposit creditAssets from.
    /// @param  recipient   The recipient of the inputAssets.
    function redeemCreditVault(
        uint256 amount,
        address vault,
        address depositFrom,
        address recipient
    )   external
        minWithdraw(amount, s.vaultParams[vault].credit)
        returns (uint256 burnAfterFee)
    {
        VaultParams memory _vault = s.vaultParams[vault];

        require(_vault.enabled == 1, "VaultFacet: Vault disabled");

        require(
            s.creditConvertEnabled[_vault.credit][_vault.active] == 1,
            "ExchangeFacet: Credit convert disabled"
        );

        require(
            amount >= s.creditRedeemAllowance[depositFrom][_vault.credit],
            "ExchangeFacet: Invalid credit redemption allowance"
        );

         /**
            STEPS FOR REDEEMING CREDIT

            1.  Burn credit from depositFrom.
            1.  Decrease the backing reserve.
            2.  Transfer assets to the recipient.
            3.  Decrease credit redemption allowance.
         */    

        // (1)
        LibToken._burn(_vault.credit, depositFrom, amount);

        uint256 fee = LibToken._getRedeemFee(_vault.credit, amount);
        burnAfterFee = amount - fee;

        LibToken._burn(_vault.active, address(this), amount);
        if (fee > 0) {
            // Redeem fee captured in the (previously backing) activeAsset.
            emit LibToken.RedeemFeeCaptured(_vault.active, fee);
        }

        // (2)
        LibTreasury._adjustBackingReserve(
            _vault.active,
            amount,
            0
        );

        // (3)
        LibVault._unwrap(amount, vault, recipient);

        // (4)
        LibTreasury._adjustCreditRedeemAllowance(
            _vault.credit,
            depositFrom,
            amount,
            0
        );
    }

    function getVault(
        address vault
    ) external view returns (VaultParams memory) {

        return s.vaultParams[vault];
    }
}