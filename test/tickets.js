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

    let owner;
    let addr1;
    let addr2;
    let addr3;
    let addr4;
    let wallet;
    let Random;
    let random;
    let lookupTable = [];

    let  lastNext = 0;

    before(async function () {
    
        data = new Data();
        await data.init();
        
        owner = data.deployerSigner;
        addr1 = data.user1Signer;
        addr2 = data.user2Signer;
        addr3 = data.user3Signer;
        addr4 = data.user4Signer;
        wallet = "0xb6c6920327B33f8eeC26786c7462c5F4098D47E3"

        bo = await provider.getBalance(owner.address)
        b1 = await provider.getBalance(addr1.address)
        b2 = await provider.getBalance(addr2.address)
        b3 = await provider.getBalance(addr3.address)
        b4 = await provider.getBalance(addr4.address)
        w1 =  await provider.getBalance(wallet)

        console.log("owner",owner.address,ethers.utils.formatEther(bo))
        console.log("addr1",addr1.address,ethers.utils.formatEther(b1))
        console.log("addr2",addr2.address,ethers.utils.formatEther(b2))
        console.log("addr3",addr3.address,ethers.utils.formatEther(b3))
        console.log("addr4",addr4.address,ethers.utils.formatEther(b4))
        console.log("wallet",addr4.address,ethers.utils.formatEther(w1))

        

        Random = await ethers.getContractFactory("random");
        random = await Random.deploy();
        await data.printTxData("deploy random",random.deployTransaction);
        
        let traitHash = ethers.utils.keccak256("0x123456")
        let oneETH = ethers.utils.parseEther("1.0")
        let pointOneETH = ethers.utils.parseEther("0.1")
        let ogs = [20]
        let ags = [200]
        let rgs = [2000]
        let ogp = [oneETH]
        let agp = [oneETH]
        let rgp = [pointOneETH]
        
        //console.log(traitHash, random.address, ogs, ogp, ags, agp, rgs, rgp); // print

        Token = await ethers.getContractFactory("ethercards");
        token = await Token.deploy(traitHash, random.address, ogs,ogp, ags,agp, rgs,rgp,0,"1645137615",wallet);
        //console.log(Token.interface.events)
        addLookup(Token.interface.events["Chance"])
        addLookup(Token.interface.events["Resolution"])
        // for (j = 0; j < Token.interface.events.length; j++){
        //     console.log("events",Token.interface.events[j]);//,Token.interface.events.topic)
        // }
        
        await data.printTxData("Deploy token",token.deployTransaction);
        console.log("-----")
        await data.setEC(token,random);
        console.log("---")
        console.log(data.card.address, data.rng.address);
    })

    it ("start", async () => {
        let oneEther = {
            value: ethers.utils.parseEther("1.0")       // ether in this case MUST be a string
        };
        tx = await token.connect(addr1).buyCard(0,oneEther)
        await  data.printTxData("first sale",tx)
        a10 = await token.tokenOfOwnerByIndex(addr1.address,0)
        console.log("first tokenId",a10)
        owned = await token.balanceOf(addr1.address)
        console.log("#1",owned)
        np = await token.needProcessing();
        expect(np).to.equal(false)
    });

    it ("+3", async () => {
        let oneEther = {
            value: ethers.utils.parseEther("1.0")       // ether in this case MUST be a string
        };
        np = await token.needProcessing();
        expect(np).to.equal(false)
        tx = await token.connect(addr2).buyCard(0,oneEther)
        await data.printTxData("second sale",tx)
        np = await token.needProcessing();
        expect(np).to.equal(false)
        tx = await token.connect(addr3).buyCard(0,oneEther)
        await data.printTxData("3rd sale",tx)
        np = await token.needProcessing();
        expect(np).to.equal(false)
        tx = await token.connect(addr4).buyCard(0,oneEther)
        await data.printTxData("4th sale",tx)
        np = await token.needProcessing();
        expect(np).to.equal(false)
        owned = await token.balanceOf(addr2.address)
        console.log("#2",owned)
        owned = await token.balanceOf(addr3.address)
        console.log("#3",owned)
        owned = await token.balanceOf(addr4.address)
        console.log("#4",owned)
        totalSupply = await token.totalSupply()
        console.log("total supply", totalSupply)
    });

    it ("random", async() => {
        op = await token.oPending();
        ap = await token.aPending();
        rp = await token.rPending();
        console.log("op,ap,rp",op,ap,rp)
        np = await token.needProcessing()
        console.log("need processing",np)
        next = await random.next();
        console.log("next",next)
        let lastRandomRequested  = await token.lastRandomRequested();
        let lastRandomProcessed  = await token.lastRandomProcessed();
        let randomRequests  = await token.randomRequests(lastRandomProcessed);
        let randomOneOfFour  = await token.randomOneOfFour();

        console.log("randomRequests",randomRequests)
        console.log("lastRandomRequested",lastRandomRequested)
        console.log("lastRandomProcessed",lastRandomProcessed)
        console.log("randomOneOfFour",randomOneOfFour)

        while (lastNext < next) {
            console.log("new random", lastNext)
            rd = ethers.utils.keccak256([lastNext,next])
            tx = await random.setRand(lastNext,rd)
            await data.printTxData("setRand",tx)
            receipt = await tx.wait()
            console.log(">>>>",receipt.logs.length);
            console.log(">>>>",receipt.logs);
            lastNext++;
        }
        lastRandomRequested  = await token.lastRandomRequested();
        lastRandomProcessed  = await token.lastRandomProcessed();
        randomRequests  = await token.randomRequests(lastRandomProcessed);
        randomOneOfFour  = await token.randomOneOfFour();
        op = await token.oPending();
        ap = await token.aPending();
        rp = await token.rPending();
        console.log("op,ap,rp",op,ap,rp)
       
        complete = await random.isRequestComplete(randomRequests)
        console.log("complete",complete,"with",randomRequests);

        console.log("randomRequests",randomRequests)
        console.log("lastRandomRequested",lastRandomRequested)
        console.log("lastRandomProcessed",lastRandomProcessed)
        console.log("randomOneOfFour",randomOneOfFour)

        np = await token.needProcessing();
        expect(np).to.equal(true)


    })

    it("processRandom", async() => {
        np = await token.needProcessing();
        expect(np).to.equal(true)
        tx = await token.processRandom();
        await data.printTxData("processRandom",tx)
        receipt = await tx.wait()
        console.log("->",receipt.logs.length)
        for (j = 0; j < receipt.logs.length; j++){
            console.log("log ",j, "->",lookup(receipt.logs[j].topics[0]),receipt.logs[j].data)
        }
        
    })

    it("checkTraits II",async() => {
        t1 = await token.tokenOfOwnerByIndex(addr1.address,0)
        t2 = await token.tokenOfOwnerByIndex(addr2.address,0)
        t3 = await token.tokenOfOwnerByIndex(addr3.address,0)
        t4 = await token.tokenOfOwnerByIndex(addr4.address,0)
        c1 = await token.cardTrait(t1)
        c2 = await token.cardTrait(t2)
        c3 = await token.cardTrait(t3)
        c4 = await token.cardTrait(t4)
        s1 = await token.specialTrait(t1)
        s2 = await token.specialTrait(t2)
        s3 = await token.specialTrait(t3)
        s4 = await token.specialTrait(t4)
        console.log("tokenIds",t1,t2,t3,t4)
        console.log("cards ",c1,c2,c3,c4)
        console.log("special ",s1,s2,s3,s4)
    })

    it ("Mixed Bag", async () => {
        let oneEther = {
            value: ethers.utils.parseEther("1.0")       // ether in this case MUST be a string
        }
        let pointOneEther = {
            value: ethers.utils.parseEther("0.1")       // ether in this case MUST be a string
        };
        np = await token.needProcessing();
        expect(np).to.equal(false)
        tx = await token.connect(addr1).buyCard(2,pointOneEther)
        await data.printTxData("2.1 sale",tx)
        tx = await token.connect(addr2).buyCard(0,oneEther)
        await data.printTxData("2.1 sale",tx)
        np = await token.needProcessing();
        expect(np).to.equal(false)
        tx = await token.connect(addr3).buyCard(2,pointOneEther)
        await data.printTxData("2.3 sale",tx)
        np = await token.needProcessing();
        expect(np).to.equal(false)
        tx = await token.connect(addr4).buyCard(0,oneEther)
        await data.printTxData("2.4 sale",tx)
        np = await token.needProcessing();
        expect(np).to.equal(false)
        a11 = await token.balanceOf(addr1.address)
        console.log("addr1 balance",a11)
        a12 = await token.balanceOf(addr2.address)
        console.log("addr2 balance",a12)
        a13 = await token.balanceOf(addr3.address)
        console.log("addr3 balance",a13)
        a14 = await token.balanceOf(addr4.address)
        console.log("addr4 balance",a14)
       
        totalSupply = await token.totalSupply()
        console.log("totalSupply",totalSupply)
        np = await token.needProcessing();
        expect(np).to.equal(false)
        tx = await random.setRand(lastNext,rd)
        await data.printTxData("setRand",tx)
        np = await token.needProcessing();
        expect(np).to.equal(true)
        

    });

    it("processRandom2", async() => {
        np = await token.needProcessing();
        expect(np).to.equal(true)
        tx = await token.processRandom();
        await data.printTxData("processRandom2",tx)
        receipt = await tx.wait()
        console.log("->",receipt.logs.length)
        for (j = 0; j < receipt.logs.length; j++){
            console.log("log ",j, "->",lookup(receipt.logs[j].topics[0]),receipt.logs[j].data)
        }
        a11 = await token.tokenOfOwnerByIndex(addr1.address,0)
        a12 = await token.tokenOfOwnerByIndex(addr2.address,0)
        a13 = await token.tokenOfOwnerByIndex(addr3.address,0)
        a14 = await token.tokenOfOwnerByIndex(addr4.address,0)
        a21 = await token.tokenOfOwnerByIndex(addr1.address,1)
        a22 = await token.tokenOfOwnerByIndex(addr2.address,1)
        a23 = await token.tokenOfOwnerByIndex(addr3.address,1)
        a24 = await token.tokenOfOwnerByIndex(addr4.address,1)
        console.log(a11,10)
        console.log(a12,11)
        console.log(a13,12)
        console.log(a14,13)
        console.log(a21,14)
        console.log(a22,15)
        console.log(a23,16)
        console.log(a24,17)

    })

    it("Balances Now", async ()=> {
        bo = await provider.getBalance(owner.address)
        b1 = await provider.getBalance(addr1.address)
        b2 = await provider.getBalance(addr2.address)
        b3 = await provider.getBalance(addr3.address)
        b4 = await provider.getBalance(addr4.address)
        w1 =  await provider.getBalance(wallet)

        console.log("owner",owner.address,ethers.utils.formatEther(bo))
        console.log("addr1",addr1.address,ethers.utils.formatEther(b1))
        console.log("addr2",addr2.address,ethers.utils.formatEther(b2))
        console.log("addr3",addr3.address,ethers.utils.formatEther(b3))
        console.log("addr4",addr4.address,ethers.utils.formatEther(b4))
        console.log("wallet",addr4.address,ethers.utils.formatEther(w1))

    })



    function printEvent(log) {
        console.log(log);
    }

    function addLookup(ev) {
        lookupTable[ev.topic] = ev.name
    }

    function lookup(x) {
        return lookupTable[x]
    }


})