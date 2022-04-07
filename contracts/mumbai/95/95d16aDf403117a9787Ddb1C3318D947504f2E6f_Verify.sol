//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

contract Verify {
    string private greeting;

    constructor() {

    }

    function gm(bool sayGM) public pure returns (string memory) {
        if(sayGM) {
            return "GM";
        }
        return "";
    }
}