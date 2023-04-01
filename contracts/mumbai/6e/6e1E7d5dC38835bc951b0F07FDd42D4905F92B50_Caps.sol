/**
 *Submitted for verification at polygonscan.com on 2023-04-01
*/

// File: contracts/Caps.sol



pragma solidity ^0.8.0;

contract Caps {
    struct Record {
        string Rid;
        string uid;
        string fileName;
        string previousHash;
        string hash;
        string name;
        uint timestamp;
    }
    
    mapping(string => Record) private records;
    
    function addRecord(string memory _Rid, string memory _uid, string memory _fileName, string memory _previousHash, string memory _hash, string memory _name, uint _timestamp) public {
        require(records[_Rid].timestamp == 0, "Record already exists.");
        Record memory newRecord = Record(_Rid, _uid, _fileName, _previousHash, _hash, _name, _timestamp);
        records[_Rid] = newRecord;
    }
    
    function getRecord(string memory _Rid) public view returns (string memory, string memory, string memory, string memory, string memory, string memory, uint) {
        Record memory record = records[_Rid];
        require(record.timestamp != 0, "Record does not exist.");
        return (record.Rid, record.uid, record.fileName, record.previousHash, record.hash, record.name, record.timestamp);
    }

    function getUID(string memory _uid) public view returns (string memory, string memory, string memory, string memory, uint) {
        Record memory record = records[_uid];
        require(record.timestamp != 0, "Record does not exist.");
        return ( record.uid, record.fileName, record.previousHash, record.hash, record.timestamp);
    }
    
    function addName(string memory _Rid, string memory _name) public {
        Record storage record = records[_Rid];
        require(record.timestamp != 0, "Record does not exist.");
        record.name = _name;
    }
    
    function addTimestamp(string memory _Rid, uint _timestamp) public {
        Record storage record = records[_Rid];
        require(record.timestamp != 0, "Record does not exist.");
        record.timestamp = _timestamp;
    }
}