/**
 *Submitted for verification at polygonscan.com on 2022-06-22
*/

// SPDX-License-Identifier: MIT

// File: contracts/test.sol



pragma solidity >=0.7.0 <0.9.0;

contract Test {
    uint256 public randomizer = 1;

    function random(uint256 maxValue) public returns (uint256) {
        randomizer *= 7;
        return uint256(keccak256(abi.encodePacked(block.difficulty, block.timestamp, block.number, randomizer))) % maxValue;       
    }
}