/**
 *Submitted for verification at polygonscan.com on 2022-07-15
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

contract AddData {

    bytes32[] public data;

    function addData(bytes32 data_) external {
        data.push(data_);
    }
}