/**
 *Submitted for verification at polygonscan.com on 2023-04-16
*/

pragma solidity ^0.8.0;

contract TPS_Calculator {
    uint256 private startTime;
    uint256 private txCount;

    // Event to log the calculated TPS
    event TPS(uint256 transactions, uint256 duration, uint256 tps);

    constructor() {
        startTime = block.timestamp;
        txCount = 0;
    }

    // Function to increment the transaction count
    function sendTransaction() public {
        txCount += 1;
    }

    // Function to calculate and emit the TPS
    function calculateTPS() public {
        require(txCount > 0, "No transactions to calculate TPS.");
        uint256 duration = block.timestamp - startTime;
        uint256 tps = (txCount * 1000) / duration;
        emit TPS(txCount, duration, tps);
        resetTPS();
    }

    // Function to reset the TPS calculation
    function resetTPS() private {
        startTime = block.timestamp;
        txCount = 0;
    }
}