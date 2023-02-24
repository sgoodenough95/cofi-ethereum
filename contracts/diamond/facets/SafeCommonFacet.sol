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

    function depositActive(
        uint256 amount,
        uint32  index
    )   external
        minDeposit(amount, IERC4626(s.safe[msg.sender][index].store).asset())
    {
        require(
            s.safe[msg.sender][index].status == 1 ||
            s.safe[msg.sender][index].status == 2,
            'SafeFacet: Safe not active'
        );

        LibSafe._deposit(amount, msg.sender, index);
    }

    // function withdrawExchange() {}

    // function withdrawVault() {}

    // function withdrawActive() {}

    // function transfer(
    //     uint256 amount,
    //     address recipient,
    //     uint32  fromIndex,
    //     uint32  toIndex     // Later do not specify (?)
    // )   external
    //     minDeposit(amount, IERC4626(s.safe[msg.sender][fromIndex].store).asset())
    // {
    //     require(
    //         s.safe[msg.sender][fromIndex].status == 1 ||
    //         s.safe[msg.sender][fromIndex].status == 2,
    //         'SafeFacet: Safe not active'
    //     );

    //     // Check has free bal

    //     if(
    //         s.safe[recipient][toIndex].status == 0 ||
    //         s.safe[recipient][toIndex].status > 2,
    //     )   pendingClaim[recipient][IERC4626(s.safe[msg.sender][fromIndex].store).asset()]
    //             += amount;

    //     require(
    //         s.safe[msg.sender][fromIndex].store == s.safe[recipient][toIndex].store,
    //         'SafeFacet: Recipient Safe belongs to different store'
    //     );
    // }

    // function transferCredit() {}

    // function transferExternal() {} // (?) Can be handled by deposit.

    function borrow(
        uint256 amount,
        address recipient,
        uint32  index
    )   external
        minWithdraw(amount, s.safe[msg.sender][index].creditAsset)
    {
        require(
            s.safe[msg.sender][index].status == 1 ||
            s.safe[msg.sender][index].status == 2,
            'SafeFacet: Safe not active'
        );

        (uint256 maxBorrow, uint256 origFee) = LibSafe._getMaxBorrow(msg.sender, index);

        require(amount <= maxBorrow, 'SafeFacet: Insufficient credit');

        // Update backing reserve only applies to direct mints.

        s.safe[msg.sender][index].status = 2;

        LibToken._mint(s.safe[msg.sender][index].creditAsset, recipient, amount);

        IERC4626 vault = IERC4626(s.safe[msg.sender][index].store);

        // Convert assets to shares to adjust Safe params.
        uint256 creditShares    = vault.previewDeposit(amount);
        uint256 origFeeShares   = vault.previewDeposit(origFee);

        LibSafe._adjustCredit(-int256(creditShares), msg.sender, index);
        LibSafe._adjustBal(-int256(origFeeShares), msg.sender, index);

        emit LibSafe.Borrow(msg.sender, index, amount, origFee);

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
        address account,
        uint32  index
    )   external
        minDeposit(amount, s.safe[account][index].creditAsset)
    {
        require(
            s.safe[account][index].status == 1 ||
            s.safe[account][index].status == 2,
            'SafeFacet: Safe not active'
        );

        LibToken._burn(s.safe[account][index].creditAsset, depositFrom, amount);

        uint256 shares = IERC4626(s.safe[account][index].store).previewDeposit(amount);

        LibSafe._adjustCredit(int256(shares), account, index);

        // Set status to 1 if fully repaid (?)

        emit LibSafe.Repay(account, index, amount);
    }

    function getSafe(
        address account,
        uint32  index
    ) external view returns (Safe memory) {

        return s.safe[account][index];
    }

    // Can be deduced off-chain.
    // function getMaxBorrow(
    //     address account,
    //     uint32  index
    // ) external returns (uint256 maxBorrow, uint256 origFee) {

    //     (maxBorrow, origFee) = LibSafe._getMaxBorrow(account, index);
    // }
}