// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

/**
    █▀▀ ▀▀█▀▀ █▀▀█ █▀▀█ 
    ▀▀█ ░░█░░ █░░█ █▄▄█ 
    ▀▀▀ ░░▀░░ ▀▀▀▀ ▀░░▀

    @author stoa.money
    @title  Rebase Facet
    @notice Provides logic for distributing yield earnings.
 */

import { VaultParams, Modifiers } from "../libs/LibAppStorage.sol";
import { PercentageMath } from "../libs/external/PercentageMath.sol";
import { LibVault } from "../libs/LibVault.sol";
import { IStoaToken } from "../interfaces/IStoaToken.sol";
import { IERC20 } from '@openzeppelin/contracts/interfaces/IERC20.sol';

contract RebaseFacet is Modifiers {
    using PercentageMath for uint256;

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
    /// @param  vault   The vault to distribute yield earnings for.
    function rebase(
        address vault
    ) external onlyAdmin() {

        VaultParams memory _vault = s.vaultParams[vault];

        uint256 currentSupply = IERC20(_vault.active).totalSupply();
        if (currentSupply == 0) return;

        uint256 assets = LibVault._totalValue(vault);

        if (assets > currentSupply) {

            uint256 yield = assets - currentSupply;

            uint256 shareYield = yield.percentMul(1e4 - s.mgmtFee[_vault.active]);

            IStoaToken(_vault.active).changeSupply(currentSupply + shareYield);

            if (yield - shareYield > 0)
            IStoaToken(_vault.active).mint(address(this), yield - shareYield);
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
}