require("@nomicfoundation/hardhat-toolbox");
require("dotenv").config();

/** @type import('hardhat/config').HardhatUserConfig */

const PRIVATE_KEY= process.env.PRIVATE_KEY;
const RPC_URL = process.env.RPC_URL;

module.exports = {
  solidity: "0.8.19",
  networks: {
    sepolia: {
      url: RPC_URL,
      accounts: [PRIVATE_KEY],
    },
  },

  etherscan: {
  apiKey: "91RK36C98DYU3SF5QYDPCWMBA2BP4U2SNU",
  },

};
