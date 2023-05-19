/**
 *Submitted for verification at polygonscan.com on 2023-05-18
*/

// SPDX-License-Identifier: MIT
pragma solidity  ^0.8.15;

contract Auditor {

    struct Record {
        uint mineTime;
        uint blockNumber;
        string awardeeId;
        string titleId;
        string titleState;
        string dateIssued;
    }

    mapping (bytes32 => Record) private diplomaHashes;

    constructor() {
        // constructor
    }

    function storeDiplomaHash (bytes32 hash, string memory _awardee, string memory _title, string memory _state, string memory _dateissued) public {
        Record memory newRecord = Record(block.timestamp, block.number, _awardee, _title, _state, _dateissued);
        diplomaHashes[hash] = newRecord;
    }

    function findDiplomaHash (bytes32 hash) public view returns (uint, uint, string memory, string memory, string memory, string memory) {
        return (diplomaHashes[hash].mineTime, diplomaHashes[hash].blockNumber, diplomaHashes[hash].awardeeId, diplomaHashes[hash].titleId, diplomaHashes[hash].titleState, diplomaHashes[hash].dateIssued);
    }

}