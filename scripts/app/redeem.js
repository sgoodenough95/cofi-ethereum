/* global ethers */
/* eslint prefer-const: "off" */

async function redeemDai() {
    const accounts = await ethers.getSigners()
    const owner = accounts[0]

    const cofi = await ethers.getContractAt(
        'FiToken',
        '0xa80b02768341152C48D051eac81A7120E0181ad4'    // Cofi address
    )

    const diamond = await ethers.getContractAt(
        'COFIMoney',
        '0x8954c3667cCc22162b3272E39a9678FaAe18decF'
    )

    await cofi.approve(
        '0x8954c3667cCc22162b3272E39a9678FaAe18decF',   // Diamond address
        '1000000000000000000000000'
    )

    await diamond.fiToInput(
        '1000000000000000000000',
        '997500000000000000000',
        cofi.address,
        owner.address,
        owner.address
    )
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
if (require.main === module) {
    redeemDai()
      .then(() => process.exit(0))
      .catch(error => {
        console.error(error)
        process.exit(1)
      })
  }
  
  exports.redeemDai = redeemDai