/**
 *Submitted for verification at polygonscan.com on 2022-04-20
*/

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.13;

contract MyTest {

    string public name;
    uint256 public value;

    constructor(string memory _name, uint256 _value) {
        name = _name;
        value = _value;
    }
}