/**
 *Submitted for verification at polygonscan.com on 2022-07-10
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

contract BoxV1 {

    uint public value;

    function set(uint _value) external {
        value = _value;
    }
}