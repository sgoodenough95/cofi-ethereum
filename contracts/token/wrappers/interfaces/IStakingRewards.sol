// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

interface IStakingRewards {

    function withdraw(uint256 amount) external;
    function getReward() external;
    function exit() external;
}