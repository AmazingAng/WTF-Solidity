import '@typechain/hardhat';
import 'hardhat-watcher'
import '@nomiclabs/hardhat-ethers';
import '@nomiclabs/hardhat-waffle';
import '@openzeppelin/hardhat-upgrades';
import 'hardhat-gas-reporter';
import 'hardhat-storage-layout';
import 'dotenv/config';

export default {
  solidity: {
    compilers: [
      {
        version: "0.7.6",
        settings: {
          optimizer: {
            enabled: true,
            runs: 200
          }
        }
      },
      {
        version: "0.8.4",
        settings: {
          optimizer: {
            enabled: true,
            runs: 200
          }
        }
      },
      {
        version: "0.8.15",
        settings: {
          optimizer: {
            enabled: true,
            runs: 200
          }
        }
      },
    ]
  },
  networks: {
    'eth': {
      url: process.env.ETH_API || 'https://api.mycryptoapi.com/eth',
      accounts: {
        mnemonic: process.env.TEST_MN || 'test test test test test test test test test test test test',
        count: 100,
      },
    },
    'bsc': {
      url: process.env.BSC_API || 'https://bsc-dataseed1.ninicoin.io',
      // url: 'https://bsc-dataseed1.ninicoin.io',
      accounts: {
        mnemonic: process.env.TEST_MN || 'test test test test test test test test test test test test',
        count: 100,
      },
      gasPrice: 6 * 1e9
    },
    'bsc-testnet': {
      url: 'https://data-seed-prebsc-1-s1.binance.org:8545/',
      accounts: [process.env.HELP_SCAN_PRIVATE_KEY || '0xb52e6d24f6caacc1961d3cedf04ed3a11a7f4a27a6ce85eeea5dbea6c694f53a',],
    },
  },
  watcher: {
    compilation: {
      tasks: ["compile"],
      files: ["./contracts"],
      verbose: true,
    }
  },
  mocha: {
    timeout: 2000000
  },
  paths: {
    sources: './[0-9][0-9]_**',
    tests: "./test",
    cache: "./cache",
    artifacts: "./artifacts"
  },
  gasReporter: {
      enabled: (process.env.REPORT_GAS) ? true : false
  }
};

