/**
 *Submitted for verification at polygonscan.com on 2022-05-31
*/

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

contract Verify {
    string private greeting;

    constructor() {

    }

    function hello(bool sayHello) public pure returns (string memory) {
        if(sayHello) {
            return "hello";
        }
        return "";
    }
}