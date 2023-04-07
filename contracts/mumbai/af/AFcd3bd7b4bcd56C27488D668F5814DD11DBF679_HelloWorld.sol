// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.9 <=0.8.19;

contract HelloWorld{
    string hello = "hello";

    function helloWorld() public view returns(string memory){
        return hello;
    }
}