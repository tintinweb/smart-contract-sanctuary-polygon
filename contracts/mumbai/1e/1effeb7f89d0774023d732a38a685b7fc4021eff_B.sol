/**
 *Submitted for verification at polygonscan.com on 2023-02-13
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract A {
    string public a = "a";
}

contract B is A {
    string public b = "b";
    
    constructor(string memory _a){
        a = _a;
    }
}