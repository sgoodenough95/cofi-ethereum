// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import { Math } from "@openzeppelin/contracts/utils/math/Math.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { IDSSPSM } from "../interfaces/IDSSPSM.sol";
import { Modifiers } from '../libs/LibAppStorage.sol';

/// @notice This contracts allows for swaps between DAI and USDC
/// by using the Maker DAI-USDC PSM
/// @author Elliot Friedman, Kassim
contract MakerRouterFacet is Modifiers {
    using SafeERC20 for IERC20;

    /// @notice reference to the Maker DAI-USDC PSM that this router interacts with
    /// @dev points to Makers DssPsm contract
    IDSSPSM public constant daiPSM =
        IDSSPSM(0x89B78CfA322F6C5dE0aBcEecab66Aee45393cC5A);

    /// @notice reference to the DAI contract used.
    /// @dev Router can be redeployed if DAI address changes
    IERC20 public constant DAI =
        IERC20(0x6B175474E89094C44Da98b954EedeAC495271d0F);

    /// @notice reference to the USDC contract used.
    IERC20 public constant USDC =
        IERC20(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48);

    /// @notice reference to the contract used to sell USDC for DAI
    address public constant GEM_JOIN =
        0x0A59649758aa4d66E25f08Dd01271e891fe52199;

    /// @notice scaling factor for USDC
    uint256 public constant USDC_SCALING_FACTOR = 1e12;

    /// @notice Function to swap USDC for DAI
    /// @param amountUsdcIn the amount of USDC sold to the DAI PSM
    /// reverts if there are any fees on redemption
    function swapUsdcForDai(
        uint256 amountUsdcIn
    )
        external
        onlyAdmin
    {
        require(daiPSM.tin() == 0, "MakerRouter: maker fee not 0");

        // First ensure USDC resides in this address.
        USDC.safeApprove(GEM_JOIN, amountUsdcIn); /// approve DAI PSM to spend USDC
        daiPSM.sellGem(address(this), amountUsdcIn); /// sell USDC for DAI
        // Delpoy DAI to new Vault.
    }

    /// @notice Function to swap DAI for USDC
    /// @param amountDaiIn the amount of DAI sold to the DAI PSM in exchange for USDC
    /// reverts if there are any fees on minting
    function swapDaiForUsdc(
        uint256 amountDaiIn
    )
        external
        onlyAdmin
    {
        require(daiPSM.tout() == 0, "MakerRouter: maker fee not 0");

        // First ensure USDC resides in this address.
        DAI.safeApprove(address(daiPSM), amountDaiIn); /// approve DAI PSM to spend DAI
        daiPSM.buyGem(
            address(this),
            amountDaiIn / USDC_SCALING_FACTOR
        ); /// sell DAI for USDC
        // Deploy USDC to new Vault.
    }
}