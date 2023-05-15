/* global ethers */
/* eslint prefer-const: "off" */

/* Run command: npx hardhat run scripts/app/toggleAdmin.js --network mumbai */

async function toggleAdmin() {

    const diamond = await ethers.getContractAt(
        'COFIMoney',
        '0xEBdBbbeA597Ac421E9f0836d06f7AF0eF96e842d'    // Diamond address
    )

    console.log(await diamond.toggleAdmin('0x01738387092E007CcB8B5a73Fac2a9BA23cf91d3'))
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