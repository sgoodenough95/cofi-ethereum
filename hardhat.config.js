require("@nomicfoundation/hardhat-toolbox");
// require("@nomicfoundation/hardhat-verify");
// require("@nomiclabs/hardhat-waffle");
require("@nomiclabs/hardhat-ethers");
require("hardhat-diamond-abi");
require('dotenv').config();

const { API_KEY, PRIV_KEY, PRIV_KEY_1, PRIV_KEY_MM, PSCAN_KEY, STOA_INFURA_API_KEY, STOA_PRIV_KEY, STOA_ARB_SCAN_API_KEY } = process.env;

/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
  solidity: {
    version: "0.8.19",
    settings: {
      optimizer: {
        enabled: true,
        runs: 1000,
      },
      viaIR: false,
    },
  },
  diamondAbi: {
    name: "COFIMoney",
    include: ["Facet"],
  },
  networks: {
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
    }
  },
  etherscan: {
    apiKey: {
      arbitrumGoerli: `${STOA_ARB_SCAN_API_KEY}`
    }
  }

  // settings: {
  //   optimizer: {
  //     enabled: true,
  //     runs: 1000,
  //   },
  //   viaIR: true,
  // }
};