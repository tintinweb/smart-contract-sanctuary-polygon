// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

contract SaveUint {
mapping(uint32=>bool) public myMap;
uint32[] public myArray;
address public owner;

constructor() {
    owner = msg.sender;
}

function saveOnMap(uint32 x) public {
    require(msg.sender == owner,"");
    myMap[x] = true;

}

function saveOnArray(uint32 x) public {
    require(msg.sender == owner,"");
    myArray.push(x);
}
}