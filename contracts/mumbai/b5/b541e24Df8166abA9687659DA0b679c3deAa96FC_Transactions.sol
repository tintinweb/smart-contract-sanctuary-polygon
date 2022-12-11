// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.7;

contract Transactions {
    struct TransferStruct {
        address sender;
        address receiver;
        uint256 amount;
        string keyword;
        string message;
        uint256 timestamp;
    }

    TransferStruct[] transactions;

    uint256 private transferCount;

    event Transfer(
        address sender,
        address receiver,
        uint256 amount,
        string message,
        uint256 timestamp,
        string keyword
    );

    constructor() {}

    function addToBlockChain(
        address payable receiver,
        uint256 amount,
        string memory keyword,
        string memory message
    ) public {
        transferCount++;
        transactions.push(
            TransferStruct(
                msg.sender,
                receiver,
                amount,
                keyword,
                message,
                block.timestamp
            )
        );
        emit Transfer(
            msg.sender,
            receiver,
            amount,
            message,
            block.timestamp,
            keyword
        );
    }

    function getAllTransactions()
        public
        view
        returns (TransferStruct[] memory)
    {
        return transactions;
    }

    function getTransactionCount() public view returns (uint256) {
        return transferCount;
    }
}