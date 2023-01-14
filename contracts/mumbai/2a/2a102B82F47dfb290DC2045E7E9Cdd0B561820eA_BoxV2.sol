// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

contract BoxV2 {
    uint public val;
    struct name{
        string names;
        uint age;
    }
    mapping(address => name) public namesStruct;

    function init() public {
        namesStruct[msg.sender].names = "Jaami";
        namesStruct[msg.sender].age = 25;
    }
}