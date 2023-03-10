// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract STOA is ERC20 {

    mapping(address => uint8) toEnabled;

    constructor(
        string memory _name,
        string memory _symbol
    ) ERC20(_name, _symbol) {}

    function mint(address _to, uint _amount) external {
        _mint(_to, _amount);
    }

    function burn(address _from, uint _amount) external {
        _burn(_from, _amount);
    }

    function transfer(address to, uint amount) public override returns (bool) {
        require(toEnabled[to] == 1, 'STOA: Transfer to non-permitted address');
        _transfer(msg.sender, to, amount);
        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public override returns (bool) {
        require(toEnabled[to] == 1, 'STOA: Transfer to non-permitted address');
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    
    function sendToPool() external {}
    
    function returnFromPool() external {}
}