//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract VotingSystem {
    struct Proposal {
        string question;
        uint256 yesCount;
        uint256 noCount;
    }

    mapping(uint256 => Proposal) public proposals;
    mapping(uint256 => mapping(address => bool)) public yesVoters;
    mapping(uint256 => mapping(address => bool)) public noVoters;
    uint256 public proposalCount;

    function createProposal(string memory _question) public {
        proposalCount++;
        proposals[proposalCount] = Proposal(_question, 0, 0);
    }

    function vote(uint256 _proposalId, bool _vote) public {
        require(
            !yesVoters[_proposalId][msg.sender] &&
                !noVoters[_proposalId][msg.sender],
            "You have already voted on this proposal."
        );

        if (_vote) {
            yesVoters[_proposalId][msg.sender] = true;
            proposals[_proposalId].yesCount++;
        } else {
            noVoters[_proposalId][msg.sender] = true;
            proposals[_proposalId].noCount++;
        }
    }

    function getProposal(
        uint256 _proposalId
    )
        public
        view
        returns (string memory question, uint256 yesCount, uint256 noCount)
    {
        Proposal memory proposal = proposals[_proposalId];
        return (proposal.question, proposal.yesCount, proposal.noCount);
    }

    function getProposalResult(
        uint256 _proposalId
    ) public view returns (string memory result) {
        Proposal memory proposal = proposals[_proposalId];
        if (proposal.yesCount > proposal.noCount) {
            return "Approved";
        } else if (proposal.yesCount < proposal.noCount) {
            return "Rejected";
        } else {
            return "Tied";
        }
    }

    function hasVotedYes(
        uint256 _proposalId,
        address _voter
    ) public view returns (bool) {
        return yesVoters[_proposalId][_voter];
    }

    function hasVotedNo(
        uint256 _proposalId,
        address _voter
    ) public view returns (bool) {
        return noVoters[_proposalId][_voter];
    }
}