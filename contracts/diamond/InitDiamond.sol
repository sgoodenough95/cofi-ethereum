// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { AppStorage } from "./libs/LibAppStorage.sol";
import { LibDiamond } from "./core/libs/LibDiamond.sol";
import { LibToken } from "./libs/LibToken.sol";
import { IERC165 } from "./core/interfaces/IERC165.sol";
import { IERC20 } from '@openzeppelin/contracts/interfaces/IERC20.sol';
import { IDiamondCut } from "./core/interfaces/IDiamondCut.sol";
import { IDiamondLoupe } from "./core/interfaces/IDiamondLoupe.sol";
import { IERC173 } from "./core/interfaces/IERC173.sol";

contract InitDiamond {
    AppStorage internal s;

    struct Args {
        address     COFI;   // fiAsset [USD]
        // address     ETHFI;  // fiAsset [ETH]
        // address     BTCFI;  // fiAsset [BTC]
        address     vUSDC;  // yieldAsset [USD]
        // address     vETH;   // yieldAsset [ETH]
        // address     vBTC;   // yieldAsset [BTC]
        address     USDC;
        // address[]   admins;
        address feeCollector;
    }
    
    function init(Args memory _args) external {

        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();

        // Adding ERC165 data.
        ds.supportedInterfaces[type(IERC165).interfaceId]       = true;
        ds.supportedInterfaces[type(IDiamondCut).interfaceId]   = true;
        ds.supportedInterfaces[type(IDiamondLoupe).interfaceId] = true;
        ds.supportedInterfaces[type(IERC173).interfaceId]       = true;

        s.underlying[_args.COFI] = _args.USDC;

        s.derivParams[_args.vUSDC].toDeriv = bytes4(keccak256("toDeriv_HOPUSDCLP(uint256)"));
        s.derivParams[_args.vUSDC].toUnderlying = bytes4(keccak256("toUnderlying_HOPUSDCLP(uint256)"));
        s.derivParams[_args.vUSDC].convertToUnderlying = bytes4(keccak256("convertToUnderlying_HOPUSDCLP(uint256)"));
        s.derivParams[_args.vUSDC].convertToDeriv = bytes4(keccak256("convertToDeriv_HOPUSDCLP(uint256)"));

        // Rebase opt-in.
        LibToken._rebaseOptIn(_args.COFI);
        // LibToken._rebaseOptIn(_args.ETHFI);
        // LibToken._rebaseOptIn(_args.BTCFI);

        // Set min deposit/withdraw values.
        s.minDeposit[_args.COFI]     = 20e6;    // 20 USDC [6 digits].
        // s.minDeposit[_args.ETHFI]    = 1e16;     // 0.01 ETH [18 digits].
        // s.minDeposit[_args.BTCFI]    = 1e5;     // 0.001 BTC [8 digits].
        s.minWithdraw[_args.COFI]    = 20e6;    // 20 USDC.
        // s.minWithdraw[_args.ETHFI]   = 1e16;     // 0.01 ETH.
        // s.minWithdraw[_args.BTCFI]   = 1e5;     // 0.001 BTC.

        s.vault[_args.COFI]     = _args.vUSDC;
        // s.vault[_args.ETHFI]    = _args.vETH;
        // s.vault[_args.BTCFI]    = _args.vBTC;

        // Set mint enabled.
        s.mintEnabled[_args.COFI]   = 1;
        // s.mintEnabled[_args.ETHFI]  = 1;
        // s.mintEnabled[_args.BTCFI]  = 1;

        // Set mint fee.
        s.mintFee[_args.COFI]   = 10;
        // s.mintFee[_args.ETHFI]  = 10;
        // s.mintFee[_args.BTCFI]  = 10;

        // Set redeem enabled.
        s.redeemEnabled[_args.COFI]     = 1;
        // s.redeemEnabled[_args.ETHFI]    = 1;
        // s.redeemEnabled[_args.BTCFI]    = 1;

        // Set redeem fee.
        s.redeemFee[_args.COFI]     = 10;
        // s.redeemFee[_args.ETHFI]    = 10;
        // s.redeemFee[_args.BTCFI]    = 10;

        // Set service fee.
        s.serviceFee[_args.COFI]    = 1e3;
        // s.serviceFee[_args.ETHFI]   = 1e3;
        // s.serviceFee[_args.BTCFI]   = 1e3;

        // Set points rate.
        s.pointsRate[_args.COFI]    = 1e6;  // 100 points/1.0 COFI earned.
        // s.pointsRate[_args.ETHFI]   = 1e9;  // 100 points/0.001 ETHFI earned.
        // s.pointsRate[_args.BTCFI]   = 1e10; // 100 points/0.0001 BTCFI earned.

        // Set feeCollector.
        s.feeCollector = _args.feeCollector;

        s.isAdmin[msg.sender] = 1;
        s.isAdmin[_args.COFI] = 1;
        // s.isAdmin[_args.ETHFI] = 1;
        // s.isAdmin[_args.BTCFI] = 1;
        s.isWhitelisted[msg.sender] = 1;
        s.isWhitelisted[_args.feeCollector] = 1;

        s.initReward = 100*10**18;  // 100 Points for initial deposit.
        s.referReward = 10*10**18;  // 10 Points each for each referral.

        s.buffer[_args.COFI]    = 100*10**18;   // 100 USDC buffer for migrations.
        // s.buffer[_args.ETHFI]   = 1*10**17;     // 0.1 wETH buffer for migrations.
        // s.buffer[_args.BTCFI]   = 1*10**16;     // 0.01 wBTC buffer for migrations.

        s.decimals[_args.USDC] = 6;

        // Set admins.
        // for(uint i = 1; i < _args.admins.length; ++i) {
        //     s.isAdmin[_args.admins[i]] = 1;
        //     s.isWhitelisted[_args.admins[i]] = 1;
        // }
    }
}