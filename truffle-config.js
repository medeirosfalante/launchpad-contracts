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
    testnet: {
      provider: () =>
        new HDWalletProvider(
          mnemonic,
          `https://kovan.infura.io/v3/f7b459d7ea4448fca122aff2dfa322f0`,
        ),
      network_id: 42,
      confirmations: 2,
      timeoutBlocks: 2000,
      skipDryRun: true,
      networkCheckTimeout: 1000000,
    },
    testnet_mubai: {
      provider: () =>
        new HDWalletProvider(
          mnemonic,
          `https://speedy-nodes-nyc.moralis.io/a068d4499612e52e5bc62566/polygon/mumbai`,
        ),
      network_id: 80001,
      confirmations: 1,
      timeoutBlocks: 20000,
      skipDryRun: true,
      networkCheckTimeout: 10000000,
    },
    bsc: {
      provider: () =>
        new HDWalletProvider(mnemonic, `https://bsc-dataseed1.binance.org`),
      network_id: 56,
      confirmations: 10,
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
      version: '0.8.13', // A version or constraint - Ex. "^0.8.0"
      settings: {
        optimizer: {
          enabled: true,
          runs: 2,
        },
        evmVersion: 'byzantium',
      },
    },
  },
}
