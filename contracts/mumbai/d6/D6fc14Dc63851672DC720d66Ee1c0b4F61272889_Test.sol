/**
 *Submitted for verification at polygonscan.com on 2023-05-23
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0; 

contract Test {
    uint256 public value;
    event SetValue(uint256 _val);

    function setValue(uint256 _val) external {
        value = _val;
        emit SetValue(_val);
    }
}