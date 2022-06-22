/**
 *Submitted for verification at polygonscan.com on 2022-06-21
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

contract Object {

    string name;
    constructor (string memory _name){
        name = _name;
    }
}

contract ObjectFactory {
    function createObject(string memory name) external {
        new Object(name);
    }
}