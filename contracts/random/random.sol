// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.7.0;

import "../interfaces/IRNG.sol";

contract random is IRNG {
    
    uint32 public next;

    mapping(uint32 => uint256) responses;
    mapping(uint32 => bool) responded;
    


    event Request(uint32 number);

    function requestRandomNumber() external override returns (uint32 requestId) {
        emit Request(next++);
    }

    function isRequestComplete(uint32 requestId) external override view returns (bool isCompleted) {
        return responded[requestId];
    } 

    function randomNumber(uint32 requestId) external view override returns (uint256 randomNum) {
        require(this.isRequestComplete(requestId), "Not ready");
        return responses[requestId];
    }

    // back end

    function setRand(uint32 requestId, uint256 rand) external {
        require (requestId < next, "bad ID");
        responses[requestId] = rand;
    }


}
