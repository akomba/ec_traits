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

    let oracle;
    let oracleSigner;

    before(async function () {
    
        data = new Data();
        await data.init();
        
        owner = data.deployerSigner;
        addr1 = data.user1Signer;
        addr2 = data.user2Signer;
        addr3 = data.user3Signer;
        addr4 = data.user4Signer;

        oracle = data.user8;
        oracleSigner = data.user8Signer;

        console.log(oracle)

        wallet = "0xb6c6920327B33f8eeC26786c7462c5F4098D47E3"

        bo = await provider.getBalance(owner.address)
        b1 = await provider.getBalance(addr1.address)
        b2 = await provider.getBalance(addr2.address)
        b3 = await provider.getBalance(addr3.address)
        b4 = await provider.getBalance(addr4.address)
        w1 =  await provider.getBalance(wallet)
        o1 =  await provider.getBalance(oracle)

        console.log("owner",owner.address,ethers.utils.formatEther(bo))
        console.log("addr1",addr1.address,ethers.utils.formatEther(b1))
        console.log("addr2",addr2.address,ethers.utils.formatEther(b2))
        console.log("addr3",addr3.address,ethers.utils.formatEther(b3))
        console.log("addr4",addr4.address,ethers.utils.formatEther(b4))
        console.log("wallet",addr4.address,ethers.utils.formatEther(w1))

        console.log("oracle",oracle,ethers.utils.formatEther(o1))

        

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
        token = await Token.deploy(traitHash, random.address, ogs,ogp, ags,agp, rgs,rgp,0,"1645137615",wallet, oracle);
        //console.log(Token.interface.events)
        addLookup(Token.interface.events["Chance"])
        addLookup(Token.interface.events["Resolution"])
        addLookup(Token.interface.events["Transfer"])
        addLookup(Token.interface.events["OG_Ordered"])
        addLookup(Token.interface.events["ALPHA_Ordered"])
        addLookup(Token.interface.events["RANDOM_Ordered"])
        addLookup(Random.interface.events["Request"])
        addLookup(Random.interface.events["RandomReceived"])
        // for (j = 0; j < Token.interface.events.length; j++){
        //     console.log("events",Token.interface.events[j]);//,Token.interface.events.topic)
        // }
        
        await data.printTxData("Deploy token",token.deployTransaction);
        console.log("-----setEC")
        await data.setEC(token,random);
        console.log("----")
        console.log(data.card.address, data.rng.address);
    })

    it("founders cards ", async() => {
        founders = [
            "0xb6c6920327B33f8eeC26786c7462c5F4098D47E3",
            "0xFef144aAFCA6b8Dd2E10907fe131C87636fc8334",
            "0xbD172f38c1bc677A238F1a2c05746Ca8A3101279",
            "0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D",
            "0x19868B43Cc7e16f8a928c500400D24f1B5F2DcfF",
            "0xe88f8313e61A97cEc1871EE37fBbe2a8bf3ed1E4",
            "0xDE701F5466ea0a27AA9503D3B703F7B99aeD26f0",
            "0x61189Da79177950A7272c88c6058b96d4bcD6BE2",
            "0x84Ba85993744d6087172eB15A3924f307582810c",
            "0x627fd152d3F7c420341FC08085e114769d03BCbb"
        ]
        tx = await token.mintFounders(founders);
        await data.printTxData("founders",tx)
        receipt = await tx.wait()
        printEvents(receipt)
        console.log("++++")
        oneWei = ethers.utils.parseUnits("1","wei")
        for (j = 0; j < 10; j++) {
            tid = await token.tokenOfOwnerByIndex(founders[j],0)
            serNo = await token.cardSerialNumber(tid)
            console.log(founders[j],tid,serNo)
        }
        console.log("++founded++")

    })

    it ("presales", async() => {
        psOG = [
            "0xb6c6920327B33f8eeC26786c7462c5F4098D47E3",
            "0xFef144aAFCA6b8Dd2E10907fe131C87636fc8334",
            "0xbD172f38c1bc677A238F1a2c05746Ca8A3101279"
        ]
        psAlpha =[
            "0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D",
            "0x19868B43Cc7e16f8a928c500400D24f1B5F2DcfF",
            "0xe88f8313e61A97cEc1871EE37fBbe2a8bf3ed1E4"
        ]
        psCommon = [
            "0xDE701F5466ea0a27AA9503D3B703F7B99aeD26f0",
            "0x61189Da79177950A7272c88c6058b96d4bcD6BE2",
            "0x84Ba85993744d6087172eB15A3924f307582810c",
            "0x627fd152d3F7c420341FC08085e114769d03BCbb"
        ]

        console.log("OG")
        tx = await token.allocateManyCards(psOG,0);
        await data.printTxData("OGS",tx)
        receipt = await tx.wait()
        printEvents(receipt)
        console.log("ALPHA")
        tx = await token.allocateManyCards(psAlpha,1);
        await data.printTxData("Alphas",tx)
        receipt = await tx.wait()
        printEvents(receipt)
        console.log("COMMON")
        tx = await token.allocateManyCards(psCommon,2);
        await data.printTxData("Common",tx)
        receipt = await tx.wait()
        printEvents(receipt)
        

    })

    it ("start", async () => {
        or = await token.OG_remaining()
        ar = await token.ALPHA_remaining()
        cr = await token.RANDOM_remaining()

        op = await token.OG_price()
        ap = await token.ALPHA_price()
        cp = await token.RANDOM_price()
        
        console.log("o",ethers.utils.formatUnits(or,"wei"),ethers.utils.formatEther(op))
        console.log("a",ethers.utils.formatUnits(ar,"wei"),ethers.utils.formatEther(ap))
        console.log("c",ethers.utils.formatUnits(cr,"wei"),ethers.utils.formatEther(cp))
        
        let oneEther = {
            value: ethers.utils.parseEther("1.0")       // ether in this case MUST be a string
        };
        tx = await token.connect(addr1).buyCard(0,oneEther)
        await  data.printTxData("first sale",tx)
        receipt = await tx.wait()
        expect(receipt.status).to.equal(1)

    });

    it ("wait and buy",async() => {
        
        
        bal = await token.balanceOf(addr1.address)
        console.log("addr1 has",ethers.utils.formatUnits(bal,"wei"))
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
            printEvents(receipt)
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
        while ( await token.needProcessing()){
            tx = await token.connect(oracleSigner).processRandom();
            await data.printTxData("processRandom",tx)
            receipt = await tx.wait()
            printEvents(receipt)
        }
        // console.log("->",receipt.logs.length)
        // for (j = 0; j < receipt.logs.length; j++){
        //     console.log("log ",j, "->",lookup(receipt.logs[j].topics[0]),receipt.logs[j].data)
        // }
        
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
        tx = await token.connect(oracleSigner).processRandom();
        await data.printTxData("processRandom2",tx)
        receipt = await tx.wait()
        printEvents(receipt)
        // console.log("->",receipt.logs.length)
        // for (j = 0; j < receipt.logs.length; j++){
        //     console.log("log ",j, "->",lookup(receipt.logs[j].topics[0]),receipt.logs[j].data)
        //}
        a11 = await token.tokenOfOwnerByIndex(addr1.address,0)
        a12 = await token.tokenOfOwnerByIndex(addr2.address,0)
        a13 = await token.tokenOfOwnerByIndex(addr3.address,0)
        a14 = await token.tokenOfOwnerByIndex(addr4.address,0)
        a21 = await token.tokenOfOwnerByIndex(addr1.address,1)
        a22 = await token.tokenOfOwnerByIndex(addr2.address,1)
        a23 = await token.tokenOfOwnerByIndex(addr3.address,1)
        a24 = await token.tokenOfOwnerByIndex(addr4.address,1)
        console.log("a11",a11,10)
        console.log("a12",a12,11)
        console.log("a13",a13,12)
        console.log("a14",a14,13)
        console.log("a21",a21,14)
        console.log("a22",a22,15)
        console.log("a23",a23,16)
        console.log("a24",a24,17)

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



    function printEvents(receipt) {
        console.log("->",receipt.logs.length)
        for (j = 0; j < receipt.logs.length; j++){
            console.log("log ",j, "->",lookup(receipt.logs[j].topics[0]),receipt.logs[j].data)
        }
    }

    function addLookup(ev) {
        lookupTable[ev.topic] = ev.name
    }

    function lookup(x) {
        return lookupTable[x]
    }


})