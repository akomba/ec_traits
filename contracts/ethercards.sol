// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.7.0;


import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/math/Math.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "./interfaces/IRNG.sol";

contract ethercards is ERC721 , Ownable, Pausable{

    IRNG rng;

    enum CardType { OG, Alpha, Random, Common, Founder,  Unresolved } 
    enum FrameType { Common, Silver, Gold, Epic } 


    uint256   constant oStart = 10;
    uint256   constant aStart = 100;
    uint256   constant cStart = 1000;
    uint256   constant oMax = 99;
    uint256   constant aMax = 999;
    uint256   constant cMax = 9999;

    uint256   constant tr_ass_order_length = 14;
    uint256   constant tr_ass_order_mask   = 0x3ff;

    uint256   constant picture_trait_mask     = 0x0ff;
    uint256   constant picture_trait_offset   = 0;
    uint256   constant frame_trait_mask     = 0x0ff;
    uint256   constant frame_trait_offset   = picture_trait_offset + 8;
    uint256   constant feature_trait_mask     = 0x0ff;
    uint256   constant feature_trait_offset   = frame_trait_offset + 8;
    uint256   constant faketoshi_trait_mask     = 0x01;
    uint256   constant faketoshi_trait_offset   = feature_trait_offset + 8;
    uint256   constant extra_trait_offset       =  faketoshi_trait_offset + 1;



    // sale conditions
    uint256   sale_start;
    uint256   sale_end;
    bool      curve_set;


    // sold AND resolved
    uint256   oSold;
    uint256   aSold;
    uint256   cSold;
    // pending resolution
    uint256   public oPending;
    uint256   public aPending;
    uint256   public cPending;
    uint256   public nextTokenId = 10;
    // Random Stuff
    mapping (uint256 => uint32) public randomRequests;
    uint256                     public lastRandomRequested;
    uint256                     public lastRandomProcessed;
    uint256                     public randomOneOfEight;

    // pricing stuff
    uint256[]                   og_stop;
    uint256[]                   og_price;
    uint256[]                   alpha_stop;
    uint256[]                   alpha_price;
    uint256[]                   random_stop;
    uint256[]                   random_price;
    uint256                     og_pointer;
    uint256                     alpha_pointer;
    uint256                     random_pointer;

    address payable             wallet;


    // traits stuff
    bytes32                        traitHash;
    mapping (uint256 => uint256)   traitAssignmentOrder;
    // Validation
    uint256                     startPos;
    bool public                 finalised;
    bytes32                     tokenIdHash;


    mapping(uint256 => uint256) serialToTokenId;
    mapping(uint256 => uint256) tokenIdToSerial;

    mapping(uint256 => uint256) cardTraits;


    bool    presale_closed;
    bool    founders_done;
    address oracle;
    address controller;


    event OG_Ordered(address buyer, uint256 price_paid, uint256 demand, uint256 orderID);
    event ALPHA_Ordered(address buyer, uint256 price_paid, uint256 demand, uint256 orderID);
    event RANDOM_Ordered(address buyer, uint256 price_paid, uint256 demand, uint256 orderID);

    event Resolution(uint256 position,uint256 tokenId,uint256 chance);
    event Chance(uint256 chance);

    event FinalisingUpTo(uint256 position ,uint256 traits_length);
    event FinalisationComplete();

    event PresaleClosed();
    event OracleSet( address oracle);
    event ControllerSet( address oracle);
    event SaleSet(uint256 start, uint256 end);
    event RandomSet(address random);
    event TraitHash(bytes32 traitHash);
    event WheresWallet(address wallet);
    event Upgrade(uint256 TokenID, uint256 position);

    modifier onlyOracle() {
        require(msg.sender == oracle,"Not Authorised");
        _;
    }

    modifier onlyAllowed() {
        require(
            msg.sender == owner() ||
            msg.sender == controller,"Not Authorised");
        _;
    }

    // SECTIONS IN CAPS TO RETAIN SANITY

    // CONSTRUCTOR

    constructor(
        bytes32 _traitHash, IRNG _rng, 
        uint256 _start, uint256 _end,
        address payable _wallet, address _oracle
        ) ERC721("Ether Cards Founder","ECF") {

        traitHash = _traitHash;
        rng = _rng;
        sale_start = _start;
        sale_end = _end;
        wallet = _wallet;
        oracle = _oracle;
// need events
        emit OracleSet(_oracle);
        emit SaleSet(_start,_end);
        emit RandomSet(address(_rng));
        emit TraitHash(_traitHash);
        emit WheresWallet(_wallet);
    }

    function setCurve(
        uint256[] memory _og_stop, uint256[] memory _og_price,
        uint256[] memory _alpha_stop, uint256[] memory _alpha_price,
        uint256[] memory _random_stop, uint256[] memory _random_price) external onlyOwner {
        og_stop = _og_stop;
        og_price = _og_price;
        alpha_stop = _alpha_stop;
        alpha_price = _alpha_price;
        random_stop = _random_stop;
        random_price = _random_price;
        curve_set = true;
    }


    // ENTRY POINT TO SALE CONTRACT
    // 0 = OG
    // 1 = ALPHA
    // 2 = RANDOM

    function buyCard(uint card_type) external payable sale_active whenNotPaused {
        require(presale_closed,"Presale needs to be closed first");
        string memory pnv = "Price no longer valid";
        wallet.transfer(msg.value);
        require(card_type < 3, "Invalid card type");
        if (card_type == 0) {
            require(msg.value >= OG_price(),pnv);
        } else if (card_type == 1) {
            require(msg.value >= ALPHA_price(),pnv);
        } else if (card_type == 2){
            require(msg.value >= RANDOM_price(),pnv);
        }  
        assignCard(msg.sender,card_type);
    }

    // PRESALE FUNCTIONS
    // 0 - OG
    // 1 - ALPHA
    // 2 - COMMON

    function allocateManyCards(address[] memory buyers, uint256 card_type) external onlyOwner {
        require(founders_done, "mint founders first");
        require(card_type < 3 , "Invalid Card Type");
        require(!presale_closed,"Presale is over");
        for (uint j = 0; j < buyers.length; j++) {
            assignCard(buyers[j],card_type);
        }
    }
    
    function allocateCard(address buyer, uint256 card_type) external onlyOwner {
        require(founders_done, "mint founders first");
        require(card_type < 3, "Invalid Card Type");
        require(!presale_closed,"Presale is over");
        assignCard(buyer,card_type);
    }

    function closePresale() external onlyOwner {
        presale_closed = true;
        if (randomOneOfEight % 8 != 0) {
            request_random();
            randomOneOfEight = 0;
        }
        emit PresaleClosed();
    }

    // FOUNDERS CARDS

    function mintFounders(address[] memory founders) external onlyOwner {
        require(founders.length == 10 && !founders_done, "There must be exactly 10 founders");
        for (uint j = 0; j < 10; j++) {
            _mint(founders[j],j);
            tokenIdToSerial[j] = j;
            serialToTokenId[j] = j;
            traitAssignmentOrder[j] = 1;
        }
        founders_done = true;
    }

    // Extra Traits

    function setExtraTraits(uint256 tokenId, uint256 bitNumber) public onlyAllowed {
        require((bitNumber >= extra_trait_offset) && (bitNumber < 256), "illegal bit number");
        cardTraits[tokenId] |=   (1 << bitNumber);
    }

    // ORACLE ACTIVATION

    function needProcessing() public view returns (bool) {
        return (oPending + cPending +aPending > 7 || nextTokenId > cMax) && randomAvailable();
    }

    function processRandom() external onlyOracle {
        require(needProcessing(),"not ready");
        uint random = nextRandom();
        for (uint i = 0; i < 8; i++) {
            if (oPending + cPending +aPending == 0) {
                return;
            }
            resolve(random & 0xffffffff);
            random = random >> 32;
        }
    }

    function setOracle(address _oracle) external onlyOwner {
        oracle = _oracle;
        emit OracleSet(_oracle);
    }

   function setController(address _controller) external onlyOwner {
        controller = _controller;
        emit ControllerSet(_controller);
    }

    // WEB3 SALE SUPPORT


    function OG_remaining() public view returns (uint256) {
        return oMax - (oStart + oSold + oPending)+1;
    }

    function ALPHA_remaining() public view returns (uint256) {
        return aMax - (aStart + aSold + aPending)+1;
    }

    function RANDOM_remaining() public view returns (uint256) {
        return cMax - (cStart + cSold + cPending)+1;
    }

    function OG_price() public view returns (uint256) {
        require(OG_remaining() > 0,"OG Cards sold out"); 
        return og_price[og_pointer];
    }

    function ALPHA_price() public view returns (uint256) {
        require(ALPHA_remaining() > 0,"Alpha Cards sold out"); 
        return alpha_price[alpha_pointer];        
    }

    function RANDOM_price() public view returns (uint256) {
        require(RANDOM_remaining() > 0,"Random Cards sold out"); 
        return random_price[random_pointer];
    }

    modifier sale_active() {
        require(block.timestamp >= sale_start,"Sale not started");
        require(block.timestamp < sale_end,"Sale ended");
        require(nextTokenId <= cMax, "Sorry. Sold out");
        _;
    }


    function request_random_if_needed() internal {
        if (randomOneOfEight++ % 8 == 7) {
            request_random();
        }
    }

 
    function assignCard(address buyer, uint256 card_type) internal {
        require(curve_set,"prece curve not set");
        _mint(buyer,nextTokenId);
        request_random_if_needed();
        require((OG_remaining() > 0) || (ALPHA_remaining() > 0) ||  (RANDOM_remaining() > 0),"All Cards Sold Out!!");
        if ((card_type == 0) || ((card_type == 2) && (ALPHA_remaining() == 0) &&  (RANDOM_remaining() == 0)) ) {
            require (OG_remaining() > 0, "Sorry, no OG cards available");
            emit OG_Ordered(msg.sender, msg.value,oStart+oSold+oPending,nextTokenId);
            serialToTokenId[oStart+oSold+oPending] = nextTokenId++;
            oPending++;
            og_pointer = bump(oSold,oPending,og_stop,og_pointer);
            return;
        }
        if ((card_type == 1) || ((card_type == 2) && (RANDOM_remaining() == 0))) {
            require (ALPHA_remaining() > 0,"Sorry - no Alpha tickets available");
            emit ALPHA_Ordered(msg.sender, msg.value,aStart+aSold+aPending,nextTokenId);
            serialToTokenId[aStart + aSold + aPending] = nextTokenId++;
            aPending++;
            alpha_pointer = bump(aSold , aPending , alpha_stop,alpha_pointer);
            return;
        }
        require(RANDOM_remaining() > 0, "Sorry no random tickets available");
        emit RANDOM_Ordered(msg.sender, msg.value,cStart+cSold+cPending,nextTokenId);
        serialToTokenId[cStart + cSold + cPending] = nextTokenId++;
        cPending++;
        random_pointer = bump(cSold , cPending , random_stop,random_pointer);
    }

    function resolve(uint256 random) internal {
        bool upgrade;
        uint256 pos;
        uint256 r = random;
        if (oPending > 0) {
            pos = oStart+oSold++;
            oPending--;
        } else if (aPending > 0) {
            pos = aStart + aSold++;
            aPending--;
        } else if (cPending > 0) {
            if (presale_closed) {
                uint tID = serialToTokenId[cStart+cSold];
                // draw for what kind of card it is
                uint256 remainingTickets = OG_remaining() + ALPHA_remaining() + RANDOM_remaining();
                pos = r % remainingTickets;
                r = r / remainingTickets;
                if (pos <= OG_remaining()) {
                    upgrade = true;
                    pos = oStart + oSold++;
                    og_pointer = bump(oSold,oPending,og_stop,og_pointer);
                } else if (pos <= OG_remaining() + ALPHA_remaining()) {
                    upgrade = true;
                    pos = aStart + aSold++;
                    alpha_pointer = bump(aSold , aPending , alpha_stop,alpha_pointer);
                } else {
                    upgrade = false;
                    pos = cStart + cSold++;
                }
                if (upgrade) {
                    emit Upgrade(tID, pos);
                    // the Random[x] is now no longer a random card
                    serialToTokenId[pos] = tID; // move the tokenId
                    uint tailTokenID = serialToTokenId[cStart+cSold+cPending];
                    if (tailTokenID == 0) {
                        emit BadEnd(tailTokenID, cStart,cSold,cPending);
                    } else {
                        emit GoodEnd(tailTokenID, cStart,cSold,cPending);
                    }
                    serialToTokenId[cStart+cSold] = tailTokenID; // bring last in to fill gap
                }
                // cSold++; // <--- still necessary MAYBE NOT
                cPending--;
            } else {
                pos = cStart + cSold++;
                cPending--;
            }
        } else {
            return; // NOTHING TO DO
        }
        uint256 chance = r & tr_ass_order_mask;
        emit Chance(chance);
        
        uint256 tokenId = serialToTokenId[pos];
        tokenIdToSerial[tokenId] = pos; 
        traitAssignmentOrder[tokenId] = chance+1;
        emit Resolution(pos,tokenId,chance);
    }

    function bump(uint sold, uint pending, uint[] memory stop, uint pointer) internal pure returns (uint256) {
        if (pointer == stop.length - 1) return pointer; 
        if (sold + pending > stop[pointer]) {
            return pointer + 1;
        }
        return pointer;
    }
    

    //
    // This is used if (heaven forbid) the verification fails
    //
    function ResetStartPos() external onlyOwner {
        require(!finalised,"This Data is already finalised");
        startPos = 0;
    }

    // tokenIds : tokenIds from 10 to 9999
    // traits   : the traits to be assigned to the cards in an order where
    //            card{j}.trait_assignment_order < card{j+1}.trait_assignment_order 
    // or
    //            card{j}.trait_assignment_order == card{j+1}.trait_assignment_order amd serNo[j] < serNo[j+1]
    //            AND card{j}.trait_assignment_order < card{j+1}.trait_assignment_order 
 
    function FinaliseTokenOrder(uint16[] memory tokenIds, uint16[] memory traits, uint256 _numberToProcess) public onlyAllowed {
        CardType ct;
        require (keccak256(abi.encodePacked(traits)) == traitHash,"invalid Traits Hash");
        bytes32 idHash = keccak256(abi.encodePacked(tokenIds));
        if (startPos == 0) {
            startPos = 10;
            tokenIdHash = idHash;
        } else {
            require(tokenIdHash == idHash, "tokenHashes do not match");
        }
        require(!finalised,"This Data is already finalised");
        uint256 numberToProcess = Math.min(tokenIds.length, _numberToProcess);
        uint start = startPos;
        uint end   = Math.min(startPos + numberToProcess,cMax+1);
        for (uint256 i = start; i < numberToProcess; i++) {
            if (i < 10 || i == 10 || i == 100 || i == 1000) {
                // founder card or first in any sequence
                cardTraits[tokenIds[i]] = traits[i];
                if (i == 10) ct =CardType.OG;
                if (i == 100) ct =CardType.Alpha;
                if (i == 1000) ct =CardType.Common;
                
                continue;
            }
            require(validate(tokenIds[i-1],tokenIds[i],ct),"tokenIds in wrong order");
            cardTraits[tokenIds[i]] = traits[i];
        }
        if (end == cMax+1) {
            finalised = true;
            emit FinalisationComplete();
        } else {
            startPos = end;
            emit FinalisingUpTo(end,traits.length);
        }
    }

    function validate(uint prevTokenId, uint tokenId, CardType ct) internal view returns (bool) {
        require(
            (traitAssignmentOrder[prevTokenId] < traitAssignmentOrder[tokenId]) ||
            ((traitAssignmentOrder[prevTokenId] == traitAssignmentOrder[tokenId]) && (tokenIdToSerial[prevTokenId] < tokenIdToSerial[tokenId])),
            "Traits in incorrect order");
        // ensure that the traits are in same group
        require(cardType(tokenId) == ct,"Cards of wrong type");
        require(cardType(tokenId) == cardType(prevTokenId),"Cards of different types");
    }

        

    function randomAvailable() internal view returns (bool) {
        return (lastRandomRequested > lastRandomProcessed) && rng.isRequestComplete(randomRequests[lastRandomProcessed]);
    }

    function nextRandom() internal returns (uint256) {
        require(randomAvailable(),"Nothing to process");
        return rng.randomNumber(randomRequests[lastRandomProcessed++]);
    }

    function request_random() internal {
        randomRequests[lastRandomRequested++] = rng.requestRandomNumber();
    }

    // View Function to get graphic properties

    function isCardResolved(uint256 tokenId) public view returns (bool) {
        return traitAssignmentOrder[tokenId] > 0;
    }

    function cardSerialNumber(uint tokenId) public view returns (uint256) {
        require(tokenId < nextTokenId,"invalid tokenId");
        require(isCardResolved(tokenId),"Card not resolved yet");
        return tokenIdToSerial[tokenId];
    }

    function fullTrait(uint256 tokenId) public view returns (uint256) {
        return cardTraits[tokenId];
    }

    function cardType(uint tokenId) public view returns(CardType) {
        if (!isCardResolved(tokenId)) return CardType.Unresolved;
        uint256 serial = tokenIdToSerial[tokenId];
        if (serial < oStart) return CardType.Founder;
        if (serial < aStart) return CardType.OG;
        if (serial < cStart) return CardType.Alpha;
        return CardType.Common;
    }

    function frameTrait(uint tokenId) public view returns(uint256) {
        return (fullTrait(tokenId) >> frame_trait_offset) & frame_trait_mask;
    }

 
    function pictureTrait(uint tokenId) public view returns(uint256) {
        return (fullTrait(tokenId) >> picture_trait_offset) & picture_trait_mask;
    }

    function featureTrait(uint tokenId) public view returns(uint256) {
        return (fullTrait(tokenId) >> feature_trait_offset) & feature_trait_mask;
    }

    function faketoshiTrait(uint256 tokenId) public view returns (uint256) {
        return (fullTrait(tokenId) >> faketoshi_trait_offset) & faketoshi_trait_mask;
    }

    function extraTrait(uint256 tokenId) public view returns (uint256) {
        return (fullTrait(tokenId) >> extra_trait_offset);
    }
   
 function OG_next() external view returns (uint256 left, uint256 nextPrice) {
        return CARD_next(og_stop,oSold,oPending,og_pointer);
        // left = og_stop[og_pointer] - (oSold + oPending);
        // if (og_pointer < og_stop.length - 1)
        //     nextPrice = og_stop[og_pointer+1];
        // else
            // nextPrice = og_stop[og_pointer+1];
    }

    function ALPHA_next() external view returns (uint256 left, uint256 nextPrice) {
            return CARD_next(alpha_stop,aSold,aPending,alpha_pointer);
    }
    function RANDOM_next() external view returns (uint256 left, uint256 nextPrice) {
            return CARD_next(random_stop,cSold,cPending,random_pointer);
    }

    function CARD_next(uint256[] storage stop, uint256 sold, uint256 pending, uint256 pointer) internal view returns (uint256 left, uint256 nextPrice) {
        left = stop[pointer] - (sold + pending);
        if (pointer < stop.length - 1)
            nextPrice = stop[pointer+1];
        else
            nextPrice = stop[pointer];
    }

}