/* global ethers */
/* eslint prefer-const: "off" */

// NOTE: Whitelist disabled for testing purposes, so no need to run this script.

async function whitelist() {
    const accounts = await ethers.getSigners()
    const owner = accounts[0]

    const diamond = await ethers.getContractAt(
        'COFIMoney',
        '0x8954c3667cCc22162b3272E39a9678FaAe18decF'
    )

    await diamond.setWhitelist(
        owner.address,      // Address to whitelist
        '1'
    )
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
if (require.main === module) {
    whitelist()
      .then(() => process.exit(0))
      .catch(error => {
        console.error(error)
        process.exit(1)
      })
  }
  
  exports.whitelist = whitelist