// // SPDX-License-Identifier: MIT
// pragma solidity 0.8.19;

// /**
//     █▀▀ ▀▀█▀▀ █▀▀█ █▀▀█ 
//     ▀▀█ ░░█░░ █░░█ █▄▄█ 
//     ▀▀▀ ░░▀░░ ▀▀▀▀ ▀░░▀

//     @author stoa.money
//     @title  Staking Facet
//     @notice Issues STOA points to stakers.
//  */

// import { VaultParams, Modifiers } from "../libs/LibAppStorage.sol";
// import { PercentageMath } from "../libs/external/PercentageMath.sol";
// import { LibToken } from "../libs/LibToken.sol";
// import { LibVault } from "../libs/LibVault.sol";
// import { IStoaToken } from "../interfaces/IStoaToken.sol";
// import { IERC20 } from '@openzeppelin/contracts/interfaces/IERC20.sol';

// contract StakingFacet is Modifiers {
//     using PercentageMath for uint256;

//     /// @dev    For now, test insofar as an external contract holding the assets.
//     ///
//     /// @notice Staking options are USDFI, USDSC, and USDC.
//     /// @notice Applies points multiplier on amount deposited.
//     function stake(address asset, uint256 amount) external {

//         // Require sender is rebasing account.

//         LibToken._transferFrom(asset, amount, msg.sender, address(this));

//         s.stake[msg.sender][asset].creditsIn += amount;

//         // USDFI-USDC LP / USDSC-USDC LP

//         /**
//             STOA REWARD CALC:

//             1.  What is the total supply of USDFI versus the USD supplied.
//             2.  Ratio is 80 : 20. USDFI has yielded 10%.
//             3.  STOA earned = equiv. yield earned(stake) * multiplier.

//             1. 80,000 USDFI outside / 20,000 USD[--] inside.
//             2. 80,000 => 88,000 / 20,000 => 22,000 * Multiplier.
//             3. 2,000 Points * 10x = 20,000
//          */
//     }

//     function getStakeEquivYieldEarned(address account, address asset) public view returns (uint256) {

//         return IStoaToken(asset).creditsToBal(s.stake[account][asset].creditsIn)
//             - s.stake[account][asset].creditsIn;
//     }

//     function getTotalPointsEarned(address account, address asset) public view returns (uint256) {

//         // Needs to reflect if points rate has previously changed.
//         return getStakeEquivYieldEarned(account, asset).percentMul(s.pointsRate[asset]);
//     }

//     function createStake(
//         uint256 rewardRate,
//         uint256 start,
//         uint256 end
//     )   external
//         onlyAdmin()
//     {
        
//     }
// }