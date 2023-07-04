require("@nomicfoundation/hardhat-toolbox");
require("@nomiclabs/hardhat-ethers");
require("@nomicfoundation/hardhat-foundry");
require("hardhat-diamond-abi");
require('dotenv').config();

const { API_KEY, PRIV_KEY, PRIV_KEY_1, PRIV_KEY_MM, PSCAN_KEY, STOA_INFURA_API_KEY, STOA_PRIV_KEY, STOA_ARB_SCAN_API_KEY, STOA_OPT_SCAN_API_KEY } = process.env;

/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
  solidity: {
    version: "0.8.20",
    settings: {
      optimizer: {
        enabled: true,
        runs: 1000,
      },
      viaIR: true,
    },
  },
  diamondAbi: {
    name: "COFIMoney",
    include: ["Facet"],
    strict: false
  },
  networks: {
    optimisticEthereum: {
      url: `https://optimism-mainnet.infura.io/v3/${STOA_INFURA_API_KEY}`,
      accounts: [`${STOA_PRIV_KEY}`]
    },
    arbitrumOne: {
      url: `https://arbitrum-mainnet.infura.io/v3/${STOA_INFURA_API_KEY}`,
      accounts: [`${STOA_PRIV_KEY}`]
    },
    mumbai: {
      url: `https://polygon-mumbai.infura.io/v3/${API_KEY}`,
      accounts: [`${PRIV_KEY_MM}`]
    },
    goerli: {
      url: `https://goerli.infura.io/v3/${API_KEY}`,
      accounts: [`${PRIV_KEY_1}`]
    },
    arbGoerli: {
      url: `https://arbitrum-goerli.infura.io/v3/${STOA_INFURA_API_KEY}`,
      accounts: [`${STOA_PRIV_KEY}`]
    },
    // hardhat: {
    //   forking: {
    //     // url: `https://arbitrum-mainnet.infura.io/v3/${STOA_INFURA_API_KEY}`
    //     url: `https://optimism-mainnet.infura.io/v3/${STOA_INFURA_API_KEY}`
    //   }
    // }
  },
  etherscan: {
    apiKey: {
      // arbitrumOne: `${STOA_ARB_SCAN_API_KEY}`,
      optimisticEthereum: `${STOA_OPT_SCAN_API_KEY}`,
      // arbitrumGoerli: `${STOA_ARB_SCAN_API_KEY}`
    }
  }
};