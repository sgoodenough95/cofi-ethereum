// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

/**

    █▀▀ █▀█ █▀▀ █
    █▄▄ █▄█ █▀░ █

    @author The Stoa Corporation Ltd
    @title  Supply Facet
    @notice Custom functions to enable integration wit certain vaults.
    @dev    Functions are organised as (k, v) mappings, where the vault is the key.
            One caveat of calling via the low-level 'call()' operation, passing
            the bytes4 function selector, is that functions must be accessible
            externally. Therefore, to prevent external calls, a modifier 
            "EXTGuard" has been implemented.
 */

import { Modifiers } from '../libs/LibAppStorage.sol';
import { LibToken } from '../libs/LibToken.sol';
import { LibVault } from '../libs/LibVault.sol';
import { IERC4626 } from '.././interfaces/IERC4626.sol';
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import 'hardhat/console.sol';

contract PartnerFacet is Modifiers {

    function toDeriv_HOPUSDCLP(
        uint256 amount
    ) public EXTGuard {

        uint256[] memory amounts = new uint256[](2);
        amounts[0] = amount;
        SafeERC20.safeApprove(
            IERC20(s.underlying[s.COFI]),
            address(LibVault.HOPUSDCLP),
            amount
        );
        s.RETURN_ASSETS = LibVault.HOPUSDCLP.addLiquidity(
            amounts,
            0,
            block.timestamp + 2 seconds
        );
    }

    function toUnderlying_HOPUSDCLP(
        uint256 amount
    ) public EXTGuard {

        SafeERC20.safeApprove(
            IERC20(IERC4626(s.vault[s.COFI]).asset()),
            address(LibVault.HOPUSDCLP),
            amount
        );
        s.RETURN_ASSETS = LibVault.HOPUSDCLP.removeLiquidityOneToken(
            amount,
            0,
            0,
            block.timestamp + 2 seconds
        );
    }

    function convertToUnderlying_HOPUSDCLP(
        uint256 amount
    ) public {

        s.RETURN_ASSETS = LibVault.HOPUSDCLP.calculateRemoveLiquidityOneToken(
            address(this),
            amount,
            0
        );
    }

    function convertToDeriv_HOPUSDCLP(
        uint256 amount
    ) public {

        uint256[] memory amounts = new uint256[](2);
        amounts[0] = LibToken._toUnderlyingDecimals(s.COFI, amount);
        s.RETURN_ASSETS = LibVault.HOPUSDCLP.calculateTokenAmount(
            address(this),
            amounts,
            false
        );
    }
}