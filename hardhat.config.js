require("@nomicfoundation/hardhat-toolbox");
require("hardhat-diamond-abi");
require('dotenv').config();

const { API_KEY, PRIV_KEY, PRIV_KEY_1, PRIV_KEY_MM } = process.env;

/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
  solidity: "0.8.17",
  diamondAbi: {
    name: "Stoa-Diamond",
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
  }
};