/**
 *Submitted for verification at polygonscan.com on 2022-06-22
*/

// SPDX-License-Identifier: MIT

// File: contracts/test.sol



pragma solidity >=0.7.0 <0.9.0;

contract Test {
    uint256 public randomizer = 1;

    uint256[] public result;

    function random(uint256 maxValue) public{
        randomizer *= 7;
        result.push(uint256(keccak256(abi.encodePacked(block.difficulty, block.timestamp, block.number, randomizer))) % maxValue);       
    }

    function mostra() public view returns(uint256[] memory){
        return result;
    }
}