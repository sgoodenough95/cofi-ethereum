require("@nomicfoundation/hardhat-toolbox");
// require("@nomiclabs/hardhat-waffle");
require("@nomiclabs/hardhat-ethers");
require("hardhat-diamond-abi");
require('dotenv').config();

const { API_KEY, PRIV_KEY, PRIV_KEY_1, PRIV_KEY_MM } = process.env;

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
    }
  },
  // settings: {
  //   optimizer: {
  //     enabled: true,
  //     runs: 1000,
  //   },
  //   viaIR: true,
  // }
};