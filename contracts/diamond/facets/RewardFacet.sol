// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

/**

    ╭━━━╮╱╱╭━━━╮
    ┃╭━╮┃╱╱┃╭━━╯
    ┃┃╱╰╋━━┫╰━━┳╮
    ┃┃╱╭┫╭╮┃╭━━╋┫
    ┃╰━╯┃╰╯┃┃╱╱┃┃
    ╰━━━┻━━┻╯╱╱╰╯

    @author cofi.money
    @title  Reward Facet
    @notice Provides logic for distributing and handling rewards, such as yield and points.
 */

import { Modifiers } from "../libs/LibAppStorage.sol";
import { PercentageMath } from "../libs/external/PercentageMath.sol";
import { LibToken } from "../libs/LibToken.sol";
import { LibVault } from "../libs/LibVault.sol";
import { IFiToken } from "../interfaces/IFiToken.sol";
import { IERC20 } from '@openzeppelin/contracts/interfaces/IERC20.sol';
import { IERC4626 } from "../interfaces/IERC4626.sol";
import { GPv2SafeERC20 } from ".././libs/external/GPv2SafeERC20.sol";

contract RewardFacet is Modifiers {
    using PercentageMath for uint256;
    using GPv2SafeERC20 for IERC20;

    function getPoints(
        address account,
        address fiAsset
    )   external
        view
        returns (uint256)
    {
        uint256 yield = IFiToken(fiAsset).getYieldEarned(account);

        uint256 capturedPoints = s.pointsCapture[account][fiAsset].points;

        uint256 pendingPoints = (yield - s.pointsCapture[account][fiAsset].yield)
            .percentMul(s.pointsRate[fiAsset]);

        return capturedPoints + pendingPoints;
    }

    function capturePoints(
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
        if (s.pointsCapture[account][fiAsset].yield < yield) {
            s.pointsCapture[account][fiAsset].points +=
                (yield - s.pointsCapture[account][fiAsset].yield)
                    .percentMul(s.pointsRate[fiAsset]);
            s.pointsCapture[account][fiAsset].yield  = yield;
        }
    }

    /// @notice This function must be called after the last rebase of a pointsRate
    ///         and before the application of a new pointsRate for a given fiAsset,
    ///         for every account that is eliigble for yield/points.
    ///
    /// @dev    This function may be required to be called multiple times, as per the
    ///         size limit for passing addresses, in order for all relevant accounts
    ///         to be updated.
    ///
    /// @param  accounts    The array of accounts to capture points for.
    /// @param  fiAsset     The fiAsset to capture points for.
    function batchCapturePoints(
        address[] memory    accounts,
        address             fiAsset
    )   external
    {
        uint256 yield;
        for(uint i = 0; i < accounts.length; ++i) {
        yield = IFiToken(fiAsset).getYieldEarned(accounts[i]);
            if (s.pointsCapture[accounts[i]][fiAsset].yield < yield) {
                s.pointsCapture[accounts[i]][fiAsset].points +=
                    (yield - s.pointsCapture[accounts[i]][fiAsset].yield)
                        .percentMul(s.pointsRate[fiAsset]);
                s.pointsCapture[accounts[i]][fiAsset].yield = yield;
            }
        }
    }

    /// @notice Function for migrating to a new Vault. The new Vault must support the
    ///         same inputAsset (e.g., DAI).
    ///
    /// @dev    Will only ever be called as part of a migration script, and therefore
    ///         requires that the relevant functions are called before and after.
    ///
    /// @param  fiAsset     The fiAsset to migrate vault backing for.
    /// @param  newVault    The vault to migrate to (must adhere to ERC4626).
    /// @param  buffer      An additional amount of inputAssets supplied by the caller to
    ///                     ensure the migration does not result in loss of funds from slippage.
    function migrateVault(
        address fiAsset,
        address newVault,
        uint256 buffer
    )   external
        onlyAdmin()
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

        // Transfer buffer.
        IERC20(IERC4626(s.vault[fiAsset]).asset())
            .safeTransferFrom(msg.sender, address(this), buffer);

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

            1.  Call 'changeSupply()' passing new supply.
            2.  Call 'rebase()'.
            3.  Enable minting/redeeming.
         */
    }

    /// @notice 'changeSupply()' is commented out, but left for reference.
    ///         For the Stoa stablecoin product, an Admin will call changeSupply() directly.
    ///         For the COFIMoney MVP, however, this will not be the case.
    ///
    // /// @notice Function for manually changing the supply of a fiAsset.
    // ///
    // /// @dev    'rebase()' must be called after for change to take effect.
    // ///
    // /// @param  fiAsset     The fiAsset to change supply for.
    // /// @param  newSupply   The new supply of fiAssets (not accounting for CoFi's yield share).
    // function changeSupply(
    //     address fiAsset,
    //     uint256 newSupply
    // )   external
    //     onlyAdmin()
    // {
    //     IFiToken(fiAsset).changeSupply(newSupply);
    // }

    /// @notice Function for updating fiAssets originating from vaults.
    ///
    /// @param  fiAsset The fiAsset to distribute rewards for.
    function rebase(
        address fiAsset
    )   external
        onlyAdmin()
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
        onlyAdmin()
    {
        IFiToken(fiAsset).rebaseOptIn();
    }

    function rebaseOptOut(
        address fiAsset
    )   external
        onlyAdmin()
    {
        IFiToken(fiAsset).rebaseOptOut();
    }
}