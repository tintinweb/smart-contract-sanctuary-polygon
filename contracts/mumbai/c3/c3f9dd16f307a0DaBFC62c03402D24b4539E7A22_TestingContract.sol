/**
 *Submitted for verification at polygonscan.com on 2022-06-19
*/

// File: contracts/TestingContract.sol

pragma solidity 0.6.6;

contract TestingContract {
    uint256 public startTime;
    uint256 public counter;
    uint256 public timePassed;

    function tmp() public payable returns (uint256, uint256) {
        require(startTime != 0);
        counter++;
        return ((now - startTime) / (1 minutes), counter);
    }

    function callThisToStart() external {
        timePassed = now - timePassed;
        startTime = now;
    }

    function callThisToStop() external {
        startTime = 0;
    }

    function doSomething() external returns (uint256, uint256) {
        counter++;
        return tmp();
    }
}