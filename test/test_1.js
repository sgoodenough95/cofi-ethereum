/* global ethers */

const { getSelectors, FacetCutAction } = require('../scripts/libraries/diamond.js')
const { loadFixture } = require('@nomicfoundation/hardhat-network-helpers')
const { expect } = require('chai')
const { diamondAbi } = require('./Stoa-Diamond.json')
const { ethers } = require('hardhat')

describe('First test', function() {

    async function deployDiamond () {
        const accounts = await ethers.getSigners()
        const owner = accounts[0]
    
        // deploy Stoa Activated Dollar
        const StoaActivatedDollar = await ethers.getContractFactory('ActivatedToken')
        const USDSTA = await StoaActivatedDollar.deploy('Stoa Activated Dollar', 'USDSTA')
        await USDSTA.deployed()
        console.log('Stoa Activated Dollar deployed:', USDSTA.address)
    
        // deploy Stoa Activated Dollar
        const StoaDeFiActivatedDollar = await ethers.getContractFactory('ActivatedToken')
        const USDFI = await StoaDeFiActivatedDollar.deploy('Stoa DeFi-Activated Dollar', 'USDFI')
        await USDFI.deployed()
        console.log('Stoa DeFi-Activated Dollar deployed:', USDFI.address)
    
        // deploy Stoa Activated Dollar
        const StoaDollar = await ethers.getContractFactory('UnactivatedToken')
        const USDST = await StoaDollar.deploy('Stoa Dollar', 'USDST')
        await USDST.deployed()
        console.log('Stoa Dollar deployed:', USDST.address)
    
        // deploy Stoa Activated Dollar
        const USDC = await ethers.getContractFactory('UnactivatedToken')
        const usdc = await USDC.deploy('USD Coin', 'USDC')
        await usdc.deployed()
        console.log('USDC deployed:', usdc.address)
    
        // deploy Stoa Activated Dollar
        const DAI = await ethers.getContractFactory('UnactivatedToken')
        const dai = await DAI.deploy('Dai', 'DAI')
        await dai.deployed()
        console.log('Dai deployed:', dai.address)
    
        // deploy Stoa Activated Dollar
        const VaultUSDC = await ethers.getContractFactory('UnactivatedToken')
        const vaultUSDC = await VaultUSDC.deploy('Vault USDC', 'vUSDC')
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
        let exchangeFacet;
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
            USDSTA: USDSTA.address,
            USDFI:  USDFI.address,
            USDST:  USDST.address,
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
            owner, USDSTA, USDFI, USDST, usdc, dai, vaultUSDC, diamond
        }
    }

    describe('ExchangeFacet', function() {

        it('Should exchange unactiveAsset for inputAsset', async function() {

            const { owner, USDSTA, USDST, usdc, diamond } = await loadFixture(deployDiamond)

            // Mint Alice 1,000 USDC.
            await usdc.mint(owner.address, '1000000000000000000000')

            await usdc.approve(diamond.address, '1000000000000000000000')

            signer = await ethers.provider.getSigner(owner.address)

            const stoa = (await ethers.getContractAt('Stoa-Diamond', diamond.address)).connect(signer)

            await stoa.inputToUnactive('1000000000000000000000', usdc.address, owner.address, owner.address)

            console.log('Diamond USDSTA bal: ' + await USDSTA.balanceOf(diamond.address))
            console.log('User USDST bal: ' + await USDST.balanceOf(owner.address))
            console.log('USDST backing reserve of USDSTA: ' + await stoa.getBackingReserve(USDST.address))
            console.log('Redemption allowance: ' + await stoa.getUnactiveRedemptionAllowance(owner.address, USDST.address))
        })


    })
})