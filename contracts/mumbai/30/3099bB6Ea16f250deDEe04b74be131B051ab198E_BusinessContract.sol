/**
 *Submitted for verification at polygonscan.com on 2023-04-10
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

// 定义业务合约，用于演示升级功能
contract BusinessContract {
    uint256 private data;

    function setData(uint256 _data) external {
        data = _data;
    }
}