// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.13;

contract MyTest {

    string public name;

    constructor(string memory _name) {
        name = _name;
    }
}