// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import { AppStorage, LibAppStorage } from "./LibAppStorage.sol";
import { PercentageMath } from "./external/PercentageMath.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
// import { IPermit2 } from "./../interfaces/IPermit2.sol";
import { IFiToken } from ".././interfaces/IFiToken.sol";
import 'hardhat/console.sol';

library LibToken {
    using PercentageMath for uint256;

    // IPermit2 constant PERMIT2 = IPermit2(0xEf1c6E67703c7BD7107eed8303Fbe6EC2554BF6B);

    /// @notice Emitted when a transfer is executed.
    ///
    /// @param  asset           The asset transferred (underlyingAsset, yieldAsset, or fiAsset).
    /// @param  amount          The amount transferred.
    /// @param  transferFrom    The account the asset was transferred from.
    /// @param  recipient       The recipient of the transfer.
    event Transfer(address indexed asset, uint256 amount, address indexed transferFrom, address indexed recipient);

    /// @notice Emitted when a fiAsset is minted.
    ///
    /// @param  fiAsset The address of the minted fiAsset.
    /// @param  amount  The amount of fiAssets minted.
    /// @param  to      The recipient of the minted fiAssets.
    event Mint(address indexed fiAsset, uint256 amount, address indexed to);

    /// @notice Emitted when a fiAsset is burned.
    ///
    /// @param  fiAsset The address of the burned fiAsset.
    /// @param  amount  The amount of fiAssets burned.
    /// @param  from    The account burned from.
    event Burn(address indexed fiAsset, uint256 amount, address indexed from);

    /// @notice Emitted when a fiAsset supply update is executed.
    ///
    /// @param  fiAsset The fiAsset with updated supply.
    /// @param  assets  The new total supply.
    /// @param  yield   The amount of yield added.
    event TotalSupplyUpdated(address indexed fiAsset, uint256 assets, uint256 yield);

    /// @notice Emitted when external points are distributed (not tied to yield).
    ///
    /// @param  account The recipient of the points.
    /// @param  amount  The amount of points distributed.
    event RewardDistributed(address indexed account, uint256 amount);

    /// @notice Emitted when a referral is executed.
    ///
    /// @param  referral    The account receiving the referral reward.
    /// @param  account     The account using the referral.
    /// @param  amount      The amount of points distributed to the referral account.
    event Referral(address indexed referral, address indexed account, uint256 amount);

    /// @notice Emitted when a mint fee is captured.
    ///
    /// @param  fiAsset The minted fiAsset.
    /// @param  amount  The mint fee amount captured in fiAssets.
    event MintFeeCaptured(address indexed fiAsset, uint256 amount);

    /// @notice Emitted when a redemption fee is captured.
    ///
    /// @param  fiAsset The redeemed fiAsset.
    /// @param  amount  The redeem fee amount captured in fiAssets.
    event RedeemFeeCaptured(address indexed fiAsset, uint256 amount);

    /// @notice Emitted when a service fee is captured from a yield distribution.
    ///
    /// @param  fiAsset The fiAsset to capture yield from.
    /// @param  amount  The service fee amount captured in fiAssets.
    event ServiceFeeCaptured(address indexed fiAsset, uint256 amount);

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
    )   internal {

        SafeERC20.safeTransferFrom(
            IERC20(asset),
            transferFrom,
            recipient,
            amount
        );
        emit Transfer(asset, amount, transferFrom, recipient);
    }

    // function _permitTransferFrom(
    //     uint256 amount,
    //     IPermit2.PermitTransferFrom calldata permit,
    //     address transferFrom,
    //     address recipient
    // ) internal {

    //     PERMIT2.permitTransferFrom(
    //         permit,
    //         IPermit2.SignatureTransferDetails({
    //             to: recipient,
    //             requestedAmount: amount
    //         }),
    //         transferFrom,
    //         abi.encode(
    //             keccak256(
    //                 "_permitTransferFrom(uint256 amount,struct IPermit2.PermitTransferFrom permit,address transferFrom,address recipient)"
    //             ),
    //             amount,
    //             permit,
    //             transferFrom,
    //             recipient
    //         )
    //     );
    //     emit Transfer(address(permit.permitted.token), amount, transferFrom, recipient);
    // }

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

        SafeERC20.safeTransfer(
            IERC20(asset),
            recipient,
            amount
        );
        emit Transfer(asset, amount, address(this), recipient);
    }

    /// @notice Executes a mint operation in the context of CoFi.
    ///
    /// @param  fiAsset The fiAsset to mint.
    /// @param  to      The account to mint to.
    /// @param  amount  The amount of fiAssets to mint.
    function _mint(
        address fiAsset,
        address to,
        uint256 amount
    ) internal {

        IFiToken(fiAsset).mint(to, amount);
        emit Mint(fiAsset, amount, to);
    }

    /// @notice Executes a burn operation in the context of CoFi.
    ///
    /// @param  fiAsset The fiAsset to burn.
    /// @param  from    The account to burn from.
    /// @param  amount  The amount of fiAssets to burn.
    function _burn(
        address fiAsset,
        address from,
        uint256 amount
    ) internal {

        IFiToken(fiAsset).burn(from, amount);
        emit Burn(fiAsset, amount, from);
    }

    /// @notice Calls redeem operation on FiToken contract.
    /// @dev    Skips approval check.
    function _redeem(
        address fiAsset,
        address from,
        uint256 amount
    ) internal {
        AppStorage storage s = LibAppStorage.diamondStorage();

        IFiToken(fiAsset).redeem(from, s.feeCollector, amount);
    }

    /// @notice Updates the total supply of the fiAsset.
    function _changeSupply(
        address fiAsset,
        uint256 amount,
        uint256 yield
    ) internal {
        
        IFiToken(fiAsset).changeSupply(amount);
        emit TotalSupplyUpdated(fiAsset, amount, yield);
    }

    /// @notice Returns the mint fee for a given fiAsset.
    ///
    /// @param  fiAsset The fiAsset to mint.
    /// @param  amount  The amount of fiAssets to mint.
    function _getMintFee(
        address fiAsset,
        uint256 amount
    ) internal view returns (uint256) {
        AppStorage storage s = LibAppStorage.diamondStorage();

        return amount.percentMul(s.mintFee[fiAsset]);
    }

    /// @notice Returns the redeem fee for a given fiAsset.
    ///
    /// @param  fiAsset The fiAsset to submit for redemption.
    /// @param  amount  The amount of fiAssets to submit for redemption.
    function _getRedeemFee(
        address fiAsset,
        uint256 amount
    ) internal view returns (uint256) {
        AppStorage storage s = LibAppStorage.diamondStorage();

        return amount.percentMul(s.redeemFee[fiAsset]);
    }

    /// @notice Opts contract into receiving rebases.
    ///
    /// @param  fiAsset The fiAsset to opt-in to rebases for.
    function _rebaseOptIn(
        address fiAsset
    ) internal {

        IFiToken(fiAsset).rebaseOptIn();
    }

    /// @notice Opts contract out of receiving rebases.
    ///
    /// @param  fiAsset The fiAsset to opt-out of rebases for.
    function _rebaseOptOut(
        address fiAsset
    ) internal {
        
        IFiToken(fiAsset).rebaseOptOut();
    }

    /// @notice Retrieves yield earned of fiAsset for account.
    ///
    /// @param  account The account to enquire for.
    /// @param  fiAsset The fiAsset to check account's yield for.
    function _getYieldEarned(
        address account,
        address fiAsset
    ) internal view returns (uint256) {
        
        return IFiToken(fiAsset).getYieldEarned(account);
    }
}