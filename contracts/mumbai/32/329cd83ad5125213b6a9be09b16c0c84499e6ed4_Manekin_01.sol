/**
 *Submitted for verification at polygonscan.com on 2023-04-18
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.15;

contract  Manekin_01 {
    
    struct Record {
        uint recordNumber;
        uint amount;
        uint timestamp;
        string note;
    }

    uint public numberOfRecords;

    mapping(uint => Record[]) public records;

    function addRecord(uint _userIdentifier, uint _amount, string memory _note) public {
        uint userRecordNumber = records[_userIdentifier].length; 
        Record memory newRecord = Record(userRecordNumber, _amount, block.timestamp, _note);
        records[_userIdentifier].push(newRecord);
        numberOfRecords ++;
    }

    function getRecordsForUser(uint _userIdentifier) public view returns(Record[] memory) {
        return records[_userIdentifier];
    }
}