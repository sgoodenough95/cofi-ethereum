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
import { LibReward } from '../libs/LibReward.sol';
import { LibVault } from '../libs/LibVault.sol';
import { IERC4626 } from '../interfaces/IERC4626.sol';
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import 'hardhat/console.sol';

contract RewardFacet is Modifiers {
    using PercentageMath for uint256;

    /// @notice Function for updating fiAssets originating from vaults.
    ///
    /// @param  fiAsset The fiAsset to distribute yield earnings for.
    function rebase(
        address fiAsset
    )   public
        returns (uint256 assets, uint256 yield, uint256 shareYield)
    {
        require(
            s.isUpkeep[msg.sender] == 1 || s.isAdmin[msg.sender] == 1,
            'RewardFacet: Caller not Upkeep or Admin'
        );
        uint256 currentSupply = IERC20(fiAsset).totalSupply();
        if (currentSupply == 0) {
            emit LibToken.TotalSupplyUpdated(fiAsset, 0, 0, 1e18);
            return (0, 0, 0); 
        }

        assets = LibVault._totalValue(s.vault[fiAsset]);

        if (assets > currentSupply) {

            yield = assets - currentSupply;

            shareYield = yield.percentMul(1e4 - s.serviceFee[fiAsset]);

            LibToken._changeSupply(fiAsset, currentSupply + shareYield, yield);

            if (yield - shareYield > 0) {
                LibToken._mint(fiAsset, s.feeCollector, yield - shareYield);
                emit LibToken.ServiceFeeCaptured(fiAsset, yield - shareYield);
            }
        } else {
            emit LibToken.TotalSupplyUpdated(
                fiAsset,
                assets,
                0,
                LibToken._getRebasingCreditsPerToken(fiAsset)
            );
            return (assets, 0, 0);
        }
    }

    // add deriv rebase

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
    function captureYieldPoints(
        address[] memory    accounts,
        address             fiAsset
    )   external
        returns (bool)
    {
        /**
            POINTS CAPTURE:

            1.  Gets current yield earned.
            2.  If greater than previous yield earned, apply points
                for difference.
            3.  Update yield earned.

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
        yield = LibToken._getYieldEarned(accounts[i], fiAsset);
            // If the account has earned yield since the last yield capture event.
            if (s.YPC[accounts[i]][fiAsset].yield < yield) {
                s.YPC[accounts[i]][fiAsset].points +=
                    (yield - s.YPC[accounts[i]][fiAsset].yield)
                        .percentMul(s.pointsRate[fiAsset]);
                s.YPC[accounts[i]][fiAsset].yield = yield;
            }
        }
        return true;
    }

    /// @notice Function for migrating to a new Vault. The new Vault must support the
    ///         same underlyingAsset (e.g., USDC).
    ///
    /// @dev    Ensure that a buffer of the underlyingAsset resides in the Diamond
    ///         beforehand to account for slippage.
    ///
    /// @param  fiAsset     The fiAsset to migrate vault backing for.
    /// @param  newVault    The vault to migrate to (must adhere to ERC4626).
    function migrateVault(
        address fiAsset,
        address newVault
    )   external
        returns (bool)
    {
        require(
            s.isUpkeep[msg.sender] == 1 || s.isAdmin[msg.sender] == 1,
            'RewardFacet: Caller not Upkeep or Admin'
        );
        // Pull funds from old vault.
        uint256 assets = IERC4626(s.vault[fiAsset]).redeem(
            IERC20(s.vault[fiAsset]).balanceOf(address(this)),
            address(this),
            address(this)
        );

        // Approve newVault spend for Diamond.
        IERC20(IERC4626(s.vault[fiAsset]).asset())
            .approve(newVault, assets + s.buffer[fiAsset]);

        // Deploy funds to new vault.
        LibVault._wrap(
            assets + s.buffer[fiAsset],
            newVault,
            address(this)
        );

        require(
            assets <= LibVault._totalValue(newVault),
            'AdminFacet: Vault migration slippage exceeded'
        );
        emit LibVault.VaultMigration(
            fiAsset,
            s.vault[fiAsset],
            newVault,
            assets,
            LibVault._totalValue(newVault)
        );

        // Update vault for fiAsset.
        s.vault[fiAsset] = newVault;

        rebase(fiAsset);

        return true;
    }

    function setBuffer(
        address fiAsset,
        uint256 buffer
    )   external
        onlyAdmin
        returns (bool)
    {
        s.buffer[fiAsset] = buffer;
        return true;
    }

    /// @dev Only for setting up a new fiAsset. 'migrateVault()' must be used otherwise.
    function setVault(
        address fiAsset,
        address vault
    )   external
        onlyAdmin
        returns (bool)
    {
        require(
            s.vault[fiAsset] == address(0),
            'RewardFacet: fiAsset must not already link with a Vault'
        );
        s.vault[fiAsset] = vault;
        return true;
    }

    /// @dev    Yield points must be captured beforehand to ensure they
    ///         have updated correctly prior to a pointsRate change.
    function setPointsRate(
        address fiAsset,
        uint256 amount
    )   external
        onlyAdmin
        returns (bool)
    {
        s.pointsRate[fiAsset] = amount;
        return true;
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
        returns (bool)
    {
        for(uint i = 0; i < accounts.length; ++i) {
            LibReward._reward(accounts[i], points);
        }
        return true;
    }

    /// @dev Setting to 0 deactivates.
    function setInitReward(
        uint256 amount
    )   external
        onlyAdmin
        returns (bool)
    {
        s.initReward = amount;
        return true;
    }

    /// @dev Setting to 0 deactivates.
    function setReferReward(
        uint256 amount
    )   external
        onlyAdmin
        returns (bool)
    {
        s.referReward = amount;
        return true;
    }

    function setRewardStatus(
        address account,
        uint8   initClaimed,
        uint8   referClaimed,
        uint8   referDisabled
    )   external
        onlyAdmin
        returns (bool)
    {
        s.rewardStatus[account].initClaimed     = initClaimed;
        s.rewardStatus[account].referClaimed    = referClaimed;
        s.rewardStatus[account].referDisabled   = referDisabled;
        return true;
    }

    function rebaseOptIn(
        address fiAsset
    )   external
        onlyAdmin
        returns (bool)
    {
        LibToken._rebaseOptIn(fiAsset);
        return true;
    }

    function rebaseOptOut(
        address fiAsset
    )   external
        onlyAdmin
        returns (bool)
    {
        LibToken._rebaseOptOut(fiAsset);
        return true;
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
            yield           += LibToken._getYieldEarned(account, fiAssets[i]);
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

    function getInitReward(
    )   external
        view
        returns (uint256)
    {
        return s.initReward;
    }

    function getReferReward(
    )   external
        view
        returns (uint256)
    {
        return s.referReward;
    }

    function getRewardStatus(
        address account
    )   external
        view
        returns (uint8, uint8, uint8)
    {
        return (
            s.rewardStatus[account].initClaimed,
            s.rewardStatus[account].referClaimed,
            s.rewardStatus[account].referDisabled
        );
    }
}