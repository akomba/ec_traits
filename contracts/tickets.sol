// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.7.0;


import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/math/Math.sol";
import "./interfaces/IRNG.sol";

contract ethercards is ERC721 , Ownable{

    IRNG rng;

    enum CardType { OG, Alpha, Regular } 
    enum FrameType { Common, Silver, Gold, Epic } 


    uint256   constant oStart = 10;
    uint256   constant aStart = 100;
    uint256   constant rStart = 1000;
    uint256   constant oMax = 99;
    uint256   constant aMax = 999;
    uint256   constant rMax = 9999;

    uint256   constant tr_ass_order_length = 14;
    uint256   constant tr_ass_order_mask   = 0x3ff;
    uint256   constant card_trait_mask     = 0x0ff;

    // sale conditions
    uint256  sale_start;
    uint256  sale_end;


    // sold AND resolved
    uint256   oSold;
    uint256   aSold;
    uint256   rSold;
    // pending resolution
    uint256   oPending;
    uint256   aPending;
    uint256   rPending;
    uint256   nextTokenId;
    // Random Stuff
    mapping (uint256 => uint32) randomRequests;
    uint256                     lastRandomRequested;
    uint256                     lastRandomProcessed;
    uint256                     randomOneOfFour;

    // pricing stuff
    uint256[]                      og_stop;
    uint256[]                      og_price;
    uint256[]                      alpha_stop;
    uint256[]                      alpha_price;
    uint256[]                      random_stop;
    uint256[]                      random_price;
    uint256                        og_pointer;
    uint256                        alpha_pointer;
    uint256                        random_pointer;


    // traits stuff
    bytes32                        traitHash;
    mapping (uint256 => uint256)   traitAssignmentOrder;
    // Validation
    uint256 startPos;
    bool finalised;
    bytes32                         tokenIdHash;


    mapping(uint256 => uint256) serialToCard;
    mapping(uint256 => uint256) tokenIdToSerial;

    mapping(uint256 => uint256) traitIndex;
    mapping(uint256 => uint256) specialTraits;
    mapping(uint256 => uint256) cardTraits;



    event OG_Ordered(address buyer, uint256 price_paid, uint256 demand, uint256 orderID);
    event ALPHA_Ordered(address buyer, uint256 price_paid, uint256 demand, uint256 orderID);
    event REGULAR_Ordered(address buyer, uint256 price_paid, uint256 demand, uint256 orderID);

    event Resolution(uint256 position,uint256 tokenId,uint256 chance);

    event FinalisingUpTo(uint256 position ,uint256 traits_length);
    event FinalisationComplete();


    constructor(
        bytes32 _traitHash, IRNG _rng, 
        uint256[] memory _og_stop, uint256[] memory _og_price,
        uint256[] memory _alpha_stop, uint256[] memory _alpha_price,
        uint256[] memory _random_stop, uint256[] memory _random_price
        ) ERC721("Ether Cards Founder","ECF") {
        traitHash = _traitHash;
        rng = _rng;
        og_stop = _og_stop;
        og_price = _og_price;
        alpha_stop = _alpha_stop;
        alpha_price = _alpha_price;
        random_stop = _random_stop;
        random_price = _random_price;
        
    }

    function request_random_if_needed() internal {
        if (randomOneOfFour++ % 4 == 3) {
            request_random();
        }
    }

    function OG_price() public view returns (uint256) {
        require(oSold + oPending <= oMax,"OG Cards sold out"); 
        return og_price[og_pointer];
    }

    function ALPHA_price() internal returns (uint256) {
        require(aSold + aPending <= aMax,"Alpha Cards sold out"); 
        return alpha_price[alpha_pointer];        
    }

    function RANDOM_price() internal returns (uint256) {
        require(rSold + rPending <= rMax,"Random Cards sold out"); 
        return random_price[random_pointer];
    }

    modifier sale_active() {
        require(block.timestamp >= sale_start,"Tickets are not available yet");
        require(block.timestamp < sale_end,"Tickets are no longer available");
        require(nextTokenId <= rMax, "Sorry. Sold out");
        _;
    }

    function needProcessing() public view returns (bool) {
        return (oPending + rPending +aPending > 3 || nextTokenId > rMax) && randomAvailable();
    }

    function processRandom() internal {
        require(needProcessing(),"Please wait for needProcessing flag");
        uint random = nextRandom();
        for (uint i = 0; i < 4; i++) {
            if (oPending + rPending +aPending == 0) {
                return;
            }
            resolve(random & 0xffffffffffffffff);
            random = random >> 64;
        }
    }
 
    function buyCard(uint card_type) external payable sale_active {
        _mint(msg.sender,nextTokenId);
        request_random_if_needed();
        if (card_type == 0) {
            require(msg.value >= OG_price(),"Price no longer valid");
            require (oStart + oSold + oPending <= oMax, "Sorry, no OG cards available");
            serialToCard[oStart+oSold+oPending] = nextTokenId++;
            oPending++;
            og_pointer = bump(oSold,oPending,og_stop,og_pointer);
            return;
        }
        if (card_type == 1) {
            require(msg.value >= ALPHA_price(),"Price no longer valid");
            require (aStart + aSold + aPending <= aMax,"Sorry - no Alpha tickets available");
            serialToCard[aStart + aSold + aPending] = nextTokenId++;
            aPending++;
            alpha_pointer = bump(aSold , aPending , alpha_stop,alpha_pointer);
            return;
        }
        require(msg.value >= RANDOM_price(),"Price no longer valid");
        require(rStart + rSold + rPending < rMax, "Sorry no random tickets available");
        serialToCard[rStart + rSold + rPending] = nextTokenId++;
        rPending++;
        random_pointer = bump(rSold , rPending , random_stop,random_pointer);
    }

    function resolve(uint256 random) internal {
        uint256 chances;
        uint chance2;
        uint256 pos;
        uint256 r = random;
        if (oPending > 0) {
            chances = 3;
            pos = oStart+oSold++;
            oPending--;
        } else if (aPending > 0) {
            chances = 2;
            pos = aStart + aSold++;
            aPending--;
        } else if (rPending > 0) {
            uint tID = serialToCard[rStart+rSold];
            // draw for what kind of card it is
            uint256 remainingTickets = oMax - oSold + aMax - aSold + rMax - rSold + 3;
            pos = r % remainingTickets;
            r = r / remainingTickets;
            if (pos <= (oMax - oSold)) {
                chances = 2;
                pos = oStart + oSold++;
                og_pointer = bump(oSold,oPending,og_stop,og_pointer);
            } else if (pos <= oMax - oSold + aMax - aSold + 1) {
                chances = 1;
                pos = aStart + aSold++;
                alpha_pointer = bump(aSold , aPending , alpha_stop,alpha_pointer);
            } else {
                pos = rStart + rSold++;
            }
            if (chances != 0) {
                // the Random[x] is now no longer a random card
                serialToCard[pos] = tID; // move the tokenId
                serialToCard[rStart+rSold] = serialToCard[rStart+rSold+rPending]; // bring last in to fill gap
            }
            rPending--;
        }   
        uint256 chance = r & tr_ass_order_mask;
        r = r >> tr_ass_order_length;
        for (uint j = 0; j < chances; j++) {
            chance2 = r & tr_ass_order_mask;
            r = r >> tr_ass_order_length;
            chance = Math.min(chance,chance2);
        }
        uint256 tokenId = serialToCard[pos];
        tokenIdToSerial[tokenId] = pos; 
        cardTraits[tokenId] = r & card_trait_mask;
        traitAssignmentOrder[tokenId] = chance;
        emit Resolution(pos,tokenId,chance);
    }

    function bump(uint sold, uint pending, uint[] memory stop, uint pointer) internal pure returns (uint256) {
        if (pointer == stop.length - 1) return pointer; 
        if (sold + pending > stop[pointer]) {
            return pointer + 1;
        }
        return pointer;
    }
    
    function ResetStartPos() external onlyOwner {
        require(!finalised,"This Data is already finalised");
        startPos = 0;
    }


    function FinaliseTokenOrder(uint16[] memory tokenIds, uint16[] memory traits, uint256 _numberToProcess) public onlyOwner {
        require (keccak256(abi.encodePacked(traits)) == traitHash,"invalid Traits Hash");
        bytes32 idHash = keccak256(abi.encodePacked(tokenIds));
        if (startPos == 0) {
            tokenIdHash = idHash;
        } else {
            require(tokenIdHash == idHash, "tokenHashes do not match");
        }
        require(!finalised,"This Data is already finalised");
        uint256 numberToProcess = Math.min(tokenIds.length, _numberToProcess);
        uint start = startPos;
        uint end   = Math.min(startPos + numberToProcess,rMax+1);
        for (uint256 i = start; i < numberToProcess; i++) {
            if (i > 0) {
                require(validate(i,tokenIds[i]),"tokenIds in wrong order");
            }
            specialTraits[tokenIds[i]] = traits[i];
        }
        if (end == rMax+1) {
            finalised = true;
            emit FinalisationComplete();
        } else {
            startPos = end;
            emit FinalisingUpTo(end,traits.length);
        }
    }

    function validate(uint prevTokenId, uint tokenId) internal view returns (bool) {
        require(
            (traitAssignmentOrder[prevTokenId] < traitAssignmentOrder[prevTokenId]) ||
            ((traitAssignmentOrder[prevTokenId] == traitAssignmentOrder[prevTokenId]) && (tokenIdToSerial[prevTokenId] < tokenIdToSerial[tokenId])),
            "Traits in incorrect order");
    }

        
    // function loadTraits(uint32[] memory _traits) external {      
    //     bytes32 hash = keccak256(abi.encodePacked(_traits));
    //     require(traitHash == hash,"traits not valid");
    //     // require(_traits.length == oMax + 1,"number of traits does not match number of cards");
    //     // functional = _traits;
    // }

    // Random number stuff

    function randomAvailable() internal view returns (bool) {
        return (lastRandomRequested > lastRandomProcessed) && rng.isRequestComplete(randomRequests[lastRandomProcessed]);
    }

    function nextRandom() internal returns (uint256) {
        require(randomAvailable(),"Nothing to process");
        return rng.randomNumber(randomRequests[lastRandomProcessed++]);
    }

    function request_random() internal {
        (randomRequests[lastRandomRequested++],) = rng.requestRandomNumber();
    }

    // View Function to get graphic properties

    function traitPos(uint tokenId) internal view returns (uint256) {
        require(tokenId < nextTokenId,"invalid tokenId");
        return traitIndex[tokenId];
    }

    function cardTrait(uint256 tokenId) internal view returns (uint24) {
//        return cardTraits[traitPos(tokenId)];
    }

    function cardtype(uint tokenId) public view returns(CardType) {
//        return CardType((cardTrait(tokenId) >> 21) & 3);
    }

    function frameType(uint tokenId) public view returns(FrameType) {
//        return FrameType((cardTrait(tokenId) >> 14) & 3);
    }

    function cardNumber(uint tokenId) public view returns(uint24) {
//        return cardTrait(tokenId) & 0x1fff;
    }

    function pictureID(uint tokenId) public view returns(uint24) {
//        return (cardTrait(tokenId) >> 16) & 0x1f;
    }
 
}