// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**

    █▀▀ █▀█ █▀▀ █
    █▄▄ █▄█ █▀░ █

    @author cofi.money
    @title  Vault
    @notice Test Vault contract
 */

import { ERC4626 } from "@openzeppelin/contracts/token/ERC20/extensions/ERC4626.sol";
import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract Vault is ERC4626 {
    using SafeERC20 for IERC20;

    constructor(
        ERC20 underlying_,
        string memory name_,
        string memory symbol_
    ) ERC20(name_, symbol_) ERC4626(underlying_) {}

    /**
     * @dev Added additional argument: depositor.
     */
    function deposit_(uint256 assets, address receiver, address depositor)
        public
        returns (uint256 shares)
    {
        shares = previewDeposit(assets);

        _deposit(depositor, receiver, assets, shares);

        emit Deposit(depositor, receiver, assets, shares);
    }
}