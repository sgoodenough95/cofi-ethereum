// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

/**
    █▀▀ ▀▀█▀▀ █▀▀█ █▀▀█ 
    ▀▀█ ░░█░░ █░░█ █▄▄█ 
    ▀▀▀ ░░▀░░ ▀▀▀▀ ▀░░▀

    @author stoa.money
    @title  Safe Facet
    @notice User-operated functions for managing Safes.
    @dev    TO-DO: Split [vault] and [exchange] into separate facets.
 */

import { Safe, VaultParams, Modifiers } from '../libs/LibAppStorage.sol';
import { LibToken } from '../libs/LibToken.sol';
import { LibVault } from '../libs/LibVault.sol';
import { LibSafe } from '../libs/LibSafe.sol';
import { IERC4626 } from ".././interfaces/IERC4626.sol";

contract SafeCommon is Modifiers {

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
        returns (uint256)
    {
        require(
            s.safe[msg.sender][index].status == 1 ||
            s.safe[msg.sender][index].status == 2,
            'SafeFacet: Safe not active'
        );

        (uint256 maxBorrow, uint256 origFee) = LibSafe._getMaxBorrow(msg.sender, index);

        require(amount <= maxBorrow, 'SafeFacet: Insufficient credit');

        // Update backing reserve only applies to direct mints (?)

        LibToken._mint(s.safe[msg.sender][index].creditAsset, recipient, amount);

        LibSafe._adjustCredit(int256(amount), msg.sender, index);

        LibSafe._adjustBal(-int256(origFee), msg.sender, index);

        // Update Stoa Treasury Safe (?)

        // emit Borrow

        return origFee;
    }

    // function repay() {}

    function getSafe(
        address account,
        uint32  index
    ) external view returns (Safe memory) {

        return s.safe[account][index];
    }

    function getMaxBorrow(
        address account,
        uint32  index
    ) external view returns (uint256 maxBorrow, uint256 origFee) {

        (maxBorrow, origFee) = LibSafe._getMaxBorrow(account, index);
    }
}