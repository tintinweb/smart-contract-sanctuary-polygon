/**
 *Submitted for verification at polygonscan.com on 2022-08-03
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.7.0;

contract TStore {
    uint storedData;

    function set(uint x) public {
        storedData = x;
    }

    function get() public view returns (uint) {
        return storedData;
    }
}