// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

contract CarbonTraceRecordManager {
    event RecordWrite(uint indexed recordId, uint indexed timestamp);

    constructor() {}

    uint id = 0;
    enum Type {
        EMISSION,
        OFFSET,
        CARBON_CREDIT
    }
    struct Record {
        uint id;
        uint timestamp;
        string data;
        Type dataType;
    }
    mapping(uint => Record) records;

    function createRecord(string memory data, Type dataType) public {
        records[id] = Record(id, block.timestamp, data, dataType);
        emit RecordWrite(id, block.timestamp);
        id++;
    }

    function getRecord(uint recordId) public view returns (Record memory) {
        return records[recordId];
    }
}