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
// import { IPermit2, IERC20 } from "../interfaces/IPermit2.sol";
import "hardhat/console.sol";

contract ExchangeFacet is Modifiers {

    /// @notice Converts an accepted inputAsset into an activeAsset (e.g., USDC to USDSTA).
    /// @dev    Permit2 functionality left for reference.
    /// @dev    inputAsset derived from permit.
    ///
    /// @param  amount      The amount of inputAssets to deposit.
    /// @param  inputAsset  The address of the inputAsset.
    /// @param  activeAsset The activeAsset to receive. Must choose one from potential 1+ options (e.g., USDFI, USDSTA).
    /// @param  depositFrom The address to deposit inputAssets from.
    /// @param  recipient   The recipient of the activeAssets.
    function inputToActive(
        uint256 amount,
        // IPermit2.PermitTransferFrom calldata permit,
        address inputAsset,
        address activeAsset,
        address depositFrom,
        address recipient
    )   external
        minDeposit(
            amount,
            // address(permit.permitted.token)
            inputAsset
        )
        nonReentrant()
        returns (uint256 mintAfterFee)
    {
        // address inputAsset = address(permit.permitted.token);

        require(
            LibToken._isValidActiveInput(inputAsset, activeAsset) == 1,
            "ExchangeFacet: Invalid input"
        );

        require(
            LibToken._isMintEnabled(activeAsset) == 1,
            "ExchangeFacet: Mint disabled"
        );

        LibToken._transferFrom(inputAsset, amount, depositFrom, address(this));

        // LibToken._permitTransferFrom(
        //     amount,
        //     permit,
        //     depositFrom,
        //     recipient
        // );

        uint256 fee = LibToken._getMintFee(activeAsset, amount);
        mintAfterFee = amount - fee;

        LibToken._mint(activeAsset, recipient, mintAfterFee);

        if (fee > 0) {
           LibToken._mint(activeAsset, s.feeCollector, fee);
            emit LibToken.MintFeeCaptured(activeAsset, fee); 
        }
    }

    /// @notice Converts an accepted inputAsset into a creditAsset (e.g., USDC to USDSC).
    /// @notice Mints the prime backing asset to Stoa (e.g., USDST).
    /// @dev    Only ONE creditAsset available given the inputAsset param.
    ///
    /// @param  amount          The amount of inputAssets to deposit.
    /// @param  inputAsset      The address of the inputAsset.
    /// @param  depositFrom     The account to deposit inputAssets from.
    /// @param  recipient       The recipient of the creditAssets.
    function inputToCredit(
        uint256 amount,
        address inputAsset,
        address depositFrom,
        address recipient
    ) external minDeposit(amount, inputAsset) returns (uint256 mintAfterFee) {
        // Returns address(0) if no creditAsset set.
        address creditAsset = s.inputToCredit[inputAsset];

        // Consequently, will fail here if no creditAsset set.
        require(LibToken._isMintEnabled(creditAsset) == 1, "ExchangeFacet: Mint disabled");

        LibToken._transferFrom(inputAsset, amount, depositFrom, address(this));

        uint256 fee = LibToken._getMintFee(creditAsset, amount);
        mintAfterFee = amount - fee;

        // (1)
        LibToken._mint(s.primeBacking[creditAsset], address(this), amount);

        // Capture 'fee' amount of USDST (as amount - fee is serving as backing).
        // Admin can claim at a future point to redeem fees [activeAssets].
        if (fee > 0) emit LibToken.MintFeeCaptured(s.primeBacking[creditAsset], fee);

        /**
            STEPS FOR ISSUING CREDIT

            1.  Obtain backing asset.
            1.  Increase the backing reserve.
            2.  Mint credit to the recipient.
            3.  Increase credit redemption allowance.
         */

        // Consequently, do not include fee in backing reserve.
        // (2)
        LibTreasury._adjustBackingReserve(
            s.primeBacking[creditAsset],
            mintAfterFee,
            1
        );

        // (3)
        LibToken._mint(creditAsset, recipient, mintAfterFee);

        // (4)
        LibTreasury._adjustCreditRedeemAllowance(
            s.primeBacking[creditAsset],
            depositFrom,
            mintAfterFee,
            1
        );
    }

    /// @notice Converts an activeAsset to its creditAsset counterpart (e.g., USDST to USDSC).
    /// @notice Increases the creditRedeemAllowance of the depositFrom account.
    /// @notice Only ONE creditAsset available per currency denomnination (e.g., USD => USDSC).
    ///
    /// @param  amount      The amount of activeAssets to convert.
    /// @param  activeAsset The activeAsset to convert.
    /// @param  depositFrom The account to deposit the activeAssets from.
    /// @param  recipient   The recipient of the creditAssets.
    function activeToCredit(
        uint256 amount,
        address activeAsset,
        address depositFrom,
        address recipient
    ) external minDeposit(amount, activeAsset) {
        // Returns address(0) if no creditAsset set (i.e., convert is NOT enabled).
        address creditAsset = s.activeConvertEnabled[activeAsset];

        // Consequently, will fail here if disabled.
        require(LibToken._isMintEnabled(creditAsset) == 1, "ExchangeFacet: Mint disabled");

        // (1)
        LibToken._transferFrom(activeAsset, amount, depositFrom, address(this));

        // (2)
        LibTreasury._adjustBackingReserve(
            activeAsset,
            amount,
            1
        );

        // (3)
        LibToken._mint(creditAsset, recipient, amount);

        // (4)
        LibTreasury._adjustCreditRedeemAllowance(
            activeAsset,
            depositFrom,
            amount,
            1
        );
    }

    /// @notice Converts a creditAsset to an accepted activeAsset.
    /// @notice Caller must have a sufficient creditRedeemAllowance.
    ///
    /// @param  amount      The amount of creditAssets to convert.
    /// @param  creditAsset The creditAsset to convert.
    /// @param  activeAsset The activeAsset to convert to.     
    /// @param  depositFrom The account to deposit creditAssets from.
    /// @param  recipient   The recipient of the activeAssets.
    function creditToActive(
        uint256 amount,
        address creditAsset,
        address activeAsset,
        address depositFrom,
        address recipient
    ) external minDeposit(amount, creditAsset) {

        require(
            s.creditConvertEnabled[creditAsset][activeAsset] == 1,
            "ExchangeFacet: Credit convert disabled"
        );

        // "Mint" can be thought of as bringing into circulation
        // (recall the activeAsset is already minted, and resides in backing reserves).
        require(LibToken._isMintEnabled(activeAsset) == 1, "ExchangeFacet: Mint disabled");

        require(
            amount >= s.creditRedeemAllowance[depositFrom][creditAsset],
            "ExchangeFacet: Invalid credit redemption allowance for activeAsset"
        );

         /**
            STEPS FOR REDEEMING CREDIT

            1.  Burn credit from depositFrom.
            1.  Decrease the backing reserve.
            2.  Transfer assets to the recipient.
            3.  Decrease credit redemption allowance.
         */       

        // (1)
        LibToken._burn(creditAsset, depositFrom, amount);

        // (2)
        LibTreasury._adjustBackingReserve(
            activeAsset,
            amount,
            0
        );

        // (3)
        LibToken._transfer(activeAsset, amount, recipient);

        // (4)
        LibTreasury._adjustCreditRedeemAllowance(
            activeAsset,
            depositFrom,
            amount,
            0
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

        // Need to perform a transferFrom operation to capture fee.
        LibToken._transferFrom(activeAsset, amount, depositFrom, s.feeCollector);

        uint256 fee = LibToken._getRedeemFee(activeAsset, amount);
        burnAfterFee = amount - fee;

        // Burn the amount for which is not captured as a fee.
        LibToken._burn(activeAsset, s.feeCollector, burnAfterFee);
        if (fee > 0) {
            emit LibToken.RedeemFeeCaptured(activeAsset, fee);
        }

        // Will fail here if attempting to redeem activeAsset originating from vault.
        address inputAsset = LibToken._getRedeemAsset(activeAsset);

        // Need to approve diamond spend for inputAsset.
        LibToken._transfer(
            inputAsset,
            burnAfterFee,
            recipient
        );
    }

    /// @notice Redeems a creditAsset for an inputAsset.
    /// @dev    Caller does not get to select inputAsset.
    /// @dev    Caller needs to specify activeAsset for which they have allowance.
    ///
    /// @param  amount      The amount of activeAssets to redeem.
    /// @param  creditAsset The creditAsset to redeem.
    /// @param  activeAsset The (backing) activeAsset to redeem through.
    /// @param  depositFrom The account to deposit activeAssets from.
    /// @param  recipient   The recipient of the inputAssets.
    function redeemCredit(
        uint256 amount,
        address creditAsset,
        address activeAsset,
        address depositFrom,
        address recipient
    ) external minWithdraw(amount, creditAsset) returns (uint256 burnAfterFee) {

        require(
            s.creditConvertEnabled[creditAsset][activeAsset] == 1,
            "ExchangeFacet: Credit convert disabled"
        );

        require(
            amount >= s.creditRedeemAllowance[depositFrom][creditAsset],
            "ExchangeFacet: Invalid credit redemption allowance"
        );

        // (1)
        LibToken._burn(creditAsset, depositFrom, amount);

        // Only consider redeem fee for activeAsset (the asset "actually" being redeemed).
        uint256 fee = LibToken._getRedeemFee(activeAsset, amount);
        burnAfterFee = amount - fee;

        // Retain 'fee' amount of activeAsset backing
        LibToken._burn(activeAsset, address(this), burnAfterFee);
        if (fee > 0) {
            // Redeem fee captured in the (previously backing) activeAsset.
            emit LibToken.RedeemFeeCaptured(activeAsset, fee);
        }

        // Will fail here if trying to redeem via an activeAsset minted from a vault deposit (e.g., USDFI).
        address inputAsset = LibToken._getRedeemAsset(activeAsset);

        // (2)
        LibTreasury._adjustBackingReserve(
            activeAsset,
            amount,
            0
        );

        // (3)
        LibToken._transfer(
            inputAsset,
            burnAfterFee,
            recipient
        );

        // (4)
        LibTreasury._adjustCreditRedeemAllowance(
            activeAsset,
            depositFrom,
            amount,
            0
        );
    }
}