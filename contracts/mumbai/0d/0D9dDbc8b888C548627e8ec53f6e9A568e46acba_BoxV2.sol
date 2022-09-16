//SPDX-License-Identifier: MIT
//Author: althabe.eth, vivek.eth
pragma solidity ^0.8.12;

contract BoxV2{
    uint public val;

// function initialize(uint _val) external {
//     val = _val;
// }

function inc() external{
    val += 1;
}

}