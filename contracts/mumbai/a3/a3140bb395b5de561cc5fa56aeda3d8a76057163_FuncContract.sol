/**
 *Submitted for verification at polygonscan.com on 2022-12-07
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

contract FuncContract {
    uint256 private app;

    event UPDATE(uint256 val);
    function updateVariable(uint256 _val) external {
        app = _val;
        emit UPDATE(app);
    }
}