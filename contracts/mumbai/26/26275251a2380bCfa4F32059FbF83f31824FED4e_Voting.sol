// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

contract Voting {
    struct Voter {
        bool voted;
        bool vote;
    }

    struct Proposal {
        string question;
        uint yesCount;
        uint noCount;
    }

    Proposal[] public proposals;
    mapping(uint => mapping(address => Voter)) public voters;

    function createProposal(string memory _question) public {
        proposals.push(Proposal({
            question: _question,
            yesCount: 0,
            noCount: 0
        }));
    }

    function vote(uint _proposalId, bool _vote) public {
        Voter storage sender = voters[_proposalId][msg.sender];
        require(!sender.voted, "Already voted.");
        sender.voted = true;
        sender.vote = _vote;

        Proposal storage proposal = proposals[_proposalId];
        if (_vote) {
            proposal.yesCount += 1;
        } else {
            proposal.noCount += 1;
        }
    }

    function result(uint _proposalId) public view returns (string memory) {
        Proposal storage proposal = proposals[_proposalId];
        require(proposal.yesCount + proposal.noCount > 0, "No votes yet.");
        if (proposal.yesCount > proposal.noCount) {
            return "Yes wins!";
        } else if (proposal.noCount > proposal.yesCount) {
            return "No wins!";
        } else {
            return "It's a tie!";
        }
    }
}