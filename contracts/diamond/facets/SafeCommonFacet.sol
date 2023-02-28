// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

/**
    █▀▀ ▀▀█▀▀ █▀▀█ █▀▀█ 
    ▀▀█ ░░█░░ █░░█ █▄▄█ 
    ▀▀▀ ░░▀░░ ▀▀▀▀ ▀░░▀

    @author stoa.money
    @title  Safe Facet
    @notice User-operated functions for managing Safes.
 */

import { Safe, VaultParams, Modifiers } from '../libs/LibAppStorage.sol';
import { LibToken } from '../libs/LibToken.sol';
import { LibVault } from '../libs/LibVault.sol';
import { LibSafe } from '../libs/LibSafe.sol';
import { IERC4626 } from ".././interfaces/IERC4626.sol";

contract SafeCommonFacet is Modifiers {

    /// @notice Opens a Safe with activeAssets already held by the account.
    ///
    /// @param  amount      The amount of activeAssets to deposit.
    /// @param  activeAsset The address of the activeAsset.
    function openActive(
        uint256 amount,
        address activeAsset
    )   external
        minDeposit(amount, activeAsset)
    {
        LibSafe._open(amount, msg.sender, s.primeStore[activeAsset]);
    }

    /// @notice Deposits an activeAsset to an existing Safe.
    ///
    /// @param  amount      The amount of activeAssets to deposit.
    /// @param  recipient   The owner of the recipient Safe.
    /// @param  index       The Safe ID.
    function depositActive(
        uint256 amount,
        address depositFrom,
        address recipient,
        uint32  index
    )   external
        minDeposit(amount, IERC4626(s.safe[recipient][index].store).asset())
        activeSafe(recipient, index)
    {
        LibSafe._deposit(amount, depositFrom, recipient, index);
    }

    /// @notice Deposits an activeAsset to a non-existent Safe.
    /// @notice recipient can only claim once created an eligible Safe.
    ///
    /// @param  amount      The amount of activeAssets to deposit.
    /// @param  asset       The activeAsset to deposit.
    /// @param  depositFrom The account to deposit assets from.
    /// @param  recipient   The account eliglble to claim assets.
    function depositActiveClaim(
        uint256 amount,
        address asset,
        address depositFrom,
        address recipient
    )   external
        minDeposit(amount, asset)
    {
        uint256 shares =
            IERC4626(s.primeStore[asset]).deposit(amount, address(this), depositFrom);

        s.pendingBal[recipient][s.primeStore[asset]] += shares;
    }

    /// @notice Deposits a creditAsset to a non-existent Safe.
    /// @notice recipient can only claim once created an eligible Safe.
    ///
    /// @param  amount      The amount of creditAssets.
    /// @param  asset       The creditAsset to deposit.
    /// @param  depositFrom The account to deposit assets from.
    /// @param  recipient   The account eligble to claim assets.
    function depositCreditClaim(
        uint256 amount,
        address asset,
        address depositFrom,
        address recipient
    )   external
        minDeposit(amount, asset)
    {
        LibToken._burn(asset, depositFrom, amount);

        uint256 shares = IERC4626(s.primeStore[asset]).previewDeposit(amount);

        s.pendingCredit[recipient][asset] += shares;
    }

    function withdrawActive(
        uint256 amount,
        address recipient,
        uint32  index
    )   external
        minWithdraw(amount, IERC4626(s.safe[msg.sender][index].store).asset())
        activeSafe(msg.sender, index)
    {
        // Check has free bal
        require(
            amount <= LibSafe._getMaxWithdraw(msg.sender, index),
            'SafeFacet: Insufficient allowance'
        );

        LibSafe._withdraw(amount, recipient, index);
    }

    function transfer(
        uint256 amount,
        address recipient,
        uint32  fromIndex,
        uint32  toIndex
    )   external
        minWithdraw(amount, IERC4626(s.safe[msg.sender][fromIndex].store).asset())
        activeSafe(msg.sender, fromIndex)
    {
        // Check has free bal
        require(
            amount <= LibSafe._getMaxWithdraw(msg.sender, fromIndex),
            'SafeFacet: Insufficient allowance'
        );

        uint256 shares = IERC4626(s.safe[msg.sender][fromIndex].store).previewDeposit(amount);

        LibSafe._adjustBal(-int256(shares), msg.sender, fromIndex);

        if (
            s.safe[recipient][toIndex].status != 1 ||
            s.safe[msg.sender][fromIndex].store != s.safe[recipient][toIndex].store
        )   
            s.pendingBal[recipient][s.safe[msg.sender][fromIndex].store] += shares;
        else
            LibSafe._adjustBal(int256(shares), recipient, toIndex);
    }

    function transferCredit(
        uint256 amount,
        address recipient,
        uint32  fromIndex,
        uint32  toIndex
    )   external
        minWithdraw(amount, IERC4626(s.safe[msg.sender][fromIndex].store).asset())
        activeSafe(msg.sender, fromIndex)
    {
        (uint256 maxBorrow, uint256 origFee) = LibSafe._getMaxBorrow(msg.sender, fromIndex);

        // Check has free credit
        require(amount <= maxBorrow, 'SafeFacet: Insufficient allowance');

        IERC4626 vault = IERC4626(s.safe[msg.sender][fromIndex].store);

        // Convert assets to shares to adjust Safe params.
        uint256 creditShares    = vault.previewDeposit(amount);
        uint256 origFeeShares   = vault.previewDeposit(origFee);

        // Reduce credit and bal of sender.
        LibSafe._adjustCredit(-int256(creditShares), msg.sender, fromIndex);
        LibSafe._adjustBal(-int256(origFeeShares), msg.sender, fromIndex);

        // Increase credit of recipient, depending on if the Safe is eligible.
        if (
            s.safe[recipient][toIndex].status != 1 ||
            // Check if sender and receiver Safes share same creditAsset.
            s.creditAsset[IERC4626(s.safe[msg.sender][fromIndex].store).asset()] !=
                s.creditAsset[IERC4626(s.safe[recipient][toIndex].store).asset()]
        )   // Increase pending credit claim if recipient Safe not compatible.
            s.pendingCredit[recipient][s.safe[msg.sender][fromIndex].creditAsset] += creditShares;
        else
            LibSafe._adjustCredit(int256(creditShares), recipient, toIndex);
    }

    function borrow(
        uint256 amount,
        address recipient,
        uint32  index
    )   external
        minWithdraw(amount, s.safe[msg.sender][index].creditAsset)
        activeSafe(msg.sender, index)
    {
        (uint256 maxBorrow, uint256 origFee) = LibSafe._getMaxBorrow(msg.sender, index);

        require(amount <= maxBorrow, 'SafeFacet: Insufficient credit');

        IERC4626 vault = IERC4626(s.safe[msg.sender][index].store);

        // Convert assets to shares to adjust Safe params.
        uint256 creditShares    = vault.previewDeposit(amount);
        uint256 origFeeShares   = vault.previewDeposit(origFee);

        LibSafe._adjustCredit(-int256(creditShares), msg.sender, index);
        LibSafe._adjustBal(-int256(origFeeShares), msg.sender, index);

        // Update backing reserve only applies to direct mints.

        LibToken._mint(s.safe[msg.sender][index].creditAsset, recipient, amount);

        /**
            LOAN CALC STEPS:

            1. User opens Safe with 10,000 USD. Has "2,500" credits.
            2. Alice can see that her maxBorrow is 2,487.5 credits.
            3. Alice calls borrow(2,487.5, Alice's wallet, 0).
            4* Alice's credit is now 12.5.
            5* Alice's maxBorrow is now 12.5-(12.5*0.05%)=12.4375.

            If Alice's maxBorrow < minWithdraw, display maxBorrow as 0.
         */

        s.origFeesCollected[s.safe[msg.sender][index].store] += origFeeShares;
    }

    function repay(
        uint256 amount,
        address depositFrom,
        address recipient,
        uint32  index
    )   external
        minDeposit(amount, s.safe[recipient][index].creditAsset)
        activeSafe(recipient, index)
    {
        LibToken._burn(s.safe[recipient][index].creditAsset, depositFrom, amount);

        uint256 shares = IERC4626(s.safe[recipient][index].store).previewDeposit(amount);

        LibSafe._adjustCredit(int256(shares), recipient, index);
    }

    function claimBal(
        address asset,
        uint32  index
    )   external
        activeSafe(msg.sender, index)
    {
        require(
            s.pendingBal[msg.sender][asset] > 0,
            'SafeFacet: Invalid bal claim'
        );

        require(
            asset == s.safe[msg.sender][index].store,
            'SafeFacet: Asset mismatch for bal claim'
        );

        s.safe[msg.sender][index].bal += s.pendingBal[msg.sender][asset];

        emit LibSafe.SafeBalUpdated(msg.sender, index, int256(s.pendingBal[msg.sender][asset]));

        s.pendingBal[msg.sender][asset] = 0;
    }

    function claimCredit(
        address asset,
        uint32  index
    )   external
        activeSafe(msg.sender, index)
    {
        require(
            s.pendingCredit[msg.sender][asset] > 0,
            'SafeFacet: Invalid credit claim'
        );

        require(
            asset == s.safe[msg.sender][index].creditAsset,
            'SafeFacet: Asset mismatch for credit claim'
        );

        s.safe[msg.sender][index].credit += s.pendingCredit[msg.sender][asset];

        emit LibSafe.SafeCreditUpdated(msg.sender, index, int256(s.pendingCredit[msg.sender][asset]));

        s.pendingCredit[msg.sender][asset] = 0;
    }

    function getSafe(
        address account,
        uint32  index
    ) external view returns (Safe memory) {

        return s.safe[account][index];
    }
}