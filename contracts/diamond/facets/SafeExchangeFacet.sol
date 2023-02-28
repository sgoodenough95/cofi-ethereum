// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

/**
    █▀▀ ▀▀█▀▀ █▀▀█ █▀▀█ 
    ▀▀█ ░░█░░ █░░█ █▄▄█ 
    ▀▀▀ ░░▀░░ ▀▀▀▀ ▀░░▀

    @author stoa.money
    @title  Safe Facet
    @notice User-operated functions for managing Safes.
 */

import { Safe, VaultParams, Modifiers } from '../libs/LibAppStorage.sol';
import { LibToken } from '../libs/LibToken.sol';
import { LibVault } from '../libs/LibVault.sol';
import { LibSafe } from '../libs/LibSafe.sol';
import { IERC4626 } from ".././interfaces/IERC4626.sol";

contract SafeExchangeFacet is Modifiers {

    /// @notice Opens a Safe with an inputAsset. Credits with activeAssets.
    /// @dev    Only caller can open a Safe for themselves (?)
    /// @dev    Optionally can have a 'primeActive' storage variable.
    /// @dev    Only consider one Safe Store per activeAsset for now.
    ///
    /// @param  inputAsset  The inputAsset to open a Safe with.
    /// @param  activeAsset The activeAsset to convert to.
    /// @param  amount      The amount of inputAssets.
    function openExchange(
        address inputAsset,
        address activeAsset,
        uint256 amount
    )   external
        minDeposit(amount, inputAsset)
    {
        require(
            LibToken._isValidActiveInput(inputAsset, activeAsset) == 1,
            "ExchangeFacet: Invalid input"
        );

        require(
            LibToken._isMintEnabled(activeAsset) == 1,
            "ExchangeFacet: Mint disabled"
        );

        LibToken._transferFrom(inputAsset, amount, msg.sender, address(this));

        // Do not apply fee when opening a Safe (?)
        // uint256 fee = LibToken._getMintFee(activeAsset, amount);
        // mintAfterFee = amount - fee;

        LibToken._mint(activeAsset, address(this), amount);

        // if (fee > 0) {
        //    LibToken._mint(activeAsset, address(this), fee);
        //     emit LibToken.MintFeeCaptured(activeAsset, fee); 
        // }

        // Deposit activeAssets to ERC4626 Safe Store contract.
        LibSafe._open(amount, address(this), s.primeStore[activeAsset]);
    }

    function depositExchange(
        uint256 amount,
        address inputAsset, // One [exchange] activeAsset can have multiple inputAssets.
        address depositFrom,
        address recipient,
        uint32  index
    )   external
        minDeposit(amount, inputAsset)
        activeSafe(recipient, index)
    {
        address activeAsset = IERC4626(s.safe[recipient][index].store).asset();

        require(
            LibToken._isValidActiveInput(inputAsset, activeAsset) == 1,
            "ExchangeFacet: Invalid input"
        );

        require(
            LibToken._isMintEnabled(activeAsset) == 1,
            "ExchangeFacet: Mint disabled"
        );

        LibToken._transferFrom(inputAsset, amount, depositFrom, address(this));

        // Do not apply fee when opening a Safe (?)
        // uint256 fee = LibToken._getMintFee(activeAsset, amount);
        // mintAfterFee = amount - fee;

        LibToken._mint(activeAsset, address(this), amount);

        // if (fee > 0) {
        //    LibToken._mint(activeAsset, address(this), fee);
        //     emit LibToken.MintFeeCaptured(activeAsset, fee); 
        // }

        // Deposit activeAssets to ERC4626 Safe Store contract.
        LibSafe._deposit(amount, address(this), recipient, index);
    }

    function withdrawExchange(
        uint256 amount,
        address recipient,
        uint32  index
    )   external
        minWithdraw(amount, IERC4626(s.safe[msg.sender][index].store).asset())
        activeSafe(msg.sender, index)
    {
        uint256 assets = LibSafe._withdraw(amount, address(this), index);

        LibToken._burn(IERC4626(s.safe[msg.sender][index].store).asset(), address(this), assets);

        address inputAsset = LibToken._getRedeemAsset(IERC4626(s.safe[msg.sender][index].store).asset());

        LibToken._transfer(inputAsset, amount, recipient);
    }
}