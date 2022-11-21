//SPDX-License-Identifier:MIT
pragma solidity ^0.8.4;

//验证合约

contract Verify {
    string private greeting;

    constructor(){}

    function hello(bool sayHello) public pure returns (string memory){
        if(sayHello){
            return "hello";
        }
        return "";
    }
}