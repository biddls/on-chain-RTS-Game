require("@nomiclabs/hardhat-waffle");
require('solidity-coverage')
require("hardhat-gas-reporter");
require('hardhat-spdx-license-identifier');
require("hardhat-interface-generator");

// import {ALCHEMY_API_KEY, ROPSTEN_PRIVATE_KEY} from "key.js";
const { ALCHEMY_API_KEY, ROPSTEN_PRIVATE_KEY } = require("./key.js");

module.exports = {
  defaultNetwork: "hardhat",
  networks: {
    hardhat: {
      initialBaseFeePerGas: 0
    },
    ropsten: {
      url: `https://eth-ropsten.alchemyapi.io/v2/${ALCHEMY_API_KEY}`,
      accounts: [`0x${ROPSTEN_PRIVATE_KEY}`],
    },
  },
  solidity: {
    version: "0.8.7",
    settings: {
      optimizer: {
        enabled: true,
        runs: 200
      },
    }
  },
  paths: {
    sources: "./contracts",
    tests: "./test",
    cache: "./cache",
    artifacts: "./artifacts"
  },
  gasReporter: {//comment me out to toggle
    enabled: process.env.REPORT_GAS
  }
  // npx hardhat coverage

  // npx hardhat node
  // npx hardhat run --network localhost script/deploy.js
};// yarn hardhat gen-interface <contract name>
