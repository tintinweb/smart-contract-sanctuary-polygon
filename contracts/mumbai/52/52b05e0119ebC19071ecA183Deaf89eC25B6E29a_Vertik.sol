/**
 *Submitted for verification at polygonscan.com on 2022-05-26
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.0;

contract Vertik {

    uint256 private _id; 
    struct EntryData {
        uint256 id;
        string auditingAmount;
        string speed;
        string date;
        string age;
        string performance;
        string name;
        string documents;
        string gender;
        string project;
        string team;   
    }

    mapping(uint256 => EntryData) private dataMap; 
   
    constructor() {
        _id = 0;
    }

    function store(string memory auditingAmount,
        string memory speed,
        string memory date,
        string memory age,
        string memory performance,
        string memory name,
        string memory documents,
        string memory gender,
        string memory project,
        string memory team) public returns(bool) {
            _id = _id + 1;
            EntryData storage data = dataMap[uint256(_id)];
            data.auditingAmount = auditingAmount;
            data.speed = speed;
            data.age = age;
            data.performance = performance;
            data.name = name;
            data.documents = documents;
            data.gender = gender;
            data.project = project;
            data.team = team;
            data.date = date;
            data.id = _id;

        return true;
    }

    
    function retrieve(uint256 id) public view returns (EntryData memory){
        return dataMap[id];
    }
}