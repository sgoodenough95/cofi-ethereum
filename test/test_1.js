/* global ethers */

const { getSelectors, FacetCutAction } = require('../scripts/libraries/diamond.js')
const { loadFixture } = require('@nomicfoundation/hardhat-network-helpers')
const { expect } = require('chai')
const { diamondAbi } = require('./Stoa-Diamond.json')
const { ethers } = require('hardhat')
const MAX_UINT = '115792089237316195423570985008687907853269984665640564039457584007913129639935'

describe('First test', function() {

    async function deployDiamond () {
        const accounts = await ethers.getSigners()
        const owner = accounts[0]
    
        // deploy Stoa Active Dollar
        const StoaActiveDollar = await ethers.getContractFactory('ActiveToken')
        const USDST = await StoaActiveDollar.deploy('Stoa Active Dollar', 'USDST')
        await USDST.deployed()
        console.log('Stoa Active Dollar deployed:', USDST.address)
    
        // deploy Stoa DeFi-Active Dollar
        const StoaDeFiActiveDollar = await ethers.getContractFactory('ActiveToken')
        const USDFI = await StoaDeFiActiveDollar.deploy('Stoa DeFi-Active Dollar', 'USDFI')
        await USDFI.deployed()
        console.log('Stoa DeFi-Active Dollar deployed:', USDFI.address)
    
        // deploy Stoa Dollar Credit
        const StoaDollarCredit = await ethers.getContractFactory('CreditToken')
        const USDSC = await StoaDollarCredit.deploy('Stoa Dollar Credit', 'USDSC')
        await USDSC.deployed()
        console.log('Stoa Dollar deployed:', USDSC.address)
    
        // deploy USDC
        const USDC = await ethers.getContractFactory('CreditToken')
        const usdc = await USDC.deploy('USD Coin', 'USDC')
        await usdc.deployed()
        console.log('USDC deployed:', usdc.address)
    
        // deploy DAI
        const DAI = await ethers.getContractFactory('CreditToken')
        const dai = await DAI.deploy('Dai', 'DAI')
        await dai.deployed()
        console.log('Dai deployed:', dai.address)
    
        // deploy Vault
        const VaultUSDC = await ethers.getContractFactory('Vault')
        const vaultUSDC = await VaultUSDC.deploy(usdc.address, 'Vault USDC', 'vUSDC')
        await vaultUSDC.deployed()
        console.log('Vault USDC deployed:', vaultUSDC.address)
    
        // deploy DiamondCutFacet
        const DiamondCutFacet = await ethers.getContractFactory('DiamondCutFacet')
        const diamondCutFacet = await DiamondCutFacet.deploy()
        await diamondCutFacet.deployed()
        console.log('DiamondCutFacet deployed:', diamondCutFacet.address)
    
        // deploy Diamond
        const Diamond = await ethers.getContractFactory('Diamond')
        const diamond = await Diamond.deploy(owner.address, diamondCutFacet.address)
        await diamond.deployed()
        console.log('Diamond deployed:', diamond.address)
    
        // deploy DiamondInit
        // DiamondInit provides a function that is called when the diamond is upgraded to initialize state variables
        // Read about how the diamondCut function works here: https://eips.ethereum.org/EIPS/eip-2535#addingreplacingremoving-functions
        const DiamondInit = await ethers.getContractFactory('InitDiamond')
        const diamondInit = await DiamondInit.deploy()
        await diamondInit.deployed()
        console.log('DiamondInit deployed:', diamondInit.address)
    
        // deploy facets
        console.log('')
        console.log('Deploying facets')
        const FacetNames = [
            'DiamondLoupeFacet',
            'OwnershipFacet',
            'ExchangeFacet',
            'VaultFacet',
            'RebaseFacet',
            'AdminFacet'
        ]
        const cut = []
        let exchangeFacet, adminFacet
        for (const FacetName of FacetNames) {
            const Facet = await ethers.getContractFactory(FacetName)
            const facet = await Facet.deploy()
            await facet.deployed()
            console.log(`${FacetName} deployed: ${facet.address}`)
            if (FacetName == 'ExchangeFacet') {
                exchangeFacet = facet.address
            }
            cut.push({
            facetAddress: facet.address,
            action: FacetCutAction.Add,
            functionSelectors: getSelectors(facet)
            })
        }
    
        const initArgs = [{
            USDST:  USDST.address,
            USDFI:  USDFI.address,
            USDSC:  USDSC.address,
            USDC:   usdc.address,
            DAI:    dai.address,
            vUSDC:  vaultUSDC.address,
            exchangeFacet: exchangeFacet
        }]
    
        // upgrade diamond with facets
        console.log('')
        console.log('Diamond Cut:', cut)
        const diamondCut = await ethers.getContractAt('IDiamondCut', diamond.address)
        let tx
        let receipt
        // call to init function
        let functionCall = diamondInit.interface.encodeFunctionData('init', initArgs)
        tx = await diamondCut.diamondCut(cut, diamondInit.address, functionCall)
        console.log('Diamond cut tx: ', tx.hash)
        receipt = await tx.wait()
        if (!receipt.status) {
            throw Error(`Diamond upgrade failed: ${tx.hash}`)
        }
        console.log('Completed diamond cut')

        return {
            owner, USDST, USDFI, USDSC, usdc, dai, vaultUSDC, diamond, exchangeFacet, MAX_UINT
        }
    }

    describe('ExchangeFacet', function() {

        // it('Should exchange creditAsset for inputAsset', async function() {

        //     const { owner, USDST, USDSC, usdc, diamond } = await loadFixture(deployDiamond)

        //     // Mint Alice 1,000 USDC.
        //     await usdc.mint(owner.address, '1000000000000000000000')

        //     await usdc.approve(diamond.address, '1000000000000000000000')

        //     signer = await ethers.provider.getSigner(owner.address)

        //     const stoa = (await ethers.getContractAt('Stoa-Diamond', diamond.address)).connect(signer)

        //     await stoa.inputToCredit('1000000000000000000000', usdc.address, owner.address, owner.address)

        //     console.log('Diamond USDST bal: ' + await USDST.balanceOf(diamond.address))
        //     console.log('User USDSC bal: ' + await USDSC.balanceOf(owner.address))
        //     console.log('USDSC backing reserve of USDST: ' + await stoa.getBackingReserve(USDSC.address))
        //     console.log('Redemption allowance: ' + await stoa.getCreditRedeemAllowance(owner.address, USDSC.address))
        // })

        // it('Should exchange activeAsset for inputAsset', async function() {

        //     const { owner, USDST, usdc, diamond, exchangeFacet } = await loadFixture(deployDiamond)

        //     await usdc.mint(owner.address, '1000000000000000000000')

        //     await usdc.approve(diamond.address, '1000000000000000000000')

        //     signer = await ethers.provider.getSigner(owner.address)

        //     const stoa = (await ethers.getContractAt('Stoa-Diamond', diamond.address)).connect(signer)

        //     await stoa.inputToActive('1000000000000000000000', usdc.address, USDST.address, owner.address, owner.address)

        //     console.log('Stoa USDC bal: ' + await usdc.balanceOf(diamond.address))
        //     console.log('User USDST bal: ' + await USDST.balanceOf(owner.address))
        //     console.log('Fees collected: ' + await USDST.balanceOf(exchangeFacet))
        // })

        // it('Should convert between activeAsset and creditAsset', async function() {

        //     const { owner, USDST, USDSC, usdc, diamond, exchangeFacet } = await loadFixture(deployDiamond)

        //     await usdc.mint(owner.address, '1000000000000000000000')

        //     await usdc.approve(diamond.address, '1000000000000000000000')

        //     signer = await ethers.provider.getSigner(owner.address)

        //     const stoa = (await ethers.getContractAt('Stoa-Diamond', diamond.address)).connect(signer)

        //     await stoa.inputToActive('1000000000000000000000', usdc.address, USDST.address, owner.address, owner.address)

        //     console.log('User USDST bal: ' + await USDST.balanceOf(owner.address))

        //     await USDST.approve(diamond.address, MAX_UINT)

        //     await stoa.activeToCredit('990000000000000000000', USDST.address, owner.address, owner.address)

        //     console.log('Stoa USDC bal: ' + await usdc.balanceOf(diamond.address))
        //     console.log('Stoa USDST bal: ' + await USDST.balanceOf(diamond.address))
        //     console.log('User USDSC bal: ' + await USDSC.balanceOf(owner.address))
        //     // Credit Redemption Allowance
        //     console.log('URA: ' + await stoa.getCreditRedeemAllowance(owner.address, USDSC.address))

        //     // Now convert back
        //     await USDSC.approve(diamond.address, MAX_UINT)
        //     await stoa.creditToActive('990000000000000000000', USDSC.address, owner.address, owner.address)

        //     // Should be minus amount
        //     console.log('User USDSC bal: ' + await USDSC.balanceOf(owner.address))  // X
        //     console.log('Stoa USDST bal: ' + await USDST.balanceOf(diamond.address))
        //     console.log('User USDST bal: ' + await USDST.balanceOf(owner.address))
        //     console.log('URA: ' + await stoa.getCreditRedeemAllowance(owner.address, USDSC.address))
        // })

        // it('Should redeem activeAsset', async function() {

        //     const { owner, USDST, usdc, diamond, exchangeFacet } = await loadFixture(deployDiamond)

        //     await usdc.mint(owner.address, '1000000000000000000000')

        //     await usdc.approve(diamond.address, '1000000000000000000000')

        //     signer = await ethers.provider.getSigner(owner.address)

        //     const stoa = (await ethers.getContractAt('Stoa-Diamond', diamond.address)).connect(signer)

        //     await stoa.inputToActive('1000000000000000000000', usdc.address, USDST.address, owner.address, owner.address)

        //     console.log('User USDST bal: ' + await USDST.balanceOf(owner.address))

        //     await USDST.approve(diamond.address, MAX_UINT)

        //     // Simulate rebase
        //     // 10% increase in [User] USDC holdings.
        //     await usdc.mint(diamond.address, '100000000000000000000')
        //     await USDST.changeSupply('1100000000000000000000')
        //     console.log("USDST new supply: " + await USDST.totalSupply())
        //     const userBal = await USDST.balanceOf(owner.address)
        //     console.log(userBal)

        //     await stoa.redeemActive(userBal.toString(), USDST.address, owner.address, owner.address)
        //     console.log('User USDC bal: ' + await usdc.balanceOf(owner.address))
        //     // Should be 0.1% * 1,000 + 0.1% * 1,100
        //     console.log('Fees collected: ' + await USDST.balanceOf(exchangeFacet))
        //     console.log('Stoa USDC bal: ' + await usdc.balanceOf(diamond.address))
        // })

        // it('Should redeem creditAsset', async function() {

        //     const { owner, USDST, USDSC, usdc, diamond, exchangeFacet } = await loadFixture(deployDiamond)

        //     await usdc.mint(owner.address, '1000000000000000000000')

        //     await usdc.approve(diamond.address, '1000000000000000000000')

        //     signer = await ethers.provider.getSigner(owner.address)

        //     const stoa = (await ethers.getContractAt('Stoa-Diamond', diamond.address)).connect(signer)

        //     // Start Point 1
        //     console.log('Start Point 1: User USDC bal: ' + await usdc.balanceOf(owner.address))

        //     await stoa.inputToCredit('1000000000000000000000', usdc.address, owner.address, owner.address)

        //     // End Point 1
        //     console.log('End Point 1: User USDC bal: ' + await usdc.balanceOf(owner.address))
        //     console.log('End Point 1: Stoa USDST backing + fee: ' + await USDST.balanceOf(diamond.address))
        //     console.log('End Point 1: User USDSC bal: ' + await USDSC.balanceOf(owner.address))
        //     const reserve = await stoa.getBackingReserve(USDSC.address)
        //     console.log('End Point 1: Stoa USDST backing: ' + reserve)

        //     // Simulate rebase
        //     // 10% increase in [User] USDC holdings.
        //     // await usdc.mint(diamond.address, '100000000000000000000')
        //     // await USDST.changeSupply('1100000000000000000000')

        //     // Point 2
        //     // console.log("USDST new supply: " + await USDST.totalSupply())
        //     // const userBal = await USDST.balanceOf(diamond.address)
        //     // console.log(userBal)

        //     await USDSC.approve(diamond.address, MAX_UINT)
        //     await stoa.redeemCredit('990000000000000000000', USDSC.address, owner.address, owner.address)
        //     console.log('User USDC bal: ' + await usdc.balanceOf(owner.address))
        //     // Should be 0.1% * 1,000 + 0.1% * 1,100
        //     console.log('Fees collected: ' + await USDST.balanceOf(diamond.address))
        //     console.log('Stoa USDC bal: ' + await usdc.balanceOf(diamond.address))
        //     const reserve2 = await stoa.getBackingReserve(USDSC.address)
        //     console.log('End Point 1: Stoa USDST backing: ' + reserve2)
        // })

        // it('Should exchange activeAsset [vault] for inputAsset', async function() {

        //     const { owner, USDFI, USDSC, usdc, diamond, vaultUSDC, exchangeFacet } = await loadFixture(deployDiamond)

        //     /* Initial set-up */

        //     await usdc.mint(owner.address, '1000000000000000000000')

        //     // Not required for inputToActiveVault() to work as the vault is the spender.
        //     await usdc.approve(diamond.address, MAX_UINT)

        //     signer = await ethers.provider.getSigner(owner.address)

        //     const stoa = (await ethers.getContractAt('Stoa-Diamond', diamond.address)).connect(signer)

        //     await usdc.approve(vaultUSDC.address, MAX_UINT)

        //     await stoa.inputToActiveVault('1000000000000000000000', vaultUSDC.address, owner.address, owner.address)

        //     // End Point 1
        //     console.log('User USDFI bal: ' + await USDFI.balanceOf(owner.address))
        //     console.log('Fee collector USDFI bal: ' + await USDFI.balanceOf(exchangeFacet))
        //     console.log('Vault USDC bal: ' + await usdc.balanceOf(vaultUSDC.address))
        //     console.log('Stoa vUSDC bal: ' + await vaultUSDC.balanceOf(diamond.address))
        // })

        it('Should exchange creditAsset for inputAsset', async function() {

            const { owner, USDFI, USDSC, usdc, diamond, vaultUSDC, exchangeFacet } = await loadFixture(deployDiamond)

            /* Initial set-up */

            await usdc.mint(owner.address, '1000000000000000000000')

            // Not required for inputToActiveVault() to work as the vault is the spender.
            await usdc.approve(diamond.address, MAX_UINT)

            signer = await ethers.provider.getSigner(owner.address)

            const stoa = (await ethers.getContractAt('Stoa-Diamond', diamond.address)).connect(signer)

            await usdc.approve(vaultUSDC.address, MAX_UINT)

            await stoa.inputToCreditVault('1000000000000000000000', vaultUSDC.address, owner.address, owner.address)

            // End Point 1
            console.log('User USDFI bal: ' + await USDFI.balanceOf(owner.address))
            console.log('User USDSC bal: ' + await USDSC.balanceOf(owner.address))
            console.log('Fee collector USDFI bal: ' + await USDFI.balanceOf(exchangeFacet))
            console.log('Vault USDC bal: ' + await usdc.balanceOf(vaultUSDC.address))
            console.log('Stoa vUSDC bal: ' + await vaultUSDC.balanceOf(diamond.address))
            console.log('USDSC backing reserve of USDFI: ' + await stoa.getBackingReserve(USDSC.address))
        })
    })
})