/**
 *Submitted for verification at polygonscan.com on 2023-07-15
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

contract RandomNumberGenerator {
    uint private constant MAX_NUMBER = 10000;
    uint private seed;
    
    struct RandomNumberData {
        uint randomNumber;
        uint timestamp;
    }
    
    RandomNumberData[] public randomNumberHistory;

    event NewRandomNumber(uint randomNumber, uint timestamp);

    constructor() {
        // Set the seed to a combination of the block timestamp and the address of the last miner
        seed = uint(keccak256(abi.encodePacked(block.timestamp, block.coinbase)));
    }

    function generateRandomNumber() public {
        // Generate the random number between 1 and MAX_NUMBER
        uint randomNumber = (uint(keccak256(abi.encodePacked(block.timestamp, block.difficulty, msg.sender, seed))) % MAX_NUMBER) + 1;
        
        // Update the seed for the next random number generation
        seed = randomNumber;
        
        // Create a new RandomNumberData struct
        RandomNumberData memory data = RandomNumberData(randomNumber, block.timestamp);
        
        // Add the new random number data to the history
        randomNumberHistory.push(data);
        
        // Emit the event with the new random number and timestamp
        emit NewRandomNumber(randomNumber, block.timestamp);
    }
    
    function getHistory() public view returns (RandomNumberData[] memory) {
        return randomNumberHistory;
    }
}