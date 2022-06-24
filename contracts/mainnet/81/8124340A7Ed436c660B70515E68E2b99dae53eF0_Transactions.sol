// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

contract Transactions {
    uint256 transactionCount;

    event Transfer(address from, address receiver, uint amount, uint256 timestamp);
  
    struct TransferStruct {
        address sender;
        address receiver;
        uint amount;
        uint256 timestamp;
    }

    TransferStruct[] transactions;

    function addToBlockchain(address payable receiver, uint amount) public {
        transactionCount += 1;
        transactions.push(TransferStruct(msg.sender, receiver, amount, block.timestamp));

        emit Transfer(msg.sender, receiver, amount, block.timestamp);
    }

    function getAllTransactions() public view returns (TransferStruct[] memory) {
        return transactions;
    }

    function getTransactionCount() public view returns (uint256) {
        return transactionCount;
    }
}