// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import { LibDiamond } from ".././core/libs/LibDiamond.sol";
import { IStoa } from "./../interfaces/IStoa.sol";
// import { LibToken } from "./LibToken.sol";
// import { LibAdmin } from "./LibAdmin.sol";

/// @dev    A Safe supports one activeToken and one unactiveToken.
struct Safe {
    address owner;
    uint256 index;              // Identifier for the Safe.
    address collateralAsset;    // Ethereum can be address(1) (?)
    // Might not necessarily know this when opening a Safe.
    address debtAsset;          // E.g., USDST.
    uint256 bal;                // Either tokens or shares, depending on the asset.
    uint256 debt;               // [tokens].
    uint8   status;
}

struct VaultParams {
    address input;
    address active;
    // If address(0), means loans are not enabled.
    address unactive;
    uint8   enabled;
}

enum SafeStatus {
    nonExistent,            // 0
    active,                 // 1
    activeDebt,             // 2
    closedByOwner,          // 3
    closedByLiquidation,    // 4
    closedByAdmin           // 5
}


/// @dev    Stores variables used by two or more Facets.
struct AppStorage {

    // E.g., USDSTA => [USDC, DAI].
    mapping(address => address[])   activeInputs;

    // E.g., USDC => USDST; DAI => USDST. Only ONE available unactiveAsset for a given inputAsset.
    mapping(address => address)     inputToUnactive;

    // E.g., USDC => 50; USDSTA => 50.
    mapping(address => uint256)     minDeposit;

    // E.g., USDSTA => USDC. Only apply minWithdraw when receiving the inputAsset.
    mapping(address => uint256)     minWithdraw;

    // E.g., USDSTA => 1; USDST => 1; USDFI => 1.
    mapping(address => uint8)       mintEnabled;

    // E.g., USDSTA => 50bps.
    mapping(address => uint256)     mintFee;

    // E.g., USDSTA => 1; USDST => 1; USDFI => 1.
    mapping(address => uint256)     redeemEnabled;

    // E.g., USDSTA => 100bps.
    mapping(address => uint256)     redeemFee;

    // E.g., USDSTA <=> USDST. Returns address(0) if conversions are disabled. Only 1 convert asset.
    mapping(address => address)     convertEnabled;

    mapping(address => uint256)     mgmtFee;

    // Used when manual movement of inputAssets is required.
    mapping(address => address)     inputStore;

    // Fees accrue to this address. Not necessarily Admin.
    address feeCollector;

    // E.g., USDST => USDSTA. For unactiveAssets only. Only consider 1 backing asset.
    mapping(address => address)     backingAsset;

    // E.g., USDSTA => backing amount. The amount held as backing.
    mapping(address => int256)      backingReserve;

    // E.g., account => USDST => allowance.
    mapping(address => mapping(address => int256)) unactiveRedemptionAllowance;

    mapping(address => VaultParams) vaultParams;

    mapping(address => uint8) isAdmin;
}

library LibAppStorage {
    function diamondStorage() internal pure returns (AppStorage storage ds) {
        bytes32 position = LibDiamond.DIAMOND_STORAGE_POSITION;
        assembly {
            ds.slot := position
        }
    }

    function abs(int256 x) internal pure returns (uint256) {
        return uint256(x >= 0 ? x : -x);
    }
}

contract Modifiers is IStoa {
    AppStorage internal s;

    /// @notice Safe Modifiers
    ///
    // modifier activeSafe(uint256 index) {
    //     if (s.safe[msg.sender][index].owner != msg.sender) {
    //         revert IStoaErrors.SafeOwnerMismatch(s.safe[msg.sender][index].owner, msg.sender);
    //     }
    //     if (s.safe[msg.sender][index].status != 1 || s.safe[msg.sender][index].status != 2) {
    //         revert IStoaErrors.SafeNotActive(s.safe[msg.sender][index].owner, index);
    //     } else {
    //         _;
    //     }
    // }

    modifier minDeposit(uint256 amount, address asset) {
        require(amount < s.minDeposit[asset], "Invalid deposit");
        _;
    }

    modifier minWithdraw(uint256 amount, address asset) {
        require(amount < s.minDeposit[asset], "Invalid withdrawal");
        _;
    }

    modifier onlyAdmin() {
        require(s.isAdmin[msg.sender] != 1, "Not Admin");
        _;
    }
}