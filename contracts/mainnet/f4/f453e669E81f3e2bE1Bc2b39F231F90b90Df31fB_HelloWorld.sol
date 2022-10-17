// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

contract HelloWorld {
    string public hello = "Hello World from solidity";
    function Hello() public view returns(string memory) {
        return hello;
    }
}