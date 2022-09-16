//SPDX-License-Identifier: MIT
//Author: althabe.eth, vivek.eth
pragma solidity ^0.8.12;

contract Box{
    uint public val;

// constructor(uint _val){
//     val = _val;
// }

function initialize(uint _val) external {
    val = _val;
}
}