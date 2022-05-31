/**
 *Submitted for verification at polygonscan.com on 2022-05-30
*/

pragma solidity ^0.8.0;


//SPDX-License-Identifier: Unlicense
contract TeamManagement {
    address public owner;

    struct Team {
        address owner;
        address[] members;
    }

    mapping(string => Team) public teams;
    address[] private owners;

    event TEAM_CREATED(string teamId, address _address);
    event NEW_MEMBER_JOINED(string teamId, address _member);

    constructor() {
        owner = msg.sender;
    }

    function createTeam(string calldata teamId) public {
        address[] memory memberArray = new address[](1);
        memberArray[0] = msg.sender;
        teams[teamId] = Team(msg.sender, memberArray);
        owners.push(msg.sender);
        emit TEAM_CREATED(teamId, msg.sender);
    }

    function joinTeam(string calldata teamId) public {
        Team storage team = teams[teamId];
        require(team.owner != address(0), "Invalid team Id");
        for (uint256 i = 0; i < team.members.length; i ++) {
            require(team.members[i] != msg.sender, "Already a member.");
        }
        team.members.push(msg.sender);
        emit NEW_MEMBER_JOINED(teamId, msg.sender);
    }

    function getTeamMembers(string calldata teamId)
        public
        view
        returns (address[] memory)
    {
        return teams[teamId].members;
    }

    function isTeamOwner(address _address) public view returns (bool) {
        require(_address != address(0), "Invalid address");
        for (uint256 i = 0; i < owners.length; i++) {
            if (owners[i] == _address) return true;
        }
        return false;
    }
}