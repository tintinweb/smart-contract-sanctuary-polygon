//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

contract Verify{
    string private greetings;

    constructor(){}

    function hello(bool sayHello) pure public returns(string memory){
        if(sayHello){
            return "Yo boi";
        }
        return "";
    }
}