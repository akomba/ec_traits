// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.7.0;

abstract contract IRNG {

    function requestRandomNumber() external virtual returns (uint32 requestId, uint32 lockBlock) ;

    function isRequestComplete(uint32 requestId) external virtual view returns (bool isCompleted) ; 

    function randomNumber(uint32 requestId) external view virtual returns (uint256 randomNum) ;
}