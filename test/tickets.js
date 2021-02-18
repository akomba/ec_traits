const { ZERO_ADDRESS, ROLE, Data } = require('./helpers/common');

// Hardhat tests are normally written with Mocha and Chai.

// We import Chai to use its asserting functions here.
const { expect } = require("chai");
const { ethers } = require('hardhat');
const provider = new ethers.providers.JsonRpcProvider();

describe("Ether Cards contract", function () { 

    let data;

    let Token
    let token

    let Rng 
    let rng

    let owner;
    let addr1;
    let addr2;
    let Random;
    let random;

    let  lastNext = 0;

    before(async function () {
    
        data = new Data();
        await data.init();
        
        owner = data.deployerSigner;
        addr1 = data.user1Signer;
        addr2 = data.user2Signer;
        addr3 = data.user3Signer;
        addr4 = data.user4Signer;

        balance = await provider.getBalance(owner.address)
        console.log("owner:",owner.address,ethers.utils.formatEther(balance))

        Random = await ethers.getContractFactory("random");
        random = await Random.deploy();
        await data.printTxData("deploy random",random.deployTransaction);
        
        let traitHash = ethers.utils.keccak256("0x123456")
        let oneETH = ethers.utils.parseEther("1.0")
        let ogs = [20]
        let ags = [200]
        let rgs = [2000]
        let ogp = [oneETH]
        let agp = [oneETH]
        let rgp = [oneETH]
        
        //console.log(traitHash, random.address, ogs, ogp, ags, agp, rgs, rgp); // print

        Token = await ethers.getContractFactory("ethercards");
        token = await Token.deploy(traitHash, random.address, ogs,ogp, ags,agp, rgs,rgp,0,"1645137615");
        
        await data.printTxData("Deploy token",token.deployTransaction);
        console.log("-----")
        await data.setEC(token,random);
        console.log("---")
        console.log(data.card.address, data.rng.address);
    })

    it ("start", async () => {
        let overrides = {
            value: ethers.utils.parseEther("1.0")       // ether in this case MUST be a string
        };
        tx = await token.connect(addr1).buyCard(0,overrides)
        await  data.printTxData("first sale",tx)
        owned = await token.balanceOf(addr1.address)
        console.log("#1",owned)
        np = await token.needProcessing();
        expect(np).to.equal(false)
    });

    it ("+3", async () => {
        let overrides = {
            value: ethers.utils.parseEther("1.0")       // ether in this case MUST be a string
        };
        np = await token.needProcessing();
        expect(np).to.equal(false)
        tx = await token.connect(addr2).buyCard(0,overrides)
        await data.printTxData("second sale",tx)
        np = await token.needProcessing();
        expect(np).to.equal(false)
        tx = await token.connect(addr3).buyCard(0,overrides)
        await data.printTxData("3rd sale",tx)
        np = await token.needProcessing();
        expect(np).to.equal(false)
        tx = await token.connect(addr4).buyCard(0,overrides)
        await data.printTxData("4th sale",tx)
        np = await token.needProcessing();
        expect(np).to.equal(false)
        owned = await token.balanceOf(addr2.address)
        console.log("#2",owned)
        owned = await token.balanceOf(addr3.address)
        console.log("#3",owned)
        owned = await token.balanceOf(addr4.address)
        console.log("#4",owned)
    });

    it ("random", async() => {
        next = await random.next();
        console.log("next",next)
        while (lastNext < next) {
            console.log("new random", lastNext)
            rd = ethers.utils.keccak256([lastNext,next])
            tx = await random.setRand(lastNext,rd)
            await data.printTxData("setRand",tx)
            lastNext++;
        }
        np = await token.needProcessing();
        expect(np).to.equal(true)


    })

    it("processRandom", async() => {
        np = await token.needProcessing();
        expect(np).to.equal(true)
        tx = await token.processRandom();
        data.printTxData("processRandom")
    })


})