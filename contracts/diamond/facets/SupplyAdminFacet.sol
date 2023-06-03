// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

/**

    █▀▀ █▀█ █▀▀ █
    █▄▄ █▄█ █▀░ █

    @author The Stoa Corporation Ltd
    @title  Supply Facet
    @notice Separated Admin setters and views for SupplyFacet.
 */

import { Modifiers } from '../libs/LibAppStorage.sol';
import { IERC4626 } from '.././interfaces/IERC4626.sol';

contract SupplyAdminFacet is Modifiers {

    /*//////////////////////////////////////////////////////////////
                        ADMIN - SETTERS
    //////////////////////////////////////////////////////////////*/

    /// @notice minDeposit applies to the underlyingAsset mapped to the fiAsset (e.g., DAI).
    function setMinDeposit(
        address fiAsset,
        uint256 amount
    )   external
        onlyAdmin
        returns (bool)
    {
        s.minDeposit[fiAsset] = amount;
        return true;
    }

    /// @notice minWithdraw applies to the underlyingAsset mapped to the fiAsset (e.g., DAI).
    function setMinWithdraw(
        address fiAsset,
        uint256 amount
    )   external
        onlyAdmin
        returns (bool)
    {
        s.minWithdraw[fiAsset] = amount;
        return true;
    }

    function setMintFee(
        address fiAsset,
        uint256 amount
    )   external
        onlyAdmin
        returns (bool)
    {
        s.mintFee[fiAsset] = amount;
        return true;
    }

    function toggleMintEnabled(
        address fiAsset
    )   external
        onlyAdmin
        returns (bool)
    {
        s.mintEnabled[fiAsset] = s.mintEnabled[fiAsset] == 0 ? 1 : 0;
        return s.mintEnabled[fiAsset] == 1 ? true : false;
    }

    function setRedeemFee(
        address fiAsset,
        uint256 amount
    )   external
        onlyAdmin
        returns (bool)
    {
        s.redeemFee[fiAsset] = amount;
        return true;
    }

    function toggleRedeemEnabled(
        address fiAsset
    )   external
        onlyAdmin
        returns (bool)
    {
        s.redeemEnabled[fiAsset] = s.redeemEnabled[fiAsset] == 0 ? 1 : 0;
        return s.redeemEnabled[fiAsset] == 1 ? true : false;
    }

    function setServiceFee(
        address fiAsset,
        uint256 amount
    )   external
        onlyAdmin
        returns (bool)
    {
        s.serviceFee[fiAsset] = amount;
        return true;
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

    function getServiceFee(
        address fiAsset
    )   external
        view
        returns (uint256)
    {
        return s.serviceFee[fiAsset];
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