/**
 *Submitted for verification at polygonscan.com on 2022-11-11
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

// Uncomment this line to use console.log
// import "hardhat/console.sol";

contract CountNumber {
    uint public number;
    address payable public owner;


    constructor(uint initialNumber) payable {
        number = initialNumber;
        owner = payable(msg.sender);
    }

    function increment() public {
        number += 1;
    }
    function decrement() public {
        require(number > 0, "number must not be less than zero");
        number -= 1;
    }
}