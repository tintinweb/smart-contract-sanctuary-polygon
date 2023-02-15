/**
 *Submitted for verification at polygonscan.com on 2023-02-15
*/

pragma solidity ^0.8.0;

// SPDX-License-Identifier: MIT

contract TestRandao {
    event Print(uint x);

    function lol() public {
        emit Print(block.difficulty);
    }

    function lol2() public view returns (uint) {
        return block.difficulty;
    }
}