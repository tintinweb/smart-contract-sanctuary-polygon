/**
 *Submitted for verification at polygonscan.com on 2023-04-26
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract UserInfo {
    
    struct User {
        string name;
        uint256 age;
        string sex;
        uint256 phoneNumber;
        string city;
    }
    
    mapping (address => User) users;
    
    function setUser(string memory _name, uint256 _age, string memory _sex, uint256 _phoneNumber, string memory _city) public {
        users[msg.sender] = User(_name, _age, _sex, _phoneNumber, _city);
    }
    
    function getUser() public view returns (string memory, uint256, string memory, uint256, string memory) {
        User memory user = users[msg.sender];
        return (user.name, user.age, user.sex, user.phoneNumber, user.city);
    }
}