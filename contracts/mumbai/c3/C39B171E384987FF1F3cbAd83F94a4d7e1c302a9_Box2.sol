// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

contract Box2 {
    uint public val;
    string public name;

    function inc() external {
        val += 1;
        name  = "ahmad";
    }

    function setName(string memory _name) external {
        name = _name;
    }

    




    
}