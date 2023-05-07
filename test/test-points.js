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
      
    // Deploy DAI
    const DAI = await ethers.getContractFactory('ERC20Token')
    const dai = await DAI.deploy('Dai', 'DAI')
    await dai.deployed()
    console.log('Dai deployed:', dai.address)
      
    // Deploy yvDAI
    const YVDAI = await ethers.getContractFactory('Vault')
    const yvdai = await YVDAI.deploy(dai.address, 'Yearn Vault Dai', 'yvDAI')
    await yvdai.deployed()
    console.log('yvDAI deployed:', yvdai.address)
      
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

    // Deploy COFI Points token
    const COFIPoint = await ethers.getContractFactory('PointToken')
    const erc20Point = await COFIPoint.deploy('COFI Point', 'PNT', diamond.address, [cofi.address])
    await erc20Point.deployed()
    console.log('Point token deployed:', erc20Point.address)

    return {
      accounts, owner, diamond, cofi, dai, yvdai, erc20Point, alice, bob
    }
  }

  describe('RewardFacet', function() {

    it('Should get correct points from yield earned', async function() {

      const { owner, diamond, cofi, dai, yvdai, erc20Point } = await loadFixture(deploy)

      // Mint owner 1,000 DAI
      await dai.mint(owner.address, '1000000000000000000000')

      await dai.approve(yvdai.address, '1000000000000000000000')

      signer = ethers.provider.getSigner(owner.address)

      const cofiMoney = (await ethers.getContractAt('COFIMoney', diamond.address)).connect(signer)

      // Obtain COFI.
      await cofiMoney.underlyingToFi(
        '1000000000000000000000',
        '997500000000000000000',
        cofi.address,
        owner.address,
        owner.address
      )

      // Get bal t0
      console.log('t0 bal: ' + await cofi.balanceOf(owner.address))
      // Get yield earned t0
      console.log('t0 yield earned: ' + await cofi.getYieldEarned(owner.address))
      // Get points earned t0
      console.log('t0 points earned: ' + await cofiMoney.getPoints(owner.address, [cofi.address]))
      // Get erc20 points t0
      console.log('t0 erc20 points earned: ' + await erc20Point.balanceOf(owner.address))

      // Simulate 100 DAI yield earned by Vault
      await dai.mint(yvdai.address, '100000000000000000000')

      // Rebase
      await cofiMoney.rebase(cofi.address)

      // Get bal t1
      console.log('t1 bal: ' + await cofi.balanceOf(owner.address))
      // Get yield earned t1
      console.log('t1 yield earned: ' + await cofi.getYieldEarned(owner.address))
      // Get yield earned t1
      console.log('t1 points earned: ' + await cofiMoney.getPoints(owner.address, [cofi.address]))
      // Get erc20 points t1
      console.log('t1 erc20 points earned: ' + await erc20Point.balanceOf(owner.address))

      // Distribute points
      await cofiMoney.reward([owner.address], '10000000000000000000000')

      // Get yield earned t2
      console.log('t2 points earned: ' + await cofiMoney.getPoints(owner.address, [cofi.address]))
      // Get yield points t2
      console.log('t2 yield points earned: ' + await cofiMoney.getYieldPoints(owner.address, [cofi.address]))
      // Get external points t2
      console.log('t2 external points earned: ' + await cofiMoney.getExternalPoints(owner.address))
      // Get erc20 points t2
      console.log('t2 erc20 points earned: ' + await erc20Point.balanceOf(owner.address))      
    })

    it('Should apply pointsRate change correctly', async function() {

      const { owner, diamond, cofi, dai, yvdai, erc20Point } = await loadFixture(deploy)

      // Mint owner 1,000 DAI
      await dai.mint(owner.address, '1000000000000000000000')

      await dai.approve(yvdai.address, '1000000000000000000000')

      signer = ethers.provider.getSigner(owner.address)

      const cofiMoney = (await ethers.getContractAt('COFIMoney', diamond.address)).connect(signer)

      // Obtain COFI.
      await cofiMoney.underlyingToFi(
        '1000000000000000000000',
        '997500000000000000000',
        cofi.address,
        owner.address,
        owner.address
      )

      // Get bal t0
      console.log('t0 bal: ' + await cofi.balanceOf(owner.address))
      // Get yield earned t0
      console.log('t0 yield earned: ' + await cofi.getYieldEarned(owner.address))
      // Get points earned t0
      console.log('t0 points earned: ' + await cofiMoney.getPoints(owner.address, [cofi.address]))
      // Get erc20 points t0
      console.log('t0 erc20 points earned: ' + await erc20Point.balanceOf(owner.address))

      // Simulate 100 DAI yield earned by Vault
      await dai.mint(yvdai.address, '100000000000000000000')

      // Rebase
      await cofiMoney.rebase(cofi.address)

      // Get bal t1
      console.log('t1 bal: ' + await cofi.balanceOf(owner.address))
      // Get yield earned t1
      console.log('t1 yield earned: ' + await cofi.getYieldEarned(owner.address))
      // Get yield earned t1
      console.log('t1 points earned: ' + await cofiMoney.getPoints(owner.address, [cofi.address]))
      // Get erc20 points t1
      console.log('t1 erc20 points earned: ' + await erc20Point.balanceOf(owner.address))

      // Lock in points, so that pointsRate change does not apply to previous yield.
      await cofiMoney.captureYieldPoints(owner.address, cofi.address)

      // Reduce pointsRate by 50%
      await cofiMoney.setPointsRate(cofi.address, '500000')

      // Simulate 100 DAI yield earned by Vault
      await dai.mint(yvdai.address, '100000000000000000000')

      // Rebase
      await cofiMoney.rebase(cofi.address)

      // Get bal t2
      console.log('t2 bal: ' + await cofi.balanceOf(owner.address))
      // Get yield earned t2
      console.log('t2 yield earned: ' + await cofi.getYieldEarned(owner.address))
      // Get yield earned t2
      console.log('t2 points earned: ' + await cofiMoney.getPoints(owner.address, [cofi.address]))
      // Get erc20 points t2
      console.log('t2 erc20 points earned: ' + await erc20Point.balanceOf(owner.address))      
    })

    it('Should batch apply pointsRate change correctly', async function() {

      const { accounts, owner, diamond, cofi, dai, yvdai, erc20Point } = await loadFixture(deploy)

      // Mint owner 50,000 DAI
      await dai.mint(owner.address, '50000000000000000000000')

      await dai.approve(yvdai.address, '50000000000000000000000')

      signer = ethers.provider.getSigner(owner.address)

      const cofiMoney = (await ethers.getContractAt('COFIMoney', diamond.address)).connect(signer)

      // Obtain COFI.
      await cofiMoney.underlyingToFi(
        '20000000000000000000000',
        '19950000000000000000000',
        cofi.address,
        owner.address,
        owner.address
      )

      // Send 1,000 COFI each to 19 accounts
      for(let i = 1; i < accounts.length; i++) {
        await cofi.transfer(
          accounts[i].address,
          '1000000000000000000000'
        )
      }

      // Check edge conditions
      console.log('t0 owner COFI bal: ' + await cofi.balanceOf(owner.address))
      console.log('t0 accounts[max] COFI bal: ' + await cofi.balanceOf(accounts[19].address))

      // Simulate 2,000 DAI yield earned by Vault
      await dai.mint(yvdai.address, '2000000000000000000000')

      // Rebase
      await cofiMoney.rebase(cofi.address)

      // Check edge conditions
      console.log('t1 owner COFI bal: ' + await cofi.balanceOf(owner.address))
      console.log('t1 accounts[max] COFI bal: ' + await cofi.balanceOf(accounts[19].address))
      console.log('t1 owner points bal: ' + await erc20Point.balanceOf(owner.address))
      console.log('t1 accounts[max] points bal: ' + await erc20Point.balanceOf(accounts[19].address))

      let accountsArray = []
      for(let i = 0; i < accounts.length; i++) {
        accountsArray.push(accounts[i].address)
      }

      // Lock in points, so that pointsRate change does not apply to previous yield.
      await cofiMoney.batchCaptureYieldPoints(
        accountsArray,
        cofi.address
      )

      // Check edge conditions
      console.log('t2 owner points bal: ' + await erc20Point.balanceOf(owner.address))
      console.log('t2 accounts[max] points bal: ' + await erc20Point.balanceOf(accounts[accounts.length-1].address))

      // Reduce pointsRate by 50%
      await cofiMoney.setPointsRate(cofi.address, '500000')

      // Simulate 2,000 DAI yield earned by Vault
      await dai.mint(yvdai.address, '2000000000000000000000')

      // Rebase
      await cofiMoney.rebase(cofi.address)

      // Check edge conditions
      console.log('t3 owner COFI bal: ' + await cofi.balanceOf(owner.address))
      console.log('t3 accounts[max] COFI bal: ' + await cofi.balanceOf(accounts[accounts.length-1].address))
      console.log('t3 owner points bal: ' + await erc20Point.balanceOf(owner.address))
      console.log('t3 accounts[max] points bal: ' + await erc20Point.balanceOf(accounts[accounts.length-1].address))    
    })
  })
})