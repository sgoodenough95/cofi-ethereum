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
        returns (bool)
    {
        s.isWhitelisted[account] = s.isWhitelisted[account] == 0 ? 1 : 0;
        return s.isWhitelisted[account] == 1 ? true : false;
    }

    function toggleAdmin(
        address account
    )   external
        onlyAdmin
        returns (bool)
    {
        s.isAdmin[account] = s.isAdmin[account] == 0 ? 1 : 0;
        return s.isAdmin[account] == 1 ? true : false;
    }

    function toggleUpkeep(
        address account
    )   external
        onlyAdmin
        returns (bool)
    {
        s.isUpkeep[account] = s.isUpkeep[account] == 0 ? 1 : 0;
        return s.isUpkeep[account] == 1 ? true : false;
    }

    function setFeeCollector(
        address feeCollector
    )   external
        onlyAdmin
        returns (bool)
    {
        s.feeCollector = feeCollector;
        return true;
    }

    function getWhitelistStatus(
        address account
    )   external
        view
        returns (bool)
    {
        return s.isWhitelisted[account] == 1 ? true : false;
    }

    function getAdminStatus(
        address account
    )   external
        onlyAdmin
        view
        returns (bool)
    {
        return s.isAdmin[account] == 1 ? true : false;
    }

    function getUpkeepStatus(
        address account
    )   external
        onlyAdmin
        view
        returns (bool)
    {
        return s.isUpkeep[account] == 1 ? true : false;
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