// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

contract MultipleChoiceVoting {
    struct Proposal {
        string question;
        uint256[] votes;
    }

    Proposal[] public proposals;
    mapping(uint256 => mapping(address => bool)) public hasVoted;

    function createProposal(string memory _question) public {
        uint256[] memory initialVotes = new uint256[](4);
        proposals.push(Proposal({question: _question, votes: initialVotes}));
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
    ) public view returns (string memory, uint256[4] memory) {
        require(_proposalIndex < proposals.length, "Invalid proposal index.");

        Proposal memory p = proposals[_proposalIndex];
        uint256[4] memory fixedSizeVotes;

        for (uint8 i = 0; i < 4; i++) {
            fixedSizeVotes[i] = p.votes[i];
        }

        return (p.question, fixedSizeVotes);
    }
}