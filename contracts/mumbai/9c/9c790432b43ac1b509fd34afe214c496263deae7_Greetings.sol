/**
 *Submitted for verification at polygonscan.com on 2023-05-23
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract Greetings {
    uint256 public guests = 0;
    mapping(address => uint256) public visits;

    function sayHello() public {
        guests = guests + 1;
        visits[msg.sender] = block.number;
    }
}