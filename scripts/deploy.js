//const { ethers } = require("ethers");
const fs = require("fs");
const { network } = require("hardhat");
// This is a script for deploying your contracts. You can adapt it to deploy
// yours, or create new ones.
async function main() {

  // This is just a convenience check
  if (network.name === "hardhat") {
    console.warn("You are trying to deploy a contract to the Hardhat Network, which" +
        "gets automatically created and destroyed every time. Use the Hardhat" +
        " option '--network localhost'");
  }

  let traitHash = ethers.utils.keccak256("0x123456")
  let oneETH = ethers.utils.parseEther("1.0")
  let pointOneETH = ethers.utils.parseEther("0.1")
  let ogs = [20]
  let ags = [200]
  let rgs = [2000]
  let ogp = [oneETH]
  let agp = [oneETH]
  let rgp = [pointOneETH]

    let wallet = "0xb6c6920327B33f8eeC26786c7462c5F4098D47E3"

    
    let [owner] = await ethers.getSigners()
    console.log(await owner.getAddress())
    console.log("network :",network.name)

    const [deployer] = await ethers.getSigners();
    console.log("deploy:",deployer.address)
    Random = await ethers.getContractFactory("random");
    random = await Random.deploy();
   
    Token = await ethers.getContractFactory("ethercards");
    token = await Token.deploy(traitHash, random.address, ogs,ogp, ags,agp, rgs,rgp,0,"1645137615",wallet);

    console.log("Ether Cards",token.address)


  

  }
  

  


 



function saveFrontendFiles(contract,contractName,obj) {
 
  const contractsDir = __dirname + "/../frontend/src/contracts";

  if (!fs.existsSync(contractsDir)) {
    fs.mkdirSync(contractsDir);
  }
  obj[contractName] = contract.address;

  fs.writeFileSync(contractsDir + "/contract-address.json", JSON.stringify(obj, undefined, 2));

  const TokenArtifact = artifacts.readArtifactSync(contractName);

  fs.writeFileSync(contractsDir + "/"+contractName+".json", JSON.stringify(TokenArtifact, null, 2));
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
