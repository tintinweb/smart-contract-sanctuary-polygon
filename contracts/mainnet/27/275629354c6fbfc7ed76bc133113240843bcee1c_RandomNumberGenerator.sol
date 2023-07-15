/**
 *Submitted for verification at polygonscan.com on 2023-07-15
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

contract RandomNumberGenerator {
    uint private constant MAX_NUMBER = 10000;
    uint private seed;

    event NewRandomNumber(uint randomNumber);

    constructor() {
        // Set the seed to a combination of the block timestamp and the address of the last miner
        seed = uint(keccak256(abi.encodePacked(block.timestamp, block.coinbase)));
    }

    function generateRandomNumber() public {
        // Generate the random number between 1 and MAX_NUMBER
        uint randomNumber = (uint(keccak256(abi.encodePacked(block.timestamp, block.difficulty, msg.sender, seed))) % MAX_NUMBER) + 1;
        
        // Update the seed for the next random number generation
        seed = randomNumber;
        
        // Emit the event with the new random number
        emit NewRandomNumber(randomNumber);
    }
}