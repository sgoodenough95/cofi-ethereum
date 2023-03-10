/* global ethers */
/* eslint prefer-const: "off" */

const { getSelectors, FacetCutAction } = require('./libraries/diamond.js')

// const diamond = require('./libraries/index/.js')

// async function deployTokens() {
//     const accounts = await ethers.getSigners()
//     const contractOwner = accounts[0]

    // deploy Stoa Activated Dollar
    //   const StoaActivatedDollar = await ethers.getContractFactory('ActivatedToken')
    //   const stoaActivatedDollar = await StoaActivatedDollar.deploy('Stoa Activated Dollar', 'USDSTA')
    //   await stoaActivatedDollar.deployed()
    //   console.log('Stoa Activated Dollar deployed:', stoaActivatedDollar.address)

    //   // deploy Stoa Activated Dollar
    //   const StoaDeFiActivatedDollar = await ethers.getContractFactory('ActivatedToken')
    //   const stoaDeFiActivatedDollar = await StoaDeFiActivatedDollar.deploy('Stoa DeFi-Activated Dollar', 'USDFI')
    //   await stoaDeFiActivatedDollar.deployed()
    //   console.log('Stoa DeFi-Activated Dollar deployed:', stoaDeFiActivatedDollar.address)

    //   // deploy Stoa Activated Dollar
    //   const StoaDollar = await ethers.getContractFactory('UnactivatedToken')
    //   const stoaDollar = await StoaDollar.deploy('Stoa Dollar', 'USDST')
    //   await stoaDollar.deployed()
    //   console.log('Stoa Dollar deployed:', stoaDollar.address)

    //   // deploy Stoa Activated Dollar
    //   const USDC = await ethers.getContractFactory('UnactivatedToken')
    //   const usdc = await USDC.deploy('USD Coin', 'USDC')
    //   await usdc.deployed()
    //   console.log('USDC deployed:', usdc.address)

    //   // deploy Stoa Activated Dollar
    //   const DAI = await ethers.getContractFactory('UnactivatedToken')
    //   const dai = await DAI.deploy('Dai', 'DAI')
    //   await dai.deployed()
    //   console.log('Dai deployed:', dai.address)

    //   // deploy Stoa Activated Dollar
    //   const AaveUSDC = await ethers.getContractFactory('UnactivatedToken')
    //   const aaveUSDC = await AaveUSDC.deploy('Aave USDC', 'aUSDC')
    //   await aaveUSDC.deployed()
    //   console.log('Aave USDC deployed:', aaveUSDC.address)
    // }

async function deployDiamond () {
  const accounts = await ethers.getSigners()
  const contractOwner = accounts[0]

    //   // deploy Stoa Activated Dollar
    //   const StoaActivatedDollar = await ethers.getContractFactory('ActivatedToken')
    //   const stoaActivatedDollar = await StoaActivatedDollar.deploy('Stoa Activated Dollar', 'USDSTA')
    //   await stoaActivatedDollar.deployed()
    //   console.log('Stoa Activated Dollar deployed:', stoaActivatedDollar.address)

      // deploy Stoa Activated Dollar
      const USDFI = await ethers.getContractFactory('ActiveToken')
      const usdfi = await USDFI.deploy('Stoa DeFi Active Dollar', 'USDFI')
      await usdfi.deployed()
      console.log('Stoa DeFi Active Dollar deployed:', usdfi.address)

      // deploy Stoa Activated Dollar
      const USDSC = await ethers.getContractFactory('CreditToken')
      const usdsc = await USDSC.deploy('Stoa Dollar Credit', 'USDSC')
      await usdsc.deployed()
      console.log('Stoa Dollar Credit deployed:', usdsc.address)

      // deploy Stoa Activated Dollar
      const USDC = await ethers.getContractFactory('CreditToken')
      const usdc = await USDC.deploy('USD Coin', 'USDC')
      await usdc.deployed()
      console.log('USDC deployed:', usdc.address)

      // deploy Stoa Activated Dollar
      const DAI = await ethers.getContractFactory('CreditToken')
      const dai = await DAI.deploy('Dai', 'DAI')
      await dai.deployed()
      console.log('Dai deployed:', dai.address)

      // deploy Stoa Activated Dollar
      const VUSDC = await ethers.getContractFactory('CreditToken')
      const vusdc = await VUSDC.deploy('Vault USDC', 'vUSDC')
      await vusdc.deployed()
      console.log('Vault USDC deployed:', vusdc.address)

      // deploy Stoa Activated Dollar
      const VDAI = await ethers.getContractFactory('CreditToken')
      const vdai = await VDAI.deploy('Vault DAI', 'vDAI')
      await vdai.deployed()
      console.log('Vault DAI deployed:', vdai.address)

      // deploy Stoa Activated Dollar
      const STOA = await ethers.getContractFactory('CreditToken')
      const stoa = await STOA.deploy('Stoa', 'STOA')
      await stoa.deployed()
      console.log('STOA deployed:', stoa.address)

  // deploy DiamondCutFacet
  const DiamondCutFacet = await ethers.getContractFactory('DiamondCutFacet')
  const diamondCutFacet = await DiamondCutFacet.deploy()
  await diamondCutFacet.deployed()
  console.log('DiamondCutFacet deployed:', diamondCutFacet.address)

  // deploy Diamond
  const Diamond = await ethers.getContractFactory('Diamond')
  const diamond = await Diamond.deploy(contractOwner.address, diamondCutFacet.address)
  await diamond.deployed()
  console.log('Diamond deployed:', diamond.address)

  // deploy DiamondInit
  // DiamondInit provides a function that is called when the diamond is upgraded to initialize state variables
  // Read about how the diamondCut function works here: https://eips.ethereum.org/EIPS/eip-2535#addingreplacingremoving-functions
  const DiamondInit = await ethers.getContractFactory('InitDiamond')
  const diamondInit = await DiamondInit.deploy()
  await diamondInit.deployed()
  console.log('DiamondInit deployed:', diamondInit.address)

// const diamondInit = ethers.getContractAt('DiamondInit', '0x3983dfcD3D157d99dEBF962e26e3d8D78eEBF76d')
// const diamondAddr = '0x2B72b533E7EA654d64B39BA153D3a8Df941aB379'

  // deploy facets
  console.log('')
  console.log('Deploying facets')
  const FacetNames = [
    'DiamondLoupeFacet',
    'OwnershipFacet',
    'VaultFacet',
    'SafeVaultFacet',
    'SafeFacet',
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
    USDFI:  usdfi.address,
    USDSC:  usdsc.address,
    USDC:   usdc.address,
    DAI:    dai.address,
    vUSDC:  vusdc.address,
    vDAI:   vdai.address,
    STOA:   stoa.address
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
  return diamond.address
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
if (require.main === module) {
  deployDiamond()
    .then(() => process.exit(0))
    .catch(error => {
      console.error(error)
      process.exit(1)
    })
}

exports.deployDiamond = deployDiamond