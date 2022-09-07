/**
 *Submitted for verification at polygonscan.com on 2022-09-07
*/

//SPDX-License-Identifier: None
pragma solidity ^0.8.0;

// Just a test contract to use with Unity as a frontend
contract HelloWeb3 {
    // Maps connected addresses to registered accounts
    mapping(address => User) addressToUser;
    // Stores all registered user info
    User[] users;
    // Tracks user account states
    enum UserStatus {
        UNREGISTERED,
        REGISTERED
    }
    // Main struct
    struct User {
        UserStatus _status;
        string _name;
    }

    // Create new user safely and store information
    function _createUser(address _address, string memory _name) private {
        // Check if address is registered
        require(
            addressToUser[_address]._status == UserStatus.UNREGISTERED,
            "You have already created an account!"
        );
        // Store user information
        users.push(User(UserStatus.REGISTERED, _name));
        addressToUser[_address] = users[users.length - 1];
    }

    // Create new user with name string
    function createUser(string memory _nameString) public {
        _createUser(msg.sender, _nameString);
    }

    // Returns registered user information from stored mapping/struct
    function getUser()
        external
        view
        returns (UserStatus _status, string memory _name)
    {
        require(
            addressToUser[msg.sender]._status != UserStatus.UNREGISTERED,
            "You are not registered!"
        );

        return (
            addressToUser[msg.sender]._status,
            addressToUser[msg.sender]._name
        );
    }

    // Delete registered user info
    function deleteUser() external {
        require(
            addressToUser[msg.sender]._status == UserStatus.REGISTERED,
            "You are not registered!"
        );
        addressToUser[msg.sender]._status = UserStatus.UNREGISTERED;
        addressToUser[msg.sender]._name = "";
    }
}