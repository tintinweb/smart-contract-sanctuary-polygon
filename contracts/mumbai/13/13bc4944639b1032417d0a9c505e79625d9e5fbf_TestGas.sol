/**
 *Submitted for verification at polygonscan.com on 2022-09-16
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract TestGas {
    uint256 public value = 0;

    function set(uint256 nweValue) external {
        require(nweValue < 101, "value >= 100");

        value = nweValue;
    }

}