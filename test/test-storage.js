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
      
    // Deploy COFI Ethereum
    const ETHFI = await ethers.getContractFactory('FiToken')
    const ethfi = await ETHFI.deploy('COFI Ethereum', 'ETHFI')
    await ethfi.deployed()
    console.log('COFIE Ethereum deployed:', ethfi.address)
      
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
    const WETH = await ethers.getContractFactory('ERC20Token')
    const weth = await WETH.deploy('Wrapped Ethereum', 'WETH')
    await weth.deployed()
    console.log('wETH deployed:', weth.address)
      
    // Deploy yvDAI
    const VDAI = await ethers.getContractFactory('Vault')
    const vdai = await VDAI.deploy(dai.address, 'Vault Dai', 'vDAI')
    await vdai.deployed()
    console.log('vDAI deployed:', vdai.address)
      
    // Deploy yvETH
    const VETH = await ethers.getContractFactory('Vault')
    const veth = await VETH.deploy(weth.address, 'Yearn Vault Ethereum', 'vETH')
    await veth.deployed()
    console.log('vETH deployed:', veth.address)
      
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
    await ethfi.setDiamond(diamond.address)
      
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
      'AccessFacet'
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
      vDAI:  vdai.address,
      // yvETH:  yveth.address
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
      owner, feeCollector, diamond, cofi, dai, vdai, ethfi, weth, veth
    }
  }

  describe('Storage', function() {

    // it('Should return storage variables', async function() {

    //   const { owner, diamond, cofi } = await loadFixture(deploy)

    //   signer = ethers.provider.getSigner(owner.address)

    //   const cofiMoney = (await ethers.getContractAt('COFIMoney', diamond.address)).connect(signer)

    //   console.log('Whitelist status: ' + await cofiMoney.getWhitelistStatus(owner.address))
    //   console.log('Admin status: ' + await cofiMoney.getAdminStatus())
    //   console.log('COFI Min Deposit: ' + await cofiMoney.getMinDeposit(cofi.address))
    //   console.log('COFI Min Withdraw: ' + await cofiMoney.getMinWithdraw(cofi.address))
    //   console.log('COFI Mint Fee: ' + await cofiMoney.getMintFee(cofi.address))
    //   console.log('COFI Mint enabled: ' + await cofiMoney.getMintEnabled(cofi.address))
    //   console.log('COFI Redeem Fee: ' + await cofiMoney.getRedeemFee(cofi.address))
    //   console.log('COFI Redeem enabled: ' + await cofiMoney.getRedeemEnabled(cofi.address))
    //   console.log('COFI Points rate: ' + await cofiMoney.getPointsRate(cofi.address))
    //   console.log('Fee Collector status: ' + await cofiMoney.getFeeCollectorStatus())
    // })

    it('Should onboard new fiAsset', async function () {

      const { owner, diamond, ethfi, weth, veth, feeCollector } = await loadFixture(deploy)

      signer = ethers.provider.getSigner(owner.address)

      const cofiMoney = (await ethers.getContractAt('COFIMoney', diamond.address)).connect(signer)

      await cofiMoney.setMinDeposit(ethfi.address, '10000000000000000')
      await cofiMoney.setMinWithdraw(ethfi.address, '10000000000000000')
      await cofiMoney.setMintFee(ethfi.address, '10')
      await cofiMoney.setRedeemFee(ethfi.address, '10')
      await cofiMoney.setServiceFee(ethfi.address, '1000')
      await cofiMoney.setPointsRate(ethfi.address, '1000000000')

      await cofiMoney.setVault(ethfi.address, veth.address)

      await cofiMoney.toggleMintEnabled(ethfi.address)
      await cofiMoney.toggleRedeemEnabled(ethfi.address)

      // Mint owner 1,000 WETH
      await weth.mint(owner.address, '1000000000000000000000')

      // Approve WETH spend for Vault contract.
      await weth.approve(veth.address, '1000000000000000000000')

      // Owner already whitelisted.

      await cofiMoney.underlyingToFi(
        '1000000000000000000000', // amount:        1,000 ETH.
        '997500000000000000000',  // minAmountOut:  1,000 * 0.9975.
        ethfi.address,             // fiAsset
        owner.address,            // depositFrom
        owner.address,            // recipient
        feeCollector.address      // referral account
      )

      // T0 End Outputs:
      console.log('t0 User COFI bal: ' + await ethfi.balanceOf(owner.address))
      console.log('t0 Vault DAI bal: ' + await ethfi.balanceOf(veth.address))
      console.log('t0 Diamond vDAI bal: ' + await veth.balanceOf(diamond.address))
      console.log('t0 feeCollector COFI bal: ' + await ethfi.balanceOf(feeCollector.address))
      console.log('t0 User Points: ' + await cofiMoney.getPoints(owner.address, [ethfi.address]))
      console.log('t0 feeCollector Points: ' + await cofiMoney.getPoints(feeCollector.address, [ethfi.address]))
      console.log('t0 User External Points: ' + await cofiMoney.getExternalPoints(owner.address))
      console.log('t0 feeCollector External Points: ' + await cofiMoney.getExternalPoints(feeCollector.address))

      // // Simulate 100 DAI yield earned by Vault
      // await dai.mint(vdai.address, '100000000000000000000')

      // Simulate 1% increase
      await cofiMoney.toggleAdmin(ethfi.address)  // Need to set for 1% yield simulation.
      await ethfi.onePercentIncrease()

      const userCOFIBalT1 = await ethfi.balanceOf(owner.address)
      console.log(userCOFIBalT1)

      // T1 End Outputs:
      console.log('t1 User COFI bal: ' + userCOFIBalT1.toString())
      console.log('t1 Vault DAI bal: ' + await weth.balanceOf(veth.address))
      console.log('t1 Diamond vDAI bal: ' + await veth.balanceOf(diamond.address))
      console.log('t1 feeCollector COFI bal: ' + await ethfi.balanceOf(feeCollector.address))
      console.log('t1 User Points: ' + await cofiMoney.getPoints(owner.address, [ethfi.address]))
      console.log('t1 feeCollector Points: ' + await cofiMoney.getPoints(feeCollector.address, [ethfi.address]))
      console.log('t1 User Yield Points: ' + await cofiMoney.getYieldPoints(owner.address, [ethfi.address]))
      console.log('t1 feeCollector Yield Points: ' + await cofiMoney.getYieldPoints(feeCollector.address, [ethfi.address]))

      // Convert back to DAI (redeem operation on FiToken contract skips approval check).
      await cofiMoney.fiToUnderlying(
        userCOFIBalT1.toString(),
        '1005480000000000000000',   // User COFI Bal * 0.9975.
        ethfi.address,
        owner.address,
        owner.address
      )

      // T2 End Outputs:
      console.log('t2 User COFI bal: ' + await ethfi.balanceOf(owner.address))
      console.log('t2 User DAI bal: ' + await weth.balanceOf(owner.address))
      console.log('t2 Vault DAI bal: ' + await weth.balanceOf(veth.address))
      console.log('t2 Diamond vDAI bal: ' + await veth.balanceOf(diamond.address))
      console.log('t2 feeCollector COFI bal: ' + await ethfi.balanceOf(feeCollector.address))
      console.log('t2 User Points: ' + await cofiMoney.getPoints(owner.address, [ethfi.address]))
      console.log('t2 feeCollector Points: ' + await cofiMoney.getPoints(feeCollector.address, [ethfi.address]))
      console.log('t2 User Yield Points: ' + await cofiMoney.getYieldPoints(owner.address, [ethfi.address]))
      console.log('t2 feeCollector Yield Points: ' + await cofiMoney.getYieldPoints(feeCollector.address, [ethfi.address]))
    })
  })
})