/* global ethers */
/* eslint prefer-const: "off" */

/* Run command: npx hardhat run scripts/app/toggleAdmin.js --network mumbai */

async function toggleAdmin() {

    const diamond = await ethers.getContractAt(
        'COFIMoney',
        '0x5769dc91fE18165C98607Ed341275fe39cBefBC7'    // Diamond address
    )

    console.log(await diamond.toggleWhitelist('0x01738387092E007CcB8B5a73Fac2a9BA23cf91d3'))
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
if (require.main === module) {
    toggleAdmin()
      .then(() => process.exit(0))
      .catch(error => {
        console.error(error)
        process.exit(1)
      })
  }
  
  exports.toggleAdmin = toggleAdmin