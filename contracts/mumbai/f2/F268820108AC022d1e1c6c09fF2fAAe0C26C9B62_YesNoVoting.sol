// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

contract YesNoVoting {
    struct Proposal {
        string question;
        uint256 yesVotes;
        uint256 noVotes;
    }
    Proposal[] public proposals;
    mapping(uint256 => mapping(address => bool)) public hasVoted;

    function createProposal(string memory _question) public {
        proposals.push(
            Proposal({question: _question, yesVotes: 0, noVotes: 0})
        );
    }

    function vote(uint256 _proposalIndex, bool _voteYes) public {
        require(
            !hasVoted[_proposalIndex][msg.sender],
            "You have already voted"
        );
        if (_voteYes) {
            proposals[_proposalIndex].yesVotes += 1;
        } else {
            proposals[_proposalIndex].noVotes += 1;
        }
        hasVoted[_proposalIndex][msg.sender] = true;
    }

    function getProposalResult(
        uint256 _proposalIndex
    ) public view returns (string memory, uint256, uint256) {
        return (
            proposals[_proposalIndex].question,
            proposals[_proposalIndex].yesVotes,
            proposals[_proposalIndex].noVotes
        );
    }
}