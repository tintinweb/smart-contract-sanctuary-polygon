//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

contract Verify {
    string private greeting;

    constructor(){

    }

    function sayHello(bool hello) public pure returns(string memory){
        if(hello){
            return "Hello";
        }else{
            return "Goodbye";
        }   
    }
}