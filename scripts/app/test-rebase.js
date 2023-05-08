/* global ethers */
/* eslint prefer-const: "off" */

/* Run command: npx hardhat run scripts/app/mint.js --network mumbai */

async function testRebase() {
    const accounts = await ethers.getSigners()
    const owner = accounts[0]

    const token = await ethers.getContractAt(
        'ERC20Token',
        '0xe8399Ba818706F41fb0256758894F93F9dd75316'    // Enter contract here.
    )

    await token.mint(
        '0xbCA7402CE895450857322Dd30E661aA00Ab29842',   // Vault
        '100000000000000000000'
    )

    // COFI Dollar deployed: 0x61A18cc685Ce60290388149911bcEf1e4504bC2b
    // Dai deployed: 0xe8399Ba818706F41fb0256758894F93F9dd75316
    // yvDAI deployed: 0x4aFD6afD49808DEa36dB1c3758D662F43aCB1ADC
    // DiamondCutFacet deployed: 0x8FFD4833615C37EF7341Ed262E75A32221F2677C
    // Diamond deployed: 0x35f4Ab5b66252a9ed65bB13Ae0A9e6617Ae73f69
    // DiamondInit deployed: 0x6c6e135269510f87670C4291654b6A04B281027d
    
    // Deploying facets
    // DiamondLoupeFacet deployed: 0x9bB6ec1B250fb259ee94A088ACf7f5dcf661960D
    // OwnershipFacet deployed: 0xB1B5599C07f6969F6376b4ceCee6b9DDd95D6af2
    // SupplyFacet deployed: 0xD3ea910fC2168D77FA2eF5387C35F1aBCD951335
    // RewardFacet deployed: 0xdE31Ad18CF564f2C7b045657b248B5F570e82241
    // LoupeFacet deployed: 0x95889c5951d29aAc84888203F1e5Ab43008e35aE
    // AdminFacet deployed: 0x7cAfae0D5599EcC4A3e13Eee528329B3D729Ea96

    const diamond = await ethers.getContractAt(
        'COFIMoney',
        '0x64Cab9754b96fB62F7A3eD04EECf93c59B5eaa67'
    )

    // await diamond.rebase('0x091028e40d6b4c3C5D4F462D52bAE4842A0F9cD2', {gasLimit: 40000000})
    console.log(await diamond.getAdminStatus())
    await diamond.toggleAdmin('0x01738387092E007CcB8B5a73Fac2a9BA23cf91d3', {gasLimit: 40000000})
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
if (require.main === module) {
    testRebase()
      .then(() => process.exit(0))
      .catch(error => {
        console.error(error)
        process.exit(1)
      })
  }
  
  exports.testRebase = testRebase