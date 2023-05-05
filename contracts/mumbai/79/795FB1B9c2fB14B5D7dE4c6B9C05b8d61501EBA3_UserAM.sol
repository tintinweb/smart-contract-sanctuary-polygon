// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// This contract stores and provides the attributes for users
contract UserAM {

    //Deployer of the contract
    address public immutable owner;

    uint256 nonce = 8;
    
    // Data stored for each user
    struct data {
        string role;
        string department;
        string[] projects;
    }

    // Mapping between user address and data belonging to that user
    mapping (address => data) private addressToData;

    constructor() {
        owner = msg.sender;
    }

    function addUser(address _user, string memory _role, string memory _department, string[] memory _projects) public {

        // Create and store the new user
        data memory userData = data(_role, _department, _projects);
        addressToData[_user] = userData;
        
    }

    function removeUser(address _user) public {

        // We assume the user is not stored if the role is not already set 
        string memory previousRole = addressToData[_user].role;
        require(keccak256(abi.encodePacked(previousRole)) != keccak256(abi.encodePacked('')), "User does not exist");

        delete addressToData[_user];
    }

    function getData(address _user) public view returns (data memory) {

        // We assume the user is not stored if the role is not already set 
        string memory previousRole = addressToData[_user].role;
        require(keccak256(abi.encodePacked(previousRole)) != keccak256(abi.encodePacked('')), "User does not exist");

        // Return the whole object
        return addressToData[_user];
    }
}