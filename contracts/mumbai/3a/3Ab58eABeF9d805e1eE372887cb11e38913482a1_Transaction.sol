/**
 *Submitted for verification at polygonscan.com on 2023-06-08
*/

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

contract Transaction {
    uint256 transactionCount;
      
    event Transfer(address from,address receiver,uint amount,string message,uint256 timeStamp,string keyword);

    struct TransferStruct{
        address from;
        address receiver;
        uint amount;
        string message;
        uint256 timeStamp;
        string keyword;
    }
    TransferStruct[] transactions;

    function addToBlockchain(address payable receiver,uint amount, string memory message,string memory keyword) public{
        transactionCount +=1;
        // msg.sender block.timestamp predefined
        transactions.push(TransferStruct(msg.sender,receiver,amount,message,block.timestamp,keyword));

        emit Transfer(msg.sender,receiver,amount,message,block.timestamp,keyword);
        //emit makes the actual transfer
    }
    function getAllTransactions() public view returns (TransferStruct[] memory){
        //returns array of TransferStruct from memory
        return transactions;

    }
    function getTransactionCount() public view returns (uint256){
        return transactionCount;
    }
}