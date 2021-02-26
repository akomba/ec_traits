// SPDX-License-Identifier: UNLICENSED
// produced by the Solididy File Flattener (c) David Appleton 2018 - 2020 and beyond
// contact : calistralabs@gmail.com
// source  : https://github.com/DaveAppleton/SolidityFlattery
// released under Apache 2.0 licence
// input  /Users/daveappleton/Documents/akombalabs/ec_traits/contracts/random/random.sol
// flattened :  Wednesday, 24-Feb-21 22:28:14 UTC
abstract contract IRNG {

    function requestRandomNumber() external virtual returns (uint32 requestId) ;

    function isRequestComplete(uint32 requestId) external virtual view returns (bool isCompleted) ; 

    function randomNumber(uint32 requestId) external view virtual returns (uint256 randomNum) ;
}
contract random is IRNG {
    
    uint32 public next = 0;

    mapping(uint32 => uint256) responses;
    mapping(uint32 => bool) responded;
    


    event Request(uint32 number);
    event RandomReceived(uint requestId,uint rand);

    function requestRandomNumber() external override returns (uint32 requestId) {
        emit Request(next);
        return next++;
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
        responded[requestId] = true;
        emit RandomReceived(requestId,rand);
    }


}

