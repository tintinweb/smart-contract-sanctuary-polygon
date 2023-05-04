//SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.4;

contract Verify {
    string private greeting;

    constructor() {
    }

    function topG(bool sayTopG) public pure returns (string memory) {
        if(sayTopG) {
            return "All hail to the top G's!!";
        }
        return "";
    }
}