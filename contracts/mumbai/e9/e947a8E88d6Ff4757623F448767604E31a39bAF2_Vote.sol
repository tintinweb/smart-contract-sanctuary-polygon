// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

contract Vote {
    struct Proposal {
        string name;
        uint256 yesVote;
        uint256 noVote;
    }
    Proposal[] public proposals;
    mapping (uint256 => mapping (address => bool)) public hasVotes;

    function createProposal(string memory _question) public {
        proposals.push(Proposal({
            name: _question,
            yesVote: 0,
            noVote: 0
        }));
        }
    function vote(uint256 _proposalIndex, bool _voteYes)  public {
        require(!hasVotes[_proposalIndex][msg.sender], "You have already voted");
        if (_voteYes) {
            proposals[_proposalIndex].yesVote++;
        } else {
            proposals[_proposalIndex].noVote++;
        }
        hasVotes[_proposalIndex][msg.sender] = true;   
        }
    function getProposal(uint256 _proposalIndex) public view returns (string memory, uint256, uint256) {
        return (
            proposals[_proposalIndex].name, 
            proposals[_proposalIndex].yesVote, 
            proposals[_proposalIndex].noVote
            );
    }
}