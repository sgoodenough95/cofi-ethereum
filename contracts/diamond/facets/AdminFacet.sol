// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

/**

    █▀▀ █▀█ █▀▀ █
    █▄▄ █▄█ █▀░ █

    @author cofi.money
    @title  Admin Facet
    @notice Admin functions for managing app.
 */

import { Modifiers } from "../libs/LibAppStorage.sol";

contract AdminFacet is Modifiers {

    function toggleWhitelist(
        address account
    )   external
        onlyAdmin
    {
        s.isWhitelisted[account] = s.isWhitelisted[account] == 0 ? 1 : 0;
    }

    function toggleAdmin(
        address account
    )   external
        onlyAdmin
    {
        s.isAdmin[account] = s.isAdmin[account] == 0 ? 1 : 0;
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

    function setFeeCollector(
        address feeCollector
    )   external
        onlyAdmin
    {
        s.feeCollector = feeCollector;
    }
}