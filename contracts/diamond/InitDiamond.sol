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
        address COFI;   // fiAsset [USD]
        address COFIE;  // fiAsset [ETH]
        // address USDC;   // inputAsset [USD]
        address DAI;    // inputAsset [USD]
        address WETH;   // inputAsset [ETH]
        address yvDAI;  // shareToken [USD]
        address yvETH;  // shareToken [ETH]
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
        LibToken._rebaseOptIn(_args.COFIE);

        // Set min deposit/withdraw values.
        // s.minDeposit[_args.USDC]    = 20e18;    // 20 USDC.
        s.minDeposit[_args.DAI]     = 20e18;    // 20 DAI.
        s.minDeposit[_args.WETH]    = 1e16;     // 0.01 ETH.

        s.fiAsset[_args.DAI]    = _args.COFI;
        s.fiAsset[_args.WETH]   = _args.COFIE;

        s.vault[_args.COFI]     = _args.yvDAI;
        s.vault[_args.COFIE]    = _args.yvETH;

        // Set mint enabled.
        s.mintEnabled[_args.COFI]   = 1;
        s.mintEnabled[_args.COFIE]  = 1;

        // Set mint fee.
        s.mintFee[_args.COFI]   = 10;
        s.mintFee[_args.COFIE]  = 10;

        // Set redeem enabled.
        s.redeemEnabled[_args.COFI]     = 1;
        s.redeemEnabled[_args.COFIE]    = 1;

        // Set redeem fee.
        s.redeemFee[_args.COFI]     = 30;
        s.redeemFee[_args.COFIE]    = 30;

        // Set service fee.
        s.serviceFee[_args.COFI]    = 1e3;
        s.serviceFee[_args.COFIE]   = 1e3;

        // Set points rate.
        s.pointsRate[_args.COFI]    = 1e6;
        s.pointsRate[_args.COFIE]   = 1e3;

        // Set feeCollector.
        s.feeCollector = address(this);

        // Set admin.
        s.isAdmin[msg.sender] = 1;
    }
}