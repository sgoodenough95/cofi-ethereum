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
    const feeCollector = accounts[1]
      
    // Deploy COFI Dollar
    const COFI = await ethers.getContractFactory('FiToken')
    const cofi = await COFI.deploy('COFI Dollar', 'COFI')
    await cofi.deployed()
    console.log('COFI Dollar deployed:', cofi.address)
 
    // Deploy USDC
    const USDC = await ethers.getContractFactory('ERC20Token')
    const usdc = await USDC.deploy('USD Coin', 'USDC', 6)
    await usdc.deployed()
    console.log('USDC deployed:', usdc.address)
      
    // Deploy aUSDC
    const VUSDC = await ethers.getContractFactory('Vault')
    const ausdc = await VUSDC.deploy(usdc.address, 'A-Vault USDC', 'aUSDC')
    await ausdc.deployed()
    console.log('aUSDC deployed:', ausdc.address)

    // Deploy bUSDC
    const busdc = await VUSDC.deploy(usdc.address, 'B-Vault USDC', 'bUSDC')
    await busdc.deployed()
    console.log('bUSDC deployed:', busdc.address)
      
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
      'PointFacet',
      'AccessFacet',
      'YieldFacet'
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
      vUSDC:  ausdc.address,
      USDC:   usdc.address,
      feeCollector: feeCollector.address
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
      owner, feeCollector, diamond, cofi, usdc, ausdc, busdc
    }
  }

  describe('RewardFacet', function() {

    it('Should migrate from aUSDC to bUSDC', async function() {

      const { owner, feeCollector, diamond, cofi, usdc, ausdc, busdc } = await loadFixture(deploy)

      // Mint owner 1,000 USDC
      await usdc.mint(owner.address, '1000000000')

      // Mint 100 USDC buffer to Diamond
      await usdc.mint(diamond.address, '100000000')

      // Approve USDC spend for Diamond.
      await usdc.approve(diamond.address, '1000000000')

      signer = ethers.provider.getSigner(owner.address)

      const cofiMoney = (await ethers.getContractAt('COFIMoney', diamond.address)).connect(signer)

      await cofiMoney.underlyingToFi(
        '1000000000',
        '997500000',
        cofi.address,
        owner.address,
        owner.address,
        '0x0000000000000000000000000000000000000000'
      )

      // T0 End Outputs:
      console.log('t0 User COFI bal: ' + await cofi.balanceOf(owner.address))
      console.log('t0 aUSDC USDC bal: ' + await usdc.balanceOf(ausdc.address))
      console.log('t0 Diamond aUSDC bal: ' + await ausdc.balanceOf(diamond.address))
      console.log('t0 feeCollector COFI bal: ' + await cofi.balanceOf(feeCollector.address))

      // Simulate 100 USDC yield earned by aUSDC vault.
      await usdc.mint(ausdc.address, '100000000')

      // Rebase
      await cofiMoney.rebase(cofi.address)

      // T1 End Outputs:
      console.log('t1 User COFI bal: ' + await cofi.balanceOf(owner.address))
      console.log('t1 aUSDC USDC bal: ' + await usdc.balanceOf(ausdc.address))
      console.log('t1 Diamond aUSDC bal: ' + await ausdc.balanceOf(diamond.address))
      console.log('t1 feeCollector COFI bal: ' + await cofi.balanceOf(feeCollector.address))

      // Do migration procedure (T2):
      await cofiMoney.migrateVault(cofi.address, busdc.address)

      // T2 End Outputs:
      console.log('t2 User COFI bal: ' + await cofi.balanceOf(owner.address))
      console.log('t2 aUSDC USDC bal: ' + await usdc.balanceOf(ausdc.address))
      console.log('t2 bUSDC USDC bal: ' + await usdc.balanceOf(busdc.address))
      console.log('t2 Diamond aUSDC bal: ' + await ausdc.balanceOf(diamond.address))
      console.log('t2 Diamond bUSDC bal: ' + await busdc.balanceOf(diamond.address))
      console.log('t2 feeCollector COFI bal: ' + await cofi.balanceOf(feeCollector.address))
    })
  })
})