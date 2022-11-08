/**
 *Submitted for verification at polygonscan.com on 2022-11-07
*/

//SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.17;

contract VerifyTest {
    string private greeting;

    constructor() {
    }

    function hello(bool sayHello) public pure returns (string memory) {
        if(sayHello) {
            return "hello";
        }
        return "goodbye";
    }
}