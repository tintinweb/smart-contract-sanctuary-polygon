/**
 *Submitted for verification at polygonscan.com on 2023-06-03
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract KeyValueStore {
    mapping(string => string) private store;

    function setValue(string memory key, string memory value) public {
        store[key] = value;
    }

    function getValue(string memory key) public view returns (string memory) {
        return store[key];
    }
}