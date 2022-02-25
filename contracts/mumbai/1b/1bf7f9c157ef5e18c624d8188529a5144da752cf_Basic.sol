/**
 *Submitted for verification at polygonscan.com on 2022-02-24
*/

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.9;

contract Basic {

    struct User {
        string name;
        uint256 age;
        address ethAddress;
    }

    mapping(address => User) public database;

    function getUser() public view returns (User memory) {
        return database[msg.sender];
    }

    function getName() public view returns (string memory) {
        return database[msg.sender].name;
    }

    function getAge() public view returns (uint256) {
        return database[msg.sender].age;
    }

    function getAddress() public view returns (address) {
        return database[msg.sender].ethAddress;
    }

    function setName(string memory pName) public {
        database[msg.sender].name = pName;
    }

    function setAge(uint256 pAge) public {
        database[msg.sender].age = pAge;
    }

    function setUser(string memory pName, uint256 pAge, address pAddress) public {
        User memory user = database[msg.sender];
        user.name = pName;
        user.age = pAge;
        user.ethAddress = pAddress;
        database[msg.sender] = user;
    }

}