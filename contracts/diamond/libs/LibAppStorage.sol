// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import { LibDiamond } from ".././core/libs/LibDiamond.sol";
import { IStoa } from "./../interfaces/IStoa.sol";

// /// @notice Use 'Safe' in place of Vault to avoid confusion.
// /// @dev    User-specific information (not system-wide).
// /// @dev    This is the life-long Safe for the [account, collateral] combination
// ///         (i.e., cannot create multiple yvDAI Safes under one address).
// struct Safe {
//     address owner;
//     address collateral;     // [shares] e.g., yvDAI.
//     uint256 bal;            // [shares].
//     uint256 debt;           // [assets].
//     uint8   status;
// }

// /// @notice Used for SupplyFacet.
// struct VaultParams {
//     address credit;         // fiToken issued for vault.
//     uint8   mintEnabled;    // fiToken can be minted from vault.
//     uint8   redeemEnabled;  // inputAsset can be redeemed from vault.
// }

// /// @notice Used for SafeFacet.
// struct SafeParams {
//     address credit;
//     // uint8   depositEnabled;  // Handled by SafeStore.
//     // uint8   withdrawEnabled; // Handled by SafeStore.
//     uint8   borrowEnabled;
//     uint8   repayEnabled;
//     uint8   liquidateEnabled;
// }

// enum SafeStatus {
//     nonExistent,    // 0
//     active,         // 1
//     frozen,         // 2
//     // May leave out (3) and (4) if non-custodial.
//     closedByAdmin,  // 3
//     closedByUser    // 4
// }

struct Vault {
    address vault;
    uint32  allocation;
}

struct Stake {
    uint256 creditsIn;
    uint256 pointsClaimed;
}

/// @dev    Stores variables used by two or more Facets.
struct AppStorage {

    // E.g., USDC => [yvUSDC, aUSDC].
    mapping(address => Vault[]) vaults;

    // // E.g., USDST => [USDC, DAI].
    // mapping(address => address[])   activeInputs;

    // // E.g., USDFI => [vUSDC, vDAI].
    // mapping(address => address[])   activeVaults;

    // // E.g., yvUSDC => fiUSD; yvDAI => fiUSD.
    // E.g., USDC => fiUSD.
    mapping(address => address)     fiAsset;

    // E.g., USDC => 50; USDST => 50. Applies to whichever asset is being provided by the user.
    mapping(address => uint256)     minDeposit;

    // E.g., USDST => USDC. Only apply minWithdraw when user is receiving the inputAsset.
    mapping(address => uint256)     minWithdraw;

    // If the fiAsset can be minted (at all, via any enabled vault).
    mapping(address => uint8)       mintEnabled;

    // E.g., USDST => 50bps.
    mapping(address => uint256)     mintFee;

    // If the fiAsset can be minted (at all, via any enabled vault).
    mapping(address => uint8)       redeemEnabled;

    // E.g., USDSTA => 100bps.
    mapping(address => uint256)     redeemFee;

    // mapping(address => uint256)     mgmtFee;

    // E.g., USDSC => 50bps.
    // mapping(address => uint256)     origFee;

    // // E.g., yvDAI => vyvDAI;
    // mapping(address => address)     safeStore;

    /// @dev    May use Gnosis Safe.
    address feeCollector;

    // Account => Collateral => Safe. E.g., 0x1234... => yvDAI => Safe.
    // mapping(address => mapping(address => Safe)) safe;

    // E.g., yvUSDC = 50,000; aUSDC = 25,000.
    // mapping(address => uint256) LTV;

    // // E.g., USDST => 0 (if no update performed to LTV). Used for gas savings.
    // mapping(address => uint32)  LTVUpdateIndex;

    // E.g., saUSDST => feesCollected.
    // mapping(address => uint256) origFeesCollected;

    // Enables transfers to non-active accounts that can later be claimed.
    // mapping(address => mapping(address => uint256)) pendingBal;
    // mapping(address => mapping(address => uint256)) pendingCredit;

    // E.g., USDST => backing amount. The amount held as backing.
    // Only consider USDSC as the token being backed for now (to avoid double-mapping).
    mapping(address => uint256)     backingReserve;

    /// @notice E.g., Account => Vault (vUSDC) => 1,000.
    mapping(address => mapping(address => uint256)) redeemAllowance;

    // E.g., yvUSDC => VaultParams.
    // mapping(address => VaultParams) vaultParams;

    // E.g., yvUSDC => SafeParams.
    // mapping(address => SafeParams)  safeParams;

    mapping(address => uint8)       isAdmin;

    mapping(address => uint8)       isWhitelisted; // Leave for now, but include later.

    // STOA points reward per 1*10**18 earned of activeAsset.
    // Initial target 100 STOA per $1 of yield earned. Therefore pointsRate = 1,000,000 = 10,000% = 100x.
    mapping(address => uint256) pointsRate;

    mapping(address => uint256) pointsClaimed;

    uint256 pointsEpoch;

    mapping(address => mapping(address => Stake)) stake;

    // Do not leave as constant for now.
    address STOA;
}

struct AppStorageB {

    uint256 number;
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

    uint8 private _reentrancyGuard;

    // Prevents reentrancy attacks via tokens with callback mechanisms. 
    modifier nonReentrant() {
        require(_reentrancyGuard == 0, 'No reentrancy');
        _reentrancyGuard = 1;
        _;
        _reentrancyGuard = 0;
    }

    modifier minDeposit(uint256 amount, address asset) {
        require(amount >= s.minDeposit[asset], "Invalid deposit");
        _;
    }

    modifier minWithdraw(uint256 amount, address asset) {
        require(amount >= s.minWithdraw[asset], "Invalid withdrawal");
        _;
    }

    // modifier isSafeOwner(uint32 index) {
    //     require(s.safe[msg.sender][index].owner == msg.sender, 'Not Safe owner');
    //     _;
    // }

    modifier activeSafe(address owner, address asset) {
        require(s.safe[owner][asset].status == 1, 'Safe not active');
        _;
    }

    modifier onlyAdmin() {
        require(s.isAdmin[msg.sender] == 1, "Not Admin");
        _;
    }
}