// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

/**

    █▀▀ █▀█ █▀▀ █
    █▄▄ █▄█ █▀░ █

    @author cofi.money
    @title  Reward Facet
    @notice Provides logic for distributing and handling rewards, such as yield and points.
 */

import { Modifiers } from '../libs/LibAppStorage.sol';
import { PercentageMath } from '../libs/external/PercentageMath.sol';
import { LibToken } from '../libs/LibToken.sol';
import { LibVault } from '../libs/LibVault.sol';
import { IFiToken } from '../interfaces/IFiToken.sol';
import { IERC20 } from '@openzeppelin/contracts/interfaces/IERC20.sol';
import { IERC4626 } from '../interfaces/IERC4626.sol';
import { GPv2SafeERC20 } from '.././libs/external/GPv2SafeERC20.sol';
import 'hardhat/console.sol';

contract RewardFacet is Modifiers {
    using PercentageMath for uint256;
    using GPv2SafeERC20 for IERC20;

    /// @notice This function must be called after the last rebase of a pointsRate
    ///         and before the application of a new pointsRate for a given fiAsset,
    ///         for every account that is eliigble for yield/points. If not, the new
    ///         pointsRate will apply to yield earned during the previous, different
    ///         pointsRate epoch - which we want to avoid.
    ///
    /// @dev    This function may be required to be called multiple times, as per the
    ///         size limit for passing addresses, in order for all relevant accounts
    ///         to be updated.
    ///
    /// @param  accounts    The array of accounts to capture points for.
    /// @param  fiAsset     The fiAsset to capture points for.
    function batchCaptureYieldPoints(
        address[] memory    accounts,
        address             fiAsset
    )   external
    {
        /**

            DETERMINE WHICH ACCOUNTS TO PASS:

            1.  Take a snapshot of all holders immediately after each rebase
                for the current points epoch.
            2.  If a new address is dectected, add to array, otherwise skip.
            3.  After the last rebase of the current points epoch, capture yield
                for all addresses in array.
            4.  Start with empty array for next points epoch.
         */
        uint256 yield;
        for(uint i = 0; i < accounts.length; ++i) {
        yield = IFiToken(fiAsset).getYieldEarned(accounts[i]);
            // If the account has earned yield since the last yield capture event.
            if (s.YPC[accounts[i]][fiAsset].yield < yield) {
                s.YPC[accounts[i]][fiAsset].points +=
                    (yield - s.YPC[accounts[i]][fiAsset].yield)
                        .percentMul(s.pointsRate[fiAsset]);
                s.YPC[accounts[i]][fiAsset].yield = yield;
            }
        }
    }

    function captureYieldPoints(
        address account,
        address fiAsset
    )   external
    {
        /**
            POINTS CAPTURE:

            1.  Gets current yield earned.
            2.  If greater than previous yield earned, apply points
                for difference.
            3.  Update yield earned.
         */
        
        uint256 yield = IFiToken(fiAsset).getYieldEarned(account);
        if (s.YPC[account][fiAsset].yield < yield) {
            s.YPC[account][fiAsset].points +=
                (yield - s.YPC[account][fiAsset].yield)
                    .percentMul(s.pointsRate[fiAsset]);
            s.YPC[account][fiAsset].yield  = yield;
        }
    }

    /// @dev    Yield points must be captured beforehand to ensure they
    ///         have updated correctly prior to a pointsRate change.
    function setPointsRate(
        address fiAsset,
        uint256 amount
    )   external
        onlyAdmin
    {
        s.pointsRate[fiAsset] = amount;
    }

    /// @notice Function for distributing points not intrinsically linked to yield.
    ///
    /// @param  accounts    The array of accounts to distribute points for.
    /// @param  points      The amount of points to distribute to each account.
    function reward(
        address[] memory    accounts,
        uint256             points
    )   external
        onlyAdmin
    {
        for(uint i = 0; i < accounts.length; ++i) {
            s.XPC[accounts[i]] += points;
        }
    }

    /// @notice Function for migrating to a new Vault. The new Vault must support the
    ///         same underlyingAsset (e.g., DAI).
    ///
    /// @dev    Will only ever be called as part of a migration script, and therefore
    ///         requires that the relevant functions are called before and after.
    ///
    /// @dev    Ensure that a buffer of the underlyingAsset has been transferred to the
    ///         Diamond beforehand to account for slippage.
    ///
    /// @param  fiAsset     The fiAsset to migrate vault backing for.
    /// @param  newVault    The vault to migrate to (must adhere to ERC4626).
    function migrateVault(
        address fiAsset,
        address newVault
    )   external
        onlyAdmin
    {
        // First, ensure minting/redeeming of fiAsset is disabled.
        require(
            s.mintEnabled[fiAsset] == 0,
            'RewardFacet: Require mint to be disabled'
        );
        require(
            s.redeemEnabled[fiAsset] == 0,
            'RewardFacet: Require redeem to be disabled'
        );

        // Pull funds from old vault.
        uint256 assets = IERC4626(s.vault[fiAsset]).redeem(
            IERC20(s.vault[fiAsset]).balanceOf(address(this)),
            address(this),
            address(this)
        );

        // Approve newVault spend for Diamond.
        IERC20(IERC4626(s.vault[fiAsset]).asset())
            .approve(newVault, IERC20(IERC4626(s.vault[fiAsset]).asset()).balanceOf(address(this)));

        // Deploy funds to new vault.
        LibVault._wrap(
            IERC20(IERC4626(s.vault[fiAsset]).asset())
                .balanceOf(address(this)),
            newVault,
            address(this)
        );

        require(
            assets <= LibVault._totalValue(newVault),
            'AdminFacet: Vault migration slippage exceeded'
        );

        // Update vault for fiAsset.
        s.vault[fiAsset] = newVault;

        /**
            TO FINALISE MIGRATION:

            1.  Call 'rebase()'.
            2.  Enable minting/redeeming.
         */
    }

    /// NOTE    ENABLED FOR TESTING PURPOSES(!)
    ///
    /// @notice 'changeSupply()' will be commented out, but left for reference.
    ///         For the Stoa stablecoin product, an Admin will call changeSupply() directly.
    ///         For the COFIMoney MVP, however, this will not be the case.
    ///
    /// @notice Function for manually changing the supply of a fiAsset.
    ///
    /// @dev    'rebase()' must be called after for change to take effect.
    ///
    /// @param  fiAsset     The fiAsset to change supply for.
    /// @param  newSupply   The new supply of fiAssets (not accounting for CoFi's yield share).
    function changeSupply(
        address fiAsset,
        uint256 newSupply
    )   external
        onlyAdmin
    {
        IFiToken(fiAsset).changeSupply(newSupply);
    }

    /// @notice Function for updating fiAssets originating from vaults.
    ///
    /// @param  fiAsset The fiAsset to distribute yield earnings for.
    function rebase(
        address fiAsset
    )   external
        onlyAdmin
    {
        uint256 currentSupply = IERC20(fiAsset).totalSupply();
        if (currentSupply == 0) return;

        uint256 assets = LibVault._totalValue(s.vault[fiAsset]);

        if (assets > currentSupply) {

            uint256 yield = assets - currentSupply;

            uint256 shareYield = yield.percentMul(1e4 - s.serviceFee[fiAsset]);

            IFiToken(fiAsset).changeSupply(currentSupply + shareYield);

            if (yield - shareYield > 0)
                LibToken._mint(fiAsset, s.feeCollector, yield - shareYield);
        }
    }

    function rebaseOptIn(
        address fiAsset
    )   external
        onlyAdmin
    {
        IFiToken(fiAsset).rebaseOptIn();
    }

    function rebaseOptOut(
        address fiAsset
    )   external
        onlyAdmin
    {
        IFiToken(fiAsset).rebaseOptOut();
    }

    /// @notice Returns the total number of points accrued for a given account
    ///         (accrued through yield earnings and other means).
    ///
    /// @param  account     The address to enquire for.
    /// @param  fiAssets    An array of fiAssets to retrieve data for.
    function getPoints(
        address             account,
        address[] memory    fiAssets
    )   public
        view
        returns (uint256 pointsTotal)
    {
        pointsTotal = getYieldPoints(account, fiAssets) + s.XPC[account];
    }

    /// @notice Returns the number of points accrued, through yield earnings, across
    ///         a given number of fiAssets (e.g., [COFI, COFIE]).
    ///
    /// @param  account     The address to enquire for.
    /// @param  fiAssets    An array of fiAssets to retrieve data for.
    function getYieldPoints(
        address             account,
        address[] memory    fiAssets
    )   public
        view
        returns (uint256 pointsTotal)
    {
        uint256 yield;
        uint256 pointsCaptured;
        uint256 pointsPending;

        for(uint i = 0; i < fiAssets.length; ++i) {
            yield           += IFiToken(fiAssets[i]).getYieldEarned(account);
            pointsCaptured  += s.YPC[account][fiAssets[i]].points;
            pointsPending   += (yield - s.YPC[account][fiAssets[i]].yield)
                .percentMul(s.pointsRate[fiAssets[i]]);
            pointsTotal     += pointsCaptured + pointsPending;
        }
    }

    function getExternalPoints(
        address account
    )   public
        view
        returns (uint256)
    {
        return s.XPC[account];
    }

    /// @return The pointsRate denominated in basis points.
    function getPointsRate(
        address fiAsset
    )   external
        view
        returns (uint256)
    {
        return s.pointsRate[fiAsset];
    }
}