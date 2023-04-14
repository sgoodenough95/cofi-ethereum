/* global ethers */
/* eslint prefer-const: "off" */

async function mintErc20() {
    const accounts = await ethers.getSigners()
    const owner = accounts[0]

    const token = await ethers.getContractAt(
        'CreditToken',
        '0x0E16C43Da43686EAeaAe69aDbE512b5ce9d50912'
    )

    await token.mint(
        owner.address,
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