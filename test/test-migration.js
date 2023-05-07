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
      
    // Deploy COFI Dollar
    const COFI = await ethers.getContractFactory('FiToken')
    const cofi = await COFI.deploy('COFI Dollar', 'COFI')
    await cofi.deployed()
    console.log('COFI Dollar deployed:', cofi.address)
      
    // Deploy DAI
    const DAI = await ethers.getContractFactory('ERC20Token')
    const dai = await DAI.deploy('Dai', 'DAI')
    await dai.deployed()
    console.log('Dai deployed:', dai.address)
      
    // Deploy USDC
    // const USDC = await ethers.getContractFactory('CreditToken')
    // const usdc = await USDC.deploy('USD Coin', 'USDC')
    // await usdc.deployed()
    // console.log('USDC deployed:', usdc.address)
      
    // Deploy yvDAI
    const YVDAI = await ethers.getContractFactory('Vault')
    const yvdai = await YVDAI.deploy(dai.address, 'Yearn Vault Dai', 'yvDAI')
    await yvdai.deployed()
    console.log('yvDAI deployed:', yvdai.address)

    // Deploy aDAI
    const ADAI = await ethers.getContractFactory('Vault')
    const adai = await ADAI.deploy(dai.address, 'Aave Dai', 'aDAI')
    await adai.deployed()
    console.log('aDAI deployed:', adai.address)
      
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

    // Set Diamond address in FiToken contract(s).
    await cofi.setDiamond(diamond.address)
      
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
      'LoupeFacet',
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
      yvDAI:  yvdai.address
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
      owner, diamond, cofi, dai, yvdai, adai
    }
  }

  describe('RewardFacet', function() {

    it('Should migrate from yvDAI to aDAI', async function() {

      const { owner, diamond, cofi, dai, yvdai, adai } = await loadFixture(deploy)

      // Mint owner 1,000 DAI
      await dai.mint(owner.address, '1000000000000000000000')

      // Approve DAI spend for Vault contract.
      await dai.approve(yvdai.address, '1000000000000000000000')

      signer = ethers.provider.getSigner(owner.address)

      const cofiMoney = (await ethers.getContractAt('COFIMoney', diamond.address)).connect(signer)

      await cofiMoney.underlyingToFi(
        '1000000000000000000000', // amount:        1,000 DAI.
        '997500000000000000000',  // minAmountOut:  1,000 * 0.9975 (0.25% slippage).
        cofi.address,             // fiAsset
        owner.address,            // depositFrom
        owner.address             // recipient
      )

      // T0 End Outputs:
      console.log('t0 User COFI bal: ' + await cofi.balanceOf(owner.address))
      console.log('t0 Vault DAI bal: ' + await dai.balanceOf(yvdai.address))
      console.log('t0 Diamond yvDAI bal: ' + await yvdai.balanceOf(diamond.address))
      console.log('t0 Diamond (feeCollector) COFI bal: ' + await cofi.balanceOf(diamond.address))

      // Simulate 100 DAI yield earned by Vault
      await dai.mint(yvdai.address, '100000000000000000000')

      // Rebase
      await cofiMoney.rebase(cofi.address)

      // T1 End Outputs:
      console.log('t1 User COFI bal: ' + await cofi.balanceOf(owner.address))
      console.log('t1 Vault DAI bal: ' + await dai.balanceOf(yvdai.address))
      console.log('t1 Diamond yvDAI bal: ' + await yvdai.balanceOf(diamond.address))
      console.log('t1 Diamond (feeCollector) COFI bal: ' + await cofi.balanceOf(diamond.address))

      // Do migration procedure (T2):
      // Add 1 DAI buffer to Diamond
      await dai.mint(cofiMoney.address, '1000000000000000000')

      // Pause minting/redeeming of COFI
      await cofiMoney.toggleMintEnabled(cofi.address)
      await cofiMoney.toggleRedeemEnabled(cofi.address)

      // Migrate DAI to new Vault
      await cofiMoney.migrateVault(cofi.address, adai.address)

      // Rebase to sync to new Vault
      await cofiMoney.rebase(cofi.address)

      // Resume minting/redeeming of COFI
      await cofiMoney.toggleMintEnabled(cofi.address)
      await cofiMoney.toggleRedeemEnabled(cofi.address)

      // T2 End Outputs:
      console.log('t2 User COFI bal: ' + await cofi.balanceOf(owner.address))
      console.log('t2 Old Vault (yvDAI) DAI bal: ' + await dai.balanceOf(yvdai.address))
      console.log('t2 New Vault (aDAI) DAI bal: ' + await dai.balanceOf(adai.address))
      console.log('t2 Diamond yvDAI bal: ' + await yvdai.balanceOf(diamond.address))
      console.log('t2 Diamond aDAI bal: ' + await adai.balanceOf(diamond.address))
      console.log('t2 Diamond (feeCollector) COFI bal: ' + await cofi.balanceOf(diamond.address))
    })
  })
})