/**
 *Submitted for verification at polygonscan.com on 2023-05-06
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

contract EvvelandEventUsers {
    address public owner;
    mapping(uint256 => address[]) private idToUsers;
    mapping(uint256 => mapping(address => bool)) private idToUserExists;

    constructor() {
        owner = msg.sender;
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

    function addUserWithSender(uint256 _id) public {
        require(!idToUserExists[_id][msg.sender], "Address already exists");
        idToUserExists[_id][msg.sender] = true;
        idToUsers[_id].push(msg.sender);
    }
}