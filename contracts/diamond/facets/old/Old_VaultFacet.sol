// // SPDX-License-Identifier: MIT
// pragma solidity 0.8.19;

// /**
//     █▀▀ ▀▀█▀▀ █▀▀█ █▀▀█ 
//     ▀▀█ ░░█░░ █░░█ █▄▄█ 
//     ▀▀▀ ░░▀░░ ▀▀▀▀ ▀░░▀

//     @author stoa.money
//     @title  Vault Facet
//     @notice User-operated functions for interacting with supported vaults.
//     @dev    TO-DO: Enable support for multiple vaults.
//  */

// import { VaultParams, Modifiers } from "../libs/LibAppStorage.sol";
// import { LibToken } from "../libs/LibToken.sol";
// import { LibVault } from "../libs/LibVault.sol";
// import { LibTreasury } from "../libs/LibTreasury.sol";
// import { IERC4626 } from ".././interfaces/IERC4626.sol";

// contract VaultFacet is Modifiers {

//     /// @notice Converts an accepted inputAsset into an activeAsset (e.g., USDC to USDFI).
//     /// [STATUS: Ready to deploy]
//     /// @param  amount          The amount of inputAssets to deposit.
//     /// @param  vault           The address of the vault.
//     /// @param  depositFrom     The address to deposit inputAssets from.
//     /// @param  recipient       The recipient of the activeAssets.
//     /// @param  minAmountOut    The minimum amount of activeAssets received (before fees).
//     function inputToActive(
//         uint256 amount,
//         uint256 minAmountOut,
//         address vault,
//         address depositFrom,
//         address recipient
//     )
//         external
//         minDeposit(amount, s.vaultParams[vault].input)
//         returns (uint256 mintAfterFee)
//     {
//         VaultParams memory _vault = s.vaultParams[vault];

//         require(_vault.enabled == 1, "VaultFacet: Vault disabled");

//         require(LibToken._isMintEnabled(_vault.active) == 1, "VaultFacet: Mint disabled");

//         uint256 shares = LibVault._wrap(amount, vault, depositFrom);

//         uint256 assets = LibVault._getAssets(shares, vault);
//         require(assets >= minAmountOut, 'VaultFacet: Slippage exceeded');

//         uint256 fee = LibToken._getMintFee(_vault.active, assets);
//         mintAfterFee = assets - fee;

//         LibToken._mint(_vault.active, recipient, mintAfterFee);

//         if (fee > 0) {
//            LibToken._mint(_vault.active, address(this), fee);
//             emit LibToken.MintFeeCaptured(_vault.active, fee); 
//         }
//     }

//     /// @notice Converts an accepted inputAsset into a creditAsset (e.g., USDC to USDSC).
//     /// @notice Mints a backing asset to Stoa (e.g., USDFI).
//     /// [STATUS: Ready to deploy]
//     /// @param  amount          The amount of inputAssets to deposit.
//     /// @param  vault           The address of the vault.
//     /// @param  depositFrom     The account to deposit inputAssets from.
//     /// @param  recipient       The recipient of the creditAssets.
//     /// @param  minAmountOut    The minimum amount of activeAssets received (before fees).
//     function inputToCredit(
//         uint256 amount,
//         uint256 minAmountOut,
//         address vault,
//         address depositFrom,
//         address recipient
//     )
//         external
//         minDeposit(amount, s.vaultParams[vault].input)
//         returns (uint256 mintAfterFee)
//     {
//         VaultParams memory _vault = s.vaultParams[vault];

//         require(_vault.enabled == 1, "VaultFacet: Vault disabled");

//         require(LibToken._isMintEnabled(_vault.credit) == 1, "VaultFacet: Mint disabled");

//         uint256 shares = LibVault._wrap(amount, vault, depositFrom);

//         uint256 assets = LibVault._getAssets(shares, vault);
//         require(assets >= minAmountOut, 'VaultFacet: Slippage exceeded');

//         uint256 fee = LibToken._getMintFee(_vault.credit, assets);
//         mintAfterFee = assets - fee;

//         /**
//             STEPS FOR ISSUING CREDIT

//             1.  Obtain backing asset.
//             1.  Increase the backing reserve.
//             2.  Mint credit to the recipient.
//             3.  Increase credit redemption allowance.
//          */

//         // (1)
//         LibToken._mint(s.primeVaultBacking[_vault.credit], address(this), amount);

//         // Capture 'fee' amount of USDST (as amount - fee is serving as backing).
//         // Admin can claim at a future point to redeem fees [activeAssets].
//         if (fee > 0) emit LibToken.MintFeeCaptured(s.primeVaultBacking[_vault.credit], fee);

//         // (2)
//         LibTreasury._adjustBackingReserve(
//             s.primeVaultBacking[_vault.credit],
//             int256(mintAfterFee)
//         );

//         // (3)
//         LibToken._mint(_vault.credit, recipient, mintAfterFee);

//         // (4)
//         LibTreasury._adjustCreditRedeemAllowance(
//             _vault.credit,
//             depositFrom,
//             int256(mintAfterFee)
//         );
//     }

//     /// @notice Converts an accepted share token into an activeAsset (e.g., yvUSDC to USDFI).
//     /// [STATUS: Ready to deploy]
//     /// @param  shares          The amount of shares to deposit (issued by vault).
//     /// @param  vault           The address of the vault.
//     /// @param  depositFrom     The address to deposit inputAssets from.
//     /// @param  recipient       The recipient of the activeAssets.
//     /// @param  minAmountOut    The minimum amount of activeAssets received (before fees).
//     function vaultToActive(
//         uint256 shares,
//         uint256 minAmountOut,
//         address vault,
//         address depositFrom,
//         address recipient
//     )
//         external
//         minDeposit(LibVault._getAssets(shares, vault), s.vaultParams[vault].input)
//         returns (uint256 mintAfterFee)
//     {
//         VaultParams memory _vault = s.vaultParams[vault];

//         require(_vault.enabled == 1, "VaultFacet: Vault disabled");

//         require(LibToken._isMintEnabled(_vault.active) == 1, "VaultFacet: Mint disabled");

//         LibToken._transferFrom(vault, shares, depositFrom, address(this));

//         uint256 assets = LibVault._getAssets(shares, vault);
//         require(assets >= minAmountOut, 'VaultFacet: Slippage exceeded');

//         uint256 fee = LibToken._getMintFee(_vault.active, assets);
//         mintAfterFee = assets - fee;

//         LibToken._mint(_vault.active, recipient, mintAfterFee);

//         if (fee > 0) {
//            LibToken._mint(_vault.active, address(this), fee);
//             emit LibToken.MintFeeCaptured(_vault.active, fee); 
//         }
//     }

//     /// @notice Converts an accepted share token into a creditAsset (e.g., yvUSDC to USDSC).
//     /// @notice Mints a backing asset to Stoa (e.g., USDFI).
//     /// [STATUS: Ready to deploy]
//     /// @param  shares          The amount of shares to deposit (issued by vault).
//     /// @param  vault           The address of the vault.
//     /// @param  depositFrom     The account to deposit inputAssets from.
//     /// @param  recipient       The recipient of the creditAssets.
//     /// @param  minAmountOut    The minimum amount of activeAssets received (before fees).
//     function vaultToCredit(
//         uint256 shares,
//         uint256 minAmountOut,
//         address vault,
//         address depositFrom,
//         address recipient
//     )
//         external
//         minDeposit(LibVault._getAssets(shares, vault), s.vaultParams[vault].input)
//         returns (uint256 mintAfterFee)
//     {
//         VaultParams memory _vault = s.vaultParams[vault];

//         require(_vault.enabled == 1, "VaultFacet: Vault disabled");

//         require(LibToken._isMintEnabled(_vault.credit) == 1, "VaultFacet: Mint disabled");

//         LibToken._transferFrom(vault, shares, depositFrom, address(this));

//         uint256 assets = LibVault._getAssets(shares, vault);
//         require(assets >= minAmountOut, 'VaultFacet: Slippage exceeded');

//         uint256 fee = LibToken._getMintFee(_vault.credit, assets);
//         mintAfterFee = assets - fee;

//         /**
//             STEPS FOR ISSUING CREDIT

//             1.  Obtain backing asset.
//             1.  Increase the backing reserve.
//             2.  Mint credit to the recipient.
//             3.  Increase credit redemption allowance.
//          */

//         // (1)
//         LibToken._mint(s.primeVaultBacking[_vault.credit], address(this), assets);

//         // Capture 'fee' amount of USDST (as amount - fee is serving as backing).
//         // Admin can claim at a future point to redeem fees [activeAssets].
//         if (fee > 0) emit LibToken.MintFeeCaptured(s.primeVaultBacking[_vault.credit], fee);

//         // (2)
//         LibTreasury._adjustBackingReserve(
//             s.primeVaultBacking[_vault.credit],
//             int256(mintAfterFee)
//         );

//         // (3)
//         LibToken._mint(_vault.credit, recipient, mintAfterFee);

//         // (4)
//         LibTreasury._adjustCreditRedeemAllowance(
//             _vault.credit,
//             depositFrom,
//             int256(mintAfterFee)
//         );
//     }

//     /// @notice Converts an activeAsset to an inputAsset.
//     /// [STATUS: Ready to deploy]
//     /// @param  amount          The amount of activeAssets to redeem.
//     /// @param  vault           The address of the vault.
//     /// @param  depositFrom     The account to deposit activeAssets from.
//     /// @param  recipient       The recipient of the inputAssets.
//     /// @param  minAmountOut    The minimum amount of inputAssets received (before fees).
//     function activeToInput(
//         uint256 amount,
//         uint256 minAmountOut,
//         address vault,
//         address depositFrom,
//         address recipient
//     )
//         external
//         minWithdraw(amount, s.vaultParams[vault].active)
//         returns (uint256 burnAfterFee) 
//     {
//         VaultParams memory _vault = s.vaultParams[vault];

//         require(_vault.enabled == 1, "VaultFacet: Vault disabled");

//         LibToken._transferFrom(_vault.active, amount, depositFrom, address(this));

//         uint256 fee = LibToken._getRedeemFee(_vault.active, amount);
//         burnAfterFee = amount - fee;

//         LibToken._burn(_vault.active, address(this), burnAfterFee);
//         if (fee > 0) {
//             emit LibToken.RedeemFeeCaptured(_vault.active, fee);
//         }

//         uint256 assets = LibVault._unwrap(burnAfterFee, vault, recipient);
//         require(assets >= minAmountOut, 'VaultFacet: Slippage exceeded');
//     }

//     /// @notice Converts an activeAsset to a share token (issued by vault).
//     /// [STATUS: Ready to deploy]
//     /// @param  amount          The amount of activeAssets to redeem.
//     /// @param  vault           The address of the vault.
//     /// @param  depositFrom     The account to deposit activeAssets from.
//     /// @param  recipient       The recipient of the inputAssets.
//     /// @param  minAmountOut    The minimum amount of inputAssets received (before fees).
//     function activeToVault(
//         uint256 amount,
//         uint256 minAmountOut,
//         address vault,
//         address depositFrom,
//         address recipient
//     )
//         external
//         minWithdraw(amount, s.vaultParams[vault].active)
//         returns (uint256 burnAfterFee) 
//     {
//         VaultParams memory _vault = s.vaultParams[vault];

//         require(_vault.enabled == 1, "VaultFacet: Vault disabled");

//         LibToken._transferFrom(_vault.active, amount, depositFrom, address(this));

//         uint256 fee = LibToken._getRedeemFee(_vault.active, amount);
//         burnAfterFee = amount - fee;

//         LibToken._burn(_vault.active, address(this), burnAfterFee);
//         if (fee > 0) {
//             emit LibToken.RedeemFeeCaptured(_vault.active, fee);
//         }

//         uint256 shares = IERC4626(vault).previewDeposit(burnAfterFee);

//         LibToken._transfer(vault, shares, recipient);
//         // May need to revisit slippage application.
//         require(
//             LibVault._getAssets(shares, vault) >= minAmountOut,
//             'VaultFacet: Slippage exceeded'
//         );
//     }

//     /// @notice Converts a creditAsset to an inputAsset.
//     /// [STATUS: Ready to deploy]
//     /// @param  amount          The amount of creditAssets to redeem.
//     /// @param  vault           The address of the vault.
//     /// @param  depositFrom     The account to deposit creditAssets from.
//     /// @param  recipient       The recipient of the inputAssets.
//     /// @param  minAmountOut    The minimum amount of inputAssets received (before fees).
//     function creditToInput(
//         uint256 amount,
//         uint256 minAmountOut,
//         address vault,
//         address depositFrom,
//         address recipient
//     )   external
//         minWithdraw(amount, s.vaultParams[vault].credit)
//         returns (uint256 burnAfterFee)
//     {
//         VaultParams memory _vault = s.vaultParams[vault];

//         require(_vault.enabled == 1, "VaultFacet: Vault disabled");

//         require(
//             s.creditConvertEnabled[_vault.credit][_vault.active] == 1,
//             "ExchangeFacet: Credit convert disabled"
//         );

//         require(
//             amount >= s.creditRedeemAllowance[depositFrom][_vault.credit],
//             "ExchangeFacet: Invalid credit redemption allowance"
//         );

//          /**
//             STEPS FOR REDEEMING CREDIT

//             1.  Burn credit from depositFrom.
//             1.  Decrease the backing reserve.
//             2.  Transfer assets to the recipient.
//             3.  Decrease credit redemption allowance.
//          */    

//         // (1)
//         LibToken._burn(_vault.credit, depositFrom, amount);

//         uint256 fee = LibToken._getRedeemFee(_vault.credit, amount);
//         burnAfterFee = amount - fee;

//         LibToken._burn(_vault.active, address(this), amount);
//         if (fee > 0) {
//             // Redeem fee captured in the (previously backing) activeAsset.
//             emit LibToken.RedeemFeeCaptured(_vault.active, fee);
//         }

//         // (2)
//         LibTreasury._adjustBackingReserve(
//             _vault.active,
//             -(int256(amount))
//         );

//         // (3)
//         uint256 assets = LibVault._unwrap(amount, vault, recipient);
//         require(assets >= minAmountOut, 'VaultFacet: Slippage exceeded');

//         // (4)
//         LibTreasury._adjustCreditRedeemAllowance(
//             _vault.credit,
//             depositFrom,
//             -(int256(amount))
//         );
//     }

//     /// @notice Converts a creditAsset to a share token (issued by vault).
//     /// [STATUS: Ready to deploy]
//     /// @param  amount          The amount of creditAssets to redeem.
//     /// @param  vault           The address of the vault.
//     /// @param  depositFrom     The account to deposit creditAssets from.
//     /// @param  recipient       The recipient of the inputAssets.
//     /// @param  minAmountOut    The minimum amount of inputAssets received (before fees).
//     function creditToVault(
//         uint256 amount,
//         uint256 minAmountOut,
//         address vault,
//         address depositFrom,
//         address recipient
//     )   external
//         minWithdraw(amount, s.vaultParams[vault].credit)
//         returns (uint256 burnAfterFee)
//     {
//         VaultParams memory _vault = s.vaultParams[vault];

//         require(_vault.enabled == 1, "VaultFacet: Vault disabled");

//         require(
//             s.creditConvertEnabled[_vault.credit][_vault.active] == 1,
//             "ExchangeFacet: Credit convert disabled"
//         );

//         require(
//             amount >= s.creditRedeemAllowance[depositFrom][_vault.credit],
//             "ExchangeFacet: Invalid credit redemption allowance"
//         );

//          /**
//             STEPS FOR REDEEMING CREDIT

//             1.  Burn credit from depositFrom.
//             1.  Decrease the backing reserve.
//             2.  Transfer assets to the recipient.
//             3.  Decrease credit redemption allowance.
//          */    

//         // (1)
//         LibToken._burn(_vault.credit, depositFrom, amount);

//         uint256 fee = LibToken._getRedeemFee(_vault.credit, amount);
//         burnAfterFee = amount - fee;

//         LibToken._burn(_vault.active, address(this), amount);
//         if (fee > 0) {
//             // Redeem fee captured in the (previously backing) activeAsset.
//             emit LibToken.RedeemFeeCaptured(_vault.active, fee);
//         }

//         // (2)
//         LibTreasury._adjustBackingReserve(
//             _vault.active,
//             -(int256(amount))
//         );

//         uint256 shares = IERC4626(vault).previewDeposit(burnAfterFee);

//         // (3)
//         LibToken._transfer(vault, shares, recipient);
//         // May need to revisit slippage application.
//         require(
//             LibVault._getAssets(shares, vault) >= minAmountOut,
//             'VaultFacet: Slippage exceeded'
//         );

//         // (4)
//         LibTreasury._adjustCreditRedeemAllowance(
//             _vault.credit,
//             depositFrom,
//             -(int256(amount))
//         );
//     }

//     /// @notice Retrieves Vault parameters.
//     /// [STATUS: Ready to deploy]
//     /// @param  vault   The vault to enquire for.
//     function getVaultParams(
//         address vault
//     ) external view returns (VaultParams memory) {

//         return s.vaultParams[vault];
//     }
// }