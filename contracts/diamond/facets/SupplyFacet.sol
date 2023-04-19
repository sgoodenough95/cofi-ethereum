// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

/**

    █▀▀ █▀█ █▀▀ █
    █▄▄ █▄█ █▀░ █

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

    /// @notice Converts a supported underlyingAsset into a fiAsset (e.g., DAI to COFI).
    ///
    /// @param  amount          The amount of underlyingAssets to deposit.
    /// @param  fiAsset         The fiAsset to mint.
    /// @param  depositFrom     The account to deposit underlyingAssets from.
    /// @param  recipient       The recipient of the fiAssets.
    /// @param  minAmountOut    The minimum amount of fiAssets received (before fees).
    function underlyingToFi(
        uint256 amount,
        uint256 minAmountOut,
        address fiAsset,
        address depositFrom,
        address recipient
    )
        external
        isWhitelisted()
        minDeposit(amount, fiAsset)
        returns (uint256 mintAfterFee)
    {
        require(
            LibToken._isMintEnabled(fiAsset) == 1,
            'SupplyFacet: Mint for token disabled'
        );

        uint256 assets = LibVault._getAssets(
           LibVault._wrap(
                amount,
                s.vault[fiAsset],
                depositFrom
            ),
            s.vault[fiAsset]
        );

        require(assets >= minAmountOut, 'SupplyFacet: Slippage exceeded');

        uint256 fee = LibToken._getMintFee(fiAsset, assets);
        mintAfterFee = assets - fee;

        // Capture mint fee in fiAssets.
        if (fee > 0) {
            LibToken._mint(fiAsset, s.feeCollector, fee);
            emit LibToken.MintFeeCaptured(fiAsset, fee);
        }

        LibToken._mint(fiAsset, recipient, mintAfterFee);
    }

    /// @notice Converts a supported yieldAsset into a fiAsset (e.g., yvDAI to COFI).
    ///
    /// @param  amount          The amount of yieldAssets to deposit.
    /// @param  minAmountOut    The minimum amount of fiAssets received (before fees).
    /// @param  fiAsset         The fiAsset to mint.
    /// @param  depositFrom     The account to deposit yieldAssets from.
    /// @param  recipient       The recipient of the fiAssets.
    function sharesToFi(
        uint256 amount,
        uint256 minAmountOut,
        address fiAsset,
        address depositFrom,
        address recipient
    )
        external
        isWhitelisted()
        minDeposit(LibVault._getAssets(amount, s.vault[fiAsset]), fiAsset)
        returns (uint256 mintAfterFee)
    {
        require(
            LibToken._isMintEnabled(fiAsset) == 1,
            'SupplyFacet: Mint for token disabled'
        );

        // Backing yieldAssets are held in the diamond contract.
        LibToken._transferFrom(s.vault[fiAsset], amount, depositFrom, address(this));

        uint256 assets = LibVault._getAssets(amount, s.vault[fiAsset]);

        require(assets >= minAmountOut, 'SupplyFacet: Slippage exceeded');

        uint256 fee = LibToken._getMintFee(fiAsset, assets);
        mintAfterFee = assets - fee;

        // Capture mint fee in fiAssets.
        if (fee > 0) {
            LibToken._mint(fiAsset, s.feeCollector, fee);
            emit LibToken.MintFeeCaptured(fiAsset, fee);
        }

        LibToken._mint(fiAsset, recipient, mintAfterFee);
    }

    /// @notice Converts a fiAsset to its collateral yieldAsset.
    ///
    /// @param  amount          The amount of fiAssets to redeem.
    /// @param  depositFrom     The account to deposit fiAssets from.
    /// @param  fiAsset         The fiAsset to redeem (e.g., COFI).
    /// @param  recipient       The recipient of the yieldAssets.
    /// @param  minAmountOut    The minimum amount of yieldAssets received (after fees).
    function fiToShares(
        uint256 amount,
        uint256 minAmountOut,
        address fiAsset,
        address depositFrom,
        address recipient
    )   external
        isWhitelisted()
        minWithdraw(amount, fiAsset)
        returns (uint256 burnAfterFee)
    {
        require(
            LibToken._isRedeemEnabled(fiAsset) == 1,
            'SupplyFacet: Redeem for token disabled'
        );

        LibToken._transferFrom(fiAsset, amount, depositFrom, s.feeCollector);

        uint256 fee = LibToken._getRedeemFee(fiAsset, amount);
        burnAfterFee = amount - fee;

        // Redemption fee is captured by retaining 'fee' amount.
        LibToken._burn(fiAsset, s.feeCollector, burnAfterFee);
        if (fee > 0) {
            emit LibToken.RedeemFeeCaptured(fiAsset, fee);
        }

        uint256 shares = LibVault._getShares(burnAfterFee, s.vault[fiAsset]);
        require(shares >= minAmountOut, 'SupplyFacet: Slippage exceeded');

        LibToken._transfer(s.vault[fiAsset], shares, recipient);
    }

    /// @notice Converts a fiAsset to its collateral underlyingAsset.
    ///
    /// @notice Can be used to make payments in underlyingAsset.
    ///         E.g., send USDC from having COFI in your wallet.
    ///
    /// @param  amount          The amount of fiAssets to redeem.
    /// @param  depositFrom     The account to deposit fiAssets from.
    /// @param  fiAsset         The fiAsset to redeem (e.g., COFI).
    /// @param  recipient       The recipient of the underlyingAssets.
    /// @param  minAmountOut    The minimum amount of underlyingAssets received (after fees).
    function fiToUnderlying(
        uint256 amount,
        uint256 minAmountOut,
        address fiAsset,
        address depositFrom,
        address recipient
    )   public
        isWhitelisted()
        minWithdraw(amount, fiAsset)
        returns (uint256 burnAfterFee)
    {
        require(
            LibToken._isRedeemEnabled(fiAsset) == 1,
            'SupplyFacet: Redeem for token disabled'
        );

        LibToken._transferFrom(fiAsset, amount, depositFrom, s.feeCollector);

        uint256 fee = LibToken._getRedeemFee(fiAsset, amount);
        burnAfterFee = amount - fee;

        // Redemption fee is captured by retaining 'fee' amount.
        LibToken._burn(fiAsset, s.feeCollector, burnAfterFee);
        if (fee > 0) {
            emit LibToken.RedeemFeeCaptured(fiAsset, fee);
        }

        require(
            LibVault._unwrap(burnAfterFee, s.vault[fiAsset], recipient) >= minAmountOut,
            'SupplyFacet: Slippage exceeded'
        );
    }

    function getUnderlyingAsset(
        address fiAsset
    )   external
        view
        returns (address)
    {
        return IERC4626(s.vault[fiAsset]).asset();
    }

    function getYieldAsset(
        address fiAsset
    )   external
        view
        returns (address)
    {
        return s.vault[fiAsset];
    }
}