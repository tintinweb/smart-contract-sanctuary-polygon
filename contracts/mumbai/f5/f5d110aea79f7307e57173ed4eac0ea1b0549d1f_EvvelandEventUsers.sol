/**
 *Submitted for verification at polygonscan.com on 2023-05-30
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

contract EvvelandEventUsers {
    address payable public owner;
    mapping(uint256 => address[]) private idToUsers;
    mapping(uint256 => mapping(address => bool)) private idToUserExists;
    mapping(uint256 => mapping(uint256 => mapping(address => bool))) private visitedStand;
    mapping(address => mapping(uint256 => uint256)) private userVisits;

    constructor() {
        owner = payable(msg.sender);
    }

    function addUser(uint256 _venueId, address _user) public {
        require(msg.sender == owner, "You are not authorized!");
        require(!idToUserExists[_venueId][_user], "Address already exists");
        idToUserExists[_venueId][_user] = true;
        idToUsers[_venueId].push(_user);
    }

    function getUsers(uint256 _venueId) public view returns (address[] memory) {
        return idToUsers[_venueId];
    }

    function checkUserExists(uint256 _venueId, address _user) public view returns (bool) {
        return idToUserExists[_venueId][_user];
    }

    function addToUsers(uint256 _venueId) public returns (bool) {
        address _user = msg.sender;
        bool userExists = checkUserExists(_venueId, _user);
        if (!userExists) {
            idToUserExists[_venueId][_user] = true;
            idToUsers[_venueId].push(_user);
            return true;
        } else {
            return false;
        }
    }

    function checkUserVisitedStand(address _user, uint256 _venueId, uint256 _standId) public view returns (bool) {
        return visitedStand[_venueId][_standId][_user];
    }

    function incrementVisits(uint256 _venueId, uint256 _standId) public {
        address user = msg.sender;
        bool visited = checkUserVisitedStand(user, _venueId, _standId);
        require(!visited, "Already visited this stand");
        userVisits[user][_venueId]++;
        visitedStand[_venueId][_standId][user] = true;
    }

    function getUserVisits(address _user, uint256 _venueId) public view returns (uint256) {
        return userVisits[_user][_venueId];
    }

    function getUserVisitsList(uint256 _venueId) public view returns (address[] memory, uint256[] memory) {
        address[] memory users = idToUsers[_venueId];
        uint256[] memory visits = new uint256[](users.length);

        for (uint256 i = 0; i < users.length; i++) {
            visits[i] = userVisits[users[i]][_venueId];
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