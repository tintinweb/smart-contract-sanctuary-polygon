/**
 *Submitted for verification at polygonscan.com on 2023-02-04
*/

// SPDX-License-Identifier: MIT
// Created by Novus-web.xyz


pragma solidity ^0.8.0;

contract RandomNumberGeneratorAG {
    uint256[] public generatedNumbers;
    address owner = msg.sender;

    
    function generateRandomNumbers(uint256 maxNumber, uint256 count) public onlyOwner {
        for (uint256 i = 0; i < count; i++) {
            generatedNumbers.push(uint256(uint256(keccak256(abi.encodePacked(block.timestamp, i))) % maxNumber));
        }
    }

    function getGeneratedNumbers() public view returns (uint256[] memory) {
        return generatedNumbers;
    }

    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0));
        owner = newOwner;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only the contract owner can execute this function.");
        _;
    }
}