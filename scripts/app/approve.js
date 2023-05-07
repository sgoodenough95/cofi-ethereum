/* global ethers */
/* eslint prefer-const: "off" */

/* Run command: npx hardhat run scripts/app/approve.js --network mumbai */

async function approveErc20() {
    const accounts = await ethers.getSigners()
    const user = accounts[0]

    const token = await ethers.getContractAt(
        'ERC20Token',
        '0x091028e40d6b4c3C5D4F462D52bAE4842A0F9cD2'    // Enter contract here.
    )

    const vault = await ethers.getContractAt(
        'Vault',
        ''  // Enter Vault address here (e.g., yvDAI).
    )

    await token.approve(
        '', // Spender address (for depositing, this will be the Vault address).
        '115792089237316195423570985008687907853269984665640564039457584007913129639935'    // Max uint256.
    )
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
if (require.main === module) {
    approveErc20()
      .then(() => process.exit(0))
      .catch(error => {
        console.error(error)
        process.exit(1)
      })
  }
  
  exports.approveErc20 = approveErc20