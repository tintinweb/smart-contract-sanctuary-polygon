/**
 *Submitted for verification at polygonscan.com on 2022-05-04
*/

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

contract Verify {
    string private greeting;
    string private greeting1;
    string private greeting2;
    string private greeting3;

    constructor() {
    }

    function hello(bool sayHello,bool sayHello2) public pure returns (string memory) {
        if(sayHello&&sayHello2) {
            return "hello test";
        }
        return "";
    }
}