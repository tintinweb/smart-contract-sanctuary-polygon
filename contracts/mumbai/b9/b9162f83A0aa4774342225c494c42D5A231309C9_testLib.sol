// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library testLib {
    function printTest() public pure returns (string memory) {
        string memory test = "TEST";
        return test;
    }
}