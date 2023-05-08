// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

/**

    █▀▀ █▀█ █▀▀ █
    █▄▄ █▄█ █▀░ █

    @author cofi.money
    @title  Access Facet
    @notice Admin functions for managing account roles.
 */

import { Modifiers } from "../libs/LibAppStorage.sol";

contract AccessFacet is Modifiers {

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

    function setFeeCollector(
        address feeCollector
    )   external
        onlyAdmin
    {
        s.feeCollector = feeCollector;
    }

    function getWhitelistStatus(
        address account
    )   external
        view
        returns (bool)
    {
        return s.isWhitelisted[account] == 1 ? true : false;
    }

    /// @dev    Only return for caller to prevent sharing of Admin public keys.
    function getAdminStatus(
    )   external
        view
        returns (bool)
    {
        return s.isAdmin[msg.sender] == 1 ? true : false;
    }

    function getFeeCollectorStatus(
        address account
    )   external
        view
        returns (bool)
    {
        return account == s.feeCollector ? true : false;
    }
}