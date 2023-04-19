/**
 *Submitted for verification at polygonscan.com on 2023-04-18
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract Transactions {
    uint256 transactionCount;
    mapping(string => address) userIdToAddress;
    mapping(address => uint) balances;

    struct TransferStruct{
        address sender;
        address receiver;
        uint amount;
        string message;
        uint256 timestamp;
        string keyword;
        string userId;
    }

    TransferStruct[] transactions;

    event Transfer(address from, address receiver, uint amount, string message, uint timestamp, string keyword, string userId);
    event Balance(string userId, address userAddress, uint balance);

   function addToBlockchain(string memory userId, uint amount, string memory message, string memory keyword) public payable {
        require(msg.value == amount, "Sent ether amount does not match the transfer amount"); // Check if the sent ether amount matches the transfer amount
        transactionCount += 1;
        address receiver = userIdToAddress[userId];
        require(receiver != address(0), "User ID not found"); // Check if userId is present
        require(balances[userIdToAddress[userId]] >= amount, "Insufficient balance"); // Check if user has sufficient balance
        transactions.push(TransferStruct(msg.sender, receiver, amount, message, block.timestamp, keyword, userId));
        balances[userIdToAddress[userId]] -= amount;
        balances[msg.sender] += amount;
        emit Transfer(msg.sender, receiver, amount, message, block.timestamp, keyword, userId);
        emit Balance(userId, userIdToAddress[userId],  balances[userIdToAddress[userId]]);
    }

    function getAllTransactions() public view returns (TransferStruct[] memory) {
        return transactions;
    }

    function getTransactionCount() public view returns (uint256) {
        return transactionCount;
    }

    function balanceOf(string memory userId) public view returns (uint) {
        require(userIdToAddress[userId] != address(0), "User ID not found");
        return address(userIdToAddress[userId]).balance;
    }


    function registerUser(string memory userId, address userAddress) public {
        require(userIdToAddress[userId] == address(0), "User ID already registered"); // Check if user ID is already registered
        require(userAddress != address(0), "Wallet address already registered"); // Check if wallet address is valid

        userIdToAddress[userId] = userAddress;
        balances[userIdToAddress[userId]] = 0; // Initialize balance to zero
    }

    
}