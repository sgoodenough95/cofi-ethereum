// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

/**

    ╭━━━╮╱╱╭━━━╮
    ┃╭━╮┃╱╱┃╭━━╯
    ┃┃╱╰╋━━┫╰━━┳╮
    ┃┃╱╭┫╭╮┃╭━━╋┫
    ┃╰━╯┃╰╯┃┃╱╱┃┃
    ╰━━━┻━━┻╯╱╱╰╯

    @author cofi.money
    @title  Supply Facet
    @notice User-operated functions for minting fiAssets.
            Backing assets are deployed to respective Vault as per schema.
 */

import { VaultParams, Modifiers } from '../libs/LibAppStorage.sol';
import { LibToken } from '../libs/LibToken.sol';
import { LibVault } from '../libs/LibVault.sol';
import { LibTreasury } from '../libs/LibTreasury.sol';
import { IERC4626 } from '.././interfaces/IERC4626.sol';
import { PercentageMath } from '../libs/external/PercentageMath.sol';

contract SupplyFacet is Modifiers {
    using PercentageMath for uint256;

    /// @notice Converts an accepted inputAsset into a fiAsset (e.g., USDC to fiUSD).
    ///
    /// @param  amount          The amount of inputAssets to deposit.
    // /// @param  vault           The address of the vault.
    /// @param  depositFrom     The account to deposit inputAssets from.
    /// @param  recipient       The recipient of the fiAssets.
    /// @param  minAmountOut    The minimum amount of fiAssets received (before fees).
    function inputToFi(
        uint256 amount,
        uint256 minAmountOut,
        address inputAsset,
        // address vault,
        address depositFrom,
        address recipient
    )
        external
        minDeposit(amount, inputAsset)
        returns (uint256 mintAfterFee)
    {
        // VaultParams memory _vault = s.vaultParams[vault];

        require(
            LibToken._isMintEnabled(fiAsset[inputAsset]) == 1,
            'SupplyFacet: Mint for token disabled'
        );

        // require(_vault.mintEnabled == 1, 'SupplyFacet: Mint for vault disabled');

        uint256 assets;

        for(uint i = 0; i <= s.vaults.length; ++i) {
            assets += LibVault._getAssets(
                LibVault._wrap(
                    amount.percentMul(s.vaults[i].allocation),
                    s.vaults[i].vault,
                    depositFrom
                ),
                s.vaults[i].vault
            );
        }

        // uint256 assets = LibVault._getAssets(
        //     LibVault._wrap(amount, vault, depositFrom),
        //     vault
        // );

        require(assets >= minAmountOut, 'SupplyFacet: Slippage exceeded');

        uint256 fee = LibToken._getMintFee(fiAsset[inputAsset], assets);
        mintAfterFee = assets - fee;

        if (fee > 0) {
            LibToken._mint(fiAsset[inputAsset], s.feeCollector, fee);
            emit LibToken.MintFeeCaptured(fiAsset[inputAsset], fee);
        }

        // Backing reserve will only ever be denominated in assets (not shares).
        LibTreasury._adjustBackingReserve(vault, int256(assets));

        LibToken._mint(fiAsset[inputAsset], recipient, mintAfterFee);

        // Track for now (in case introducing CDPs at a later stage).
        // Achievable with Events also.
        LibTreasury._adjustRedeemAllowance(
            vault,                  // The vault to redeem from.
            msg.sender,             // Update allowance for caller (not 'depositFrom').
            int256(mintAfterFee)    // The amount of assets redeemable.
        );
    }

    /// @notice Converts a fiAsset to an inputAsset.
    /// @dev    REVERSE PATH SHOULD PROVIDE A SINGLE inputAsset.
    /// @param  amount          The amount of fiAssets to redeem.
    /// @param  vault           The address of the vault. Must have redeem allowance for.
    /// @param  depositFrom     The account to deposit fiAssets from.
    /// @param  recipient       The recipient of the inputAssets.
    /// @param  minAmountOut    The minimum amount of inputAssets received (after fees).
    function fiToInput(
        uint256 amount,
        uint256 minAmountOut,
        address vault,
        address depositFrom,
        address recipient
    )   external
        minWithdraw(amount, s.vaultParams[vault].credit)
        returns (uint256 burnAfterFee)
    {
        VaultParams memory _vault = s.vaultParams[vault];

        // First, check if redemptions of fiAsset are enabled.
        require(LibToken._isRedeemEnabled(_vault.credit) == 1, 'SupplyFacet: Redeem for token disabled');

        // Second, check if redemption of specific vault is enabled.
        require(_vault.redeemEnabled == 1, 'SupplyFacet: Redeem for vault disabled');

        // Last, check if caller has sufficient redeem allowance for said vault.
        require(
            amount >= s.redeemAllowance[msg.sender][vault],
            'SupplyFacet: Invalid redemption allowance for requested vault'
        );

         /**
            STEPS FOR REDEEMING CREDIT

            1.  Burn credit, retaining fee.
            1.  Decrease the backing reserve.
            2.  Transfer assets to the recipient.
            3.  Decrease redemption allowance.
         */

        LibToken._transferFrom(_vault.credit, amount, depositFrom, s.feeCollector);

        uint256 fee = LibToken._getRedeemFee(_vault.credit, amount);
        burnAfterFee = amount - fee;

        // (1) Fee is captured by retaining 'fee' amount.
        LibToken._burn(_vault.credit, s.feeCollector, burnAfterFee);
        
        if (fee > 0) {
            emit LibToken.RedeemFeeCaptured(_vault.credit, fee);
        }

        // (2)
        LibTreasury._adjustBackingReserve(
            vault,
            -(int256(burnAfterFee)) // Reserve is still backing 'fee' portion.
        );

        // (3)
        require(
            LibVault._unwrap(burnAfterFee, vault, recipient) >= minAmountOut,
            'SupplyFacet: Slippage exceeded'
        );

        // (4)
        LibTreasury._adjustRedeemAllowance(
            vault,
            msg.sender,
            -(int256(amount))   // Has to cancel out mint operation, hence use 'amount'
        );
    }

    /// @dev    OLD - COMMENTED OUT FOR NOW:

    // /// @notice Converts an accepted share token into a fiAsset (e.g., yvUSDC to fiUSD).
    // ///
    // /// @param  shares          The amount of shares to deposit (issued by vault).
    // /// @param  vault           The address of the vault.
    // /// @param  depositFrom     The account to deposit inputAssets from.
    // /// @param  recipient       The recipient of the fiAssets.
    // /// @param  minAmountOut    The minimum amount of fiAssets received (before fees).
    // function sharesToFi(
    //     uint256 shares,
    //     uint256 minAmountOut,
    //     address vault,
    //     address depositFrom,
    //     address recipient
    // )
    //     external
    //     minDeposit(LibVault._getAssets(shares, vault), IERC4626(vault).asset())
    //     returns (uint256 mintAfterFee)
    // {
    //     VaultParams memory _vault = s.vaultParams[vault];

    //     require(LibToken._isMintEnabled(_vault.credit) == 1, 'SupplyFacet: Mint for token disabled');

    //     require(_vault.mintEnabled == 1, 'SupplyFacet: Mint for vault disabled');

    //     LibToken._transferFrom(vault, shares, depositFrom, address(this));

    //     uint256 assets = LibVault._getAssets(shares, vault);
    //     require(assets >= minAmountOut, 'SupplyFacet: Slippage exceeded');

    //     uint256 fee = LibToken._getMintFee(_vault.credit, assets);
    //     mintAfterFee = assets - fee;

    //     if (fee > 0) {
    //         LibToken._mint(_vault.credit, s.feeCollector, fee);
    //         emit LibToken.MintFeeCaptured(_vault.credit, fee);
    //     }

    //     LibTreasury._adjustBackingReserve(vault, int256(assets));

    //     LibToken._mint(_vault.credit, recipient, mintAfterFee);

    //     LibTreasury._adjustRedeemAllowance(
    //         vault,
    //         msg.sender,
    //         int256(mintAfterFee)
    //     );
    // }

    // /// @notice Converts a fiAsset to its underlying share token.
    // ///
    // /// @param  amount          The amount of fiAssets to redeem.
    // /// @param  vault           The address of the vault. Must have redeem allowance for.
    // /// @param  depositFrom     The account to deposit fiAssets from.
    // /// @param  recipient       The recipient of the share tokens.
    // /// @param  minAmountOut    The minimum amount of share tokens received (after fees).
    // function fiToShares(
    //     uint256 amount,
    //     uint256 minAmountOut,
    //     address vault,
    //     address depositFrom,
    //     address recipient
    // )   external
    //     minWithdraw(amount, s.vaultParams[vault].credit)
    //     returns (uint256 burnAfterFee)
    // {
    //     VaultParams memory _vault = s.vaultParams[vault];

    //     require(LibToken._isRedeemEnabled(_vault.credit) == 1, 'SupplyFacet: Redeem for token disabled');

    //     require(_vault.redeemEnabled == 1, 'SupplyFacet: Redeem for vault disabled');

    //     require(
    //         amount >= s.redeemAllowance[msg.sender][vault],
    //         'SupplyFacet: Invalid redemption allowance for requested vault'
    //     );

    //      /**
    //         STEPS FOR REDEEMING CREDIT

    //         1.  Burn credit, retaining fee.
    //         1.  Decrease the backing reserve.
    //         2.  Transfer assets to the recipient.
    //         3.  Decrease redemption allowance.
    //      */

    //     LibToken._transferFrom(_vault.credit, amount, depositFrom, s.feeCollector);

    //     uint256 fee = LibToken._getRedeemFee(_vault.credit, amount);
    //     burnAfterFee = amount - fee;

    //     // (1) Fee is captured by retaining 'fee' amount.
    //     LibToken._burn(_vault.credit, s.feeCollector, burnAfterFee);
        
    //     if (fee > 0) {
    //         emit LibToken.RedeemFeeCaptured(_vault.credit, fee);
    //     }

    //     // (2)
    //     LibTreasury._adjustBackingReserve(
    //         vault,
    //         -(int256(burnAfterFee)) // Reserve is still backing 'fee' portion.
    //     );

    //     uint256 shares = LibVault._getShares(burnAfterFee, vault);
    //     require(shares >= minAmountOut, 'SupplyFacet: Slippage exceeded');

    //     // (3)
    //     LibToken._transfer(vault, shares, recipient);

    //     // (4)
    //     LibTreasury._adjustRedeemAllowance(
    //         vault,
    //         msg.sender,
    //         -(int256(amount))   // Has to cancel out mint operation, hence use 'amount'
    //     );
    // }

    // /// @notice Retrieves Vault parameters.
    // ///
    // /// @param  vault   The vault to enquire for.
    // function getVaultParams(
    //     address vault
    // ) external view returns (VaultParams memory) {

    //     return s.vaultParams[vault];
    // }
}