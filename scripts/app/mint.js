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
        '0x61a0DEA56ffb559f50075E7BB8796b1C59408104',   // MA address.
        '1000000000000000000000000'
    )
}

  // Dai deployed: 0x091028e40d6b4c3C5D4F462D52bAE4842A0F9cD2
  // yvDAI deployed: 0xbCA7402CE895450857322Dd30E661aA00Ab29842
  // COFI Dollar deployed: 0xFA2dC5b3C09a97DE541ac6D80338C58D3dbF60a6

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