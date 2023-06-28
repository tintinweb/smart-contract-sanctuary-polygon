/**
 *Submitted for verification at polygonscan.com on 2023-06-28
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.7;


contract Counter {
    uint256 public counter;

    function incrementCounter() public {
        counter = counter + 1;
    }
}