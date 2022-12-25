/**
 *Submitted for verification at polygonscan.com on 2022-12-24
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

contract RandomNumberGenerator {
    uint public randomNumber;

    constructor()  {
        generateRandomNumber();
    }

    function generateRandomNumber() public {
        randomNumber = uint(keccak256(abi.encodePacked(block.timestamp, msg.sender))) % 100 + 1;
    }
}