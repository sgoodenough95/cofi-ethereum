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
    const ethfi = await ETHFI.deploy('COFI Ethreum', 'ETHFI')
    await ethfi.deployed()
    console.log('COFI Ethereum deployed:', ethfi.address)

    // Deploy COFI Bitcoin
    const BTCFI = await ethers.getContractFactory('FiToken')
    const btcfi = await BTCFI.deploy('COFI Bitcoin', 'BTCFI')
    await btcfi.deployed()
    console.log('COFI Ethereum deployed:', btcfi.address)
      
    // Deploy USDC
    const USDC = await ethers.getContractFactory('ERC20Token')
    const usdc = await USDC.deploy('USD Coin', 'USDC', 6)
    await usdc.deployed()
    console.log('USDC deployed:', usdc.address)
      
    // Deploy WETH
    const WETH = await ethers.getContractFactory('ERC20Token')
    const weth = await WETH.deploy('Wrapped Ethereum', 'WETH', 18)
    await weth.deployed()
    console.log('wETH deployed:', weth.address)

    // Deploy WETH
    const WBTC = await ethers.getContractFactory('ERC20Token')
    const wbtc = await WBTC.deploy('Wrapped Ethereum', 'WETH', 8)
    await wbtc.deployed()
    console.log('wBTC deployed:', wbtc.address)
      
    // Deploy vUSDC
    const VUSDC = await ethers.getContractFactory('Vault')
    const vusdc = await VUSDC.deploy(usdc.address, 'Vault USDC', 'vUSDC')
    await vusdc.deployed()
    console.log('vDAI deployed:', vusdc.address)
      
    // Deploy vETH
    const VETH = await ethers.getContractFactory('Vault')
    const veth = await VETH.deploy(weth.address, 'Vault Ethereum', 'vETH')
    await veth.deployed()
    console.log('vETH deployed:', veth.address)

    // Deploy vBTC
    const VBTC = await ethers.getContractFactory('Vault')
    const vbtc = await VBTC.deploy(wbtc.address, 'Vault Bitcoin', 'vBTC')
    await vbtc.deployed()
    console.log('vBTC deployed:', vbtc.address)
      
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
    await btcfi.setDiamond(diamond.address)
      
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
      'PartnerFacet',
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
      ETHFI:  ethfi.address,
      BTCFI:  btcfi.address,
      vUSDC:  vusdc.address,
      vETH:   veth.address,
      vBTC:   vbtc.address,
      USDC:   usdc.address,
      wETH:   weth.address,
      wBTC:   wbtc.address,
      admins: [
        feeCollector.address
      ],
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
      owner, feeCollector, diamond, cofi, usdc, vusdc
    }
  }

  describe('SupplyFacet', function() {

    // it('Should execute function by sig', async function() {

    //   const { owner, diamond, cofi } = await loadFixture(deploy)

    //   signer = ethers.provider.getSigner(owner.address)

    //   const cofiMoney = (await ethers.getContractAt('COFIMoney', diamond.address)).connect(signer)

    //   await cofiMoney._executeBySig(cofi.address)

    //   await cofiMoney._execute()
    // })

    it('Should exchange USDC for COFI --x, rebase, and back again x--', async function() {

      const { owner, feeCollector, diamond, cofi, usdc, vusdc } = await loadFixture(deploy)

      // Mint owner 1,000 DAI
      await usdc.mint(owner.address, '1000000000')

      // Approve DAI spend for Diamond contract.
      await usdc.approve(diamond.address, '1000000000')

      signer = ethers.provider.getSigner(owner.address)

      const cofiMoney = (await ethers.getContractAt('COFIMoney', diamond.address)).connect(signer)

      // Owner already whitelisted.

      await cofiMoney.underlyingToFi(
        '1000000000', // amount:        1,000 DAI.
        '997500000000000000000',  // minAmountOut:  1,000 * 0.9975 [fiAssets].
        cofi.address,             // fiAsset
        owner.address,            // depositFrom
        owner.address,            // recipient
        feeCollector.address      // referral account
      )

      // T0 End Outputs:
      console.log('t0 User COFI bal: ' + await cofi.balanceOf(owner.address))
      console.log('t0 Vault USDC bal: ' + await usdc.balanceOf(vusdc.address))
      console.log('t0 Diamond vUSDC bal: ' + await vusdc.balanceOf(diamond.address))
      console.log('t0 feeCollector COFI bal: ' + await cofi.balanceOf(feeCollector.address))
      console.log('t0 User Points: ' + await cofiMoney.getPoints(owner.address, [cofi.address]))
      console.log('t0 feeCollector Points: ' + await cofiMoney.getPoints(feeCollector.address, [cofi.address]))
      console.log('t0 User External Points: ' + await cofiMoney.getExternalPoints(owner.address))
      console.log('t0 feeCollector External Points: ' + await cofiMoney.getExternalPoints(feeCollector.address))

      const rcpt0 = await cofi.rebasingCreditsPerTokenHighres()
      const ts0 = await cofi.totalSupply()

      console.log('rcpt: ' + rcpt0)
      console.log('ts0: ' + ts0)

      // Simulate 10% increase
      // await cofi.percentIncrease(10000)

      await usdc.mint(vusdc.address, '1000000000000')
      await cofiMoney.rebase(cofi.address)

      const userCOFIBalT1 = await cofi.balanceOf(owner.address)
      const rcpt = await cofi.rebasingCreditsPerTokenHighres()
      const ts1 = await cofi.totalSupply()

      console.log('rcpt: ' + rcpt)
      console.log('ts1: ' + ts1)

      // Simulate 20% increase
      // await cofi.percentIncrease(1000)

      // const rcpt2 = await cofi.rebasingCreditsPerToken()
      // const ts2= await cofi.totalSupply()
      
      // console.log('rcpt2: ' + rcpt2)
      // console.log('ts2: ' + ts2)

      // T1 End Outputs:
      console.log('t1 User COFI bal: ' + userCOFIBalT1.toString())
      console.log('t1 Vault USDC bal: ' + await usdc.balanceOf(vusdc.address))
      console.log('t1 Diamond vUSDC bal: ' + await vusdc.balanceOf(diamond.address))
      console.log('t1 feeCollector COFI bal: ' + await cofi.balanceOf(feeCollector.address))
      console.log('t1 User Points: ' + await cofiMoney.getPoints(owner.address, [cofi.address]))
      console.log('t1 feeCollector Points: ' + await cofiMoney.getPoints(feeCollector.address, [cofi.address]))
      console.log('t1 User Yield Points: ' + await cofiMoney.getYieldPoints(owner.address, [cofi.address]))
      console.log('t1 feeCollector Yield Points: ' + await cofiMoney.getYieldPoints(feeCollector.address, [cofi.address]))

      // Convert back to DAI (redeem operation on FiToken contract skips approval check).
      await cofiMoney.fiToUnderlying(
        userCOFIBalT1.toString(),
        '1000000000',   // User COFI Bal * 0.9975.
        cofi.address,
        owner.address,
        owner.address
      )

      // T2 End Outputs:
      console.log('t2 User COFI bal: ' + await cofi.balanceOf(owner.address))
      console.log('t2 User USDC bal: ' + await usdc.balanceOf(owner.address))
      console.log('t2 Vault USDC bal: ' + await usdc.balanceOf(vusdc.address))
      console.log('t2 Diamond vUSDC bal: ' + await vusdc.balanceOf(diamond.address))
      console.log('t2 feeCollector COFI bal: ' + await cofi.balanceOf(feeCollector.address))
      console.log('t2 User Points: ' + await cofiMoney.getPoints(owner.address, [cofi.address]))
      console.log('t2 feeCollector Points: ' + await cofiMoney.getPoints(feeCollector.address, [cofi.address]))
      console.log('t2 User Yield Points: ' + await cofiMoney.getYieldPoints(owner.address, [cofi.address]))
      console.log('t2 feeCollector Yield Points: ' + await cofiMoney.getYieldPoints(feeCollector.address, [cofi.address]))
    })
  })
})