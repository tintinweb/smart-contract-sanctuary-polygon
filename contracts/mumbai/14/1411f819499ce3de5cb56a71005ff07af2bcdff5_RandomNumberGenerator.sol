/**
 *Submitted for verification at polygonscan.com on 2023-07-12
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

contract RandomNumberGenerator {
    uint256 private seed;

    constructor() {
        seed = uint256(keccak256(abi.encodePacked(block.timestamp, msg.sender)));
    }

    function getRandomNumber(uint256 upperBound) public view returns (uint256) {
        return (uint256(keccak256(abi.encodePacked(block.difficulty, block.timestamp, seed, msg.sender)))) % upperBound;
    }
}