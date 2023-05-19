// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

/// @title  Fi Token Interface
/// @author cofi.money
/// @notice Interface for executing functions on Fi tokens.
interface IFiToken {

    function mint(address to, uint amount) external;

    function burn(address from, uint amount) external;

    function redeem(address from, address to, uint256 amount) external;

    function changeSupply(uint newTotalSupply) external returns (uint256 earnings);

    function getYieldEarned(address account) external view returns (uint256);

    function creditsToBal(uint256 amount) external view returns (uint256);

    function rebaseOptIn() external;

    function rebaseOptOut() external;
}