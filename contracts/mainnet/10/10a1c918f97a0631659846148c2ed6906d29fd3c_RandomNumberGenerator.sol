/**
 *Submitted for verification at polygonscan.com on 2023-07-15
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract RandomNumberGenerator {

    struct RandomNumberInfo {
        uint256 number;
        uint256 timestamp;
    }

    RandomNumberInfo[] public randomNumberHistory;

    function generateRandomNumber() public {
        uint256 randomNumber = (uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty))) % 10000) + 1;
        RandomNumberInfo memory newRandomNumberInfo = RandomNumberInfo(randomNumber, block.timestamp);
        randomNumberHistory.push(newRandomNumberInfo);
    }
    
    function getHistoryLength() public view returns(uint256) {
        return randomNumberHistory.length;
    }

    function getHistoryItem(uint256 index) public view returns (uint256 number, uint256 timestamp) {
        return (randomNumberHistory[index].number, randomNumberHistory[index].timestamp);
    }
}