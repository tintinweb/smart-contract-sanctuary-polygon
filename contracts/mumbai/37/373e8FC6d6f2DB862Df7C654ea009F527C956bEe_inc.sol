/**
 *Submitted for verification at polygonscan.com on 2022-03-13
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;



contract inc {

    uint256 public num = 0;

    function increases() public{
        num += 1;
    }
}