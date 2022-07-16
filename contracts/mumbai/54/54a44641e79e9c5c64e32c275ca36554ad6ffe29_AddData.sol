/**
 *Submitted for verification at polygonscan.com on 2022-07-15
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

contract AddData {

    string[] public data;

    function addData(string memory data_) external {
        data.push(data_);
    }
}