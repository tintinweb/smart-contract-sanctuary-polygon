/**
 *Submitted for verification at polygonscan.com on 2022-03-19
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.6.0;

contract SimpleStorage {

   uint256 value = 5;

    function get () view public returns (uint256) {
        return value;
    }
}