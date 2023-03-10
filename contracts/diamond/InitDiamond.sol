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
        // address USDST;          // activeAsset
        address USDFI;          // activeAsset [vault]
        address USDSC;          // creditAsset
        address USDC;           // inputAsset
        address DAI;            // inputAsset
        address vUSDC;          // shareToken [vault]
        address vDAI;           // shareToken [vault]
        address STOA;
    }
    
    function init(Args memory _args) external {

        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();

        // adding ERC165 data
        ds.supportedInterfaces[type(IERC165).interfaceId]       = true;
        ds.supportedInterfaces[type(IDiamondCut).interfaceId]   = true;
        ds.supportedInterfaces[type(IDiamondLoupe).interfaceId] = true;
        ds.supportedInterfaces[type(IERC173).interfaceId]       = true;

        // Rebase opt-in
        // LibToken._rebaseOptIn(_args.USDST);
        LibToken._rebaseOptIn(_args.USDFI);

        s.vaultParams[_args.vUSDC].input    = _args.USDC;
        s.vaultParams[_args.vUSDC].active   = _args.USDFI;
        s.vaultParams[_args.vUSDC].credit   = _args.USDSC;
        s.vaultParams[_args.vUSDC].enabled  = 1;

        s.activeVaults[_args.USDFI] = [_args.vUSDC, _args.vDAI];

        // s.activeInputs[_args.USDST] = [_args.USDC, _args.DAI];

        s.creditAsset[_args.USDC] = _args.USDSC;
        s.creditAsset[_args.DAI]  = _args.USDSC;
        // Can add more.

        s.minDeposit[_args.USDC]    = 50 * 10**18;
        s.minDeposit[_args.DAI]     = 50 * 10**18;
        // s.minDeposit[_args.USDST]   = 50 * 10**18;
        s.minDeposit[_args.USDFI]   = 50 * 10**18;
        s.minDeposit[_args.USDSC]   = 50 * 10**18;
        // s.minWithdraw[_args.USDST]  = 50 * 10**18;
        s.minWithdraw[_args.USDFI]  = 50 * 10**18;
        s.minWithdraw[_args.USDSC]  = 50 * 10**18;

        // s.mintEnabled[_args.USDST]  = 1;
        s.mintEnabled[_args.USDFI]  = 1;
        s.mintEnabled[_args.USDSC]  = 1;

        // s.mintFee[_args.USDST]  = 100;
        s.mintFee[_args.USDFI]  = 100;
        s.mintFee[_args.USDSC]  = 100;

        // s.redeemEnabled[_args.USDST]    = 1;
        s.redeemEnabled[_args.USDFI]    = 1;
        s.redeemEnabled[_args.USDSC]    = 1;

        // s.redeemFee[_args.USDST]    = 100;
        s.redeemFee[_args.USDFI]    = 100;
        s.redeemFee[_args.USDSC]    = 100;

        s.mgmtFee[_args.USDFI] = 1_000;
        // Apply mgmtFee manually for USDST / off-chain yields.

        // s.LTV[_args.USDST]  = 2_500;
        s.LTV[_args.USDFI]  = 5_000;

        // s.primeBacking[_args.USDSC]         = _args.USDST;
        s.primeVaultBacking[_args.USDSC]    = _args.USDFI;

        // s.activeConvertEnabled[_args.USDST] = _args.USDSC;
        s.activeConvertEnabled[_args.USDFI] = _args.USDSC;
        
        // s.creditConvertEnabled[_args.USDSC][_args.USDST] = 1;
        s.creditConvertEnabled[_args.USDSC][_args.USDFI] = 1;

        s.pointsRate[_args.USDFI] = 1_000_000;
        s.STOA = _args.STOA;

        s.isAdmin[msg.sender] = 1;
    }
}