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

    /// @notice Opens a Safe with an activeAsset originating from a vault.
    /// @dev    Only this route likely to be available for MVP.
    /// @dev    Only caller can open a Safe for themselves.
    ///
    /// @param  amount          The amount of inputAssets to deposit.
    /// @param  minAmountOut    The minimum amount of activeAssets received (before fees).
    /// @param  vault           The vault to interact with.
    function openVault(
        uint256 amount,
        uint256 minAmountOut,
        address vault
    )   external
        minDeposit(amount, s.vaultParams[vault].input)
        returns (uint256 mintAfterFee)
    {
        VaultParams memory _vault = s.vaultParams[vault];

        require(_vault.enabled == 1, 'SafeVaultFacet: Vault disabled');
        require(LibToken._isMintEnabled(_vault.active) == 1, 'SafeVaultFacet: Mint disabled');

        uint256 shares = LibVault._wrap(amount, vault, msg.sender);

        uint256 assets = LibVault._getAssets(shares, vault);
        require(assets >= minAmountOut, 'SafeVaultFacet: Slippage exceeded');

        uint256 fee = LibToken._getMintFee(_vault.active, assets);
        mintAfterFee = assets - fee;

        LibToken._mint(_vault.active, address(this), assets);

        if (fee > 0) {
           LibToken._mint(_vault.active, address(this), fee);
            emit LibToken.MintFeeCaptured(_vault.active, fee); 
        }

        // Deposit activeAssets to ERC4626 Safe Store contract.
        LibSafe._open(mintAfterFee, address(this), s.primeStore[_vault.active]);
    }

    /// @notice Opens a Safe with an activeAsset originating from a vault.
    /// @dev    Only this route likely to be available for MVP.
    ///
    /// @param  amount          The amount of inputAssets to deposit.
    /// @param  minAmountOut    The minimum amount of activeAssets received (before fees).
    /// @param  vault           The vault to interact with.
    /// @param  depositFrom     The address to deposit inputAssets from.
    /// @param  recipient       The target Safe owner.
    /// @param  index           The index of the Safe.
    function depositVault(
        uint256 amount,
        uint256 minAmountOut,
        address vault,
        address depositFrom,
        address recipient,
        uint32  index
    )   external
        minDeposit(amount, s.vaultParams[vault].input)
        activeSafe(recipient, index)
        returns (uint256 mintAfterFee)
    {
        VaultParams memory _vault = s.vaultParams[vault];

        require(_vault.enabled == 1, "VaultFacet: Vault disabled");
        require(LibToken._isMintEnabled(_vault.active) == 1, "VaultFacet: Mint disabled");

        uint256 shares = LibVault._wrap(amount, vault, depositFrom);

        uint256 assets = LibVault._getAssets(shares, vault);
        require(assets >= minAmountOut, 'SafeVaultFacet: Slippage exceeded');

        uint256 fee = LibToken._getMintFee(_vault.active, assets);
        mintAfterFee = assets - fee;

        // LibToken._mint(_vault.active, address(this), amount);

        if (fee > 0) {
           LibToken._mint(_vault.active, address(this), fee);
            emit LibToken.MintFeeCaptured(_vault.active, fee); 
        }

        // Deposit activeAssets to ERC4626 Safe Store contract.
        LibSafe._deposit(mintAfterFee, depositFrom, recipient, index);
    }

    /// @notice Withdraws inputAssets from vault contract.
    /// @dev    Only this route likely to be available for MVP.
    /// @dev    Apply slippage calc post redeem fee (e.g., 100 * 99.9% * 99.75%).
    ///
    /// @param  amount          The amount of inputAssets to deposit.
    /// @param  minAmountOut    The minimum amount of activeAssets received (after fees).
    /// @param  vault           The vault to interact with.
    /// @param  index           The index of the Safe.
    /// @param  recipient       The recipient of the inputAssets.
    function withdrawInputVault(
        uint256 amount,
        uint256 minAmountOut,
        address vault,
        uint32  index,
        address recipient
    )   external
        minWithdraw(amount, s.vaultParams[vault].active)
        activeSafe(msg.sender, index)
        returns (uint256 burnAfterFee)
    {
        VaultParams memory _vault = s.vaultParams[vault];

        require(_vault.enabled == 1, "VaultFacet: Vault disabled");

        // First, pull activeAssets from Safe Store contract.
        uint256 activeAssets = LibSafe._withdraw(amount, address(this), index);

        uint256 fee = LibToken._getRedeemFee(s.vaultParams[vault].active, activeAssets);
        burnAfterFee = activeAssets - fee;

        // Second, burn activeAssets.
        LibToken._burn(_vault.active, address(this), burnAfterFee);

        // Lastly, transfer inputAssets from vault to recipient.
        uint256 assets = LibVault._unwrap(burnAfterFee, vault, recipient);
        require(assets >= minAmountOut, 'SafeVaultFacet: Slippage exceeded');
    }

    /// @notice Withdraws inputAssets from vault contract.
    /// @dev    Only this route likely to be available for MVP.
    /// @dev    Apply slippage calc post redeem fee (e.g., 100 * 99.9% * 99.75%).
    ///
    /// @param  amount          The amount of inputAssets to deposit.
    /// @param  minAmountOut    The minimum amount of activeAssets received (after fees).
    /// @param  vault           The vault to interact with.
    /// @param  index           The index of the Safe.
    /// @param  recipient       The recipient of the inputAssets.
    function withdrawVaultVault(
        uint256 amount,
        uint256 minAmountOut,
        address vault,
        uint32  index,
        address recipient
    )   external
        minWithdraw(amount, s.vaultParams[vault].active)
        activeSafe(msg.sender, index)
        returns (uint256 burnAfterFee)
    {
        VaultParams memory _vault = s.vaultParams[vault];

        require(_vault.enabled == 1, "VaultFacet: Vault disabled");

        // First, pull activeAssets from Safe Store contract.
        uint256 activeAssets = LibSafe._withdraw(amount, address(this), index);

        uint256 fee = LibToken._getRedeemFee(s.vaultParams[vault].active, activeAssets);
        burnAfterFee = activeAssets - fee;

        // Second, burn activeAssets.
        LibToken._burn(_vault.active, address(this), burnAfterFee);

        // Lastly, transfer inputAssets from vault to recipient.
        uint256 assets = LibVault._unwrap(burnAfterFee, vault, recipient);
        require(assets >= minAmountOut, 'SafeVaultFacet: Slippage exceeded');
    }
}