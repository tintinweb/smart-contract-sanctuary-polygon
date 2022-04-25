/**
 *Submitted for verification at polygonscan.com on 2022-04-23
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Setter {

    uint public value;

    function setValue(uint value_) public {
        value = value_;
    }
}