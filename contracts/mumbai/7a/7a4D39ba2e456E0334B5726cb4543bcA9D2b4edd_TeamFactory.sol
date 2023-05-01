/**
 *Submitted for verification at polygonscan.com on 2023-04-29
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract TeamFactory {

    uint public numberOfTeams = 10;
    address[] public teams;
    uint public carsPerTeam = 2;
    uint public driversPerTeam = 2;

    struct Team {
        address owner;
        uint teamId;
        address[] cars;
        address[] drivers;
    }

    mapping(uint => Team) public idToTeam;

    event TeamCreated(uint indexed teamId, address indexed owner);

    function createTeam() public {
        uint teamId = teams.length;
        require(teamId < numberOfTeams, "All teams have been created.");

        Team memory newTeam = Team({
            owner: msg.sender,
            teamId: teamId,
            cars: new address[](carsPerTeam),
            drivers: new address[](driversPerTeam)
        });

        idToTeam[teamId] = newTeam;
        teams.push(msg.sender);

        emit TeamCreated(teamId, msg.sender);
    }

    function getTeam(uint teamId) public view returns (Team memory) {
        return idToTeam[teamId];
    }
}