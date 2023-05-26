// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

contract YesNoVote {
    struct Proposal {
        string description;
        uint yesVotes;
        uint noVotes;
    }

    mapping(address => mapping(uint256 => bool)) public hasVoted;
    Proposal[] public proposals;

    function createProposal(string memory _description) public {
        proposals.push(
            Proposal({description: _description, yesVotes: 0, noVotes: 0})
        );
    }

    function vote(uint _proposalId, bool _vote) public {
        Proposal storage proposal = proposals[_proposalId];

        require(
            !hasVoted[msg.sender][_proposalId],
            "This address has already voted on this proposal."
        );

        if (_vote) {
            proposal.yesVotes++;
        } else {
            proposal.noVotes++;
        }

        hasVoted[msg.sender][_proposalId] = true;
    }

    function getProposalsCount() public view returns (uint) {
        return proposals.length;
    }
}