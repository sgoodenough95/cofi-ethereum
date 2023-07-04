/* global ethers */
/* eslint prefer-const: "off" */

/* Run command: npx hardhat run scripts/app/mint.js --network mumbai */

async function mintErc20() {

    /**
     * Task: Change current ETHFI for new ETHFI.
     * 
     * 1. Deploy new ETHFI contract.
     * 2. Set parameters in ETHFI and Diamond.
     * 3. Disable mint/redeem of old ETHFI.
     */

    // Deploy COFI Ethereum
    const ETHFI = await ethers.getContractFactory('FiToken')
    const ethfi = await ETHFI.deploy('COFI Ethereum', 'ETHFI')
    await ethfi.deployed()
    console.log('COFI Ethereum deployed:', ethfi.address)

    await ethfi.setDiamond('0x1B61BD8Cc32D77c6aa1EfE27eF51223b8c078e78')

    
}