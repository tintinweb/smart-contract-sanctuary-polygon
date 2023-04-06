/**
 *Submitted for verification at polygonscan.com on 2023-04-06
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.16;

contract RandomClassic {
    uint256 public randomResult;
    uint256 private lastTimeRandom;

    constructor() {
        lastTimeRandom = block.timestamp;
    }

    /**
    * This function is used to check if a given reward limit is greater than 0, 
    * and returns a random number within the limit.
    */
    function createRandomNumber(uint256 _ramdomWithLimitValue, bool _isRandomOnlyTime) public {
        require(_ramdomWithLimitValue > 0, "THE REWARD IS OVER.");
        /**
        * This function generates a random number using the keccak256 hashing algorithm
        * It takes in parameters including the current timestamp, difficulty level, coinbase address, and block number
        * It then calculates a hash value using the keccak256 algorithm, and returns the modulus of that value with the given limit
        * This ensures that the random value falls within the range of 1 to the given limit (inclusive)
        * The returned value is the generated random number
        */
        uint256 firstRamdomValue = uint256(
            keccak256(
                abi.encodePacked(block.timestamp, block.difficulty, block.coinbase, block.number, blockhash(block.number - 1))
            )
        ) % _ramdomWithLimitValue;
        
        randomResult = firstRamdomValue + 1;

        if(_isRandomOnlyTime && block.timestamp - lastTimeRandom > 10) {
            randomResult = firstRamdomValue + 1;
            lastTimeRandom = block.timestamp;
        }
    }
}