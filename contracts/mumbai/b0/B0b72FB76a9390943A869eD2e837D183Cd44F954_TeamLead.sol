/**
 *Submitted for verification at polygonscan.com on 2023-02-08
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

contract TeamLead {

    string private teamLead;

    event LeadSet(address indexed setter, string newLead);

    function getLead() view external returns (string memory) {
        return teamLead;
    }

    function setLead(string calldata newTeamLead) external {
        teamLead = newTeamLead;
        emit LeadSet(msg.sender, newTeamLead);
    }
}