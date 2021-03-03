// SPDX-License-Identifier: MIT

pragma solidity ^0.6.6;

import "@chainlink/contracts/src/v0.6/VRFConsumerBase.sol";

import "@openzeppelin/contracts/access/Ownable.sol";


contract random is VRFConsumerBase, Ownable {
    

    mapping(bytes32=>uint256)   public responses;
    mapping(bytes32=>bool)      public responded;
    bytes32[]                   public requestIDs; 

    bytes32                     public keyHash;
    uint256                     public fee;

    mapping(address => bool)    authorised;

    modifier onlyAuth {
        require(authorised[msg.sender],"Not Authorised");
        _;
    }

    event Request(bytes32 RequestID);
    event RandomReceived(bytes32 requestId, uint256 randomNumber);
    event AuthChanged(address user,bool auth);

    constructor(address VRFCoordinator, address LinkToken)
       public
       VRFConsumerBase(VRFCoordinator, LinkToken)
    {
        uint256 id;
        assembly {
            id := chainid()
        }
        if (id == 4) {
            keyHash = 0x2ed0feb3e7fd2022120aa84fab1945545a9f2ffc9076fd6156fa96eaff4c1311;
            fee = 1e17; // 0.1 LINK
        } else if (id == 1) {
            keyHash = 0xAA77729D3466CA35AE8D28B3BBAC7CC36A5031EFDC430821C02BC31A238AF445;
            fee = 2e18;
        } else {
            require(false,"Invalid Chain");
        }
    }

    function setAuth(address user, bool auth) public onlyOwner {
        authorised[user] = auth;
        emit AuthChanged(user,auth);
    }

    function requestRandomNumber( ) public returns (bytes32) {
       require(
           LINK.balanceOf(address(this)) >= fee,
           "Not enough LINK - fill contract with faucet"
       );
       uint userProvidedSeed = uint256(blockhash(block.number-1));
       bytes32 requestId = requestRandomness(keyHash, fee, userProvidedSeed);
       requestIDs.push(requestId);
       emit Request(requestId);
       return requestId;
    }

    function isRequestComplete(bytes32 requestId) external view returns (bool isCompleted) {
        return responded[requestId];
    } 

    function randomNumber(bytes32 requestId) external view returns (uint256 randomNum) {
        require(this.isRequestComplete(requestId), "Not ready");
        return responses[requestId];
    }


    function fulfillRandomness(bytes32 requestId, uint256 randomNumber)
       internal
       override
    {
        responses[requestId] = randomNumber;
        responded[requestId] = true;
        emit RandomReceived(requestId, randomNumber);
    }


}
