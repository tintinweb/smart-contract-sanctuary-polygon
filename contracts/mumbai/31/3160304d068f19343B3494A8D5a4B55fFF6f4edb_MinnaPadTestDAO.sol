/**
 *Submitted for verification at polygonscan.com on 2023-05-25
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
contract MinnaPadTestDAO {
    struct Proposal {
        string description;
        uint votes;
        bool executed;
    }

    Proposal[] public proposals;
    mapping(address => bool) public voters;

    function createProposal(string memory _description) public {
        proposals.push(Proposal({
            description: _description,
            votes: 0,
            executed: false
        }));
    }

    function vote(uint _proposalIndex) public {
        require(!voters[msg.sender], "You have already voted.");
        require(_proposalIndex < proposals.length, "Invalid proposal index.");

        voters[msg.sender] = true;
        proposals[_proposalIndex].votes++;
    }

    function executeProposal(uint _proposalIndex) public {
        require(proposals[_proposalIndex].votes > (proposals.length / 2), "Not enough votes.");
        require(!proposals[_proposalIndex].executed, "Proposal already executed.");

        proposals[_proposalIndex].executed = true;
    }
    function readProposalDescription(uint _proposalIndex) public view returns (string memory) {
        require(_proposalIndex < proposals.length, "Invalid proposal index.");

        return proposals[_proposalIndex].description;
    }
     function getAllProposals() public view returns (Proposal[] memory) {
        return proposals;
    }
}