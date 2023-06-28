/**
 *Submitted for verification at polygonscan.com on 2023-06-28
*/

// SPDX-License-Identifier: MIT
// compiler version must be greater than or equal to 0.8.17 and less than 0.9.0
pragma solidity ^0.8.17;

contract HelloWorld {
    address public owner;
    uint256 public itemCount;

    constructor() {
        owner = msg.sender;
    }

    function getItem() public view returns (uint256) {
        return itemCount;
    }

    function setItem() public returns (bool) {
        itemCount++;
        return true;
    }
}