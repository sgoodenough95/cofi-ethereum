// // SPDX-License-Identifier: Apache-2.0
// pragma solidity 0.8.19;

// import {ERC20} from "solmate/tokens/ERC20.sol";
// import {ERC4626} from "solmate/mixins/ERC4626.sol";
// import {SafeTransferLib} from "solmate/utils/SafeTransferLib.sol";
// import {FixedPointMathLib} from "solmate/utils/FixedPointMathLib.sol";

// import {CometMainInterface} from "./external/IComet.sol";
// import {LibCompound} from "./external/LibCompound.sol";
// import {ICometRewards} from "./external/ICometRewards.sol";
// import {ISwapRouter} from "../aave-v2/utils/ISwapRouter.sol";
// import {DexSwap} from "../_global/swapUtils.sol";

// /// @title CompoundV3ERC4626Wrapper
// /// @notice Custom implementation with flexible reinvesting logic
// /// @notice Rationale: Forked protocols often implement custom functions and modules on top of forked code.
// /// @author ZeroPoint Labs
// contract CompoundV3ERC4626Wrapper is ERC4626 {
//     /*//////////////////////////////////////////////////////////////
//                         LIBRARIES USAGE
//     //////////////////////////////////////////////////////////////*/

//     using LibCompound for CometMainInterface;
//     using SafeTransferLib for ERC20;
//     using FixedPointMathLib for uint256;

//     /*//////////////////////////////////////////////////////////////
//                             ERRORS
//     //////////////////////////////////////////////////////////////*/

//     /// @notice Thrown when reinvest amount is not enough.
//     error MIN_AMOUNT_ERROR();
//     /// @notice Thrown when caller is not the manager.
//     error INVALID_ACCESS_ERROR();
//     /// @notice Thrown when swap path fee in reinvest is invalid.
//     error INVALID_FEE_ERROR();

//     /*//////////////////////////////////////////////////////////////
//                             CONSTANTS
//     //////////////////////////////////////////////////////////////*/

//     uint256 internal constant NO_ERROR = 0;
//     /// @notice Pointer to swapInfo
//     bytes public swapPath;

//     ERC20 public immutable reward;

//     /*//////////////////////////////////////////////////////////////
//                       IMMUTABLES & VARIABLES
//     //////////////////////////////////////////////////////////////*/

//     /// @notice Access Control for harvest() route
//     address public immutable manager;

//     /// @notice The Compound cToken contract
//     CometMainInterface public immutable cToken;

//     /// @notice The Compound rewards manager contract
//     ICometRewards public immutable rewardsManager;

//     ISwapRouter public immutable swapRouter =
//         ISwapRouter(0xE592427A0AEce92De3Edee1F18E0157C05861564);

//     /*//////////////////////////////////////////////////////////////
//                             CONSTRUCTOR
//     //////////////////////////////////////////////////////////////*/

//     /// @notice constructor for the CompoundV3StrategyWrapper
//     /// @param asset_ The address of the underlying asset
//     /// @param cToken_ The address of the Compound comet contract
//     /// @param rewardsManager_ The address of the Compound rewards manager
//     /// @param manager_ The address of the manager
//     constructor(
//         ERC20 asset_, // underlying
//         CometMainInterface cToken_, // compound concept of a share
//         ICometRewards rewardsManager_,
//         address manager_
//     ) ERC4626(asset_, _vaultName(asset_), _vaultSymbol(asset_)) {
//         cToken = cToken_;
//         rewardsManager = rewardsManager_;
//         manager = manager_;
//         (address reward_, , ) = rewardsManager.rewardConfig(address(cToken));
//         reward = ERC20(reward_);
//     }

//     /*//////////////////////////////////////////////////////////////
//                       COMPOUND LIQUIDITY MINING
//     //////////////////////////////////////////////////////////////*/
//     /// @notice sets the swap path for reinvesting rewards
//     /// @param poolFee1_ fee for first swap
//     /// @param tokenMid_ token for first swap
//     /// @param poolFee2_ fee for second swap
//     function setRoute(
//         uint24 poolFee1_,
//         address tokenMid_,
//         uint24 poolFee2_
//     ) external {
//         if (msg.sender != manager) revert INVALID_ACCESS_ERROR();
//         if (poolFee1_ == 0) revert INVALID_FEE_ERROR();
//         if (poolFee2_ == 0 || tokenMid_ == address(0))
//             swapPath = abi.encodePacked(reward, poolFee1_, address(asset));
//         else
//             swapPath = abi.encodePacked(
//                 reward,
//                 poolFee1_,
//                 tokenMid_,
//                 poolFee2_,
//                 address(asset)
//             );
//         ERC20(reward).approve(address(swapRouter), type(uint256).max); /// max approve
//     }

//     /*//////////////////////////////////////////////////////////////
//                         ERC4626 OVERRIDES
//     //////////////////////////////////////////////////////////////*/

//     function totalAssets() public view virtual override returns (uint256) {
//         return cToken.balanceOf(address(this));
//     }

//     function beforeWithdraw(
//         uint256 assets_,
//         uint256 /*shares*/
//     ) internal virtual override {
//         cToken.withdraw(address(asset), assets_);
//     }

//     function afterDeposit(
//         uint256 assets_,
//         uint256 /*shares*/
//     ) internal virtual override {
//         // approve to cToken
//         asset.safeApprove(address(cToken), assets_);

//         // deposit into cToken
//         cToken.supply(address(asset), assets_);
//     }

//     function harvest(uint256 minAmountOut_) external {
//         rewardsManager.claim(address(cToken), address(this), true);

//         uint256 earned = ERC20(reward).balanceOf(address(this));
//         uint256 reinvestAmount;
//         /// @dev Swap rewards to asset
//         ISwapRouter.ExactInputParams memory params = ISwapRouter
//             .ExactInputParams({
//                 path: swapPath,
//                 recipient: msg.sender,
//                 deadline: block.timestamp,
//                 amountIn: earned,
//                 amountOutMinimum: minAmountOut_
//             });

//         // Executes the swap.
//         reinvestAmount = swapRouter.exactInput(params);
//         if (reinvestAmount < minAmountOut_) {
//             revert MIN_AMOUNT_ERROR();
//         }
//         afterDeposit(asset.balanceOf(address(this)), 0);
//     }

//     function maxDeposit(address) public view override returns (uint256) {
//         if (cToken.isSupplyPaused()) return 0;
//         return type(uint256).max;
//     }

//     function maxMint(address) public view override returns (uint256) {
//         if (cToken.isSupplyPaused()) return 0;
//         return type(uint256).max;
//     }

//     function maxWithdraw(address owner_)
//         public
//         view
//         override
//         returns (uint256)
//     {
//         // uint256 cash = cToken.getCash();
//         if (cToken.isWithdrawPaused()) return 0;
//         uint256 assetsBalance = convertToAssets(balanceOf[owner_]);
//         return assetsBalance;
//     }

//     function maxRedeem(address owner_) public view override returns (uint256) {
//         // uint256 cash = cToken.getCash();
//         // uint256 cashInShares = convertToShares(cash);
//         if (cToken.isWithdrawPaused()) return 0;
//         uint256 shareBalance = balanceOf[owner_];
//         return shareBalance;
//     }

//     /*//////////////////////////////////////////////////////////////
//                       ERC20 METADATA
//     //////////////////////////////////////////////////////////////*/

//     function _vaultName(ERC20 asset_)
//         internal
//         view
//         virtual
//         returns (string memory vaultName)
//     {
//         vaultName = string.concat("CompStratERC4626- ", asset_.symbol());
//     }

//     function _vaultSymbol(ERC20 asset_)
//         internal
//         view
//         virtual
//         returns (string memory vaultSymbol)
//     {
//         vaultSymbol = string.concat("cS-", asset_.symbol());
//     }
// }