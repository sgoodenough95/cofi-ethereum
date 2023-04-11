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

import { Modifiers } from '../libs/LibAppStorage.sol';
import { LibToken } from '../libs/LibToken.sol';
import { LibVault } from '../libs/LibVault.sol';
import { IERC20 } from '@openzeppelin/contracts/interfaces/IERC20.sol';
import { IERC4626 } from '.././interfaces/IERC4626.sol';
import 'hardhat/console.sol';

contract SupplyFacet is Modifiers {

    /// @notice Converts an accepted inputAsset into a fiAsset (e.g., DAI to COFI).
    ///
    /// @param  amount          The amount of inputAssets to deposit.
    /// @param  inputAsset      The asset provided to mint fiAssets.
    /// @param  depositFrom     The account to deposit inputAssets from.
    /// @param  recipient       The recipient of the fiAssets.
    /// @param  minAmountOut    The minimum amount of fiAssets received (before fees).
    function inputToFi(
        uint256 amount,
        uint256 minAmountOut,
        address inputAsset,
        address depositFrom,
        address recipient
    )
        external
        isWhitelisted()
        minDeposit(amount, inputAsset)
        returns (uint256 mintAfterFee)
    {
        require(
            LibToken._isMintEnabled(s.fiAsset[inputAsset]) == 1,
            'SupplyFacet: Mint for token disabled'
        );

        uint256 assets = LibVault._getAssets(
           LibVault._wrap(
                amount,
                s.vault[s.fiAsset[inputAsset]],
                depositFrom
            ),
            s.vault[s.fiAsset[inputAsset]]
        );

        require(assets >= minAmountOut, 'SupplyFacet: Slippage exceeded');

        uint256 fee = LibToken._getMintFee(s.fiAsset[inputAsset], assets);
        mintAfterFee = assets - fee;

        // Capture mint fee in fiAssets.
        if (fee > 0) {
            LibToken._mint(s.fiAsset[inputAsset], s.feeCollector, fee);
            emit LibToken.MintFeeCaptured(s.fiAsset[inputAsset], fee);
        }

        LibToken._mint(s.fiAsset[inputAsset], recipient, mintAfterFee);
    }

    /// @notice Converts an accepted share token into a fiAsset (e.g., yvDAI to COFI).
    ///
    /// @param  amount          The amount of inputAssets to deposit.
    /// @param  vault           The share token provided to mint fiAssets.
    /// @param  depositFrom     The account to deposit inputAssets from.
    /// @param  recipient       The recipient of the fiAssets.
    /// @param  minAmountOut    The minimum amount of fiAssets received (before fees).
    function sharesToFi(
        uint256 amount,
        uint256 minAmountOut,
        address vault,
        address depositFrom,
        address recipient
    )
        external
        isWhitelisted()
        minDeposit(amount, IERC4626(vault).asset())
        returns (uint256 mintAfterFee)
    {
        address inputAsset = IERC4626(vault).asset();

        require(
            LibToken._isMintEnabled(s.fiAsset[inputAsset]) == 1,
            'SupplyFacet: Mint for token disabled'
        );

        LibToken._transferFrom(vault, amount, depositFrom, address(this));

        uint256 assets = LibVault._getAssets(
           amount,
            s.vault[s.fiAsset[inputAsset]]
        );

        require(assets >= minAmountOut, 'SupplyFacet: Slippage exceeded');

        uint256 fee = LibToken._getMintFee(s.fiAsset[inputAsset], assets);
        mintAfterFee = assets - fee;

        // Capture mint fee in fiAssets.
        if (fee > 0) {
            LibToken._mint(s.fiAsset[inputAsset], s.feeCollector, fee);
            emit LibToken.MintFeeCaptured(s.fiAsset[inputAsset], fee);
        }

        LibToken._mint(s.fiAsset[inputAsset], recipient, mintAfterFee);
    }

    /// @notice Converts a fiAsset to its underlying share token.
    ///
    /// @param  amount          The amount of fiAssets to redeem.
    /// @param  depositFrom     The account to deposit fiAssets from.
    /// @param  vault           The share token to redeem (e.g., yvDAI).
    /// @param  recipient       The recipient of the share tokens.
    /// @param  minAmountOut    The minimum amount of share tokens received (after fees).
    function fiToShares(
        uint256 amount,
        uint256 minAmountOut,
        address vault,
        address depositFrom,
        address recipient
    )   external
        isWhitelisted()
        // minWithdraw(amount, IERC4626(vault).asset())
        returns (uint256 burnAfterFee)
    {
        address inputAsset = IERC4626(vault).asset();

        require(
            LibToken._isRedeemEnabled(s.fiAsset[inputAsset]) == 1,
            'SupplyFacet: Redeem for token disabled'
        );

        LibToken._transferFrom(s.fiAsset[inputAsset], amount, depositFrom, s.feeCollector);
        console.log('transferFrom amount: %s', amount);

        uint256 fee = LibToken._getRedeemFee(s.fiAsset[inputAsset], amount);
        burnAfterFee = amount - fee;

        // Redemption fee is captured by retaining 'fee' amount.
        LibToken._burn(s.fiAsset[inputAsset], s.feeCollector, burnAfterFee);
        console.log('burnAfterFee amount: %s', burnAfterFee);
        if (fee > 0) {
            emit LibToken.RedeemFeeCaptured(s.fiAsset[inputAsset], fee);
        }

        uint256 shares = LibVault._getShares(burnAfterFee, vault);
        require(shares >= minAmountOut, 'SupplyFacet: Slippage exceeded');

        LibToken._transfer(vault, shares, recipient);
        console.log('transfer shares: %s', shares);
    }

    /// @notice Converts a fiAsset to its underlying inputAsset.
    ///
    /// @notice Can be used to make payments in underlying asset.
    ///         E.g., send USDC from having COFI in your wallet.
    ///
    /// @param  amount          The amount of fiAssets to redeem.
    /// @param  depositFrom     The account to deposit fiAssets from.
    /// @param  inputAsset      The asset to redeem (e.g., USDC).
    /// @param  recipient       The recipient of the inputAssets.
    /// @param  minAmountOut    The minimum amount of inputAssets received (after fees).
    function fiToInput(
        uint256 amount,
        uint256 minAmountOut,
        address inputAsset,
        address depositFrom,
        address recipient
    )   public
        isWhitelisted()
        minWithdraw(amount, inputAsset)
        returns (uint256 burnAfterFee)
    {
        require(
            LibToken._isRedeemEnabled(s.fiAsset[inputAsset]) == 1,
            'SupplyFacet: Redeem for token disabled'
        );

        LibToken._transferFrom(s.fiAsset[inputAsset], amount, depositFrom, s.feeCollector);

        uint256 fee = LibToken._getRedeemFee(s.fiAsset[inputAsset], amount);
        burnAfterFee = amount - fee;

        // Redemption fee is captured by retaining 'fee' amount.
        LibToken._burn(s.fiAsset[inputAsset], s.feeCollector, burnAfterFee);
        if (fee > 0) {
            emit LibToken.RedeemFeeCaptured(s.fiAsset[inputAsset], fee);
        }

        require(
            LibVault._unwrap(
                burnAfterFee,
                s.vault[s.fiAsset[inputAsset]],
                recipient
            ) >= minAmountOut,
            'SupplyFacet: Slippage exceeded'
        );
    }
}