/**
 *Submitted for verification at polygonscan.com on 2023-06-16
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract UserVerification {
    struct User {
        string email;
        bytes32 passwordHash;
    }

    mapping(address => User) private users;

    event UserRegistered(address indexed userAddress, string email);
    event UserLogin(address indexed userAddress, string email);

    function registerUser(string memory _email, string memory _password) public {
        require(bytes(_email).length > 0, "Email cannot be empty");
        require(bytes(_password).length > 0, "Password cannot be empty");
        require(keccak256(bytes(users[msg.sender].email)) != keccak256(bytes(_email)),"Email already registered");
        
        // require(users[msg.sender].passwordHash == 0, "User already registered");

        bytes32 passwordHash = keccak256(bytes(_password));
        users[msg.sender] = User(_email, passwordHash);
        emit UserRegistered(msg.sender, _email);
    }

    function verifyUser(string memory _email, string memory _password) private view returns(bool) {
        bytes32 passwordHash = keccak256(bytes(_password));
        return (keccak256(bytes(users[msg.sender].email)) == keccak256(bytes(_email))) && (users[msg.sender].passwordHash == passwordHash);
    }

    function loginUser(string memory _email, string memory _password) public  returns(bool) {
        require(verifyUser(_email, _password), "Invalid email or password");
        emit UserLogin(msg.sender, users[msg.sender].email);
        return true;
    }

    function getUserEmail(address userAddress) private view returns(string memory) {
        return users[userAddress].email;
    }
}