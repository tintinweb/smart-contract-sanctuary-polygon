/**
 *Submitted for verification at polygonscan.com on 2023-06-22
*/

// SPDX-License-Identifier: MIT
// @author: test
pragma solidity ^0.8.18;

contract ExternalRegistry {
    string public jsonLink;
    address public owner;

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only contract owner can modify the registry");
        _;
    }

    function updateJsonLink(string memory newLink) public onlyOwner {
        jsonLink = newLink;
    }
}