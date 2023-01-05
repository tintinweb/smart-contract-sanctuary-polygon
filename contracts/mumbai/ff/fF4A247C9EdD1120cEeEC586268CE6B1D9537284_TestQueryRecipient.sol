/**
 *Submitted for verification at polygonscan.com on 2023-01-04
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

contract TestQueryRecipient {
    mapping(uint256 => address) public addresses;

    constructor() {
        addresses[1] = msg.sender;
        addresses[2] = address(this);
    }

    function getAddress(uint256 id) external view returns(address) {
        return addresses[id];
    }

    function setAddress(uint256 id, address addr) external {
        addresses[id] = addr;
    }
}