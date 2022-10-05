/**
 *Submitted for verification at polygonscan.com on 2022-10-04
*/

//SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.7;


contract Verify {
    string private greeting;

    constructor() {}

    function hello(bool sayHello) public pure returns (string memory) {
        if (sayHello) {
            return "hello";
        }
        return "";
    }
}