const { ZERO_ADDRESS, ROLE, Data } = require('./helpers/common');

// Hardhat tests are normally written with Mocha and Chai.

// We import Chai to use its asserting functions here.
const { expect } = require("chai");
const { ethers } = require('hardhat');

describe("Ether Cards contract", function () { 

    let data;

    let Token
    let token

    let owner;
    let addr1;
    let addr2;
    let addrs;

    beforeEach(async function () {
    
        data = new Data();
        await data.init();
    
        owner = data.deployerSigner;
        addr1 = data.user1Signer;
        addr2 = data.user2Signer;
        addr3 = data.user3Signer;
        addr4 = data.user4Signer;

        Token = await ethers.getContractFactory("ethercards");
        token = await MintyArt.deploy();
        await data.printTxData("Deploy token",token.deployTransaction);
    })

    it ("start", async () => {
        let alpha =5;
        console.log(alpha)
    });

})