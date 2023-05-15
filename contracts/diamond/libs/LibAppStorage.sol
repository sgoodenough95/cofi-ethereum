// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import { LibDiamond } from ".././core/libs/LibDiamond.sol";
// import { ICoFi } from "./../interfaces/ICoFi.sol";

// struct FiAssetParams {
//     uint256 minDeposit;     // E.g., COFI => 20*10**18. Applies to underlyingAsset (e.g., DAI).
//     uint256 minWithdraw;    // E.g., COFI => 20*10**18. Applies to underlyingAsset (e.g., DAI).
//     uint256 mintFee;        // E.g., COFI => 10bps (=0.1%). Applies to fiAsset only.
//     uint256 redeemFee;      // E.g., COFI => 10bps (=0.1%). Applies to fiAsset only.
//     uint256 serviceFee;     // E.g., COFI => 1,000bps (=10%). Applies to fiAsset only.
//     uint256 pointsRate;     // E.g., COFI => 1,000,000bps (100x / 1*10**18 yield earned).
//     address vault;          // E.g., COFI => yvDAI; fiETH => maETH; fiBTC => maBTC.
//     uint8   mintEnabled;    // E.g., COFI => 1.
//     uint8   redeemEnabled;  // E.g., COFI => 1.
// }

struct YieldPointsCapture {
    uint256 yield;
    uint256 points;
}

struct AppStorage {

    // E.g., COFI => 20*10**18. Applies to underlyingAsset (e.g., DAI).
    mapping(address => uint256) minDeposit;

    // E.g., COFI => 20*10**18. Applies to underlyingAsset (e.g., DAI).
    mapping(address => uint256) minWithdraw;

    // E.g., COFI => 10bps. Applies to fiAsset only.
    mapping(address => uint256) mintFee;

    // E.g., COFI => 10bps. Applies to fiAsset only.
    mapping(address => uint256) redeemFee;

    // E.g., COFI => 1,000bps. Applies to fiAsset only.
    mapping(address => uint256) serviceFee;

    // E.g., COFI => 1,000,000bps (100x / 1*10**18 yield earned).
    mapping(address => uint256) pointsRate;

    // E.g., COFI => yvDAI; fiETH => maETH; fiBTC => maBTC.
    mapping(address => address) vault;

    // E.g., COFI => 1.
    mapping(address => uint8)   mintEnabled;

    // E.g., COFI => 1.
    mapping(address => uint8)   redeemEnabled;

    // Yield points capture (determined via yield earnings from fiAsset).
    // E.g., 0x1234... => COFI => YieldPointsCapture.
    mapping(address => mapping(address => YieldPointsCapture)) YPC;

    // External points capture (to yield earnings). Maps to account only (not fiAsset).
    mapping(address => uint256) XPC;

    mapping(address => uint8)   isWhitelisted;

    mapping(address => uint8)   isAdmin;

    mapping(address => uint8)   isUpkeep;

    // Gnosis Safe contract.
    address feeCollector;
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

    modifier minDeposit(uint256 amount, address fiAsset) {
        require(amount >= s.minDeposit[fiAsset], 'Insufficient deposit amount');
        _;
    }

    modifier minWithdraw(uint256 amount, address fiAsset) {
        require(amount >= s.minWithdraw[fiAsset], 'Insufficient withdraw amount');
        _;
    }

    modifier mintEnabled(address fiAsset) {
        require(s.mintEnabled[fiAsset] == 1, 'Mint not enabled');
        _;
    }

    modifier redeemEnabled(address fiAsset) {
        require(s.redeemEnabled[fiAsset] == 1, 'Redeem not enabled');
        _;
    }
    
    modifier onlyAdmin() {
        require(s.isAdmin[msg.sender] == 1, 'Caller not Admin');
        _;
    }
}