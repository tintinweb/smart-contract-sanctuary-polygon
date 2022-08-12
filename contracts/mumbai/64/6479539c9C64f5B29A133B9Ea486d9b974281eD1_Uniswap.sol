/**
 *Submitted for verification at polygonscan.com on 2022-08-11
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

// Import this file to use console.log
// import 'hardhat/console.sol';

contract Uniswap {
    event Transfer(
        address sense,
        address receiver,
        uint256 amount,
        string message,
        uint256 timestamp,
        string keyword
    );

    function publishTransaction(
        address payable receiver,
        uint256 amount,
        string memory message,
        string memory keyword
    ) public {
        emit Transfer(
            msg.sender,
            receiver,
            amount,
            message,
            block.timestamp,
            keyword
        );
    }
}