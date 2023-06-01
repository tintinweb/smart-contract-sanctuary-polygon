/**
 *Submitted for verification at polygonscan.com on 2023-06-01
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

contract Random {
    uint public salt = 98454566;

    function random2(uint maxNumber, uint minNumber) public returns (uint amount) {
        salt += block.timestamp - block.number * 1989;        
        amount = uint(keccak256(abi.encodePacked(block.timestamp, msg.sender, block.number, salt, msg.sender))) % (maxNumber-minNumber);
        amount = amount + minNumber;
        return amount;
    } 

    function random(uint maxNumber,uint minNumber) public returns (uint amount) {
        amount = uint(keccak256(abi.encodePacked(block.timestamp, msg.sender, block.number, salt))) % (maxNumber-minNumber);
        amount = amount + minNumber;
        salt = salt + amount;
        return amount;
    } 
}