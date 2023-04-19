/**
 *Submitted for verification at polygonscan.com on 2023-04-19
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.15;

contract  Manekin_01 {
    
    /**
     * Structs that defines the data stored for every record stored in the BLockchain
     */
    struct Record {
        uint8 contributionType;
        uint recordNumber;
        uint amount;
        uint timestamp;
        string note;
    }

    /**
     * Call the getter of this variable to know how many records are stored in total in the Blockchain
     */
    uint public numberOfRecords;

    /**
     * Private mapping to stored records
     */
    mapping(string => Record[]) records;

    /**
     * Method to add a Record
     * Returns and error if contributionType is not an int8
     */
    function addRecord(uint8 _contributionType, string memory _userIdentifier, uint _amount, string memory _note) public {
        require(_contributionType == uint8(_contributionType), "Please enter a valid contributionType");
        uint userRecordNumber = records[_userIdentifier].length; 
        Record memory newRecord = Record(_contributionType, userRecordNumber, _amount, block.timestamp, _note);
        records[_userIdentifier].push(newRecord);
        numberOfRecords ++;
    }

    /**
     * Method to retrieve all the records for a specific User
     * Returns and error if no records stored for this User
     */
    function getRecordsForUser(string memory _userIdentifier) public view returns(Record[] memory) {
        require(records[_userIdentifier].length > 0, "Not records found for this User.");
        return records[_userIdentifier];
    }

    /**
     * Method to retrieve the number the records for a specific User
     * Returns and error if no records stored for this User
     */
    function getRecordsNumberForUser(string memory _userIdentifier) public view returns(uint) {
        require(records[_userIdentifier].length > 0, "Not records found for this User.");
        return records[_userIdentifier].length;
    }
}