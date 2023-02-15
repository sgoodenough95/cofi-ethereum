// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

/// @title  Stoa Token Interface
/// @author The Stoa Corporation Ltd.
/// @notice Interface for executing functions on Stoa tokens.
interface IStoaToken {

    function mint(address to, uint amount) external;

    function burn(address from, uint amount) external;

    function changeSupply(uint newTotalSupply) external;

    function rebaseOptIn() external;

    function rebaseOptOut() external;
}