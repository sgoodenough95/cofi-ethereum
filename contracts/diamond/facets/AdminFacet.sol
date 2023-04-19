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
import { ICoFi } from "../interfaces/ICoFi.sol";

contract AdminFacet is Modifiers {

    function setWhitelist(
        address account,
        uint8   whitelisted
    )   external
        onlyAdmin()
    {
        s.isWhitelisted[account] = whitelisted == 1 ? 1 : 0;
    }

    function setAdmin(
        address account,
        uint8   isAdmin
    )   external
        onlyAdmin()
    {
        s.isWhitelisted[account] = isAdmin == 1 ? 1 : 0;
    }

    function setMinDeposit(
        address inputAsset,
        uint256 amount
    )   external
        onlyAdmin()
    {
        s.minDeposit[inputAsset] = amount;
    }

    function setMinWithdraw(
        address inputAsset,
        uint256 amount
    )   external
        onlyAdmin()
    {
        s.minWithdraw[inputAsset] = amount;
    }

    function setMintFee(
        address fiAsset,
        uint256 amount
    )   external
        onlyAdmin()
    {
        s.mintFee[fiAsset] = amount;
    }

    function setMintEnabled(
        address fiAsset,
        uint8   enabled
    )   external
        onlyAdmin()
    {
        s.mintEnabled[fiAsset] = enabled;
    }

    function setRedeemFee(
        address fiAsset,
        uint256 amount
    )   external
        onlyAdmin()
    {
        s.redeemFee[fiAsset] = amount;
    }

    function setRedeemEnabled(
        address fiAsset,
        uint8   enabled
    )   external
        onlyAdmin()
    {
        s.redeemEnabled[fiAsset] = enabled;
    }

    /// @dev    'batchPointsCapture()' must be called beforehand to ensure
    ///         points have updated correctly prior to a pointsRate change.
    function setPointsRate(
        address fiAsset,
        uint256 amount
    )   external
        onlyAdmin()
    {
        s.pointsRate[fiAsset] = amount;
    }

    function setFeeCollector(
        address feeCollector
    )   external
        onlyAdmin()
    {
        s.feeCollector = feeCollector;
    }

    function getBacking(
        address fiAsset
    )   external
        view
        returns (uint256, address)
    {
        return (s.backing[s.vault[fiAsset]], s.vault[fiAsset]);
    }
}