const HDWalletProvider = require('@truffle/hdwallet-provider')
const fs = require('fs')
const mnemonic = fs.readFileSync('.secret').toString().trim()

module.exports = {
  networks: {
    development: {
      host: '127.0.0.1', // Localhost (default: none)
      port: 7545, // Standard BSC port (default: none)
      network_id: '*', // Any network (default: none)
    },
    // development: {
    //   provider: () =>
    //     new HDWalletProvider(
    //       mnemonic,
    //       `https://data-seed-prebsc-1-s1.binance.org:8545`,
    //     ),
    //   network_id: 97,
    //   confirmations: 1,
    //   timeoutBlocks: 2000,
    //   skipDryRun: true,
    //   networkCheckTimeout: 1000000,
    //   disableConfirmationListener: true,
    // },
    testnet: {
      provider: () =>
        new HDWalletProvider(
          mnemonic,
          `https://data-seed-prebsc-1-s1.binance.org:8545`,
        ),
      network_id: 97,
      confirmations: 1,
      timeoutBlocks: 2000,
      skipDryRun: true,
      networkCheckTimeout: 1000000,
      disableConfirmationListener: true,
    },
    testnet_mubai: {
      provider: () =>
        new HDWalletProvider(
          mnemonic,
          `https://polygon-mumbai.g.alchemy.com/v2/wzJWxdXWNMUEB8uOtimnWsoiDXI4t6Su`,
        ),
      network_id: 80001,
      confirmations: 1,
      timeoutBlocks: 20000,
      skipDryRun: true,
      networkCheckTimeout: 10000000,
      disableConfirmationListener: true,
    },
    bsc: {
      provider: () =>
        new HDWalletProvider(
          mnemonic,
          `https://data-seed-prebsc-1-s1.binance.org:8545`,
        ),
      network_id: 97,
      confirmations: 1,
      timeoutBlocks: 200,
      skipDryRun: true,
    },
    coinex_testnet: {
      provider: () =>
        new HDWalletProvider(mnemonic, `https://testnet-rpc.coinex.net`),
      network_id: 53,
      confirmations: 2,
      timeoutBlocks: 2000,
      skipDryRun: true,
      networkCheckTimeout: 1000000,
    },
  },

  // Set default mocha options here, use special reporters etc.
  mocha: {
    // timeout: 100000
  },

  // Configure your compilers
  compilers: {
    solc: {
      version: '0.8.14', // A version or constraint - Ex. "^0.8.0"
      settings: {
        optimizer: {
          enabled: true,
          runs: 200,
        },
        evmVersion: 'byzantium',
      },
    },
  },
}
