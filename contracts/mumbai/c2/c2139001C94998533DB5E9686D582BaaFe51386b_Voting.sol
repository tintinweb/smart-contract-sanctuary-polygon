/**
 *Submitted for verification at polygonscan.com on 2022-11-27
*/

// SPDX-License-Identifier: None
pragma solidity ^0.8.17;
contract Voting {
    struct Proposal {
        uint count;
        string name;
    }

    struct Voter {
        uint weight;
        bool voted;
        bool canVote;
        uint prop;
    }

    mapping(address=>Voter) voteMapping;
    Proposal[] public proposals;
    address public chairperson;
    string public winner;

    constructor(string[] memory proposalNames) {
        chairperson = msg.sender;
        for(uint i = 0; i < proposalNames.length; i++) {
            proposals.push(Proposal({
                name: proposalNames[i],
                count: 0
            }));
        }
    }

    function giveVoteTo(uint proposalID) external {
        Voter memory voter = voteMapping[msg.sender];
        // require(voter.canVote, "Voting permissions not given");
        // require(!voter.voted, "vote is already given");
        // require(proposalID > 0 || proposalID < proposals.length, "Invalid proposal given");   
    
        proposals[proposalID].count = 1;
        voter.prop = proposalID;
        voter.voted = true;
    }
    
    function enableVote(address voteAddr) external payable {
        Voter memory voter = voteMapping[voteAddr];
        require(msg.sender == chairperson, "Only chairperson can enable voting permission");
        require(!voter.canVote, "Voting permission is already given");

        voter.canVote = true;
    }

    function countVotes() external payable returns (string memory winStr) {
        uint maxID;
        uint maxVal;

        for(uint i = 0; i < proposals.length; i++) {
            if(maxVal < proposals[i].count) {
                maxVal = proposals[i].count;
                maxID = i;
            }
        }

        winner = proposals[maxID].name;
        winStr = proposals[maxID].name;
    }
}