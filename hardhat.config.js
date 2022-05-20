require("dotenv").config();

require("@nomiclabs/hardhat-etherscan");
require("@nomiclabs/hardhat-waffle");
require("hardhat-gas-reporter");
require("solidity-coverage");

// This is a sample Hardhat task. To learn how to create your own go to
// https://hardhat.org/guides/create-task.html
task("accounts", "Prints the list of accounts", async (taskArgs, hre) => {
  const accounts = await hre.ethers.getSigners();

  for (const account of accounts) {
    console.log(account.address);
  }
});

// You need to export an object to set up your config
// Go to https://hardhat.org/config/ to learn more

/**
 * @type import('hardhat/config').HardhatUserConfig
 */
module.exports = {
  solidity: {
    version: "0.8.4",
    settings: {
      optimizer: {
        enabled: true,
        runs: 200,
      },
    },
    outputSelection: {
      "*": {
        "*": ["evm.bytecode", "evm.deployedBytecode", "abi"],
      },
    },
  },
  networks: {
    localhost: {
      url: process.env.LOCAL_URL || "",
      accounts:
        process.env.LOCAL_PRIVATE_KEY !== undefined
          ? [process.env.LOCAL_PRIVATE_KEY]
          : [],
    },
    bscTestnet: {
      url: "https://speedy-nodes-nyc.moralis.io/86519729daec0d9c5cb0fd8f/bsc/testnet",
      accounts: { mnemonic: process.env.MNEMONIC },
    },
    // testnet: {
    //   url: `https://data-seed-prebsc-1-s1.binance.org:8545`,
    //   accounts: { mnemonic: process.env.MNEMONIC },
    //   network_id: 97,
    //   confirmations: 10,
    //   timeoutBlocks: 200,
    //   skipDryRun: true,
    // },
    // mainnet: {
    //   url: "https://bsc-dataseed.binance.org/",
    //   chainId: 56,
    //   gasPrice: 20000000000,
    //   accounts: { mnemonic: process.env.PRODUCTION_MNEMONIC },
    // },
  },
  gasReporter: {
    enabled: process.env.REPORT_GAS !== undefined,
    currency: "USD",
  },
  etherscan: {
    apiKey: {
      // process.env.BSCSCAN_KEY,
      bscTestnet: process.env.BLOCK_EXPLORER_API_KEY,
    } 
  },
};
