/**
 *Submitted for verification at polygonscan.com on 2022-02-18
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

contract MyList {
  uint public recordCount = 0;

  struct Record {
    uint id;
    string data;
    string timestamp;
  }

  event RecordCreated (
      uint recordId,
      string recordData,
      string recordTimestamp
  );

  event RecordUpdated (
    uint recordId,
    string recordData,
    string timestamp
  );

  event RecordNotFound (
    uint recordId
  );
 /*
  u dont need to create dummy record, just check record count 0 in the api, before checking records
  this is just to demonstrate how to use constructor
 */
  constructor() {
      createNewRecord("Admin Record", "Nov 4, 2021");
  } 

  mapping(uint => Record) public records;

  function updateRecord(uint _id, string memory _data, string memory _timestamp) public {
    if(_id<=recordCount) {
      records[_id] = Record(_id, _data, _timestamp);
      emit RecordUpdated(_id, _data, _timestamp);
    }
    else
    {
      emit RecordNotFound(_id);
    }
  }

function createNewRecord(string memory _data, string memory _tt) public {
      recordCount++;
      records[recordCount] = Record(recordCount, _data, _tt);
      emit RecordCreated(recordCount, _data, _tt);
  }


  //emit the event and it will be available in result.logs[0].args
// also after u get the mapping object, struct params wll be found with its index like 0, 1, 2 etc
}