/* global ethers */
/* eslint prefer-const: "off" */

const { getSelectors, FacetCutAction } = require('./libraries/diamond.js')

async function deployDiamond() {
  const accounts = await ethers.getSigners()
  const contractOwner = accounts[0]

  // First deploy tokens
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

  // Mint owner 1,000,000 DAI.
  await dai.mint(contractOwner.address, '1000000000000000000000000')

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

  // Mint owner 1,000,000 WETH.
  // await weth.mint(contractOwner.address, '1000000000000000000000000')

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
  const diamond = await Diamond.deploy(contractOwner.address, diamondCutFacet.address)
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
    DAI:    dai.address,
    // WETH:   weth.address,
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