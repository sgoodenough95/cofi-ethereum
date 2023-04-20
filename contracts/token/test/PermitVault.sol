// SPDX-License-Identifier: MIT
pragma solidity ^0.8;

import "@openzeppelin/contracts/token/ERC20/extensions/draft-IERC20Permit.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/draft-ERC20Permit.sol";

contract PermitVault {
    IERC20Permit public immutable token;
    IERC20 public immutable token_;

    constructor(address _token) {
        token = IERC20Permit(_token);
        token_ = IERC20(_token);
    }

    function deposit(uint amount) external {
        token_.transferFrom(msg.sender, address(this), amount);
    }

    /*
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    )
    */
    function depositWithPermit(uint amount, uint deadline, uint8 v, bytes32 r, bytes32 s) external {
        token.permit(msg.sender, address(this), amount, deadline, v, r, s);
        token_.transferFrom(msg.sender, address(this), amount);
    }
}