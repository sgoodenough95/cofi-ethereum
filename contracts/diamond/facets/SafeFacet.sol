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

contract SafeFacet is Modifiers {

    /// @notice Opens a Safe with an inputAsset.
    /// @dev    Only caller can open a Safe for themselves.
    ///
    /// @param  amount          The amount of inputAssets to deposit.
    /// @param  minAmountOut    The minimum amount of claimable inputAssets denoted by shares.
    /// @param  vault           The vault to interact with (e.g., yvUSDC).
    function openInput(
        uint256 amount,
        uint256 minAmountOut,
        address depositFrom,
        address vault
    )   external
        // Need to set minDeposit for each vault.
        minDeposit(amount, vault)
    {
        // Once opened, account can never close (open indefinitely).
        require(
            s.safe[msg.sender][vault].status == 0,
            'SafeFacet: Safe already exists for [account, asset] combination'
        );

        uint256 shares = LibVault._wrap(amount, vault, depositFrom);

        require(
            // Get corresponding assets in vault contract for slippage check.
            LibVault._getAssets(shares, vault) >= minAmountOut,
            'SafeFacet: Slippage exceeded'
        );
        
        // Deposit assets into ERC4626 SafeStore contract.
        LibSafe._open(shares, msg.sender, s.safeStore[vault]);
    }

    /// @notice Opens a Safe with shares originating from a supported vault.
    ///
    /// @param  shares  The amount of shares to deposit.
    /// @param  vault   The vault to interact with.
    function openShares(
        uint256 shares,
        address vault
    )   external
        // Ensure minDeposit is denominated in underlying assets.
        minDeposit(LibVault._getAssets(shares, vault), vault)
        returns (uint256 mintAfterFee)
    {
        require(
            s.safe[msg.sender][vault].status == 0,
            'SafeFacet: Safe already exists for [account, asset] combination'
        );

        LibSafe._open(shares, msg.sender, s.safeStore[vault]);
    }

    /// @notice User can deposit inputAsset (e.g., USDC) to their Safe.
    ///         Automatically put to work in yield venue.
    ///
    /// @param  amount          The amount of inputAssets deposited.
    /// @param  minAmountOut    The minimum amount of claimable inputAssets denoted by shares.
    /// @param  vault           The yield venue.
    /// @param  depositFrom     The account to deposit inputAssets from.
    /// @param  recipient       The Safe owner - must have an active Safe.
    function depositInput(
        uint256 amount,
        uint256 minAmountOut,
        address vault,
        address depositFrom,
        address recipient
    )   external
        minDeposit(amount, vault)
        activeSafe(recipient, vault)
    {
        uint256 shares = LibVault._wrap(amount, vault, depositFrom);

        require(
            // Get corresponding assets in vault contract for slippage check.
            LibVault._getAssets(shares, vault) >= minAmountOut,
            'SafeFacet: Slippage exceeded'
        );

        // As protocol contract holds shares from wrap operation, use address(this) for 2nd arg.
        LibSafe._deposit(shares, address(this), recipient, s.safeStore[vault]);
    }

    /// @notice User can deposit shares (e.g., yvUSDC) directly.
    ///
    /// @param  shares      The amount of shares to deposit.
    /// @param  vault       The address and yield venue of the shares.
    /// @param  depositFrom The account to deposit shares from.
    function depositShares(
        uint256 shares,
        address vault,
        address depositFrom
    )   external
        minDeposit(LibVault._getAssets(shares, vault), vault)
        activeSafe(msg.sender, vault)
    {
        LibSafe._deposit(shares, depositFrom, address(this), s.safeStore[vault]);
    }

    /// @notice Enables a user to borrow fiAssets against their Safe collateral.
    ///
    /// @param  amount      The amount of fiAssets to borrow.
    /// @param  vault       The collateral asset (used for identifying the Safe).
    /// @param  recipient   The recipient of the fiAssets.
    function borrow(
        uint256 amount,
        address vault,
        address recipient
    )   external
        // Apply minWithdraw for borrowed amount.
        minWithdraw(amount, vault)
        activeSafe(msg.sender, vault)
    {
        address asset = IERC4626(vault).asset();

        (uint256 credit, uint256 origFee) = LibSafe._getAvailCredit(msg.sender, asset);

        require(amount <= credit, 'SafeFacet: Insufficient credit');

        // Convert assets to shares to accurately adjust Safe params.
        uint256 creditShares    = s.safeStore[asset].previewDeposit(amount);
        uint256 origFeeShares   = s.safeStore[asset].previewDeposit(origFee);

        LibSafe._adjustCredit(-int256(creditShares), msg.sender, asset);
        LibSafe._adjustBal(-int256(origFeeShares), msg.sender, asset);

        // Update backing reserve only applies to direct mints.

        LibToken._mint(s.creditAsset[asset], recipient, amount);

        /**
            LOAN CALC STEPS:

            1. Alice opens Safe with 10,000 USD. Has '2,500' credits.
            2. Alice can see that her maxBorrow is 2,487.5 credits.
            3. Alice calls borrow(2,487.5, yvDAI, Alice's wallet).
            4* Alice's credit is now 12.5.
            5* Alice's maxBorrow is now 12.5-(12.5*0.05%)=12.4375.

            If Alice's maxBorrow < minWithdraw modifier, display maxBorrow as 0 (on FE).
         */

        // Amount made available for feeCollector to claim in Safe Store contract.
        s.origFeesCollected[s.safeStore[asset]] += origFeeShares;
    }

    /// @notice Enables a user to repay a loan with fiAssets.
    /// @dev    Cannot pay in excess of debt.
    ///
    /// @param  amount      The amount repaid (in fiAssets).
    /// @param  depositFrom The account to repay from.
    /// @param  recipient   The recipient of the repayment amount.
    function repay(
        uint256 amount,
        address depositFrom,
        address recipient,
        address vault
    )   external
        // Apply minDeposit for repayment amount, in creditAsset (e.g., fiUSD).
        minDeposit(amount, s.creditAsset[vault])
        activeSafe(recipient, vault)
    {
        amount =
            amount > LibSafe._getMaxCredit(recipient, vault) ?
            LibSafe._getMaxCredit(recipient, vault) :
            amount;

        LibToken._burn(s.creditAsset[vault], depositFrom, amount);

        uint256 shares = IERC4626(s.safeStore[vault]).previewDeposit(amount);

        LibSafe._adjustCredit(int256(shares), recipient, vault);
    }

    function repayWithInput(
        uint256 amount,
        address depositFrom,
        address recipient,
        address vault
    )   external
        minDeposit(amount, IERC4626(vault).asset())
        activeSafe(recipient, vault)
    {

    }

    function repayWithShares(
        uint256 amount,
        address depositFrom,
        address recipient,
        address vault
    )   external
        minDeposit(amount, IERC4626(vault).asset())
        activeSafe(recipient, vault)
    {

    }

    /// @notice Withdraws inputAssets from vault contract.
    /// @dev    Apply slippage calc post redeem fee (e.g., 100 * 99.9% * 99.75%).
    ///
    /// @param  amount          The amount of inputAssets to deposit.
    /// @param  minAmountOut    The minimum amount of activeAssets received (after fees).
    /// @param  vault           The vault to interact with.
    /// @param  recipient       The recipient of the inputAssets.
    function withdrawInputVault(
        uint256 amount,
        uint256 minAmountOut,
        address vault,
        address recipient
    )   external
        minWithdraw(amount, vault)
        activeSafe(msg.sender, vault)
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