/* global ethers */
/* eslint prefer-const: "off" */

async function setDiamond() {
    const accounts = await ethers.getSigners()
    const owner = accounts[0]

    const cofi = await ethers.getContractAt(
        'FiToken',
        '0xFA2dC5b3C09a97DE541ac6D80338C58D3dbF60a6'    // fiAsset address
    )

    await cofi.setDiamond('0x64Cab9754b96fB62F7A3eD04EECf93c59B5eaa67')
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
if (require.main === module) {
    setDiamond()
      .then(() => process.exit(0))
      .catch(error => {
        console.error(error)
        process.exit(1)
      })
  }
  
  exports.setDiamond = setDiamond