//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;


contract test {

    string public str;

    function zapis(string memory _str) external {
        str = _str;
    }

    constructor() {}
}