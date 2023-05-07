// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

/**

    █▀▀ █▀█ █▀▀ █
    █▄▄ █▄█ █▀░ █

    @author cofi.money
    @title  Loupe Facet
    @notice View functions for data retrieval (e.g., mintFee, etc.).
 */

import { Modifiers } from "../libs/LibAppStorage.sol";

contract LoupeFacet is Modifiers {

    function getWhitelistStatus(
        address account
    )   external
        view
        returns (bool)
    {
        return s.isWhitelisted[account] == 1 ? true : false;
    }

    /// @notice Only return for caller to prevent sharing of Admin public keys.
    function getAdminStatus(
    )   external
        view
        returns (bool)
    {
        return s.isAdmin[msg.sender] == 1 ? true : false;
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

    /// @return The pointsRate denominated in basis points.
    function getPointsRate(
        address fiAsset
    )   external
        view
        returns (uint256)
    {
        return s.pointsRate[fiAsset];
    }

    /// @dev    Need to ensure feeCollector contract can call this function.
    function getFeeCollectorStatus(
    )   external
        view
        returns (bool)
    {
        return msg.sender == s.feeCollector ? true : false;
    }
}