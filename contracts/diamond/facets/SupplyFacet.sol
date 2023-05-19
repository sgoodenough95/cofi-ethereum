// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

/**

    █▀▀ █▀█ █▀▀ █
    █▄▄ █▄█ █▀░ █

    @author The Stoa Corporation Ltd
    @title  Supply Facet
    @notice User-operated functions for minting fiAssets.
            Backing assets are deployed to respective Vault as per schema.
 */

import { Modifiers } from '../libs/LibAppStorage.sol';
import { LibToken } from '../libs/LibToken.sol';
import { LibReward } from '../libs/LibReward.sol';
import { LibVault } from '../libs/LibVault.sol';
import { IERC4626 } from '.././interfaces/IERC4626.sol';
import 'hardhat/console.sol';

contract SupplyFacet is Modifiers {

    /// @notice Converts a supported underlyingAsset into a fiAsset (e.g., DAI to COFI).
    ///
    /// @param  amount          The amount of underlyingAssets to deposit.
    /// @param  minAmountOut    The minimum amount of fiAssets received (before fees).
    /// @param  fiAsset         The fiAsset to mint.
    /// @param  depositFrom     The account to deposit underlyingAssets from.
    /// @param  recipient       The recipient of the fiAssets.
    /// @param  referral        The referral account (address(0) if none provided).
    function underlyingToFi(
        uint256 amount,
        uint256 minAmountOut, // E.g., 1,000 * 0.9975 = 997.50. Auto-set to 0.25%.
        address fiAsset,
        address depositFrom,
        address recipient,
        address referral
    )
        external
        isWhitelisted
        mintEnabled(fiAsset)
        minDeposit(amount, fiAsset)
        returns (uint256 mintAfterFee)
    {
        uint256 assets = LibVault._getAssets(
            // Add permit for Vault transfer.
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
        LibReward._initReward();
        if (referral != address(0)) LibReward._referReward(referral);
    }

    /// @notice Converts a supported yieldAsset into a fiAsset (e.g., yvDAI to COFI).
    ///
    /// @param  amount          The amount of yieldAssets to deposit.
    /// @param  minAmountOut    The minimum amount of fiAssets received (before fees).
    /// @param  fiAsset         The fiAsset to mint.
    /// @param  depositFrom     The account to deposit yieldAssets from.
    /// @param  recipient       The recipient of the fiAssets.
    /// @param  referral        The referral account (address(0) if none provided).
    function sharesToFi(
        uint256 amount,
        uint256 minAmountOut,
        address fiAsset,
        address depositFrom,
        address recipient,
        address referral
    )
        external
        isWhitelisted
        mintEnabled(fiAsset)
        minDeposit(LibVault._getAssets(amount, s.vault[fiAsset]), fiAsset)
        returns (uint256 mintAfterFee)
    {
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
        LibReward._initReward();
        if (referral != address(0)) LibReward._referReward(referral);
    }

    /// @notice Converts a fiAsset to its collateral yieldAsset.
    ///
    /// @param  amount          The amount of fiAssets to redeem.
    /// @param  minAmountOut    The minimum amount of yieldAssets received (after fees).
    /// @param  fiAsset         The fiAsset to redeem (e.g., COFI).
    /// @param  depositFrom     The account to deposit fiAssets from.
    /// @param  recipient       The recipient of the yieldAssets.
    function fiToShares(
        uint256 amount,
        uint256 minAmountOut,
        address fiAsset,
        address depositFrom,
        address recipient
    )   external
        isWhitelisted
        redeemEnabled(fiAsset)
        minWithdraw(amount, fiAsset)
        returns (uint256 burnAfterFee)
    {
        depositFrom == msg.sender ?
            LibToken._redeem(fiAsset, msg.sender, amount) :
            LibToken._transferFrom(fiAsset, amount, depositFrom, s.feeCollector);

        uint256 fee = LibToken._getRedeemFee(fiAsset, amount);
        burnAfterFee = amount - fee;

        // Redemption fee is captured by retaining 'fee' amount.
        LibToken._burn(fiAsset, s.feeCollector, burnAfterFee);
        if (fee > 0) emit LibToken.RedeemFeeCaptured(fiAsset, fee);

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
    /// @param  minAmountOut    The minimum amount of underlyingAssets received (after fees).
    /// @param  fiAsset         The fiAsset to redeem (e.g., COFI).
    /// @param  depositFrom     The account to deposit fiAssets from.
    /// @param  recipient       The recipient of the underlyingAssets.
    function fiToUnderlying(
        uint256 amount,
        uint256 minAmountOut,
        address fiAsset,
        address depositFrom,
        address recipient
    )   public
        isWhitelisted
        redeemEnabled(fiAsset)
        minWithdraw(amount, fiAsset)
        returns (uint256 burnAfterFee)
    {
        depositFrom == msg.sender ?
            LibToken._redeem(fiAsset, msg.sender, amount) :
            LibToken._transferFrom(fiAsset, amount, depositFrom, s.feeCollector);

        uint256 fee = LibToken._getRedeemFee(fiAsset, amount);
        burnAfterFee = amount - fee;

        // Redemption fee is captured by retaining 'fee' amount.
        LibToken._burn(fiAsset, s.feeCollector, burnAfterFee);
        if (fee > 0) emit LibToken.RedeemFeeCaptured(fiAsset, fee);

        require(
            LibVault._unwrap(burnAfterFee, s.vault[fiAsset], recipient) >= minAmountOut,
            'SupplyFacet: Slippage exceeded'
        );
    }

    /// @notice minDeposit applies to the underlyingAsset mapped to the fiAsset (e.g., DAI).
    function setMinDeposit(
        address fiAsset,
        uint256 amount
    )   external
        onlyAdmin
    {
        s.minDeposit[fiAsset] = amount;
    }

    /// @notice minWithdraw applies to the underlyingAsset mapped to the fiAsset (e.g., DAI).
    function setMinWithdraw(
        address fiAsset,
        uint256 amount
    )   external
        onlyAdmin
    {
        s.minWithdraw[fiAsset] = amount;
    }

    function setMintFee(
        address fiAsset,
        uint256 amount
    )   external
        onlyAdmin
    {
        s.mintFee[fiAsset] = amount;
    }

    function toggleMintEnabled(
        address fiAsset
    )   external
        onlyAdmin
    {
        s.mintEnabled[fiAsset] = s.mintEnabled[fiAsset] == 0 ? 1 : 0;
    }

    function setRedeemFee(
        address fiAsset,
        uint256 amount
    )   external
        onlyAdmin
    {
        s.redeemFee[fiAsset] = amount;
    }

    function toggleRedeemEnabled(
        address fiAsset
    )   external
        onlyAdmin
    {
        s.redeemEnabled[fiAsset] = s.redeemEnabled[fiAsset] == 0 ? 1 : 0;
    }

    function getMinDeposit(
        address fiAsset
    )   external
        view
        returns (uint256)
    {
        return s.minDeposit[fiAsset];
    }

    function getMinWithdraw(
        address fiAsset
    )   external
        view
        returns (uint256)
    {
        return s.minWithdraw[fiAsset];
    }

    function getMintFee(
        address fiAsset
    )   external
        view
        returns (uint256)
    {
        return s.mintFee[fiAsset];
    }

    function getMintEnabled(
        address fiAsset
    )   external
        view
        returns (bool)
    {
        return s.mintEnabled[fiAsset] == 1 ? true : false;
    }

    function getRedeemFee(
        address fiAsset
    )   external
        view
        returns (uint256)
    {
        return s.redeemFee[fiAsset];
    }

    function getRedeemEnabled(
        address fiAsset
    )   external
        view
        returns (bool)
    {
        return s.redeemEnabled[fiAsset] == 1 ? true : false;
    }

    /// @notice Returns the underlyingAsset (variable) for a given fiAsset.
    ///
    /// @param  fiAsset The fiAsset to query for.
    function getUnderlyingAsset(
        address fiAsset
    )   external
        view
        returns (address)
    {
        return IERC4626(s.vault[fiAsset]).asset();
    }

    /// @notice Returns the yieldAsset (variable) for a given fiAsset.
    ///
    /// @param  fiAsset The fiAsset to query for. 
    function getYieldAsset(
        address fiAsset
    )   external
        view
        returns (address)
    {
        return s.vault[fiAsset];
    }
}