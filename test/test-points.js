/* global ethers */

const { getSelectors, FacetCutAction } = require('../scripts/libraries/diamond.js')
const { loadFixture } = require('@nomicfoundation/hardhat-network-helpers')
const { expect } = require('chai')
// const { diamondAbi } = require('./Stoa-Diamond.json')
const { ethers } = require('hardhat')
// const MAX_UINT = '115792089237316195423570985008687907853269984665640564039457584007913129639935'
const hre = require("hardhat");

describe('First test', function() {

    async function deploy() {
        const accounts = await ethers.getSigners()
        const owner = accounts[0]
        const alice = accounts[1]
        const bob = accounts [2]
      
        // Deploy COFI Dollar
        const COFI = await ethers.getContractFactory('FiToken')
        const cofi = await COFI.deploy('COFI Dollar', 'COFI')
        await cofi.deployed()
        console.log('COFI Dollar deployed:', cofi.address)
      
        // Deploy COFI Ethereum
        const COFIE = await ethers.getContractFactory('FiToken')
        const cofie = await COFIE.deploy('COFI Ethreum', 'COFIE')
        await cofie.deployed()
        console.log('COFIE Ethereum deployed:', cofie.address)
      
        // Deploy DAI
        const DAI = await ethers.getContractFactory('CreditToken')
        const dai = await DAI.deploy('Dai', 'DAI')
        await dai.deployed()
        console.log('Dai deployed:', dai.address)
      
        // Deploy USDC
        // const USDC = await ethers.getContractFactory('CreditToken')
        // const usdc = await USDC.deploy('USD Coin', 'USDC')
        // await usdc.deployed()
        // console.log('USDC deployed:', usdc.address)
      
        // Deploy WETH
        const WETH = await ethers.getContractFactory('CreditToken')
        const weth = await WETH.deploy('Wrapped Ethereum', 'WETH')
        await weth.deployed()
        console.log('wETH deployed:', weth.address)
      
        // Deploy yvDAI
        const YVDAI = await ethers.getContractFactory('Vault')
        const yvdai = await YVDAI.deploy(dai.address, 'Yearn Vault Dai', 'yvDAI')
        await yvdai.deployed()
        console.log('yvDAI deployed:', yvdai.address)
      
        // Deploy yvETH
        const YVETH = await ethers.getContractFactory('Vault')
        const yveth = await YVETH.deploy(weth.address, 'Yearn Vault Ethereum', 'yvETH')
        await yveth.deployed()
        console.log('yvETH deployed:', yveth.address)
      
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
          'SupplyFacet',
          'RewardFacet',
          'AdminFacet'
        ]
        const cut = []
        for (const FacetName of FacetNames) {
          const Facet = await ethers.getContractFactory(FacetName)
          const facet = await Facet.deploy()
          await facet.deployed()
          console.log(`${FacetName} deployed: ${facet.address}`)
          cut.push({
            facetAddress: facet.address,
            action: FacetCutAction.Add,
            functionSelectors: getSelectors(facet)
          })
        }
      
        const initArgs = [{
          COFI:   cofi.address,
          COFIE:  cofie.address,
          DAI:    dai.address,
          WETH:   weth.address,
          yvDAI:  yvdai.address,
          yvETH:  yveth.address
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
            owner, diamond, cofi, cofie, dai, weth, yvdai, yveth, alice, bob
        }
    }

    describe('RewardFacet', function() {

        it('Should get correct points from yield earned', async function() {

            const { owner, diamond, cofi, dai, yvdai } = await loadFixture(deploy)

            // Mint owner 1,000 DAI
            await dai.mint(owner.address, '1000000000000000000000')

            await dai.approve(yvdai.address, '1000000000000000000000')

            signer = ethers.provider.getSigner(owner.address)

            const cofiMoney = (await ethers.getContractAt('COFIMoney', diamond.address)).connect(signer)

            await cofiMoney.setWhitelist(owner.address, 1)

            await cofiMoney.inputToFi(
                '1000000000000000000000',
                '997500000000000000000',
                dai.address,
                owner.address,
                owner.address
            )

            // Get bal t0
            console.log('t0 bal: ' + await cofi.balanceOf(owner.address))
            // Get yield earned t0
            console.log('t0 yield earned: ' + await cofi.getYieldEarned(owner.address))
            // Get yield earned t0
            console.log('t0 points earned: ' + await cofiMoney.getPoints(owner.address, cofi.address))

            // Simulate 100 DAI yield earned by Vault
            await dai.mint(yvdai.address, '100000000000000000000')

            // Rebase
            await cofiMoney.rebase(cofi.address)

            // Get bal t1
            console.log('t1 bal: ' + await cofi.balanceOf(owner.address))
            // Get yield earned t1
            console.log('t1 yield earned: ' + await cofi.getYieldEarned(owner.address))
            // Get yield earned t1
            console.log('t1 points earned: ' + await cofiMoney.getPoints(owner.address, cofi.address))
        })
    })
})