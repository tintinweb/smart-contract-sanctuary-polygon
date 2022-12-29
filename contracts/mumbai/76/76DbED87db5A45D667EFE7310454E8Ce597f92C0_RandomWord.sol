/**
 *Submitted for verification at polygonscan.com on 2022-12-28
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

contract RandomWord{
    uint nonce = 0;
    uint public randomNumber;
    function generateRandom() public{
        uint random = uint(keccak256(abi.encodePacked(nonce, block.timestamp, msg.sender)));
        nonce++;
        randomNumber = (random%99)+1;
    }
}