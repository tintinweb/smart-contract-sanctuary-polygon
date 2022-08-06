/**
 *Submitted for verification at polygonscan.com on 2022-08-06
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

contract Counter {
    // int public count;

    int[100] public count;

    uint id;

    function get() public view returns (int) {
        return count[id];
    }

    function setId(uint _newId) public {
        id = _newId;
    }

    // Function to increment count by 1
    function inc() public {
        count[id] += 1;
    }

    // Function to decrement count by 1
    function dec() public {
        count[id] -= 1;
    }
}