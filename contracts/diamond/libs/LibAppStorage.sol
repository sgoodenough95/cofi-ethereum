// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import { LibDiamond } from ".././core/libs/LibDiamond.sol";
import { IStoa } from "./../interfaces/IStoa.sol";

/// @dev    A Safe supports one activeAsset [vault] and one creditAsset.
struct Safe {
    // address owner;
    // uint256 index;              // Identifier for the Safe.
    // safeStore token (4626).
    address store;    // Ethereum can be address(1) (?)
    address creditAsset;          // E.g., USDSC.
    uint256 bal;                // Either tokens or shares, depending on the asset.
    uint256 credit;               // [tokens].
    uint8   status;
    // uint8   authorised;
}

struct VaultParams {
    address input;
    address active;
    // If address(0), means loans are not enabled.
    address credit;
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

    // E.g., USDST => [USDC, DAI].
    mapping(address => address[])   activeInputs;

    // E.g., USDC => USDSC; DAI => USDSC; USDST => USDSC; USDFI => USDSC; saUSDST => USDSC.
    mapping(address => address)     creditAsset;

    // E.g., USDC => 50; USDST => 50. Applies to whichever asset is being provided by the user.
    mapping(address => uint256)     minDeposit;

    // E.g., USDST => USDC. Only apply minWithdraw when user is receiving the inputAsset.
    mapping(address => uint256)     minWithdraw;

    // E.g., USDST => 1; USDSC => 1; USDFI => 1.
    mapping(address => uint8)       mintEnabled;

    // E.g., USDST => 50bps. NOTE: PercentageMath might not work when using different types.
    mapping(address => uint256)     mintFee;

    // E.g., USDST => 1; USDSC => 1; USDFI => 1.
    mapping(address => uint8)     redeemEnabled;

    // E.g., USDSTA => 100bps.
    mapping(address => uint256)     redeemFee;

    // Retrieves creditAsset address if converting activeAsset is enabled.
    // Only ONE creditAsset available per currency denomination (e.g., USD => USDST).
    mapping(address => address)     activeConvertEnabled;

    // E.g., USDSC => USDST => 1; USDSC => USDFI => 0.
    // creditAssets can originate from 2+ activeAssets, hence the need for a double-mapping.
    mapping(address => mapping(address => uint8)) creditConvertEnabled;

    mapping(address => uint256)     mgmtFee;

    // E.g., USDSC => 50bps.
    mapping(address => uint256) origFee;

    // Used when manual movement of inputAssets is required.
    // (At least to start with) consider the diamond as the inputStore.
    // mapping(address => address)     inputStore;

    // Fees accrue to this address. Not necessarily Admin.
    // Only collects fees in activeAssets for now, which are backed by inputAssets held in diamond.
    // address feeCollector;

    // E.g., USDSC => USDST. The go-to Exchange backing asset of a creditAsset.
    mapping(address => address)     primeBacking;

    // E.g., USDSC => USDFI. The go-to Vault backing asset of a creditAsset.
    mapping(address => address)     primeVaultBacking;

    // E.g., USDST => saUSDST.
    mapping(address => address) primeStore;

    // mapping(address => address) primeActive;

    // account => safeIndex => Safe. uint32 allows for circa 4.3m Safes created per address.
    mapping(address => mapping(uint32 => Safe)) safe;

    mapping(address => uint32) safeIndex;

    // E.g., USDST => 2_500.
    mapping(address => uint256) LTV;

    // Enables transfers to non-active accounts that can later be claimed.
    // mapping(address => mapping(address => uint256)) pendingClaim;

    // E.g., USDST => backing amount. The amount held as backing.
    // Only consider USDSC as the token being backed for now (to avoid double-mapping).
    mapping(address => uint256)     backingReserve;

    // E.g., account => USDST => allowance.
    mapping(address => mapping(address => uint256)) creditRedeemAllowance;

    mapping(address => VaultParams) vaultParams;

    mapping(address => uint8) isAdmin;
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

    modifier onlyAdmin() {
        require(s.isAdmin[msg.sender] == 1, "Not Admin");
        _;
    }
}