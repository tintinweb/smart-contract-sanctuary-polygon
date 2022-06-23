/**
 *Submitted for verification at polygonscan.com on 2022-06-23
*/

//SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.7;

contract DAOVote_Single {
    uint public votestartdate;
    uint public voteenddate;    

    struct Voter {
        uint weight; 
        bool voted;  
        uint vote;
    }

    struct Proposal {
        string name;   
        uint voteCount; 
    }

    address public ProposalCreator;

    mapping(address => Voter) public voters;

    Proposal[] public proposals;

    constructor(string[] memory proposalNames, uint startdate, uint enddate) {
        require(enddate>startdate,"Please confirm StartDate and EndDate");
        ProposalCreator = msg.sender;
        voters[ProposalCreator].weight = 1;
        votestartdate = startdate;
        voteenddate = enddate;

        for (uint i = 0; i < proposalNames.length; i++) {
            proposals.push(Proposal({
                name: proposalNames[i],
                voteCount: 0
            }));
        }
    }
    function giveRightToVote(address voter, uint ticket) public {
        require(msg.sender == ProposalCreator,"Only Proposal Creator can give right to vote.");
        require(!voters[voter].voted,"The voter already added.");
        voters[voter].weight = ticket;
    }

    function vote(uint proposal) public {
        
        Voter storage sender = voters[msg.sender];
        require(sender.weight > 0, "Has no right to vote");
        require(!sender.voted,"Already voted");
        require(block.timestamp>votestartdate, "Vote Time Not Yet Begin");
        require(block.timestamp<voteenddate, "Vote Time Ended");

        sender.voted = true;
        sender.vote=proposal;

        proposals[proposal].voteCount += sender.weight;
    }

    function winningProposal() public view
            returns (uint winningProposal_)
    {
        uint winningVoteCount = 0;
        for (uint p = 0; p < proposals.length; p++) {
            if (proposals[p].voteCount > winningVoteCount) {
                winningVoteCount = proposals[p].voteCount;
                winningProposal_ = p;
            }
        }
    }

    function winnerName() public view
            returns (string memory winnerName_)
    {
        winnerName_ = proposals[winningProposal()].name;
    }
}