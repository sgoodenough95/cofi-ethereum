// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import { LibDiamond } from ".././core/libs/LibDiamond.sol";
// import { ICoFi } from "./../interfaces/ICoFi.sol";

struct PointsCapture {
    uint256 yield;
    uint256 points;
    uint256 spent;
}

struct AppStorage {

    // E.g., COFI => yvDAI; COFIE => aETH.
    mapping(address => address) vault;

    // E.g., DAI => 50*10**18. Applies to inputAsset only.
    mapping(address => uint256) minDeposit;

    // E.g., DAI => 50*10**18. Applies to inputAsset only.
    mapping(address => uint256) minWithdraw;

    // E.g., COFI => 1.
    mapping(address => uint8)   mintEnabled;

    // E.g., COFI => 10bps. Applies to fiAsset only.
    mapping(address => uint256) mintFee;

    // E.g., COFI => 1.
    mapping(address => uint8)   redeemEnabled;

    // E.g., COFI => 10bps. Applies to fiAsset only.
    mapping(address => uint256) redeemFee;

    // E.g., COFI => 1,000bps. Applies to fiAsset only.
    mapping(address => uint256) serviceFee;

    // Gnosis Safe contract.
    address feeCollector;

    // E.g., yvDAI => backing amount [DAI].
    mapping(address => uint256) backing;

    // E.g., COFI => 1,000,000bps (100x / 1*10**18 yield earned).
    mapping(address => uint256) pointsRate;

    mapping(address => mapping(address => PointsCapture)) pointsCapture;

    mapping(address => uint8)   isAdmin;

    mapping(address => uint8)   isWhitelisted; // Leave for now, but include later.
}

library LibAppStorage {
    function diamondStorage() internal pure returns (AppStorage storage ds) {
        // bytes32 position = LibDiamond.DIAMOND_STORAGE_POSITION;
        assembly {
            ds.slot := 0
        }
    }

    function abs(int256 x) internal pure returns (uint256) {
        return uint256(x >= 0 ? x : -x);
    }
}

contract Modifiers {
    AppStorage internal s;

    modifier isWhitelisted() {
        require(s.isWhitelisted[msg.sender] == 1, 'Caller not whitelisted');
        _;
    }

    modifier minDeposit(uint256 amount, address asset) {
        require(amount >= s.minDeposit[asset], 'Insufficient deposit amount');
        _;
    }

    modifier minWithdraw(uint256 amount, address asset) {
        require(amount >= s.minWithdraw[asset], 'Insufficient withdraw amount');
        _;
    }
    
    modifier onlyAdmin() {
        require(s.isAdmin[msg.sender] == 1, 'Caller not Admin');
        _;
    }
}