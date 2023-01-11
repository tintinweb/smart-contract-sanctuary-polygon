/**
 *Submitted for verification at polygonscan.com on 2023-01-10
*/

// SPDX-License-Identifier: MIT
// File: contracts/storage/UserStorage.sol


pragma solidity  ^0.8.0;

contract UserStorage  {
    
    struct User {
        address userAddress;
        string userType;
    }
    User[] private users;

    mapping(address => uint) private indexOf;
    
    function createUser(string calldata userType) external {
        require(indexOf[msg.sender] == 0, "Error: User is already registered");
        User memory user = User(msg.sender, userType);
        users.push(user);
        indexOf[msg.sender] = users.length;
    }
    
    function isRegistered(address userAddress) public view returns(bool){
        if(indexOf[userAddress] != 0) {
            return true;
        } else {
            return false;
        }
    }
    
    function getUserType(address userAddress) public view returns(string memory){
        require(indexOf[userAddress] != 0, "ERROR: User is not registered");
        return users[indexOf[userAddress] - 1].userType;
    }
}