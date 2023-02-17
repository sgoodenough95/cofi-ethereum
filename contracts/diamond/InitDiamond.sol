// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { AppStorage } from "./libs/LibAppStorage.sol";
import { LibDiamond } from "./core/libs/LibDiamond.sol";
import { LibToken } from "./libs/LibToken.sol";
import { IERC165 } from "./core/interfaces/IERC165.sol";
import { IDiamondCut } from "./core/interfaces/IDiamondCut.sol";
import { IDiamondLoupe } from "./core/interfaces/IDiamondLoupe.sol";
import { IERC173 } from "./core/interfaces/IERC173.sol";

contract InitDiamond {
    AppStorage internal s;

    struct Args {
        address USDSTA;     // activeToken
        address USDFI;      // activeToken
        address USDST;      // debtToken
        address USDC;       // underlyingToken
        address DAI;
        address vUSDC;      // vaultToken
        address exchangeFacet;  // inputStore for inputAssets.
    }
    
    function init(Args memory _args) external {

        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();

        // adding ERC165 data
        ds.supportedInterfaces[type(IERC165).interfaceId] = true;
        ds.supportedInterfaces[type(IDiamondCut).interfaceId] = true;
        ds.supportedInterfaces[type(IDiamondLoupe).interfaceId] = true;
        ds.supportedInterfaces[type(IERC173).interfaceId] = true;

        // Rebase opt-in
        LibToken._rebaseOptIn(_args.USDSTA);
        LibToken._rebaseOptIn(_args.USDFI);

        s.vaultParams[_args.vUSDC].input    = _args.USDC;
        s.vaultParams[_args.vUSDC].active   = _args.USDFI;
        // Loans are not enabled, so leave unactive empty.
        s.vaultParams[_args.vUSDC].enabled  = 1;

        s.activeInputs[_args.USDSTA] = [_args.USDC, _args.DAI];

        s.inputToUnactive[_args.USDC]   = _args.USDST;
        s.inputToUnactive[_args.DAI]    = _args.USDST;

        s.inputStore[_args.USDC]    = _args.exchangeFacet;
        s.inputStore[_args.DAI]     = _args.exchangeFacet;

        s.minDeposit[_args.USDC]    = 50 * 10**18;
        s.minDeposit[_args.DAI]     = 50 * 10**18;
        s.minDeposit[_args.USDSTA]  = 50 * 10**18;
        s.minDeposit[_args.USDFI]   = 50 * 10**18;
        s.minDeposit[_args.USDST]   = 50 * 10**18;
        s.minWithdraw[_args.USDSTA] = 50 * 10**18;
        s.minWithdraw[_args.USDFI]  = 50 * 10**18;
        s.minWithdraw[_args.USDST]  = 50 * 10**18;

        s.mintEnabled[_args.USDSTA] = 1;
        s.mintEnabled[_args.USDFI]  = 1;
        s.mintEnabled[_args.USDST]  = 1;

        s.mintFee[_args.USDSTA] = 100;
        s.mintFee[_args.USDFI]  = 100;
        s.mintFee[_args.USDST]  = 100;

        s.redeemEnabled[_args.USDSTA] = 1;
        s.redeemEnabled[_args.USDFI]  = 1;
        s.redeemEnabled[_args.USDST]  = 1;

        s.redeemFee[_args.USDSTA]   = 100;
        s.redeemFee[_args.USDFI]    = 100;
        s.redeemFee[_args.USDST]    = 100;

        s.mgmtFee[_args.USDFI] = 1_000;
        // Apply mgmtFee manually for USDSTA / off-chain yields.

        s.backingAsset[_args.USDST] = _args.USDSTA;

        s.convertEnabled[_args.USDSTA]  = _args.USDST;
        s.convertEnabled[_args.USDST]   = _args.USDSTA;

        s.isAdmin[msg.sender] = 1;

        s.feeCollector = msg.sender;
    }
}