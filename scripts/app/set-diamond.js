/* global ethers */
/* eslint prefer-const: "off" */

/* Run command: npx hardhat run scripts/app/set-diamond.js --network mumbai */

async function setDiamond() {
  const accounts = await ethers.getSigners()
  const owner = accounts[0]

  const cofi = await ethers.getContractAt(
    'FiToken',
    '0xFA2dC5b3C09a97DE541ac6D80338C58D3dbF60a6'    // Enter contract here.
  )

  await cofi.setDiamond('0xEBdBbbeA597Ac421E9f0836d06f7AF0eF96e842d')
}

  // Dai deployed: 0x091028e40d6b4c3C5D4F462D52bAE4842A0F9cD2
  // yvDAI deployed: 0xbCA7402CE895450857322Dd30E661aA00Ab29842
  // COFI Dollar deployed: 0xFA2dC5b3C09a97DE541ac6D80338C58D3dbF60a6

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
if (require.main === module) {
    setDiamond()
      .then(() => process.exit(0))
      .catch(error => {
        console.error(error)
        process.exit(1)
      })
  }
  
  exports.setDiamond = setDiamond