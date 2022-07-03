// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.9.0;

contract Verify{
    string private greeting;

    constructor(){

    }

    function hello(bool sayHello) public pure returns(string memory){
        if(sayHello){
            return "hello";
        }else{
            return "";
        }
    }
}