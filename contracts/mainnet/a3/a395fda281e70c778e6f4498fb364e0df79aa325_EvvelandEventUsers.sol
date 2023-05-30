/**
 *Submitted for verification at polygonscan.com on 2023-05-30
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

contract EvvelandEventUsers {
    address payable public owner; // Make the owner address payable
    mapping(uint256 => address[]) private idToUsers;
    mapping(uint256 => mapping(address => bool)) private idToUserExists;
    mapping(address => uint256) private userVisits;

    constructor() {
        owner = payable(msg.sender); // Assign the owner address as payable
    }

    function addUser(uint256 _id, address _user) public {
        require(msg.sender == owner, "You are not authorized!");
        require(!idToUserExists[_id][_user], "Address already exists");
        idToUserExists[_id][_user] = true;
        idToUsers[_id].push(_user);
    }

    function getUsers(uint256 _id) public view returns (address[] memory) {
        return idToUsers[_id];
    }

    function addToUsers(uint256 _id) public {
        require(!idToUserExists[_id][msg.sender], "Address already exists");
        idToUserExists[_id][msg.sender] = true;
        idToUsers[_id].push(msg.sender);
    }

    function incrementVisits() public {
        userVisits[msg.sender]++;
    }

    function getUserVisits(address _user) public view returns (uint256) {
        return userVisits[_user];
    }

    function getUserVisitsList(uint256 _id) public view returns (address[] memory, uint256[] memory) {
        address[] memory users = idToUsers[_id];
        uint256[] memory visits = new uint256[](users.length);

        for (uint256 i = 0; i < users.length; i++) {
            visits[i] = userVisits[users[i]];
        }

        return (users, visits);
    }

    function withdraw() public {
        require(msg.sender == owner, "You are not authorized!");
        uint256 contractBalance = address(this).balance;
        require(contractBalance > 0, "No balance to withdraw");
        owner.transfer(contractBalance);
    }
}