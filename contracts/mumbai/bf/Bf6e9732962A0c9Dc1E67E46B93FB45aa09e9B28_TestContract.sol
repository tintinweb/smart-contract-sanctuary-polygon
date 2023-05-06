/**
 *Submitted for verification at polygonscan.com on 2023-05-05
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

contract TestContract {
    uint256 public counter = 1;

    function addOne() external {
        counter++;
    }

    function err() external {
        require(counter == 100, "TestContract counter must be 100");
        counter++;
    }
}