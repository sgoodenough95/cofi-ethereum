// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import { AppStorage, LibAppStorage } from "./LibAppStorage.sol";
import { PercentageMath } from "./external/PercentageMath.sol";
import { IERC20 } from '@openzeppelin/contracts/interfaces/IERC20.sol';
import { GPv2SafeERC20 } from "./external/GPv2SafeERC20.sol";
import { IStoaToken } from ".././interfaces/IStoaToken.sol";

library LibToken {
    using PercentageMath for uint256;
    using GPv2SafeERC20 for IERC20;

    /// @notice Emitted when a transfer is executed.
    ///
    /// @param  asset           The asset transferred.
    /// @param  amount          The amount transferred.
    /// @param  transferFrom    The account the asset was transferred from.
    /// @param  recipient       The recipient of the transfer.
    event Transfer(address asset, uint256 amount, address transferFrom, address recipient);

    /// @notice Emitted when a token is minted.
    ///
    /// @param  asset   The address of the minted token.
    /// @param  amount  The amount of tokens minted.
    /// @param  to      The recipient of the minted tokens.
    event Mint(address asset, uint256 amount, address to);

    /// @notice Emitted when a token is minted.
    ///
    /// @param  asset   The address of the minted token.
    /// @param  amount  The amount of tokens minted.
    /// @param  from    The recipient of the minted tokens.
    event Burn(address asset, uint256 amount, address from);

    /// @notice Emitted when a mint fee is captured.
    ///
    /// @param  asset   The minted asset.
    /// @param  amount  The fee amount captured.
    event MintFeeCaptured(address asset, uint256 amount);

    /// @notice Emitted when a redemption fee is captured.
    ///
    /// @param  asset   The asset submitted for redemption.
    /// @param  amount  The fee amount captured.
    event RedeemFeeCaptured(address asset, uint256 amount);

    // /// @notice Indicates an operation failed because the deposit amount is not accepted.
    // ///
    // /// @param  asset   The address of the asset.
    // /// @param  amount  The amount of assets.
    // error InvalidDeposit(address asset, uint256 amount);

    // /// @notice Indicates an operation failed because the deposit amount is not accepted.
    // ///
    // /// @param  asset   The address of the asset submitted for withdrawing (not the withdrawn asset).
    // /// @param  amount  The amount of assets.
    // error InvalidWithdraw(address asset, uint256 amount);

    // /// @notice Indicates if a token is unavailable for minting.
    // ///
    // /// @param  asset   The asset to mint.
    // error MintDisabled(address asset);

    // /// @notice Indicates if an operation failed because the account has an inavlid unactive redemption allowance.
    // ///
    // /// @param  account The account attempting to redeem for.
    // /// @param  asset   The unactiveAsset to be redeemed.
    // /// @param  amount  The amount of unactiveAssets.
    // error InvalidUnactiveRedemptionAllowance(address account, address asset, uint256 amount);

    /// @notice Executes a transferFrom operation in the context of Stoa.
    ///
    /// @param  asset           The asset to transfer.
    /// @param  amount          The amount to transfer.
    /// @param  transferFrom    The account to transfer from, must have approved spender.
    /// @param  recipient       The recipient of the transfer.
    function _transferFrom(
        address asset,
        uint256 amount,
        address transferFrom,
        address recipient
    ) internal {

        IERC20(asset).safeTransferFrom(
            transferFrom,
            recipient,
            amount
        );
        emit Transfer(asset, amount, transferFrom, recipient);
    }

    /// @notice Executes a transfer operation in the context of Stoa.
    ///
    /// @param  asset       The asset to transfer.
    /// @param  amount      The amount to transfer.
    /// @param  recipient   The recipient of the transfer.
    function _transfer(
        address asset,
        uint256 amount,
        address recipient
    ) internal {

        IERC20(asset).safeTransfer(
            recipient,
            amount
        );
        emit Transfer(asset, amount, address(this), recipient);
    }

    /// @notice Executes a mint operation in the context of Stoa.
    ///
    /// @param  asset   The asset to mint.
    /// @param  to      The account to mint to.
    /// @param  amount  The amount of assets to mint.
    function _mint(
        address asset,
        address to,
        uint256 amount
    ) internal {

        IStoaToken(asset).mint(to, amount);
        emit Mint(asset, amount, to);
    }

    /// @notice Executes a burn operation in the context of Stoa.
    ///
    /// @param  asset   The asset to burn.
    /// @param  from    The account to burn from.
    /// @param  amount  The amount of assets to burn.
    function _burn(
        address asset,
        address from,
        uint256 amount
    ) internal {

        IStoaToken(asset).burn(from, amount);
        emit Burn(asset, amount, from);
    }

    /// @notice Opts contract into receiving rebases.
    function _rebaseOptIn(
        address asset
    ) internal {

        IStoaToken(asset).rebaseOptIn();
    }

    /// @notice Opts contract out of receiving rebases.
    function _rebaseOptOut(
        address asset
    ) internal {
        
        IStoaToken(asset).rebaseOptOut();
    }

    /// @notice Indicates if an asset is available for minting.
    ///
    /// @param  asset   The asset to mint.
    function _isMintEnabled(
        address asset
    ) internal view returns (uint8) {
        AppStorage storage s = LibAppStorage.diamondStorage();

        return s.mintEnabled[asset];
    }

    /// @notice Indicates if an asset is available for minting.
    ///
    /// @param  asset   The asset to mint.
    function _isRedeemEnabled(
        address asset
    ) internal view returns (uint8) {
        AppStorage storage s = LibAppStorage.diamondStorage();

        return s.mintEnabled[asset];
    }

    /// @notice Returns the mint fee for a given asset.
    ///
    /// @param  asset   The asset to mint.
    /// @param  amount  The amount of assets to mint.
    function _getMintFee(
        address asset,
        uint256 amount
    ) internal view returns (uint256) {
        AppStorage storage s = LibAppStorage.diamondStorage();

        return amount.percentMul(s.mintFee[asset]);
    }

    /// @notice Returns the redeem fee for a given asset.
    ///
    /// @param  asset   The asset to submit for redemption.
    /// @param  amount  The amount of assets to submit for redemption.
    function _getRedeemFee(
        address asset,
        uint256 amount
    ) internal view returns (uint256) {
        AppStorage storage s = LibAppStorage.diamondStorage();

        return amount.percentMul(s.redeemFee[asset]);
    }

    /// @notice Indicates if the input token is accepted to mint a specific asset for in return.
    ///
    /// @param  inputAsset  The asset to input (e.g., USDC).
    /// @param  activeAsset       The asset to be returned for the input asset (e.g., USDSTA).
    function _isValidActiveInput(
        address inputAsset,
        address activeAsset   // (?)
    ) internal view returns (uint8) {
        AppStorage storage s = LibAppStorage.diamondStorage();

        for (uint i = 0; i < s.activeInputs[inputAsset].length; i++) {
            if (s.activeInputs[activeAsset][i] == inputAsset) return 1;
        }
        return 0;
    }

    /// @notice Returns an array of accepted input assets for a given asset (e.g., [DAI, USDC]).
    ///
    /// @param  activeAsset The inputAsset to enquire for.
    function _getActiveInputs(
        address activeAsset
    ) internal view returns (address[] memory) {
        AppStorage storage s = LibAppStorage.diamondStorage();

        return s.activeInputs[activeAsset];
    }

    /// @notice Returns the unactiveAsset for a given inputAsset (returns address(0) if no unactiveAsset set).
    ///
    /// @dev    May use in AdminFacet.
    ///
    /// @param  inputAsset  The inputAsset to enquire for.
    function _getUnactiveFromInput(
        address inputAsset
    ) internal view returns (address) {
        AppStorage storage s = LibAppStorage.diamondStorage();

        return s.inputToUnactive[inputAsset];
    }

    /// @notice Returns the inputAsset to service a redemption.
    /// @dev    MVP will only provide first asset in inputs array.
    /// @dev    Will later expand with more custom logic.
    ///
    /// @param  activeAsset The asset to submit for redemption.
    function _getRedeemAsset(
        address activeAsset
    ) internal view returns (address) {
        AppStorage storage s = LibAppStorage.diamondStorage();

        return s.activeInputs[activeAsset][0];
    }
}