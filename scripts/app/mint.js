/* global ethers */
/* eslint prefer-const: "off" */

/* Run command: npx hardhat run scripts/app/mint.js --network mumbai */

async function mintErc20() {
    const accounts = await ethers.getSigners()
    const owner = accounts[0]

    const token = await ethers.getContractAt(
        'ERC20Token',
        '0x091028e40d6b4c3C5D4F462D52bAE4842A0F9cD2'    // Enter contract here.
    )

    await token.mint(
        '0x01738387092E007CcB8B5a73Fac2a9BA23cf91d3',   // MA address.
        '1000000000000000000000000'
    )
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
if (require.main === module) {
    mintErc20()
      .then(() => process.exit(0))
      .catch(error => {
        console.error(error)
        process.exit(1)
      })
  }
  
  exports.mintErc20 = mintErc20