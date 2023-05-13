/* global ethers */
/* eslint prefer-const: "off" */

/* Run command: npx hardhat run scripts/app/getAdminStatus.js --network mumbai */

async function getAdminStatus() {

    const diamond = await ethers.getContractAt(
        'COFIMoney',
        '0xEBdBbbeA597Ac421E9f0836d06f7AF0eF96e842d'    // Diamond address
    )

    console.log(await diamond.getAdminStatus())
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
if (require.main === module) {
    getAdminStatus()
      .then(() => process.exit(0))
      .catch(error => {
        console.error(error)
        process.exit(1)
      })
  }
  
  exports.getAdminStatus = getAdminStatus