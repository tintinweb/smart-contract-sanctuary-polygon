/**
 *Submitted for verification at polygonscan.com on 2022-08-03
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;


contract SimpleContract {
    uint256 public simpleNumber;

    function add(uint256 value) public returns (uint256) {
        simpleNumber += value;
        return simpleNumber;
    }

    function substract(uint256 value) public returns (uint256) {
        simpleNumber -= value;
        return simpleNumber;
    }
}