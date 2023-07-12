/**
 *Submitted for verification at polygonscan.com on 2023-07-11
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract UserManagement {
    struct User {
        address userAddress;
        string role;
        string publicKey;
    }

    mapping(address => User) private users;
    mapping(address => bool) private loggedInUsers;

    event UserRegistered(address indexed userAddress, string role, string publicKey);

    function registerUser(string memory _role, string memory _publicKey) public {
        require(users[msg.sender].userAddress == address(0), "User already registered");
        
        users[msg.sender] = User(msg.sender, _role, _publicKey);
        emit UserRegistered(msg.sender, _role, _publicKey);
    }

    function login() public {
        require(users[msg.sender].userAddress != address(0), "User not registered");
        
        loggedInUsers[msg.sender] = true;
    }

    function logout() public {
        loggedInUsers[msg.sender] = false;
    }

    function getUserRole(address _userAddress) public view returns (string memory) {
        return users[_userAddress].role;
    }

    function getUserPublicKey(address _userAddress) public view returns (string memory) {
        return users[_userAddress].publicKey;
    }

    function isUserLoggedIn(address _userAddress) public view returns (bool) {
        return loggedInUsers[_userAddress];
    }
}