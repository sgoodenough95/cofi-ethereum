// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

/**

    █▀▀ █▀█ █▀▀ █
    █▄▄ █▄█ █▀░ █

    @author The Stoa Corporation Ltd
    @title  Supply Facet
    @notice User-operated functions for minting fiAssets.
            Backing assets are deployed to respective Vault as per schema.
 */

import { Modifiers } from '../libs/LibAppStorage.sol';
import { LibToken } from '../libs/LibToken.sol';
import { LibReward } from '../libs/LibReward.sol';
import { LibVault } from '../libs/LibVault.sol';
import { IERC4626 } from '.././interfaces/IERC4626.sol';
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import 'hardhat/console.sol';

contract SupplyFacet is Modifiers {

    /// @notice Entry point that routes to a function accoriding to if a derivative asset
    ///         e.g., USDC-LP needs to be acquired for the vault.
    function underlyingToFi(
        uint256 amount,
        uint256 minAmountOut,
        address fiAsset,
        address depositFrom,
        address recipient,
        address referral
    )   external
        returns (uint256 mintAfterFee)
    {
        mintAfterFee = IERC4626(s.vault[fiAsset]).asset() == s.underlying[fiAsset] ?
            underlyingToFiMutual(
                amount,
                minAmountOut,
                fiAsset,
                depositFrom,
                recipient,
                referral
            ) :
            underlyingToFiViaDeriv(
                amount,
                minAmountOut,
                fiAsset,
                depositFrom,
                recipient,
                referral
            );
    }

    /// @notice Converts a supported underlyingAsset into a fiAsset (e.g., DAI to COFI).
    ///
    /// @param  amount          The amount of underlyingAssets to deposit.
    /// @param  minAmountOut    The minimum amount of fiAssets received (before fees).
    /// @param  fiAsset         The fiAsset to mint.
    /// @param  depositFrom     The account to deposit underlyingAssets from.
    /// @param  recipient       The recipient of the fiAssets.
    /// @param  referral        The referral account (address(0) if none provided).
    function underlyingToFiMutual(
        uint256 amount,
        uint256 minAmountOut, // E.g., 1,000 * 0.9975 = 997.50. Auto-set to 0.25%.
        address fiAsset,
        address depositFrom,
        address recipient,
        address referral
    )
        public
        isWhitelisted
        mintEnabled(fiAsset)
        minDeposit(amount, fiAsset)
        returns (uint256 mintAfterFee)
    {
        // Transfer underlying to this contract first to prevent user having to 
        // approve 1+ vaults (if/when the vault used changes, upon revisiting platform).
        LibToken._transferFrom(
            s.underlying[fiAsset],
            amount,
            depositFrom,
            address(this)
        );
        
        SafeERC20.safeApprove(
            IERC20(IERC4626(s.vault[fiAsset]).asset()),
            s.vault[fiAsset],
            amount
        );

        uint256 assets = LibVault._getAssets(
            LibVault._wrap(
                amount,
                s.vault[fiAsset],
                depositFrom // Purely for Event emission. Wraps from Diamond.
            ),
            s.vault[fiAsset]
        );

        require(assets >= minAmountOut, 'SupplyFacet: Slippage exceeded');

        uint256 fee = LibToken._getMintFee(fiAsset, assets);
        mintAfterFee = assets - fee;

        // Capture mint fee in fiAssets.
        if (fee > 0) LibToken._mint(fiAsset, s.feeCollector, fee);

        LibToken._mint(fiAsset, recipient, mintAfterFee);
        LibReward._initReward();
        if (referral != address(0)) LibReward._referReward(referral);
        emit LibToken.Deposit(s.underlying[fiAsset], amount, depositFrom, fee);
    }

    /// @notice Converts a supported underlyingAsset into a fiAsset (e.g., USDC to COFI)
    ///         via a derivative asset (e.g., USDC-LP).
    ///
    /// @param  amount          The amount of underlyingAssets to deposit.
    /// @param  minAmountOut    The minimum amount of fiAssets received (before fees).
    /// @param  fiAsset         The fiAsset to mint.
    /// @param  depositFrom     The account to deposit underlyingAssets from.
    /// @param  recipient       The recipient of the fiAssets.
    /// @param  referral        The referral account (address(0) if none provided).
    function underlyingToFiViaDeriv(
        uint256 amount,
        uint256 minAmountOut, // E.g., 1,000 * 0.9975 = 997.50. Auto-set to 0.25%.
        address fiAsset,
        address depositFrom,
        address recipient,
        address referral
    )
        public
        isWhitelisted
        mintEnabled(fiAsset)
        minDeposit(amount, fiAsset)
        returns (uint256 mintAfterFee)
    {
        // Transfer underlying to this contract first to prevent user having to 
        // approve 1+ vaults (if/when the vault used changes, upon revisiting platform).
        LibToken._transferFrom(
            s.underlying[fiAsset],
            amount,
            depositFrom,
            address(this)
        );

        // Transform from underlying to underlyingPrime hook.
        s.EXT_GUARD = 1;
        (bool success, ) = address(this).call(abi.encodeWithSelector(
            s.derivParams[s.vault[fiAsset]].toDeriv,
            fiAsset,
            amount
        )); // Will fail here if set vault is not using a derivative.
        require(success, 'SupplyFacet: Underlying to derivative operation failed');
        require(s.RETURN_ASSETS > 0, 'SupplyFacet: Zero return assets received');

        SafeERC20.safeApprove(
            IERC20(IERC4626(s.vault[fiAsset]).asset()),
            s.vault[fiAsset],
            s.RETURN_ASSETS
        );

        (success, ) = address(this).call(abi.encodeWithSelector(
            s.derivParams[s.vault[fiAsset]].convertToUnderlying,
            LibVault._getAssets(
                LibVault._wrap(
                    s.RETURN_ASSETS,
                    s.vault[fiAsset],
                    depositFrom
                ),
                s.vault[fiAsset]
            )
        ));
        require(success, 'SupplyFacet: Convert to underlying operation failed');

        uint256 assets = LibToken._toFiDecimals(fiAsset, s.RETURN_ASSETS);
        require(assets >= minAmountOut, 'SupplyFacet: Slippage exceeded');
        s.RETURN_ASSETS = 0;

        uint256 fee = LibToken._getMintFee(fiAsset, assets);
        mintAfterFee = assets - fee;

        // Capture mint fee in fiAssets.
        if (fee > 0) LibToken._mint(fiAsset, s.feeCollector, fee);

        LibToken._mint(fiAsset, recipient, mintAfterFee);
        LibReward._initReward();
        if (referral != address(0)) LibReward._referReward(referral);
        emit LibToken.Deposit(s.underlying[fiAsset], amount, depositFrom, fee);
    }

    /// @notice Converts a supported yieldAsset into a fiAsset (e.g., yvDAI to COFI).
    ///
    /// @param  amount          The amount of yieldAssets to deposit.
    /// @param  minAmountOut    The minimum amount of fiAssets received (before fees).
    /// @param  fiAsset         The fiAsset to mint.
    /// @param  depositFrom     The account to deposit yieldAssets from.
    /// @param  recipient       The recipient of the fiAssets.
    /// @param  referral        The referral account (address(0) if none provided).
    function sharesToFi(
        uint256 amount,
        uint256 minAmountOut,
        address fiAsset,
        address depositFrom,
        address recipient,
        address referral
    )
        external
        isWhitelisted
        mintEnabled(fiAsset)
        minDeposit(LibVault._getAssets(amount, s.vault[fiAsset]), fiAsset)
        returns (uint256 mintAfterFee)
    {
        // Backing yieldAssets are held in the diamond contract.
        LibToken._transferFrom(s.vault[fiAsset], amount, depositFrom, address(this));

        uint256 assets = LibVault._getAssets(amount, s.vault[fiAsset]);

        require(assets >= minAmountOut, 'SupplyFacet: Slippage exceeded');

        uint256 fee = LibToken._getMintFee(fiAsset, assets);
        mintAfterFee = assets - fee;

        // Capture mint fee in fiAssets.
        if (fee > 0) LibToken._mint(fiAsset, s.feeCollector, fee);

        LibToken._mint(fiAsset, recipient, mintAfterFee);
        LibReward._initReward();
        if (referral != address(0)) LibReward._referReward(referral);
        emit LibToken.Deposit(s.underlying[fiAsset], amount, depositFrom, fee);
    }

    /// @notice Converts a fiAsset to its collateral yieldAsset.
    ///
    /// @param  amount          The amount of fiAssets to redeem.
    /// @param  minAmountOut    The minimum amount of yieldAssets received (after fees).
    /// @param  fiAsset         The fiAsset to redeem (e.g., COFI).
    /// @param  depositFrom     The account to deposit fiAssets from.
    /// @param  recipient       The recipient of the yieldAssets.
    function fiToShares(
        uint256 amount,
        uint256 minAmountOut,
        address fiAsset,
        address depositFrom,
        address recipient
    )   external
        isWhitelisted
        redeemEnabled(fiAsset)
        minWithdraw(amount, fiAsset)
        returns (uint256 burnAfterFee)
    {
        depositFrom == msg.sender ?
            LibToken._redeem(fiAsset, msg.sender, amount) :
            LibToken._transferFrom(fiAsset, amount, depositFrom, s.feeCollector);

        uint256 fee = LibToken._getRedeemFee(fiAsset, amount);
        burnAfterFee = amount - fee;

        // Redemption fee is captured by retaining 'fee' amount.
        LibToken._burn(fiAsset, s.feeCollector, burnAfterFee);

        uint256 shares = LibVault._getShares(burnAfterFee, s.vault[fiAsset]);
        require(shares >= minAmountOut, 'SupplyFacet: Slippage exceeded');

        LibToken._transfer(s.vault[fiAsset], shares, recipient);
        emit LibToken.Withdraw(s.underlying[fiAsset], amount, depositFrom, fee);
    }

    function fiToUnderlying(
        uint256 amount,
        uint256 minAmountOut,
        address fiAsset,
        address depositFrom,
        address recipient
    )   external
        returns (uint256 burnAfterFee)
    {
        burnAfterFee = IERC4626(s.vault[fiAsset]).asset() == s.underlying[fiAsset] ?
            fiToUnderlyingMutual(
                amount,
                minAmountOut,
                fiAsset,
                depositFrom,
                recipient
            ) :
            fiToUnderlyingViaDeriv(
                amount,
                minAmountOut,
                fiAsset,
                depositFrom,
                recipient
            );
    }

    /// @notice Converts a fiAsset to its collateral underlyingAsset.
    ///
    /// @notice Can be used to make payments in underlyingAsset.
    ///         E.g., send USDC from having COFI in your wallet.
    ///
    /// @param  amount          The amount of fiAssets to redeem.
    /// @param  minAmountOut    The minimum amount of underlyingAssets received (after fees).
    /// @param  fiAsset         The fiAsset to redeem (e.g., COFI).
    /// @param  depositFrom     The account to deposit fiAssets from.
    /// @param  recipient       The recipient of the underlyingAssets.
    function fiToUnderlyingMutual(
        uint256 amount,
        uint256 minAmountOut,
        address fiAsset,
        address depositFrom,
        address recipient
    )   public
        isWhitelisted
        redeemEnabled(fiAsset)
        minWithdraw(amount, fiAsset)
        returns (uint256 burnAfterFee)
    {
        depositFrom == msg.sender ?
            LibToken._redeem(fiAsset, msg.sender, amount) :
            LibToken._transferFrom(fiAsset, amount, depositFrom, s.feeCollector);

        uint256 fee = LibToken._getRedeemFee(fiAsset, amount);
        burnAfterFee = amount - fee;

        // Redemption fee is captured by retaining 'fee' amount.
        LibToken._burn(fiAsset, s.feeCollector, burnAfterFee);

        require(
            // Redeems assets directly to recipient (does not traverse through Diamond).
            LibVault._unwrap(burnAfterFee, s.vault[fiAsset], recipient) >= minAmountOut,
            'SupplyFacet: Slippage exceeded'
        );
        emit LibToken.Withdraw(s.underlying[fiAsset], amount, depositFrom, fee);
    }

    /// @notice Converts a fiAsset to its collateral underlyingAsset through unwinding
    ///         the vault's derivative asset.
    ///
    /// @param  amount          The amount of fiAssets to redeem.
    /// @param  minAmountOut    The minimum amount of underlyingAssets received (after fees).
    /// @param  fiAsset         The fiAsset to redeem (e.g., COFI).
    /// @param  depositFrom     The account to deposit fiAssets from.
    /// @param  recipient       The recipient of the underlyingAssets.
    function fiToUnderlyingViaDeriv(
        uint256 amount,
        uint256 minAmountOut,
        address fiAsset,
        address depositFrom,
        address recipient
    )   public
        isWhitelisted
        redeemEnabled(fiAsset)
        minWithdraw(amount, fiAsset)
        returns (uint256 burnAfterFee)
    {
        depositFrom == msg.sender ?
            LibToken._redeem(fiAsset, msg.sender, amount) :
            LibToken._transferFrom(fiAsset, amount, depositFrom, s.feeCollector);

        uint256 fee = LibToken._getRedeemFee(fiAsset, amount);
        burnAfterFee = amount - fee;

        // Redemption fee is captured by retaining 'fee' amount.
        LibToken._burn(fiAsset, s.feeCollector, burnAfterFee);

        // Determine equivalent number of underlyingPrime tokens to redeem.
        (bool success, ) = address(this).call(abi.encodeWithSelector(
            s.derivParams[s.vault[fiAsset]].convertToDeriv,
            burnAfterFee
        )); 
        require(success, 'SupplyFacet: Convert to prime operation failed');

        // Transform from underlyingPrime to underlying hook.
        s.EXT_GUARD = 1;
        (success, ) = address(this).call(abi.encodeWithSelector(
            s.derivParams[s.vault[fiAsset]].toUnderlying,
            fiAsset,
            LibVault._unwrap(s.RETURN_ASSETS, s.vault[fiAsset], address(this))
        ));
        require(success, 'SupplyFacet: Prime to underlying operation failed');
        require(s.RETURN_ASSETS > minAmountOut, 'SupplyFacet: Slippage exceeded');

        LibToken._transfer(s.underlying[fiAsset], s.RETURN_ASSETS, recipient);
        s.RETURN_ASSETS = 0;
        emit LibToken.Withdraw(s.underlying[fiAsset], amount, depositFrom, fee);
    }

    /*//////////////////////////////////////////////////////////////
                        PARTNER INTEGRATION
    //////////////////////////////////////////////////////////////*/

    function toDeriv_HOPUSDCLP(
        uint256 amount
    ) public EXTGuard {

        uint256[] memory amounts = new uint256[](2);
        amounts[0] = amount;
        SafeERC20.safeApprove(
            IERC20(s.underlying[s.COFI]),
            address(LibVault.HOPUSDCLP),
            amount
        );
        s.RETURN_ASSETS = LibVault.HOPUSDCLP.addLiquidity(
            amounts,
            0,
            block.timestamp + 2 seconds
        );
    }

    function toUnderlying_HOPUSDCLP(
        uint256 amount
    ) public EXTGuard {

        SafeERC20.safeApprove(
            IERC20(IERC4626(s.vault[s.COFI]).asset()),
            address(LibVault.HOPUSDCLP),
            amount
        );
        s.RETURN_ASSETS = LibVault.HOPUSDCLP.removeLiquidityOneToken(
            amount,
            0,
            0,
            block.timestamp + 2 seconds
        );
    }

    function convertToUnderlying_HOPUSDCLP(
        uint256 amount
    ) public {

        s.RETURN_ASSETS = LibVault.HOPUSDCLP.calculateRemoveLiquidityOneToken(
            address(this),
            amount,
            0
        );
    }

    function convertToDeriv_HOPUSDCLP(
        uint256 amount
    ) public {

        uint256[] memory amounts = new uint256[](2);
        amounts[0] = LibToken._toUnderlyingDecimals(s.COFI, amount);
        s.RETURN_ASSETS = LibVault.HOPUSDCLP.calculateTokenAmount(
            address(this),
            amounts,
            false
        );
    }

    /// @notice minDeposit applies to the underlyingAsset mapped to the fiAsset (e.g., DAI).
    function setMinDeposit(
        address fiAsset,
        uint256 amount
    )   external
        onlyAdmin
        returns (bool)
    {
        s.minDeposit[fiAsset] = amount;
        return true;
    }

    /// @notice minWithdraw applies to the underlyingAsset mapped to the fiAsset (e.g., DAI).
    function setMinWithdraw(
        address fiAsset,
        uint256 amount
    )   external
        onlyAdmin
        returns (bool)
    {
        s.minWithdraw[fiAsset] = amount;
        return true;
    }

    function setMintFee(
        address fiAsset,
        uint256 amount
    )   external
        onlyAdmin
        returns (bool)
    {
        s.mintFee[fiAsset] = amount;
        return true;
    }

    function toggleMintEnabled(
        address fiAsset
    )   external
        onlyAdmin
        returns (bool)
    {
        s.mintEnabled[fiAsset] = s.mintEnabled[fiAsset] == 0 ? 1 : 0;
        return s.mintEnabled[fiAsset] == 1 ? true : false;
    }

    function setRedeemFee(
        address fiAsset,
        uint256 amount
    )   external
        onlyAdmin
        returns (bool)
    {
        s.redeemFee[fiAsset] = amount;
        return true;
    }

    function toggleRedeemEnabled(
        address fiAsset
    )   external
        onlyAdmin
        returns (bool)
    {
        s.redeemEnabled[fiAsset] = s.redeemEnabled[fiAsset] == 0 ? 1 : 0;
        return s.redeemEnabled[fiAsset] == 1 ? true : false;
    }

    function setServiceFee(
        address fiAsset,
        uint256 amount
    )   external
        onlyAdmin
        returns (bool)
    {
        s.serviceFee[fiAsset] = amount;
        return true;
    }

    function getMinDeposit(
        address fiAsset
    )   external
        view
        returns (uint256)
    {
        return s.minDeposit[fiAsset];
    }

    function getMinWithdraw(
        address fiAsset
    )   external
        view
        returns (uint256)
    {
        return s.minWithdraw[fiAsset];
    }

    function getMintFee(
        address fiAsset
    )   external
        view
        returns (uint256)
    {
        return s.mintFee[fiAsset];
    }

    function getMintEnabled(
        address fiAsset
    )   external
        view
        returns (bool)
    {
        return s.mintEnabled[fiAsset] == 1 ? true : false;
    }

    function getRedeemFee(
        address fiAsset
    )   external
        view
        returns (uint256)
    {
        return s.redeemFee[fiAsset];
    }

    function getRedeemEnabled(
        address fiAsset
    )   external
        view
        returns (bool)
    {
        return s.redeemEnabled[fiAsset] == 1 ? true : false;
    }

    function getServiceFee(
        address fiAsset
    )   external
        view
        returns (uint256)
    {
        return s.serviceFee[fiAsset];
    }

    /// @notice Returns the underlyingAsset (variable) for a given fiAsset.
    ///
    /// @param  fiAsset The fiAsset to query for.
    function getUnderlyingAsset(
        address fiAsset
    )   external
        view
        returns (address)
    {
        return IERC4626(s.vault[fiAsset]).asset();
    }

    /// @notice Returns the yieldAsset (variable) for a given fiAsset.
    ///
    /// @param  fiAsset The fiAsset to query for. 
    function getYieldAsset(
        address fiAsset
    )   external
        view
        returns (address)
    {
        return s.vault[fiAsset];
    }
}