/**
 *Submitted for verification at polygonscan.com on 2023-04-06
*/

// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.7.0 <0.9.0;

contract Incremental {
    uint256 public index;

    uint256[] public increment; 

    uint256[] public lastIncrement;

    constructor() {}

    function increase() external {
        index += 1;

        increment.push(index);

        lastIncrement.push(block.timestamp);
    }
}