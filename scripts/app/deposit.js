/* global ethers */
/* eslint prefer-const: "off" */

async function depositDai() {
    const accounts = await ethers.getSigners()
    const owner = accounts[0]

    const dai = await ethers.getContractAt(
        'ERC20Token',
        '0x0E16C43Da43686EAeaAe69aDbE512b5ce9d50912'    // Dai address
    )

    const diamond = await ethers.getContractAt(
        'COFIMoney',
        '0x8954c3667cCc22162b3272E39a9678FaAe18decF'
    )

    // Try permit, catch approve.

    await dai.approve(
        '0x925df5d5F3edD6B1b2C03dB83955f30dE70Ea49E',   // yvDAI
        '1000000000000000000000000'
    )

    await diamond.underlyingToFi(
        '1000000000000000000000',
        '997500000000000000000',
        '', // Enter COFI token address here.
        owner.address,
        owner.address
    )
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
if (require.main === module) {
    depositDai()
      .then(() => process.exit(0))
      .catch(error => {
        console.error(error)
        process.exit(1)
      })
  }
  
  exports.depositDai = depositDai