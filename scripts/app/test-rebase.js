/* global ethers */
/* eslint prefer-const: "off" */

/* Run command: npx hardhat run scripts/app/mint.js --network mumbai */

async function testRebase() {
    const accounts = await ethers.getSigners()
    const owner = accounts[0]

    const dai = await ethers.getContractAt(
        'ERC20Token',
        '0x091028e40d6b4c3C5D4F462D52bAE4842A0F9cD2'    // Enter underlyingAsset here.
    )

    const cofi = await ethers.getContractAt(
        'FiToken',
        '0xFA2dC5b3C09a97DE541ac6D80338C58D3dbF60a6'    // Enter fiAsset here.
    )

    await dai.mint(
        '0xbCA7402CE895450857322Dd30E661aA00Ab29842',   // Vault
        '100000000000000000000'                         // 100 DAI yield.
    )

  // Dai deployed: 0x091028e40d6b4c3C5D4F462D52bAE4842A0F9cD2
  // yvDAI deployed: 0xbCA7402CE895450857322Dd30E661aA00Ab29842
  // COFI Dollar deployed: 0xFA2dC5b3C09a97DE541ac6D80338C58D3dbF60a6

    const diamond = await ethers.getContractAt(
        'COFIMoney',
        '0x64Cab9754b96fB62F7A3eD04EECf93c59B5eaa67'
    )

    // await cofi.setDiamond('0x64Cab9754b96fB62F7A3eD04EECf93c59B5eaa67')

    const tx = await diamond.rebase('0xFA2dC5b3C09a97DE541ac6D80338C58D3dbF60a6')  // , {gasLimit: 40000000}
    console.log(tx)

    console.log('Owner COFI bal: ' + await cofi.balanceOf(owner.address))
    console.log('Total supply COFI: ' + await cofi.totalSupply())
    console.log('Total supply DAI: ' + await dai.totalSupply())
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