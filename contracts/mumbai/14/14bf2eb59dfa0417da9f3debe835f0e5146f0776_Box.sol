/**
 *Submitted for verification at polygonscan.com on 2022-12-22
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Box {
    uint public val;

    function initialize(uint _val) public {
        val = _val;
    }
}