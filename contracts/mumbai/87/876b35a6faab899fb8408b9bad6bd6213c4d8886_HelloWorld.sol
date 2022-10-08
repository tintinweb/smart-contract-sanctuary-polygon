/**
 *Submitted for verification at polygonscan.com on 2022-10-08
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

contract HelloWorld {
    string public name = "Hello World";

    function getName() public view returns (string memory) {
        return name;
    } 
}