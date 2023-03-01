// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

/**
    █▀▀ ▀▀█▀▀ █▀▀█ █▀▀█ 
    ▀▀█ ░░█░░ █░░█ █▄▄█ 
    ▀▀▀ ░░▀░░ ▀▀▀▀ ▀░░▀

    @author stoa.money
    @title  SafeVault Facet
    @notice Functions for opening, depositing, and withdrawing via Vault pathway.
 */

import { Safe, VaultParams, Modifiers } from '../libs/LibAppStorage.sol';
import { LibToken } from '../libs/LibToken.sol';
import { LibVault } from '../libs/LibVault.sol';
import { LibSafe } from '../libs/LibSafe.sol';
import { IERC4626 } from ".././interfaces/IERC4626.sol";

contract SafeVaultFacet is Modifiers {

    /// @notice Opens a Sade with an activeAsset originating from a vault.
    /// @dev    Only this route likely to be available for MVP.
    ///
    /// @param  amount  The amount of inputAssets to deposit.
    /// @param  vault   The vault to interact with.
    function openVault(
        uint256 amount,
        address vault
    )   external
        minDeposit(amount, s.vaultParams[vault].input)
    {
        VaultParams memory _vault = s.vaultParams[vault];

        require(_vault.enabled == 1, "VaultFacet: Vault disabled");

        require(LibToken._isMintEnabled(_vault.active) == 1, "VaultFacet: Mint disabled");

        LibVault._wrap(amount, vault, msg.sender);

        // uint256 assets = LibVault._getAssets(shares, vault);

        // uint256 fee = LibToken._getMintFee(_vault.active, assets);
        // mintAfterFee = assets - fee;

        LibToken._mint(_vault.active, address(this), amount);

        // if (fee > 0) {
        //    LibToken._mint(_vault.active, address(this), fee);
        //     emit LibToken.MintFeeCaptured(_vault.active, fee); 
        // }

        // Deposit activeAssets to ERC4626 Safe Store contract.
        LibSafe._open(amount, address(this), s.primeStore[_vault.active]);
    }

    function depositVault(
        uint256 amount,
        address vault,
        address depositFrom,
        address recipient,
        uint32  index
    )   external
        minDeposit(amount, s.vaultParams[vault].input)
        activeSafe(recipient, index)
    {
        VaultParams memory _vault = s.vaultParams[vault];

        require(_vault.enabled == 1, "VaultFacet: Vault disabled");

        require(LibToken._isMintEnabled(_vault.active) == 1, "VaultFacet: Mint disabled");

        LibVault._wrap(amount, vault, depositFrom);

        // uint256 assets = LibVault._getAssets(shares, vault);

        // uint256 fee = LibToken._getMintFee(_vault.active, assets);
        // mintAfterFee = assets - fee;

        LibToken._mint(_vault.active, address(this), amount);

        // if (fee > 0) {
        //    LibToken._mint(_vault.active, address(this), fee);
        //     emit LibToken.MintFeeCaptured(_vault.active, fee); 
        // }

        // Deposit activeAssets to ERC4626 Safe Store contract.
        LibSafe._deposit(amount, depositFrom, recipient, index);
    }

    function withdrawVault(
        uint256 amount,
        uint32  index,
        address recipient
    )   external
        minWithdraw(amount, IERC4626(s.safe[msg.sender][index].store).asset())
        activeSafe(msg.sender, index)
    {
        address vault = s.activeToVault[IERC4626(s.safe[msg.sender][index].store).asset()];

        VaultParams memory _vault = s.vaultParams[vault];

        require(_vault.enabled == 1, "VaultFacet: Vault disabled");

        // First, pull activeAssets from Safe Store contract.
        uint256 assets = LibSafe._withdraw(amount, address(this), index);

        // Second, burn activeAssets.
        LibToken._burn(_vault.active, address(this), assets);

        // Lastly, transfer inputAssets from vault to recipient.
        LibVault._unwrap(amount, vault, recipient);
    }
}