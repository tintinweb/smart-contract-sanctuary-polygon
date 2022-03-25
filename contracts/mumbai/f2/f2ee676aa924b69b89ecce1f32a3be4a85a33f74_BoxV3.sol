/**
 *Submitted for verification at polygonscan.com on 2022-03-24
*/

// contracts/MyContract.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

contract BoxV3 {
    uint256 public x;
    uint256 public y;

    constructor(uint256 _y) public {
        y = _y;
    }
}