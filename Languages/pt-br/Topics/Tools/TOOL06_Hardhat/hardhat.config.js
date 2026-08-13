require("@nomicfoundation/hardhat-toolbox");

const GOERLI_RPC_URL = process.env.GOERLI_RPC_URL;
const GOERLI_PRIVATE_KEY = process.env.GOERLI_PRIVATE_KEY;

/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
  solidity: "0.8.34",
  networks: GOERLI_RPC_URL && GOERLI_PRIVATE_KEY
    ? {
        goerli: {
          url: GOERLI_RPC_URL,
          accounts: [GOERLI_PRIVATE_KEY],
        },
      }
    : {},
  etherscan: {
    apiKey: "YOUR_ETHERSCAN_API_KEY",
  },
};
