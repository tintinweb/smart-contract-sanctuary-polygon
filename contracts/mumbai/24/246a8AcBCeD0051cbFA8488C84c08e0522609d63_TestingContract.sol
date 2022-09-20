/**
 *Submitted for verification at polygonscan.com on 2022-09-19
*/

// File: contracts/TestingContract.sol

pragma solidity 0.6.6;

contract TestingContract {
    uint256 startTime;

    function tmp() public view returns (uint256) {
        require(startTime != 0);
        return (now - startTime) / (1 minutes);
    }

    function callThisToStart() external {
        startTime = now;
    }

    function callThisToStop() external {
        startTime = 0;
    }

    function doSomething() internal returns (uint256) {
        return tmp();
    }
}