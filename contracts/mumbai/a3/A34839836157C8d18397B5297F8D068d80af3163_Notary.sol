/**
 *Submitted for verification at polygonscan.com on 2022-05-12
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract Notary {

    // Atributes
    mapping (bytes32 => Record) private docHashes;
    struct Record {
        uint mineTime;
        uint blockNumber;
        address  author; 
    }

    //Constructor
    constructor(){

    }
    
    //Functions
    //1. Add a document 

    function addDocHash (bytes32 hash) public {
        require(docHashes[hash].blockNumber == 0);
        Record memory newRecord = Record(block.timestamp, block.number, msg.sender);
        docHashes[hash] = newRecord;
    }

    //2. Check if a document exists
    function findDocHash (bytes32 hash) public view returns(uint, uint, address) {
        return (docHashes[hash].mineTime, docHashes[hash].blockNumber, docHashes[hash].author);
    }
}