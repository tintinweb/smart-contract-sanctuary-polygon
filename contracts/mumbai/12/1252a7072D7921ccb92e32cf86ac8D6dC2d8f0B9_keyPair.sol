/**
 *Submitted for verification at polygonscan.com on 2022-11-09
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

contract keyPair {
    mapping (string => string) pair;

    constructor() {

    }

    event pairSet(string key, string value);

    function getValue(string memory _key) public view returns (string memory) {
        return pair[_key];
    }

    function setPair(string memory _key, string memory _value) public {
        
        pair[_key] = _value;

        emit pairSet(_key, _value);
    }
}