// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '@openzeppelin/contracts/token/ERC20/ERC20.sol';

interface ICOFIMoney {

    function getPoints(address account, address[] memory fiAssets) external view returns (uint256 pointsTotal);
}

/**

    █▀▀ █▀█ █▀▀ █
    █▄▄ █▄█ █▀░ █

    @author cofi.money
    @title  Point Token Facet
    @notice Provides ERC20 representation for Points whilst removing/adjusting functionality such as transfer op.
 */

contract PointToken is ERC20 {

    constructor(
        string memory       _name,
        string memory       _symbol,
        address             _diamond,
        address[] memory    _fiAssets
    ) ERC20(_name, _symbol) { 
        diamond = _diamond;
        fiAssets = _fiAssets;
        admin[msg.sender] = true;
    }

    address     diamond;
    address[]   fiAssets;

    mapping(address => bool)    admin;

    event TransferDisabled(address _from, address _to, uint256 _value);

    function mint(address _to, uint _amount) external isAdmin {
        _mint(_to, _amount);
    }

    function burn(address _from, uint _amount) external {
        _burn(_from, _amount);
    }

    function balanceOf(address _account)
        public
        view
        override
        returns (uint256)
    {
        return ICOFIMoney(diamond).getPoints(_account, fiAssets);
    }

    function transfer(address _to, uint256 _value)
        public
        override
        returns (bool)
    {
        emit TransferDisabled(msg.sender, _to, _value);
        return false;
    }

    function transferFrom(address _from, address _to, uint256 _value)
        public
        override
        returns (bool)
    {
        emit TransferDisabled(_from, _to, _value);
        return false;
    }

    function setFiAssets(address[] memory _fiAssets) external isAdmin {
        fiAssets = _fiAssets;
    }

    function setDiamond(address _diamond) external isAdmin {
        diamond = _diamond;
    }

    function toggleAdmin(address _account) external isAdmin {
        admin[_account] = !admin[_account];
    }

    modifier isAdmin() {
        require(admin[msg.sender] == true, 'PointToken: Caller not admin');
        _;
    }
}