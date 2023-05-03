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
      
    // Deploy COFI Ethereum
    // const COFIE = await ethers.getContractFactory('FiToken')
    // const cofie = await COFIE.deploy('COFI Ethreum', 'COFIE')
    // await cofie.deployed()
    // console.log('COFIE Ethereum deployed:', cofie.address)
      
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
      
    // Deploy WETH
    // const WETH = await ethers.getContractFactory('CreditToken')
    // const weth = await WETH.deploy('Wrapped Ethereum', 'WETH')
    // await weth.deployed()
    // console.log('wETH deployed:', weth.address)
      
    // Deploy yvDAI
    const YVDAI = await ethers.getContractFactory('Vault')
    const yvdai = await YVDAI.deploy(dai.address, 'Yearn Vault Dai', 'yvDAI')
    await yvdai.deployed()
    console.log('yvDAI deployed:', yvdai.address)
      
    // Deploy yvETH
    // const YVETH = await ethers.getContractFactory('Vault')
    // const yveth = await YVETH.deploy(weth.address, 'Yearn Vault Ethereum', 'yvETH')
    // await yveth.deployed()
    // console.log('yvETH deployed:', yveth.address)
      
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
      // COFIE:  cofie.address,
      yvDAI:  yvdai.address,
      // yvETH:  yveth.address
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
      owner, diamond, cofi, dai, yvdai
    }
  }

  describe('LoupeFacet', function() {

    it('Should return storage variables', async function() {

      const { owner, diamond, cofi } = await loadFixture(deploy)

      signer = ethers.provider.getSigner(owner.address)

      const cofiMoney = (await ethers.getContractAt('COFIMoney', diamond.address)).connect(signer)

      console.log('Whitelist status: ' + await cofiMoney.getWhitelistStatus(owner.address))
      console.log('Admin status: ' + await cofiMoney.getAdminStatus())
      console.log('COFI Min Deposit: ' + await cofiMoney.getMinDeposit(cofi.address))
      console.log('COFI Min Withdraw: ' + await cofiMoney.getMinWithdraw(cofi.address))
      console.log('COFI Mint Fee: ' + await cofiMoney.getMintFee(cofi.address))
      console.log('COFI Mint enabled: ' + await cofiMoney.getMintEnabled(cofi.address))
      console.log('COFI Redeem Fee: ' + await cofiMoney.getRedeemFee(cofi.address))
      console.log('COFI Redeem enabled: ' + await cofiMoney.getRedeemEnabled(cofi.address))
      console.log('COFI Points rate: ' + await cofiMoney.getPointsRate(cofi.address))
      console.log('Fee Collector status: ' + await cofiMoney.getFeeCollectorStatus())
    })
  })
})