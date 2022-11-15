/**
 *Submitted for verification at polygonscan.com on 2022-11-14
*/

// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.4;

contract Verify {
    string private greeting;

    constructor() {

    }

    function hello(bool sayHello) public pure returns (string memory) {
        if(sayHello) {
            return "Jello Jeff";
        }
        return "";
    }
}