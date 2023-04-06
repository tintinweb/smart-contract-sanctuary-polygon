// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

contract MultipleChoiceVoting {
    struct Proposal {
        string question;
        string[4] answers;
        uint256[4] votes;
    }

    Proposal[] public proposals;
    mapping(uint256 => mapping(address => bool)) public hasVoted;

    function createProposal(
        string memory _question,
        string[4] memory _answers
    ) public {
        uint256[4] memory initialVotes;
        proposals.push(
            Proposal({
                question: _question,
                answers: _answers,
                votes: initialVotes
            })
        );
    }

    function vote(uint256 _proposalIndex, uint8 _selectedOption) public {
        require(
            !hasVoted[_proposalIndex][msg.sender],
            "You have already voted."
        );
        require(
            _selectedOption >= 0 && _selectedOption <= 3,
            "Invalid voting option. Please select between 0 and 3."
        );

        proposals[_proposalIndex].votes[_selectedOption] += 1;
        hasVoted[_proposalIndex][msg.sender] = true;
    }

    function getProposalResult(
        uint256 _proposalIndex
    ) public view returns (string memory, string[4] memory, uint256[4] memory) {
        require(_proposalIndex < proposals.length, "Invalid proposal index.");

        Proposal memory p = proposals[_proposalIndex];
        return (p.question, p.answers, p.votes);
    }
}