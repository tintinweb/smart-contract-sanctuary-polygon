// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

contract BoxV2 {
    uint public val;
    struct name {
        string names;
        uint age;
    }
    mapping(address => name) public namesStruct;


    function setStruct(string memory _name, uint age) public {
        namesStruct[msg.sender].names = _name;
        namesStruct[msg.sender].age = age;
    }
}