/**
 *Submitted for verification at polygonscan.com on 2022-06-04
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

contract SimpleStorage {
    uint256 public favoriteNumber;
    address immutable owner;

    constructor() {
        owner = msg.sender;
    }

    function updateFavoriteNumber(uint256 _favoriteNumber) public {
        require(msg.sender == owner, "Only Owner Can Update");
        favoriteNumber = _favoriteNumber;
    }

    function getFavoriteNumber() public view returns (uint256) {
        return favoriteNumber;
    }

    struct People {
        uint256 id;
        string name;
    }
    People[] public people;
    mapping(string => uint256) public nameToID;

    function addPerson(uint256 _id, string memory _name) public {
        people.push(People(_id, _name));
        nameToID[_name] = _id;
    }
}