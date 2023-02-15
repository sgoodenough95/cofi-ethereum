// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

/**
    █▀▀ ▀▀█▀▀ █▀▀█ █▀▀█ 
    ▀▀█ ░░█░░ █░░█ █▄▄█ 
    ▀▀▀ ░░▀░░ ▀▀▀▀ ▀░░▀

    @author stoa.money
    @title  Exchange Facet
    @notice User-operated functions for exchanging between supported assets.
 */

import { Modifiers } from "../libs/LibAppStorage.sol";
import { LibToken } from "../libs/LibToken.sol";
import { LibTreasury } from "../libs/LibTreasury.sol";
import { IStoa } from "../interfaces/IStoa.sol";

contract ExchangeFacet is Modifiers {

    /// @notice Converts an accepted inputAsset into an activeAsset (e.g., USDC to USDSTA).
    ///
    /// @param  amount      The amount of inputAssets to deposit.
    /// @param  inputAsset  The address of the inputAsset.
    /// @param  activeAsset The activeAsset to receive.
    /// @param  depositFrom The address to deposit inputAssets from.
    /// @param  recipient   The recipient of the activeAssets.
    function inputToActive(
        uint256 amount,
        address inputAsset,
        address activeAsset,
        address depositFrom,
        address recipient
    ) external minDeposit(amount, inputAsset) returns (uint256 mintAfterFee) {

        require(LibToken._isValidInput(inputAsset, activeAsset) != 1, "ExchangeFacet: Invalid input");

        require(LibToken._isMintEnabled(activeAsset) != 1, "ExchangeFacet: Mint disabled");

        LibToken._transferFrom(inputAsset, amount, depositFrom, s.inputStore[inputAsset]);

        uint256 fee = LibToken._getMintFee(activeAsset, amount);
        mintAfterFee = amount - fee;

        LibToken._mint(activeAsset, recipient, mintAfterFee);

        if (fee > 0) {
           LibToken._mint(activeAsset, s.feeCollector, fee);
            emit LibToken.MintFeeCaptured(activeAsset, fee); 
        }
    }

    /// @notice Converts an accepted inputAsset into an activeAsset (e.g., USDC to USDSTA).
    /// @notice Mints a backing asset to Stoa (e.g., USDSTA).
    ///
    /// @param  amount          The amount of inputAssets to deposit.
    /// @param  inputAsset      The address of the inputAsset.
    /// @param  unactiveAsset   The unactiveAsset to receive.
    /// @param  depositFrom     The account to deposit inputAssets from.
    /// @param  recipient       The recipient of the unactiveAssets.
    function inputToUnactive(
        uint256 amount,
        address inputAsset,
        address unactiveAsset,
        address depositFrom,
        address recipient
    ) external minDeposit(amount, inputAsset) returns (uint256 mintAfterFee) {

        require(LibToken._isValidInput(inputAsset, unactiveAsset) != 1, "Exchange Facet: Invalid input");

        require(LibToken._isMintEnabled(unactiveAsset) != 1, "ExchangeFacet: Mint disabled");

        LibToken._transferFrom(inputAsset, amount, depositFrom, s.inputStore[inputAsset]);

        uint256 fee = LibToken._getMintFee(unactiveAsset, amount);
        mintAfterFee = amount - fee;

        LibToken._mint(s.backingAsset[unactiveAsset], address(this), mintAfterFee);

        LibTreasury._adjustBackingReserve(
            s.backingAsset[unactiveAsset],
            int256(mintAfterFee)
        );

        LibToken._mint(unactiveAsset, recipient, mintAfterFee);

        LibTreasury._adjustUnactiveRedemptionAllowance(
            unactiveAsset,
            depositFrom,
            int256(amount)
        );

        if (fee > 0) {
           LibToken._mint(s.backingAsset[unactiveAsset], s.feeCollector, fee);
            emit LibToken.MintFeeCaptured(s.backingAsset[unactiveAsset], fee); 
        }
    }

    /// @notice Converts an activeAsset to its unactiveAsset counterpart (e.g., USDSTA to USDST).
    /// @notice Increases the unactive redemption allowance of the recipient account.
    /// @notice Only consider the risk-free activeAsset (e.g., USDSTA, not USDFI).
    ///
    /// @param  amount      The amount of activeAssets to convert.
    /// @param  activeAsset The activeAsset to convert.
    /// @param  depositFrom The account to deposit the activeAssets from.
    /// @param  recipient   The recipient of the unactiveAssets.
    function activeToUnactive(
        uint256 amount,
        address activeAsset,
        address depositFrom,
        address recipient
    ) external minDeposit(amount, activeAsset) {
        address unactiveAsset = s.convertEnabled[activeAsset];

        require(LibToken._isMintEnabled(unactiveAsset) != 1, "ExchangeFacet: Mint disabled");

        LibToken._transferFrom(activeAsset, amount, depositFrom, address(this));

        LibTreasury._adjustBackingReserve(
            s.backingAsset[unactiveAsset],
            int256(amount)
        );

        LibToken._mint(unactiveAsset, recipient, amount);

        LibTreasury._adjustUnactiveRedemptionAllowance(
            unactiveAsset,
            depositFrom,
            int256(amount)
        );
    }

    /// @notice Converts an unactiveAsset to its activeAsset counterpart (e.g., USDST to USDSTA).
    /// @notice Caller must have a sufficient unactive redemption allowance.
    ///
    /// @param  amount          The amount of unactiveAssets to convert.
    /// @param  unactiveAsset   The unactiveAsset to convert.
    /// @param  depositFrom     The account to deposit unactiveAssets from.
    /// @param  recipient       The recipient of the activeAssets.
    function unactiveToActive(
        uint256 amount,
        address unactiveAsset,
        address depositFrom,
        address recipient
    ) external minDeposit(amount, unactiveAsset) {
        address activeAsset = s.convertEnabled[unactiveAsset];

        require(LibToken._isMintEnabled(activeAsset) != 1, "ExchangeFacet: Mint disabled");

        require(
            int256(amount) > s.unactiveRedemptionAllowance[depositFrom][unactiveAsset],
            "ExchangeFacet: Invalid unactive redemption allowance"
        );

        LibToken._burn(unactiveAsset, depositFrom, amount);

        LibTreasury._adjustBackingReserve(
            s.backingAsset[unactiveAsset],
            int256(amount) * -1
        );

        LibToken._transfer(activeAsset, amount, recipient);

        LibTreasury._adjustUnactiveRedemptionAllowance(
            unactiveAsset,
            depositFrom,
            int256(amount) * -1
        );
    }

    /// @notice Redeems an activeAsset for an inputAsset.
    /// @dev    Caller does not get to select inputAsset.
    ///
    /// @param  amount      The amount of activeAssets to redeem.
    /// @param  activeAsset The activeAsset to redeem.
    /// @param  depositFrom The account to deposit activeAssets from.
    /// @param  recipient   The recipient of the inputAssets.
    function redeemActive(
        uint256 amount,
        address activeAsset,
        address depositFrom,
        address recipient
    ) external minWithdraw(amount, activeAsset) returns (uint256 burnAfterFee) {

        LibToken._transferFrom(activeAsset, amount, depositFrom, s.feeCollector);

        uint256 fee = LibToken._getRedeemFee(activeAsset, amount);
        burnAfterFee = amount - fee;

        LibToken._burn(activeAsset, s.feeCollector, burnAfterFee);
        if (fee > 0) {
            emit LibToken.RedeemFeeCaptured(activeAsset, fee);
        }

        address inputAsset = LibToken._getRedeemAsset(activeAsset);

        LibToken._transferFrom(
            inputAsset,
            burnAfterFee,
            s.inputStore[inputAsset],
            recipient
        );
    }

    /// @notice Redeems an unactiveAsset for an inputAsset.
    /// @dev    Caller does not get to select inputAsset.
    ///
    /// @param  amount          The amount of activeAssets to redeem.
    /// @param  unactiveAsset   The activeAsset to redeem.
    /// @param  depositFrom     The account to deposit activeAssets from.
    /// @param  recipient       The recipient of the inputAssets.
    function redeemUnactive(
        uint256 amount,
        address unactiveAsset,
        address depositFrom,
        address recipient
    ) external minWithdraw(amount, unactiveAsset) returns (uint256 burnAfterFee) {

        LibToken._burn(unactiveAsset, depositFrom, amount);

        address activeAsset = s.convertEnabled[unactiveAsset];

        uint256 fee = LibToken._getRedeemFee(activeAsset, amount);
        burnAfterFee = amount - fee;

        LibToken._burn(activeAsset, address(this), amount);

        address inputAsset = LibToken._getRedeemAsset(activeAsset);

        LibToken._transferFrom(
            inputAsset,
            burnAfterFee,
            s.inputStore[inputAsset],
            recipient
        );

        LibTreasury._adjustUnactiveRedemptionAllowance(
            unactiveAsset,
            depositFrom,
            int256(amount) * -1
        );

        LibTreasury._adjustBackingReserve(
            s.backingAsset[unactiveAsset],
            int256(amount) * -1
        );
        if (fee > 0) {
            // Redeem fee captured in the (previously backing) activeAsset.
            emit LibToken.RedeemFeeCaptured(activeAsset, fee);
        }
    }
}