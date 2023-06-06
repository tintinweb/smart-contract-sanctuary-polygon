/**
 *Submitted for verification at polygonscan.com on 2023-06-06
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

contract Z5DataLake {
    mapping(string => string) public database;

    event DataStored(string key, string value);

    function store(string memory key, string memory value) public {
        database[key] = value;
        emit DataStored(key, value);
    }

    function get(string memory key) public view returns (string memory) {
        return database[key];
    }
}