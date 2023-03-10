// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

/// @title  Stoa Token Interface
/// @author The Stoa Corporation Ltd.
/// @notice Interface for executing functions on Stoa tokens.
interface IStoaToken {

    function mint(address to, uint amount) external;

    function burn(address from, uint amount) external;

    function changeSupply(uint newTotalSupply) external;

    function getYieldEarned(address account) external view returns (uint256);

    function creditsToBal(uint256 amount) external view returns (uint256);

    function rebaseOptIn() external;

    function rebaseOptOut() external;
}