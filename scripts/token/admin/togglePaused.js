/* global ethers */
/* eslint prefer-const: "off" */

async function togglePaused() {

    const cofi = await ethers.getContractAt(
      'FiToken',
      '0xFA2dC5b3C09a97DE541ac6D80338C58D3dbF60a6'    // fiAsset address
    )
  
    // Caller must be admin. Returns true if paused.
    console.log(await cofi.togglePaused())
}
  
// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
if (require.main === module) {
    togglePaused()
      .then(() => process.exit(0))
      .catch(error => {
        console.error(error)
        process.exit(1)
    })
}
    
exports.togglePaused = togglePaused