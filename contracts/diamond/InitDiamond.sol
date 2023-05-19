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
        // address     fiETH;  // fiAsset [ETH]
        // address     fiBTC;  // fiAsset [BTC]
        address     vDAI;   // yieldAsset [USD]
        // address     vETH;   // yieldAsset [ETH]
        // address     vBTC;   // yieldAsset [BTC]
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

        // Rebase opt-in.
        LibToken._rebaseOptIn(_args.COFI);
        // LibToken._rebaseOptIn(_args.fiETH);
        // LibToken._rebaseOptIn(_args.fiBTC);

        // Set min deposit/withdraw values.
        s.minDeposit[_args.COFI]     = 20e18;    // 20 USD.
        // s.minDeposit[_args.fiETH]    = 1e16;     // 0.01 ETH.
        // s.minDeposit[_args.fiBTC]    = 1e15;     // 0.001 BTC.
        s.minWithdraw[_args.COFI]    = 20e18;    // 20 DAI.
        // s.minWithdraw[_args.fiETH]   = 1e16;     // 0.01 ETH.
        // s.minWithdraw[_args.fiBTC]   = 1e15;     // 0.001 BTC.

        s.vault[_args.COFI]     = _args.vDAI;
        // s.vault[_args.fiETH]    = _args.vETH;
        // s.vault[_args.fiETH]    = _args.vBTC;

        // Set mint enabled.
        s.mintEnabled[_args.COFI]   = 1;
        // s.mintEnabled[_args.fiETH]  = 1;
        // s.mintEnabled[_args.fiBTC]  = 1;

        // Set mint fee.
        s.mintFee[_args.COFI]   = 10;
        // s.mintFee[_args.fiETH]  = 10;
        // s.mintFee[_args.fiBTC]  = 10;

        // Set redeem enabled.
        s.redeemEnabled[_args.COFI]     = 1;
        // s.redeemEnabled[_args.fiETH]    = 1;
        // s.redeemEnabled[_args.fiBTC]    = 1;

        // Set redeem fee.
        s.redeemFee[_args.COFI]     = 10;
        // s.redeemFee[_args.fiETH]    = 10;
        // s.redeemFee[_args.fiBTC]    = 10;

        // Set service fee.
        s.serviceFee[_args.COFI]    = 1e3;
        // s.serviceFee[_args.fiETH]   = 1e3;
        // s.serviceFee[_args.fiBTC]   = 1e3;

        // Set points rate.
        s.pointsRate[_args.COFI]    = 1e6;  // 100 points/COFI earned.
        // s.pointsRate[_args.fiETH]   = 1e9;  // 100 points/0.001 fiETH earned.
        // s.pointsRate[_args.fiBTC]   = 1e10; // 100 points/0.0001 fiBTC earned.

        // Set feeCollector.
        s.feeCollector = _args.feeCollector;

        s.isAdmin[msg.sender] = 1;
        s.isAdmin[_args.COFI] = 1;
        s.isWhitelisted[msg.sender] = 1;
        s.isWhitelisted[_args.feeCollector] = 1;

        s.initReward = 100*10**18;  // 100 Points for initial deposit.
        s.referReward = 10*10**18;  // 10 Points each for each referral.

        s.buffer[_args.COFI] = 100*10**18;  // 100 USDC buffer for migrations.

        // Set admins.
        // for(uint i = 1; i < _args.admins.length; ++i) {
        //     s.isAdmin[_args.admins[i]] = 1;
        // }
    }
}