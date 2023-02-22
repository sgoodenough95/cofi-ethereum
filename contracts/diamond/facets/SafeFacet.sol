// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

/**
    █▀▀ ▀▀█▀▀ █▀▀█ █▀▀█ 
    ▀▀█ ░░█░░ █░░█ █▄▄█ 
    ▀▀▀ ░░▀░░ ▀▀▀▀ ▀░░▀

    @author stoa.money
    @title  Safe Facet
    @notice User-operated functions for managing Safes.
    @dev    TO-DO: Split [vault] and [exchange] into separate facets.
 */

import { Safe, VaultParams, Modifiers } from '../libs/LibAppStorage.sol';
import { LibToken } from '../libs/LibToken.sol';
import { LibVault } from '../libs/LibVault.sol';
import { LibSafe } from '../libs/LibSafe.sol';
import { IERC4626 } from ".././interfaces/IERC4626.sol";

contract SafeFacet is Modifiers {

    /// @notice Opens a Safe with an inputAsset. Credits with activeAssets.
    /// @dev    Only caller can open a Safe for themselves.
    /// @dev    Optionally can have a 'primeActive' storage variable.
    /// @dev    Only consider one Safe Store per activeAsset for now.
    ///
    /// @param  inputAsset  The inputAsset to open a Safe with.
    /// @param  activeAsset The activeAsset to convert to.
    /// @param  amount      The amount of inputAssets.
    function openExchange(
        address inputAsset,
        address activeAsset
        uint256 amount
    )   external
        minDeposit(amount, inputAsset)
    {
        require(
            LibToken._isValidActiveInput(inputAsset, activeAsset) == 1,
            "ExchangeFacet: Invalid input"
        );

        require(
            LibToken._isMintEnabled(activeAsset) == 1,
            "ExchangeFacet: Mint disabled"
        );

        LibToken._transferFrom(inputAsset, amount, depositFrom, address(this));

        // Do not apply fee when opening a Safe (?)
        // uint256 fee = LibToken._getMintFee(activeAsset, amount);
        // mintAfterFee = amount - fee;

        LibToken._mint(activeAsset, address(this), amount);

        // if (fee > 0) {
        //    LibToken._mint(activeAsset, address(this), fee);
        //     emit LibToken.MintFeeCaptured(activeAsset, fee); 
        // }

        // Deposit activeAssets to ERC4626 Safe Store contract.
        LibSafe._open(amount, address(this), s.primeStore[activeAsset]);
    }

    /// @notice Opens a Sade with an activeAsset originating from a vault.
    /// @dev    Only this route likely to be available for MVP.
    ///
    /// @param  amount  The amount of inputAssets to deposit.
    /// @param  vault   The vault to interact with.
    function openVault(
        uint256 amount,
        address vault
    )   external
        minDeposit(amount, s.vaultParams[vault].input)
    {
        VaultParams memory _vault = s.vaultParams[vault];

        require(_vault.enabled == 1, "VaultFacet: Vault disabled");

        require(LibToken._isMintEnabled(_vault.active) == 1, "VaultFacet: Mint disabled");

        uint256 shares = LibVault._wrap(amount, vault, depositFrom);

        uint256 assets = LibVault._getAssets(shares, vault);

        // uint256 fee = LibToken._getMintFee(_vault.active, assets);
        // mintAfterFee = assets - fee;

        LibToken._mint(_vault.active, address(this), amount);

        // if (fee > 0) {
        //    LibToken._mint(_vault.active, address(this), fee);
        //     emit LibToken.MintFeeCaptured(_vault.active, fee); 
        // }

        // Deposit activeAssets to ERC4626 Safe Store contract.
        LibSafe._open(amount, address(this), s.primeStore[_vault.active]);
    }

    /// @notice Opens a Safe with activeAssets already held by the account.
    ///
    /// @param  amount      The amount of activeAssets to deposit.
    /// @param  activeAsset The address of the activeAsset.
    function openActive(
        uint256 amount,
        address activeAsset
    )   external
        minDeposit(amount, activeAsset)
    {
        LibSafe._open(amount, msg.sender, s.primeStore[_vault.active]);
    }


    function depositExchange(
        uint256 amount,
        address inputAsset, // One [exchange] activeAsset can have multiple inputAssets.
        uint32  index
    )   external
        minDeposit(amount, inputAsset)
    {
        require(
            s.safe[msg.sender][index].status == 1 ||
            s.safe[msg.sender][index].status == 2,
            'SafeFacet: Safe not active'
        );

        address activeAsset = IERC4626(s.safe[msg.sender][index].store).asset();

        require(
            LibToken._isValidActiveInput(inputAsset, activeAsset) == 1,
            "ExchangeFacet: Invalid input"
        );

        require(
            LibToken._isMintEnabled(activeAsset) == 1,
            "ExchangeFacet: Mint disabled"
        );

        LibToken._transferFrom(inputAsset, amount, depositFrom, address(this));

        // Do not apply fee when opening a Safe (?)
        // uint256 fee = LibToken._getMintFee(activeAsset, amount);
        // mintAfterFee = amount - fee;

        LibToken._mint(activeAsset, address(this), amount);

        // if (fee > 0) {
        //    LibToken._mint(activeAsset, address(this), fee);
        //     emit LibToken.MintFeeCaptured(activeAsset, fee); 
        // }

        // Deposit activeAssets to ERC4626 Safe Store contract.
        LibSafe._deposit(amount, address(this), index);
    }

    function depositVault(
        uint256 amount,
        address vault,
        uint32  index
    )   external
        minDeposit(amount, s.vaultParams[vault].input)
    {
        require(
            s.safe[msg.sender][index].status == 1 ||
            s.safe[msg.sender][index].status == 2,
            'SafeFacet: Safe not active'
        );

        VaultParams memory _vault = s.vaultParams[vault];

        require(_vault.enabled == 1, "VaultFacet: Vault disabled");

        require(LibToken._isMintEnabled(_vault.active) == 1, "VaultFacet: Mint disabled");

        uint256 shares = LibVault._wrap(amount, vault, depositFrom);

        uint256 assets = LibVault._getAssets(shares, vault);

        // uint256 fee = LibToken._getMintFee(_vault.active, assets);
        // mintAfterFee = assets - fee;

        LibToken._mint(_vault.active, address(this), amount);

        // if (fee > 0) {
        //    LibToken._mint(_vault.active, address(this), fee);
        //     emit LibToken.MintFeeCaptured(_vault.active, fee); 
        // }

        // Deposit activeAssets to ERC4626 Safe Store contract.
        LibSafe._deposit(amount, address(this), index);
    }

    function depositActive(
        uint256 amount,
        uint32  index
    )   external
        minDeposit(amount, IERC4626(s.safe[msg.sender][index].store).asset())
    {
        require(
            s.safe[msg.sender][index].status == 1 ||
            s.safe[msg.sender][index].status == 2,
            'SafeFacet: Safe not active'
        );

        LibSafe._deposit(amount, msg.sender, index);
    }

    function withdrawExchange() {}

    function withdrawVault() {}

    function withdrawActive() {}

    function transfer(
        uint256 amount,
        address recipient,
        uint32  fromIndex,
        uint32  toIndex     // Later do not specify (?)
    )   external
        minDeposit(amount, IERC4626(s.safe[msg.sender][fromIndex].store).asset())
    {
        require(
            s.safe[msg.sender][fromIndex].status == 1 ||
            s.safe[msg.sender][fromIndex].status == 2,
            'SafeFacet: Safe not active'
        );

        // Check has free bal

        if(
            s.safe[recipient][toIndex].status == 0 ||
            s.safe[recipient][toIndex].status > 2,
        )   pendingClaim[recipient][IERC4626(s.safe[msg.sender][fromIndex].store).asset()]
                += amount;

        require(
            s.safe[msg.sender][fromIndex].store == s.safe[recipient][toIndex].store,
            'SafeFacet: Recipient Safe belongs to different store'
        );


    }

    function transferCredit() {}

    function transferExternal() {} // (?) Can be handled by deposit.

    function borrow() {}

    function repay() {}

    function getSafe(
        address account,
        uint32  index
    ) external view returns (Safe memory) {

        return s.safe[account][index];
    }
}