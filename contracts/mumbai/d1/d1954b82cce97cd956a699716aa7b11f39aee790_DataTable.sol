/**
 *Submitted for verification at polygonscan.com on 2023-06-23
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract DataTable {
    struct DataEntry {
        uint256 id;
        string name;
        uint256 age;
    }

    DataEntry[] public data;

    function addData(uint256 _id, string memory _name, uint256 _age) public {
        DataEntry memory entry = DataEntry(_id, _name, _age);
        data.push(entry);
    }

    function getData(uint256 index) public view returns (uint256, string memory, uint256) {
        require(index < data.length, "Invalid index");

        DataEntry memory entry = data[index];
        return (entry.id, entry.name, entry.age);
    }

    function getDataCount() public view returns (uint256) {
        return data.length;
    }
}