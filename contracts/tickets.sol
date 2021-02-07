// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.7.0;

contract ethercards {

    enum CardType { OG, Alpha, Regular } 
    enum FrameType { Common, Silver, Gold, Epic } 

    uint256 constant OG_PRICE = 2 ether;
    uint256 constant ALPHA_PRICE = 2 ether;
    uint256 constant REGULAR_PRICE = 2 ether;

    // 3 arrays of available token indexes
    // ogs
    // alphas
    // regulars
    //
    // each of these holds unsold tokens before xxxPtr and sold items after
    //
    // e.g. 
    //     90 x alphas, alphaPtr = 37, 
    //     ==> 0 - 36 are unsold, 37 - 89 are sold
    //     nothing must move after it is sold
    // --------------------------------------------------------------------
    uint16    []ogs;
    uint16    []alphas;
    uint16    []regulars;
    //
    uint256   ogDemand;
    uint256   alphaDemand;
    uint256   regularDemand;
    //
    // arrays of addresses waiting for their tokens
    uint256   []ogOrders;
    uint256   []alphaOrders;
    uint256   []regularOrders;
    //
    // How many of above have been handled?
    uint256 regularOrdersProcessed;
    uint256 alphaOrdersProcessed;
    uint256 ogOrdersProcessed;
    uint256 waiting;
    uint256 orderId = 1;
    //
    // Random Stuff
    uint256 random;
    //
    // arrays of 10,000 traits some revealed in advance and some revealed after the drawing
    uint32    []traits;         // revealed after all are drawn
    uint24    []cardfixed;      // discovered when the next random number comes in

    bytes32   traithash;        // proves that the traits (that are sent later) have not been messed with

    // cardFixed Format
    // 0 - 13  : number  (10,000 / 16k)
    // 14 & 15 : frame   (4 / 4)
    // 16 - 20 : picture (32 / 32)
    // 21 - 22 : card type (3 / 4)

    event OG_Ordered(address buyer, uint256 price_paid, uint256 demand, uint256 orderID);
    event ALPHA_Ordered(address buyer, uint256 price_paid, uint256 demand, uint256 orderID);
    event REGULAR_Ordered(address buyer, uint256 price_paid, uint256 demand, uint256 orderID);

    function buyCard(CardType ct) public payable {
        processRandom();
        waiting++;
        if (ct == CardType.OG) {
            require (msg.value >= OG_PRICE, "Insuffient value");
            require (ogDemand++ < ogs.length, "No OG tickets available");
            ogOrders.push(msg.sender);
            emit OG_Ordered(msg.sender, msg.value, ogDemand, orderId++);
            return;
        } 
        if (ct == CardType.Alpha){ 
            require (msg.value >= ALPHA_PRICE, "Insuffient value");
            require (alphaDemand++ < alphas.length,"No ALPHA tickets available");
            alphaOrders.push(msg.sender);
            emit ALPHA_Ordered(msg.sender, msg.value, alphaDemand, orderId++);
            return;
        }
        require(msg.value >= REGULAR_PRICE, "Insuffient value");
        require (regularDemand++ < regulars.length,"No ALPHA tickets available");
        regularOrders.push(msg.sender);
        emit REGULAR_Ordered(msg.sender, msg.value, regularDemand, orderId++);
        return;
    }

    function processRandom() internal {
        if (waiting == 0) return;
        if (random == 0 && !randomAvailable()) {
            request_random();
            return;
        }
        if (random == 0) random = nextRandom();
        if (ogOrders.length > ogOrdersProcessed) {
            address toProcess = ogOrders[ogOrdersProcessed++];
            sellCard(toProcess,CardType.OG,random);
            random = random >> 16;
            return;
        }
        if (alphaOrders.length > alphaOrdersProcessed) {
            address toProcess = alphaOrders[alphaOrdersProcessed++];
            sellCard(toProcess,CardType.ALPHA,random);
            return;
        }
        if (regularOrders.length > regularOrdersProcessed) {
            address toProcess = regularOrders[regularOrdersProcessed++];
            sellCard(toProcess,CardType.REGULAR,random);
        }
    }


    function sellCard(address owner, CardType buyer, uint256 rand)  internal{
        waiting--;
        uint pos = rand;
        if (buyer == CardType.OG) {
            markOgCardAsSold(owner,pos);
            return;
        }
        if (buyer == CardType.Alpha) {
            if (pos < ogs.length - ogDemand) {
                markOgCardAsSold(owner,pos);
                alphaDemand--;
                ogDemand++;
                return;
            }
            pos -= ogs.length - ogDemand;
            markAlphaCardAsSold(owner,pos);
            return;
        }
        if (pos < ogs.length - ogDemand) {
            markOgCardAsSold(owner,pos);
            regularDemand--;
            ogDemand++;
            return;
        }
        pos -= ogs.length - ogDemand;
        if (pos < alphas.length - alphaDemand) {
            markAlphaCardAsSold(owner,pos);
            regularDemand--;
            alphaDemand++;
            return;
        }
        pos -= alphas.length - alphaDemand;
        markRegularCardAsSold(owner,pos);
    }

    function markOgCardAsSold(address owner, uint pos) internal {
    uint last = ogs.length - 1;
    uint tokenId = uint256(ogs[pos]);
    ogs[pos] = ogs[last];
    _mint(owner, tokenId);
}

function markAlphaCardAsSold(address owner, uint pos) internal {
    uint last = alphas.length - 1;
    uint tokenId = uint256(alphas[pos]);
    alphas[pos] = alphas[last];
    _mint(owner, tokenId);
}

function markRegularCardAsSold(address owner, uint pos) internal {
    uint last = regulars.length - 1;
    uint tokenId = uint256(regulars[pos]);
    regulars[pos] = regulars[last];
    _mint(owner, tokenId);
}
    
    constructor(uint16[] memory _alphas, uint16[] memory _ogs, uint24[] memory _cardfixed, bytes32 _cfHash) {
        bytes32 hash = keccak256(abi.encodePacked(_cardfixed));
        require(hash == _cfHash, "Data not valid");
        cardfixed = _cardfixed;
        alphas = _alphas;
        ogs = _ogs;
        uint alphaPos;
        uint ogPos;
        for (uint j = 0; j < _cardfixed.length; j++) {
            uint24 z = _cardfixed[j] >> 21 ;
            if (z == 1){
                require(uint(_ogs[ogPos++])==j,"incorrect OG reference");
            } else if (z == 2) {
                require(uint(_alphas[alphaPos++])==j,"incorrect ALPHA reference");
            } else if (z != 0){
                require(false,"bad card type supplied");
            }
        }
        require(ogPos == _ogs.length,"Incorrect number of OG cards");
        require(alphaPos == _alphas.length,"Incorrect number of alpha cards");
    }

    function loadTraits(uint32[] memory _traits) external {      
        bytes32 hash = keccak256(abi.encodePacked(_traits));
        require(traithash == hash,"traits not valid");
        require(_traits.length == cardfixed.length,"number of traits does not match number of cards");
        traits = _traits;
    }

    // Random number stuff

    function randomAvailable() internal view returns (bool) {
        return false;
    }

    function nextRandom() internal returns (uint256) {
        return 1;
    }

    function request_random() internal {

    }

    // View Function to get graphic properties

    function cardtype(uint tokenId) public view returns(CardType) {
        return CardType((cardfixed[tokenId] >> 21) & 3);
    }

    function frameType(uint tokenId) public view returns(FrameType) {
        return FrameType((cardfixed[tokenId] >> 14) & 3);
    }

    function cardNumber(uint tokenId) public view returns(uint24) {
        return cardfixed[tokenId] & 0x1fff;
    }

    function pictureID(uint tokenId) public view returns(uint24) {
        return (cardfixed[tokenId] >> 16) & 0x1f;
    }
 
}