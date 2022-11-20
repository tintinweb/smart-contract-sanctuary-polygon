/**
 *Submitted for verification at polygonscan.com on 2022-11-19
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

contract Krypton {
    uint256 public transactionsCounter;

    event Transfer(address from, address receiver, uint256 amount, string message, uint256 timestamp, string keyword);

    struct TransferStruct {
        address sender;
        address receiver;
        uint256 amount;
        string message;
        uint256 timestamp;
        string keyword;
    }

    TransferStruct[] public transactions;

    function addToBlockchain(address payable receiver, uint256 amount, string memory message, string memory keyword) external {
        transactionsCounter++;
        transactions.push(TransferStruct(msg.sender, receiver, amount, message, block.timestamp, keyword));

        emit Transfer(msg.sender, receiver, amount, message, block.timestamp, keyword);
    }

}