require("@nomiclabs/hardhat-waffle");
require("hardhat-deploy");
const fs = require("fs")

const INFURA_ID = '';
const OWNER_PRIVATE_KEY = '';

task("accounts", "Prints the list of accounts", async () => {
  const accounts = await ethers.getSigners();

  for (const account of accounts) {
    console.log(account.address);
  }
});

let mnemonic = ""
let main_key = ""
try {
  mnemonic = (fs.readFileSync("./mnemonic.txt")).toString().trim()
} catch (e) { /* ignore for now because it might now have a mnemonic.txt file */ 
  console.log(e)
}
// try{
//  main_key = (fs.readFileSync("./mainnet.txt")).toString().trim()
// }catch(e){ /* ignore for now because it might now have a mnemonic.txt file */ }
console.log("menmonic:",mnemonic)
/**
 * @type import('hardhat/config').HardhatUserConfig
 */
module.exports = {
  solidity: {
    //version: "0.7.3"
    compilers: [
      { version: "0.6.6", settings: {} },
      { version: "0.7.3", settings: {} }
    ],
  },
  defaultNetwork: "hardhat",
  networks: {
    hardhat: {
     
    },
    localhost: {
      url: 'http://localhost:8545',
      chainId: 31337
    },
    ganache: {
      url: 'http://localhost:7545',
      chainId: 1337
    },
    rinkeby: {
      url: `https://rinkeby.infura.io/v3/${INFURA_ID}`,
      accounts: {
        mnemonic: mnemonic
      },

      chainId: 4
    },
    kovan: {
      url: `https://kovan.infura.io/v3/${INFURA_ID}`,
      accounts: {
        mnemonic: mnemonic
      },

      chainId: 42
    }
  },


  paths: {
    sources: "./contracts",
    tests: "./test",
    cache: "./cache",
    artifacts: "./artifacts"
  }
};
