/**
 *Submitted for verification at polygonscan.com on 2023-02-05
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

contract Teste {
    uint private num;

    function plus() public {
        num += 1;
    }

    function minus() public {
        num -= 1;
    }

    function show() public view returns (uint) {
        return num;
    }
}