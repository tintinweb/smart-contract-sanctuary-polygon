// SPDX-License-Identifier: UNLICENSED
pragma solidity^0.8.7;

contract GifStore {
    uint256 transactionCount;

    receive() external payable {}

    struct Transaction {
        address sender;
        uint256 amount;
        uint256 timestamp;
    }

    Transaction[] transactions;

    event Transfer(address from, uint256 amount, uint256 timestamp);

    function processTransfer(address from, uint256 amount) public {
        transactionCount++;
        transactions.push(Transaction(from, amount, block.timestamp));

        emit Transfer(from, amount, block.timestamp);
    }

    function getNoOfTransactions() public view returns (uint256) {
        return transactionCount;
    }

    function getAllTransactions() public view returns (Transaction[] memory) {
        return transactions;
    }
}