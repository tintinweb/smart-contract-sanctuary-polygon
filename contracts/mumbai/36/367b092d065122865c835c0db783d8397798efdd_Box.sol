/**
 *Submitted for verification at polygonscan.com on 2022-06-20
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8;

/*
proxy --> implementation
  ^
  |
  |
proxy admin
*/

contract Box {
    uint public val;
    function initialize(uint _val) public {
        val = _val;
    }
}