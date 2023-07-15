/**
 *Submitted for verification at polygonscan.com on 2023-07-15
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

contract RandomNumberGenerator {
    struct Number {
        uint256 value;
        uint256 dateTime;
    }

    Number[] public numbers;

    function generateRandomNumber() public {
        uint256 random = uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty))) % 10000 + 1;
        numbers.push(Number(random, block.timestamp));
    }

    function getNumbersCount() public view returns (uint256) {
        return numbers.length;
    }

    function getNumber(uint256 index) public view returns (uint256, uint256) {
        return (numbers[index].value, numbers[index].dateTime);
    }
}