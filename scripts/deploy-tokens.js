/* global ethers */
/* eslint prefer-const: "off" */

async function deployTokens() {
    const accounts = await ethers.getSigners()
    const contractOwner = accounts[0]

  // deploy Stoa Activated Dollar
  const StoaActivatedDollar = await ethers.getContractFactory('ActivatedToken')
  const stoaActivatedDollar = await StoaActivatedDollar.deploy('Stoa Activated Dollar', 'USDSTA')
  await stoaActivatedDollar.deployed()
  console.log('Stoa Activated Dollar deployed:', stoaActivatedDollar.address)

  // deploy Stoa Activated Dollar
  const StoaDeFiActivatedDollar = await ethers.getContractFactory('ActivatedToken')
  const stoaDeFiActivatedDollar = await StoaDeFiActivatedDollar.deploy('Stoa DeFi-Activated Dollar', 'USDFI')
  await stoaDeFiActivatedDollar.deployed()
  console.log('Stoa DeFi-Activated Dollar deployed:', stoaDeFiActivatedDollar.address)

  // deploy Stoa Activated Dollar
  const StoaDollar = await ethers.getContractFactory('UnactivatedToken')
  const stoaDollar = await StoaDollar.deploy('Stoa Dollar', 'USDST')
  await stoaDollar.deployed()
  console.log('Stoa Dollar deployed:', stoaDollar.address)

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
  const AaveUSDC = await ethers.getContractFactory('UnactivatedToken')
  const aaveUSDC = await AaveUSDC.deploy('Aave USDC', 'aUSDC')
  await aaveUSDC.deployed()
  console.log('Aave USDC deployed:', aaveUSDC.address)
}