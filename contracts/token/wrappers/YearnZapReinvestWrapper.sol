// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/**

    █▀▀ █▀█ █▀▀ █
    █▄▄ █▄█ █▀░ █

    @author The Stoa Corporation Ltd. (Adapted from RobAnon, 0xTraub, 0xTinder).
    @title  Yearn Zap Reinvest Wrapper
    @notice Provides 4626-compatibility and functions for reinvesting
            staking rewards.
 */

import "./interfaces/IVaultWrapper.sol";
import "./interfaces/IStakingRewardsZap.sol";
import "./interfaces/IStakingRewards.sol";
import { VaultAPI, IYearnRegistry } from "./interfaces/VaultAPI.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC4626.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable2Step.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import { FixedPointMathLib } from "./lib/FixedPointMathLib.sol";
import { PercentageMath } from "./lib/PercentageMath.sol";
import { StableMath } from "./lib/StableMath.sol";
import "@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

contract YearnZapReinvestWrapper is ERC4626, IVaultWrapper, Ownable2Step, ReentrancyGuard {

    using FixedPointMathLib for uint;
    using PercentageMath for uint;
    using StableMath for uint;
    using StableMath for int;
    using SafeERC20 for IERC20;

    IYearnRegistry public registry = IYearnRegistry(0x79286Dd38C9017E5423073bAc11F53357Fc5C128);

    VaultAPI public yVault;

    VaultAPI public yVaultReward; // yvOP

    IStakingRewards public stakingRewards = IStakingRewards(0xB2c04C55979B6CA7EB10e666933DE5ED84E6876b);

    IStakingRewardsZap public stakingRewardsZap = IStakingRewardsZap(0x498d9dCBB1708e135bdc76Ef007f08CBa4477BE2);

    AggregatorV3Interface public priceFeed = AggregatorV3Interface(0x0D276FC14719f9292D5C1eA2198673d1f4269246);

    ISwapRouter public swapRouter = ISwapRouter(0xE592427A0AEce92De3Edee1F18E0157C05861564);

    uint256 private constant MIN_DEPOSIT = 1e3;

    /* Swap params */
    struct SwapParams {
        uint256 minHarvest;
        uint256 slippage;
        uint256 wait;
        uint24 poolFee;
        uint8 enabled;
    }

    SwapParams private swapParams;

    event Harvest(uint256 rewardShares, uint256 rewardAssets, uint256 deposited, uint256 yearnShares);
    event HarvestAttempted(uint256 rewardShares, uint256 rewardAssets, uint256 minHarvest);
    event HarvestIsDisabled();

    constructor(
        VaultAPI _vault,
        VaultAPI _rewardVault,
        address _underlying,
        uint256 _minHarvest,
        uint256 _slippage,
        uint256 _wait,
        uint24 _poolFee,
        uint8 _enabled
    )
        ERC20(
            string(abi.encodePacked("Wrapped ", _vault.name(), "-Reinvest4626")),
            string(abi.encodePacked("w", _vault.symbol(), "-R4626"))
        )
        ERC4626(
            IERC20(_underlying) // OZ contract retrieves decimals from asset
        )
    {
        yVault = _vault;
        yVaultReward = _rewardVault;
        swapParams.minHarvest = _minHarvest;
        swapParams.slippage = _slippage;
        swapParams.wait = _wait;
        swapParams.poolFee = _poolFee;
        swapParams.enabled = _enabled;
    }

    function vault() external view returns (address) {
        return address(yVault);
    }

    /// @dev Verifies that the yearn registry has "_target" recorded as the asset's latest vault
    /// @dev Target must utilise same rewards
    function migrate(address _target) external onlyOwner returns (address) {
        // verify _target is a valid address
        if(registry.latestVault(asset()) != _target) {
            revert InvalidMigrationTarget();
        }

        // Retrieves shares and rewards from yVault
        stakingRewards.exit();

        harvest();

        uint assets = yVault.withdraw(type(uint).max);
        yVault = VaultAPI(_target);

        // Redeposit want into target vault
        yVault.deposit(assets);

        return _target;
    }

    // NB: this number will be different from this token's totalSupply
    function vaultTotalSupply() external view returns (uint256) {
        return yVault.totalSupply();
    }

    /*//////////////////////////////////////////////////////////////
                    STAKING REWARDS REINVEST LOGIC
    //////////////////////////////////////////////////////////////*/

    function harvest() public returns (uint256 deposited, uint256 yearnShares) {

        if (swapParams.enabled != 1) {
            emit HarvestIsDisabled();
            return (0, 0);
        }
    
        stakingRewards.getReward();

        uint256 rewardShares = IERC20(yVaultReward).balanceOf(address(this));

        // Check if has a balance of yvReward of Reward token first
        if (
            // If this contract current yvReward balance is less than minHarvest and;
            rewardShares < swapParams.minHarvest &&
            // If this contract current Reward balance is less than minHarvest [assets]
            IERC20(yVaultReward.token()).balanceOf(address(this)) <
                convertYearnRewardSharesToAssets(swapParams.minHarvest)
        ) {
            if (previewRedeemReward(stakingRewards.earned(address(this))) < swapParams.minHarvest) {
                emit HarvestAttempted(
                    stakingRewards.earned(address(this)),
                    previewRedeemReward(rewardShares),
                    swapParams.minHarvest
                );
                return (0, 0);
            }
        }

        // Redeem OP from yvOP vault.
        _doRewardWithdrawal(rewardShares, yVaultReward);

        uint256 rewardAssets = IERC20(yVaultReward.token()).balanceOf(address(this));

        // Swap for want
        uint256 amountOut = swapExactInputSingle(rewardAssets);

        // Deposit to yVault.
        (deposited, yearnShares) = _doRewardDeposit(amountOut);
        emit Harvest(rewardShares, rewardAssets, deposited, yearnShares);
    }

    function getLatestPrice() public view returns (int answer) {

        (, answer, , , ) = priceFeed.latestRoundData();
    }

    function swapExactInputSingle(
        uint256 _amountIn
    )
        internal
        returns (uint256 amountOut)
    {
        address tokenIn = yVaultReward.token();

        IERC20(tokenIn).approve(address(swapRouter), _amountIn);

        // Need to divide by Chainlink answer 8 decimals after multiplying
        uint minOut = (_amountIn.mulDivUp(getLatestPrice().abs(), 1e8))
        // yVault always has same decimals as its underlying
            .percentMul(1e4 - swapParams.slippage).scaleBy(decimals(), yVaultReward.decimals());

        ISwapRouter.ExactInputSingleParams memory params = ISwapRouter
            .ExactInputSingleParams({
                tokenIn: tokenIn,
                tokenOut: asset(),
                fee: swapParams.poolFee,
                recipient: address(this),
                deadline: block.timestamp + swapParams.wait,
                amountIn: _amountIn,
                amountOutMinimum: minOut,
                sqrtPriceLimitX96: 0
            });

        amountOut = swapRouter.exactInputSingle(params);
    }

    /// @dev Extremely small Uniswap trades can incur high slippage, hence important to set this
    function setMinHarvest(uint256 _minHarvest) external onlyOwner returns (bool) {

        swapParams.minHarvest = _minHarvest;
        return true;
    }

    function setSlippage(uint256 _slippage) external onlyOwner returns (bool) {

        swapParams.slippage = _slippage;
        return true;
    }

    function setWait(uint256 _wait) external onlyOwner returns (bool) {

        swapParams.wait = _wait;
        return true;
    }

    function setPoolFee(uint24 _poolFee) external onlyOwner returns (bool) {

        swapParams.poolFee = _poolFee;
        return true;
    }

    function setEnabled(uint8 _enabled) external onlyOwner returns (bool) {

        swapParams.enabled = _enabled;
        return true;
    }

    /*//////////////////////////////////////////////////////////////
                        DEPOSIT/WITHDRAWAL LOGIC
    //////////////////////////////////////////////////////////////*/

    function deposit(
        uint256 assets,
        address receiver
    ) public override nonReentrant returns (uint256 shares) {
        // Harvest to ensure depositor does not earn others rewards
        if (stakingRewards.balanceOf(address(this)) > 0) {
            harvest();
        }

        if(assets < MIN_DEPOSIT) {
            revert MinimumDepositNotMet();
        }

        (assets, shares) = _deposit(assets, receiver, msg.sender);

        emit Deposit(msg.sender, receiver, assets, shares);
    }

    function mint(
        uint256 shares, 
        address receiver
    ) public override nonReentrant returns (uint256 assets) {
        // Harvest to ensure depositor does not earn others rewards
        if (stakingRewards.balanceOf(address(this)) > 0) {
            harvest();
        }

        // No need to check for rounding error, previewMint rounds up.
        assets = previewMint(shares); 

        uint expectedShares = shares;
        (assets, shares) = _deposit(assets, receiver, msg.sender);

        if(assets < MIN_DEPOSIT) {
            revert MinimumDepositNotMet();
        }

        if(shares != expectedShares) {
            revert NotEnoughAvailableAssetsForAmount();
        }

        emit Deposit(msg.sender, receiver, assets, shares);
    }

    function withdraw(
        uint256 assets,
        address receiver,
        address _owner
    ) public override nonReentrant returns (uint256 shares) {
        // Harvest to ensure withdrawer gets their rightful rewards
        if (stakingRewards.balanceOf(address(this)) > 0) {
            harvest();
        }
        
        if(assets == 0) {
            revert NonZeroArgumentExpected();
        }

        (assets, shares) = _withdraw(
            assets,
            receiver,
            _owner
        );

        emit Withdraw(msg.sender, receiver, _owner, assets, shares);
    }

    function redeem(
        uint256 shares,
        address receiver,
        address _owner
    ) public override nonReentrant returns (uint256 assets) {
        // Harvest to ensure withdrawer gets their rightful rewards
        if (stakingRewards.balanceOf(address(this)) > 0) {
            harvest();
        }
        
        if(shares == 0) {
            revert NonZeroArgumentExpected();
        }

        (assets, shares) = _redeem(
            shares,
            receiver,
            _owner
        );

        emit Withdraw(msg.sender, receiver, _owner, assets, shares);
    }

    /*//////////////////////////////////////////////////////////////
                    DEPOSIT/WITHDRAWAL LIMIT LOGIC
    //////////////////////////////////////////////////////////////*/

    function maxDeposit(address)
        public
        view
        override
        returns (uint256)
    {
        return yVault.availableDepositLimit();
    }

    function maxMint(address _account)
        public
        view
        override
        returns (uint256)
    {
        return maxDeposit(_account)/ yVault.pricePerShare();
    }

    function maxWithdraw(address _owner)
        public
        view
        override
        returns (uint256)
    {
        return convertToAssets(this.balanceOf(_owner));
    }

    function maxRedeem(address _owner) public view override returns (uint256) {
        return this.balanceOf(_owner);
    }

     function _deposit(
        uint256 amount,
        address receiver,
        address depositor
    ) internal returns (uint256 deposited, uint256 mintedShares) {
        IERC20 _token = IERC20(asset());

        if (amount == type(uint256).max) {
            amount = Math.min(
                _token.balanceOf(depositor),
                _token.allowance(depositor, address(this))
            );
        }

        SafeERC20.safeTransferFrom(
            _token,
            depositor,
            address(this),
            amount
        );

        SafeERC20.safeApprove(
            _token,
            address(stakingRewardsZap),
            amount
        );

        uint256 beforeBal = _token.balanceOf(address(this));

        mintedShares = stakingRewardsZap.zapIn(address(yVault), amount);

        uint256 afterBal = _token.balanceOf(address(this));
        deposited = beforeBal - afterBal;

        // afterDeposit custom logic
        _mint(receiver, mintedShares);
    }

    /// @dev Deposit obtained want from reward
    /// @dev "Reward" being the want (e.g., USDC) obtained from swapping Reward tokens
    function _doRewardDeposit(
        uint256 amount
    ) internal returns (uint256 deposited, uint256 mintedShares) {
        IERC20 _token = IERC20(asset());

        SafeERC20.safeApprove(
            _token,
            address(stakingRewardsZap),
            amount
        );

        uint256 beforeBal = _token.balanceOf(address(this));

        // Returns 'toStake'
        mintedShares = stakingRewardsZap.zapIn(address(yVault), amount);

        uint256 afterBal = _token.balanceOf(address(this));
        deposited = beforeBal - afterBal;
    }

    function _withdraw(
        uint256 amount,
        address receiver,
        address sender
    ) internal returns (uint256 assets, uint256 shares) {
        VaultAPI _vault = yVault;

        shares = previewWithdraw(amount); 
        uint yearnShares = convertAssetsToYearnShares(amount);

        assets = _doWithdrawal(shares, yearnShares, sender, receiver, _vault);

        if(assets < amount) {
            revert NotEnoughAvailableSharesForAmount();
        }
    }

    function _redeem(
        uint256 shares, 
        address receiver,
        address sender
    ) internal returns (uint256 assets, uint256 sharesBurnt) {
        VaultAPI _vault = yVault;
        uint yearnShares = convertSharesToYearnShares(shares);
        assets = _doWithdrawal(shares, yearnShares, sender, receiver, _vault);    
        sharesBurnt = shares;
    }

    function _doWithdrawal(
        uint shares,
        uint yearnShares,
        address sender,
        address receiver,
        VaultAPI _vault
    ) private returns (uint assets) {
        if (sender != msg.sender) {
            uint currentAllowance = allowance(sender, msg.sender);
            if(currentAllowance < shares) {
                revert SpenderDoesNotHaveApprovalToBurnShares();
            }
            _approve(sender, msg.sender, currentAllowance - shares);
        }

        if (shares > balanceOf(sender)) {
            revert NotEnoughAvailableSharesForAmount();
        }

        if(yearnShares == 0 || shares == 0) {
            revert NoAvailableShares();
        }

        _burn(sender, shares);

        // withdraw from staking pool (yearn shares only, not rewards)
        stakingRewards.withdraw(yearnShares);

        // withdraw from vault and get total used shares
        assets = _vault.withdraw(yearnShares, receiver, 0);
    }

    function _doRewardWithdrawal(
        uint yearnShares,
        VaultAPI _vault
    ) private returns (uint assets) {

        if(yearnShares == 0) {
            revert NoAvailableShares();
        }

        // Withdraw OP from yvOP vault
        assets = _vault.withdraw(yearnShares, address(this), 0);
    }

    /*//////////////////////////////////////////////////////////////
                          ACCOUNTING LOGIC
    //////////////////////////////////////////////////////////////*/

    function totalAssets() public view override returns (uint256) {

        return convertYearnSharesToAssets(stakingRewards.balanceOf(address(this)));
        // Left for reference to show how this contract adapts vanilla Yearn wrapper
        // return convertYearnSharesToAssets(yVault.balanceOf(address(this)));
    }

    function convertToShares(uint256 assets)
        public
        view
        override
        returns (uint256)
    {
        uint supply = totalSupply(); // Total supply of wyvTokens

        // yvTokens held in staking contract
        uint localAssets = convertYearnSharesToAssets(stakingRewards.balanceOf(address(this)));
        return supply == 0 ? assets : assets.mulDivDown(supply, localAssets); 
    }

    function convertToAssets(uint256 shares)
        public
        view
        override
        returns (uint assets)
    {
        uint supply = totalSupply();

        uint localAssets = convertYearnSharesToAssets(
            // Shares held in staking contract
            stakingRewards.balanceOf(address(this))
        );

        return supply == 0 ? shares : shares.mulDivDown(localAssets, supply);
    }

    // Added function for reward conversion
    function convertToRewardAssets(uint256 shares)
        public
        view
        returns (uint assets)
    {
        uint supply = totalSupply();
        uint localAssets = convertYearnSharesToAssets(
            // Pending rewards
            stakingRewards.earned(address(this))
        );
        return supply == 0 ? shares : shares.mulDivDown(localAssets, supply);
    }

    function getFreeFunds() public view virtual returns (uint256) {
        uint256 lockedFundsRatio = (block.timestamp - yVault.lastReport()) * yVault.lockedProfitDegradation();
        uint256 _lockedProfit = yVault.lockedProfit();

        uint256 DEGRADATION_COEFFICIENT = 10 ** 18;
        uint256 lockedProfit = lockedFundsRatio < DEGRADATION_COEFFICIENT ? 
            _lockedProfit - (lockedFundsRatio * _lockedProfit / DEGRADATION_COEFFICIENT)
            : 0; // hardcoded DEGRADATION_COEFFICIENT  
        return yVault.totalAssets() - lockedProfit;
    }

    // Added function for reward conversion
    function getFreeRewardFunds() public view virtual returns (uint256) {
        uint256 lockedFundsRatio = (block.timestamp - yVaultReward.lastReport()) * yVaultReward.lockedProfitDegradation();
        uint256 _lockedProfit = yVaultReward.lockedProfit();

        uint256 DEGRADATION_COEFFICIENT = 10 ** 18;
        uint256 lockedProfit = lockedFundsRatio < DEGRADATION_COEFFICIENT ? 
            _lockedProfit - (lockedFundsRatio * _lockedProfit / DEGRADATION_COEFFICIENT)
            : 0; // hardcoded DEGRADATION_COEFFICIENT        
        return yVaultReward.totalAssets() - lockedProfit;
    }
    
    function previewDeposit(uint256 assets)
        public
        view
        override
        returns (uint256)
    {
        return convertToShares(assets);
    }

    function previewWithdraw(uint256 assets)
        public
        view
        override
        returns (uint256)
    {
        uint supply = totalSupply();
        uint localAssets = convertYearnSharesToAssets(stakingRewards.balanceOf(address(this)));
        return supply == 0 ? assets : assets.mulDivUp(supply, localAssets); 
    }

    function previewMint(uint256 shares)
        public
        view
        override
        returns (uint256)
    {
        uint supply = totalSupply();
        uint localAssets = convertYearnSharesToAssets(stakingRewards.balanceOf(address(this)));
        return supply == 0 ? shares : shares.mulDivUp(localAssets, supply);
    }

    function previewRedeem(uint256 shares)
        public
        view
        override
        returns (uint256)
    {
        return convertToAssets(shares);
    }

    // Only concerned about redeem op for rewards reinvesting
    function previewRedeemReward(uint256 shares)
        public
        view
        returns (uint256)
    {
        return convertToRewardAssets(shares);
    }

    /*//////////////////////////////////////////////////////////////
                            VIEW FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    function convertAssetsToYearnShares(uint assets) internal view returns (uint yShares) {
        uint256 supply = yVault.totalSupply();
        return supply == 0 ? assets : assets.mulDivUp(supply, getFreeFunds());
    }

    /// @dev yvTokens held in staking rewards contract
    function convertYearnSharesToAssets(uint yearnShares) internal view returns (uint assets) {
        uint supply = yVault.totalSupply();
        return supply == 0 ? yearnShares : yearnShares * getFreeFunds() / supply;
    }

    /// @dev Added function for rewards
    function convertYearnRewardSharesToAssets(uint yearnShares) internal view returns (uint assets) {
        uint supply = yVaultReward.totalSupply();
        return supply == 0 ? yearnShares : yearnShares * getFreeRewardFunds() / supply;
    }

    function convertSharesToYearnShares(uint shares) internal view returns (uint yShares) {
        uint supply = totalSupply(); 
        return supply == 0 ? shares : shares.mulDivUp(stakingRewards.balanceOf(address(this)), totalSupply());
    }

    function allowance(address _owner, address spender) public view virtual override(ERC20, IERC20) returns (uint256) {
        return super.allowance(_owner,spender);
    }

    function balanceOf(address account) public view virtual override(ERC20, IERC20) returns (uint256) {
        return super.balanceOf(account);
    }

    function name() public view virtual override(ERC20, IERC20Metadata) returns (string memory) {
        return super.name();
    }

    function symbol() public view virtual override(ERC20, IERC20Metadata) returns (string memory) {
        return super.symbol();
    }

    function totalSupply() public view virtual override(ERC20, IERC20) returns (uint256) {
        return super.totalSupply();
    }
}