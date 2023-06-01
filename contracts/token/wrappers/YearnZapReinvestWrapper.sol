// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

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
    using StableMath for int;
    using SafeERC20 for IERC20;

    IYearnRegistry public registry = IYearnRegistry(0x79286Dd38C9017E5423073bAc11F53357Fc5C128);

    VaultAPI public yVault;

    VaultAPI public yVaultRewards; // yvOP

    IStakingRewards public stakingRewards = IStakingRewards(0xB2c04C55979B6CA7EB10e666933DE5ED84E6876b);

    IStakingRewardsZap public stakingRewardsZap = IStakingRewardsZap(0x498d9dCBB1708e135bdc76Ef007f08CBa4477BE2);

    AggregatorV3Interface internal priceFeed = AggregatorV3Interface(0x0D276FC14719f9292D5C1eA2198673d1f4269246);

    ISwapRouter public immutable swapRouter;

    uint256 private constant MIN_DEPOSIT = 1e3;

    /* Swap params */
    uint256 slippage;
    uint256 deadline;
    uint24 poolFee;

    constructor(VaultAPI _vault, ISwapRouter _router)
        ERC20(
            string(abi.encodePacked(_vault.name(), "-4646-Adapter")),
            string(abi.encodePacked(_vault.symbol(), "-4646"))
        )
        ERC4626(
            IERC20(yVault.token()) // OZ contract retrieves decimals from asset
        )
    {
        yVault = _vault;
        swapRouter = _router;
    }

    function vault() external view returns (address) {
        return address(yVault);
    }

    /// @dev Verifies that the yearn registry has "_target" recorded as the asset's latest vault
    function migrate(address _target) external onlyOwner returns (address) {
        // verify _target is a valid address
        if(registry.latestVault(asset()) != _target) {
            revert InvalidMigrationTarget();
        }

        // Retrieves shares and rewards from yVault
        stakingRewards.exit();

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
                        STAKING REWARDS LOGIC
    //////////////////////////////////////////////////////////////*/

    function harvest() external {

        stakingRewards.getReward();

        uint rewards = IERC20(address(yVaultRewards)).balanceOf(address(this));

        // Redeem from vault.
        uint256 assets = _doRewardWithdrawal(rewards, yVaultRewards);

        // Swap for want
        uint256 amountOut = swapExactInputSingle(assets);

        // Deposit to yVault.
        deposit(amountOut, address(this));
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
        address tokenIn = yVaultRewards.token();

        IERC20(tokenIn).approve(address(swapRouter), _amountIn);

        uint minOut = getLatestPrice().abs().percentMul(1e4 - slippage);

        ISwapRouter.ExactInputSingleParams memory params = ISwapRouter
            .ExactInputSingleParams({
                tokenIn: tokenIn,
                tokenOut: asset(),
                fee: poolFee,
                recipient: address(this),
                deadline: deadline,
                amountIn: _amountIn,
                amountOutMinimum: minOut,
                sqrtPriceLimitX96: 0
            });

        amountOut = swapRouter.exactInputSingle(params);
    }

    /*//////////////////////////////////////////////////////////////
                        DEPOSIT/WITHDRAWAL LOGIC
    //////////////////////////////////////////////////////////////*/

    function deposit(
        uint256 assets,
        address receiver
    ) public override nonReentrant returns (uint256 shares) {
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

        // withdraw from staking pool
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

        // withdraw from staking pool
        stakingRewards.withdraw(yearnShares);

        // withdraw from vault and get total used shares
        assets = _vault.withdraw(yearnShares, address(this), 0);
    }

    /*//////////////////////////////////////////////////////////////
                          ACCOUNTING LOGIC
    //////////////////////////////////////////////////////////////*/

    function totalAssets() public view override returns (uint256) {
        return convertYearnSharesToAssets(yVault.balanceOf(address(this)));
    }

    function convertToShares(uint256 assets)
        public
        view
        override
        returns (uint256)
    {
        uint supply = totalSupply();
        uint localAssets = convertYearnSharesToAssets(yVault.balanceOf(address(this)));
        return supply == 0 ? assets : assets.mulDivDown(supply, localAssets); 
    }

    function convertToAssets(uint256 shares)
        public
        view
        override
        returns (uint assets)
    {
        uint supply = totalSupply();
        uint localAssets = convertYearnSharesToAssets(yVault.balanceOf(address(this)));
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
        uint localAssets = convertYearnSharesToAssets(yVault.balanceOf(address(this)));
        return supply == 0 ? assets : assets.mulDivUp(supply, localAssets); 
    }

    function previewMint(uint256 shares)
        public
        view
        override
        returns (uint256)
    {
        uint supply = totalSupply();
        uint localAssets = convertYearnSharesToAssets(yVault.balanceOf(address(this)));
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

    /*//////////////////////////////////////////////////////////////
                            VIEW FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    function convertAssetsToYearnShares(uint assets) internal view returns (uint yShares) {
        uint256 supply = yVault.totalSupply();
        return supply == 0 ? assets : assets.mulDivUp(supply, getFreeFunds());
    }

    function convertYearnSharesToAssets(uint yearnShares) internal view returns (uint assets) {
        uint supply = yVault.totalSupply();
        return supply == 0 ? yearnShares : yearnShares * getFreeFunds() / supply;
    }

    function convertSharesToYearnShares(uint shares) internal view returns (uint yShares) {
        uint supply = totalSupply(); 
        return supply == 0 ? shares : shares.mulDivUp(yVault.balanceOf(address(this)), totalSupply());
    }
}