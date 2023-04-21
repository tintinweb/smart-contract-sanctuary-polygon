// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

contract UltiBetsLeaderBoard {

    mapping(string => bool) public isUsedName;
    mapping(address => bool) public isOnLeaderboard;
    mapping(address => string) public nameOfInfluencer;

    event NewLeader(address indexed leader, string name);

    function registerOnLeaderboard(string memory _name) external {
        require(!isOnLeaderboard[msg.sender], "You are already on the board.");
        require(!isUsedName[_name], "Already Used Name.");
        isOnLeaderboard[msg.sender] = true;
        nameOfInfluencer[msg.sender] = _name;

        emit NewLeader(msg.sender, _name);
    }
}