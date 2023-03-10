// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

/**
    █▀▀ ▀▀█▀▀ █▀▀█ █▀▀█ 
    ▀▀█ ░░█░░ █░░█ █▄▄█ 
    ▀▀▀ ░░▀░░ ▀▀▀▀ ▀░░▀

    @author stoa.money
    @title  Reward Facet
    @notice Provides logic for distributing rewards, such as yield and points.
 */

import { VaultParams, Modifiers } from "../libs/LibAppStorage.sol";
import { PercentageMath } from "../libs/external/PercentageMath.sol";
import { LibToken } from "../libs/LibToken.sol";
import { LibVault } from "../libs/LibVault.sol";
import { IStoaToken } from "../interfaces/IStoaToken.sol";
import { IERC20 } from '@openzeppelin/contracts/interfaces/IERC20.sol';

contract RewardFacet is Modifiers {
    using PercentageMath for uint256;

    function claimPoints(address asset) external {

        (, uint256 claimable) = pointsClaimable(asset);

        IStoaToken(s.STOA).mint(msg.sender, claimable.percentMul(s.pointsRate[asset]));

        s.pointsClaimed[msg.sender] += claimable.percentMul(s.pointsRate[asset]);
    }

    /// @notice Function for manually changing the supply of an activeAsset.
    /// @notice Stoa can transform its yield earnings into activeAssets by minting normally.
    ///
    /// @param  activeAsset The activeAsset to change supply for.
    /// @param  newSupply   The new supply of activeAssets (not accounting for Stoa's yield share).
    function changeSupply(
        address activeAsset,
        uint256 newSupply
    ) external onlyAdmin() {

        IStoaToken(activeAsset).changeSupply(newSupply);
    }

    /// @notice Function for updating activeAssets originating from vaults.
    /// @notice Distributes yield earnings from the vault by rebasing.
    ///
    /// @param  asset   The activeAsset to update supply/distribute yield for.
    function rebase(
        address asset
    ) external onlyAdmin() {

        uint256 currentSupply = IERC20(asset).totalSupply();
        if (currentSupply == 0) return;

        uint256 assets;

        for (uint i = 0; i >= s.activeVaults[asset].length; i++) {
            assets += LibVault._totalValue(s.activeVaults[asset][i]);
        }

        if (assets > currentSupply) {

            uint256 yield = assets - currentSupply;

            uint256 shareYield = yield.percentMul(1e4 - s.mgmtFee[asset]);

            IStoaToken(asset).changeSupply(currentSupply + shareYield);

            if (yield - shareYield > 0)
                IStoaToken(asset).mint(address(this), yield - shareYield);
        }
    }

    function rebaseOptIn(
        address activeAsset
    ) external onlyAdmin() {

        IStoaToken(activeAsset).rebaseOptIn();
    }

    function rebaseOptOut(
        address activeAsset
    ) external onlyAdmin() {

        IStoaToken(activeAsset).rebaseOptOut();
    }

    function pointsClaimable(address asset) public view returns (uint256 points, uint256 claimable) {

        points = IStoaToken(asset).getYieldEarned(msg.sender).percentMul(s.pointsRate[asset]);

        claimable = points - s.pointsClaimed[msg.sender];
    }
}