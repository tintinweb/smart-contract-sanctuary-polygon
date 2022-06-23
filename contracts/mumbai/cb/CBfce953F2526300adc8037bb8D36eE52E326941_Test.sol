/**
 *Submitted for verification at polygonscan.com on 2022-06-22
*/

// SPDX-License-Identifier: MIT

// File: contracts/test.sol



pragma solidity >=0.7.0 <0.9.0;

contract Test {
    uint256 a = 300;
    uint256 b = 100;
    function random(uint256 maxValue) public returns (uint256) {
        uint256 randomizer = uint256(keccak256(abi.encodePacked(block.difficulty + block.timestamp + (a + 2) ** (b + 2) + (b + 2) ** (a + 2)  + a * b )));
        a--;
        b--;
        return uint256(keccak256(abi.encodePacked(block.difficulty, block.timestamp, block.number, randomizer))) % maxValue;
    }
}