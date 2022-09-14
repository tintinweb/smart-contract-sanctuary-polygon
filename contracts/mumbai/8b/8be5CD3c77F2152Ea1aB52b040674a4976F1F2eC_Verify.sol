// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

contract Verify {
    string private greeting;

    constructor(){
    }

    function hello(bool sayHi) public pure returns(string memory){
        if(sayHi){
            return "hello";
        }
        return "";
    }
}