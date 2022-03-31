//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

contract Verify {
    string private greeting;

    function hello(bool a) public pure returns (string memory) {
        if (a) return "hello";
        else return "bye";
    }
}