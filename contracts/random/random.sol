// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.7.0;

import "../interfaces/IRNG.sol";

contract random is IRNG {
    
    uint public next = 0;

    mapping(bytes32 => uint256) responses;
    mapping(bytes32 => bool) responded;
    


    event Request(uint number);
    event RandomReceived(uint requestId,uint rand);

    function requestRandomNumber() external override returns (bytes32 requestId) {
        emit Request(next);
        return bytes32(next++);
    }

    function isRequestComplete(bytes32 requestId) external override view returns (bool isCompleted) {
        return responded[requestId];
    } 

    function randomNumber(bytes32 requestId) external view override returns (uint256 randomNum) {
        require(this.isRequestComplete(requestId), "Not ready");
        return responses[requestId];
    }

    // back end

    function setRand(uint requestId, uint256 rand) external {
        require (requestId < next, "bad ID");
        responses[bytes32(requestId)] = rand;
        responded[bytes32(requestId)] = true;
        emit RandomReceived(requestId,rand);
    }

}
