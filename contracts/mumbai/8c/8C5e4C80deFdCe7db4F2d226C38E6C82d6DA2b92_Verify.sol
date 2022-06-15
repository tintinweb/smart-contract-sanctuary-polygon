//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Verify{
    string private greeting;

    constructor(){

    }
    function hello (bool sayhello) public pure returns(string memory){
        if(sayhello){
            return "hello";
        }
        return "";
    }
}