// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../utils/ERC4626.sol";
import {ISwap} from "./utils/ISwap.sol";

interface IVault {
    function deposit(uint256) external;
    function withdraw(uint256) external;
    function balance() external view returns (uint256);
    function want() external view returns (IERC20Metadata);
    function totalSupply() external view returns (uint256);
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
}

/**
 * @dev Implementation of an ERC4626 wrapper for Beefy Vaults.
 * Depositing underlying tokens to this contract will transfer the Beefy Vault tokens from the
 * caller to this address and mint the wrapped version to the caller. Burning wrapped tokens
 * burns the wrapped version transferred by the caller, then withdraws the underlying tokens
 * from the Beefy vault and transfers those tokens back to the caller.
 */
contract HOP_LP_USDC_BeefyWrapper is ERC4626 {
    using SafeERC20 for IERC20;
    using Math for uint256;

    address public vault;
    ISwap public HOP_LP_USDC = ISwap(0x10541b07d8Ad2647Dc6cD67abd4c03575dade261);

    /**
     * @dev Constructs an ERC4626 wrapper for a Beefy Vault token.
     * @param _vault the address of the vault.
     * @param _name the name of this contract's token.
     * @param _symbol the symbol of this contract's token.
     */
    constructor(
        address _vault,
        string memory _name,
        string memory _symbol
    ) ERC20(_name, _symbol) ERC4626(IVault(vault).want()) {
        vault = _vault;
        IERC20(asset()).safeApprove(vault, type(uint256).max);
    }

    /**
     * @dev Wraps all vault share tokens owned by the caller.
     */
    function wrapAll() external {
        wrap(IERC20(vault).balanceOf(msg.sender));
    }

    /**
     * @dev Wraps an amount of vault share tokens.
     * @param amount the total amount of vault share tokens to be wrapped.
     */
    function wrap(uint256 amount) public {
        IERC20(vault).safeTransferFrom(msg.sender, address(this), amount);
        _mint(msg.sender, amount);
    }

    /**
     * @dev Unwraps all wrapped tokens owned by the caller.
     */
    function unwrapAll() external {
        unwrap(balanceOf(msg.sender));
    }

    /**
     * @dev Unwraps an amount of vault share tokens.
     * @param amount the total amount of vault share tokens to be unwrapped.
     */
    function unwrap(uint256 amount) public {
        _burn(msg.sender, amount);
        IERC20(vault).safeTransfer(msg.sender, amount);
    }

    /**
     * @dev Fetches the total assets held by the vault.
     * @return totalAssets the total balance of assets held by the vault.
     */
    function totalAssets() public view virtual override returns (uint256) {
        return IVault(vault).balance();
    }

    /**
     * @dev Fetches the total vault shares.
     * @return totalSupply the total supply of vault shares.
     */
    function totalSupply()
        public view virtual override(ERC20, IERC20) 
    returns (uint256) {
        return IERC20(vault).totalSupply();
    }

    /**
     * @dev Deposit assets to the vault and mint an equal number of wrapped tokens to vault shares.
     * @param caller the address of the sender of the assets.
     * @param receiver the address of the receiver of the wrapped tokens.
     * @param assets the amount of assets being deposited.
     * @param shares the amount of shares being minted.
     */
    function _deposit(
        address caller,
        address receiver,
        uint256 assets,
        uint256 shares
    ) internal virtual override {
        _beforeDeposit(caller, assets);
        IERC20(asset()).safeTransferFrom(caller, address(this), assets);
        uint balance = IERC20(vault).balanceOf(address(this));
        IVault(vault).deposit(assets);
        shares = IERC20(vault).balanceOf(address(this)) - balance;
        _mint(receiver, shares);

        emit Deposit(caller, receiver, assets, shares);
    }

    /**
     * @dev Burn wrapped tokens and withdraw assets from the vault.
     * @param caller the address of the caller of the withdraw.
     * @param receiver the address of the receiver of the assets.
     * @param owner the address of the owner of the burnt shares.
     * @param assets the amount of assets being withdrawn.
     * @param shares the amount of shares being burnt.
     */
    function _withdraw(
        address caller,
        address receiver,
        address owner,
        uint256 assets,
        uint256 shares
    ) internal virtual override {
        if (caller != owner) {
            _spendAllowance(owner, caller, shares);
        }
        _burn(owner, shares);

        IVault(vault).withdraw(shares);
        uint balance = IERC20(asset()).balanceOf(address(this));
        if (assets > balance) {
            assets = balance;
        }

        IERC20(asset()).safeTransfer(receiver, assets);

        emit Withdraw(caller, receiver, owner, assets, shares);
    }

    /// @dev minToMint can be set to 0 as this is covered by minAmountOut.
    /// @param assets The amount of USDC deposited.
    function _beforeDeposit(
        address caller,
        uint256 assets
    ) internal {
        IERC20(HOP_LP_USDC.getToken(0)).safeTransferFrom(caller, address(this), assets);
        uint256[] memory amounts = new uint256[](1);
        amounts[0] = assets;
        HOP_LP_USDC.addLiquidity(amounts, 0, block.timestamp + 30 seconds);
    }

    /// @dev minToMint can be set to 0 as this is covered by minAmountOut.
    /// @param amount The amount of COFI to burn.
    function _beforeWithdraw(
        uint256 amount
    ) internal {
        HOP_LP_USDC.removeLiquidityOneToken(
            HOP_LP_USDC.calculateRemoveLiquidityOneToken(amount, 0),
            0,
            0,
            block.timestamp + 30 seconds
        );
    }
}