// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

/**
    █▀▀ ▀▀█▀▀ █▀▀█ █▀▀█ 
    ▀▀█ ░░█░░ █░░█ █▄▄█ 
    ▀▀▀ ░░▀░░ ▀▀▀▀ ▀░░▀

    @author stoa.money
    @title  Admin Facet
    @notice Administrator functions for protcol management.
 */

import { Modifiers } from "../libs/LibAppStorage.sol";
import { LibToken } from "../libs/LibToken.sol";
import { LibTreasury } from "../libs/LibTreasury.sol";
import { LibVault } from "../libs/LibVault.sol";
import { IStoa } from "../interfaces/IStoa.sol";
import { IERC20 } from '@openzeppelin/contracts/interfaces/IERC20.sol';
import { IERC4626 } from "../interfaces/IERC4626.sol";
import { GPv2SafeERC20 } from ".././libs/external/GPv2SafeERC20.sol";

contract AdminFacet is Modifiers {
    using GPv2SafeERC20 for IERC20;

    function whitelist(
        address account,
        uint8   whitelisted
    ) external onlyAdmin() {

        s.isWhitelisted[account] = whitelisted == 1 ? 1 : 0;
    }

    function setMinDeposit(
        address asset,
        uint256 amount
    ) external onlyAdmin() {

        s.minDeposit[asset] = amount;
    }

    function setMinWithdraw(
        address asset,
        uint256 amount
    ) external onlyAdmin() {

        s.minWithdraw[asset] = amount;
    }

    function setMintFee(
        address asset,
        uint256 amount
    ) external onlyAdmin() {

        s.mintFee[asset] = amount;
    }

    function setMintEnabled(
        address asset,
        uint8   enabled
    ) external onlyAdmin() {

        s.mintEnabled[asset] = enabled;
    }

    function setRedeemFee(
        address asset,
        uint256 amount
    ) external onlyAdmin() {

        s.redeemFee[asset] = amount;
    }

    function setRedeemEnabled(
        address asset,
        uint8   enabled
    ) external onlyAdmin() {

        s.redeemEnabled[asset] = enabled;
    }

    // Only consider diamond as the inputStore for now.
    // /// @dev    For non-vault/exchange interactions only.
    // function setInputStore(
    //     address inputStore,
    //     address inputAsset
    // ) external onlyAdmin() {

    //     s.inputStore[inputAsset] = inputStore;
    // }

    function setCreditAsset(
        address asset,
        address creditAsset
    ) external onlyAdmin() {

        s.creditAsset[asset] = creditAsset;
    }

    function addActiveInput(
        address activeAsset,
        address inputAsset
    ) external onlyAdmin() {

        for (uint i = 0; i < s.activeInputs[activeAsset].length; i++) {

            // Check if the inputAsset is not yet added.
            if (s.activeInputs[activeAsset][i] == inputAsset) return;
        }
        s.activeInputs[activeAsset].push(inputAsset);
    }

    /// @dev    delete will leave a gap - address(0) - in the array. Can later remove.
    function revokeActiveInput(
        address activeAsset,
        address inputAsset
    ) external onlyAdmin() {

        for (uint i = 0; i < s.activeInputs[activeAsset].length; i++) {
            if (s.activeInputs[activeAsset][i] == inputAsset) {
                delete s.activeInputs[activeAsset][i];
                return;
            }
        }
    }

    /// @dev    Set 'vault' to address(0) to disassociate inputAsset from vault.
    /// @dev    migrateVault() should be called instead if associated assets are still live.
    function setVault(
        address vault,
        address input,
        address active,
        address credit, // Leaving this blank means credit cannot be minted against vault.
        uint8   enabled
    ) external onlyAdmin() {

        s.vaultParams[vault].input      = input;
        s.vaultParams[vault].active     = active;
        s.vaultParams[vault].credit     = credit;
        s.vaultParams[vault].enabled    = enabled;
    }

    function migrateVault(
        address vault,
        address newVault,
        uint256 buffer
    ) external onlyAdmin() returns (uint256 newAssets) {

        // Vault needs to be disabled before executing migration.
        if (s.vaultParams[vault].enabled != 0) return 0;

        s.vaultParams[newVault].input       = s.vaultParams[vault].input;
        s.vaultParams[newVault].active      = s.vaultParams[vault].active;
        s.vaultParams[newVault].credit      = s.vaultParams[vault].credit;

        uint256 assets = LibVault._unwrapShares(
            IERC20(vault).balanceOf(address(this)),
            vault,
            address(this)
        );

        IERC20(IERC4626(vault).asset()).safeTransferFrom(msg.sender, address(this), buffer);

        LibVault._wrap(assets + buffer, newVault, address(this));

        newAssets = LibVault._totalValue(newVault);

        require(assets > newAssets, "AdminFacet: Vault migration failed");

        // To finalise migration, re-enable vault and call rebase.
    }

    /// @dev    Set 'convertTo' to address(0) to disable conversions.
    function setActiveConvert(
        address activeAsset,
        address creditAsset
    ) external onlyAdmin() {

        s.activeConvertEnabled[activeAsset] = creditAsset;
    }

    /// @dev    Set 'convertTo' to address(0) to disable conversions.
    function setCreditConvert(
        address creditAsset,
        address activeAsset,
        uint8   enabled
    ) external onlyAdmin() {

        s.creditConvertEnabled[creditAsset][activeAsset] = enabled;
    }

    function freezeSafe(
        address account,
        uint32  index,
        uint8   freeze
    ) external onlyAdmin() {

        s.safe[account][index].status = freeze == 1 ? 2 : 1;
    }

    function setPointsRate(
        address asset,
        uint256 amount
    ) external onlyAdmin() {

        s.pointsRate[asset] = amount;
    }

    // function setFeeCollector(
    //     address feeCollector
    // ) external onlyAdmin() {

    //     s.feeCollector = feeCollector;
    // }

    function getBackingReserve(
        address backingAsset
    ) external view returns (uint256) {

        return s.backingReserve[backingAsset];
    }

    function getCreditRedeemAllowance(
        address account,
        address backingAsset
    ) external view returns (uint256) {

        return s.creditRedeemAllowance[account][backingAsset];
    }
}