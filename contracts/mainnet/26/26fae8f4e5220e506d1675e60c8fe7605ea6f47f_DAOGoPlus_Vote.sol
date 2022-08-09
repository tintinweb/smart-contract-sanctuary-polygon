/**
 *Submitted for verification at polygonscan.com on 2022-08-09
*/

//SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.15;

contract DAOGoPlus_Vote {
    uint public votesnapshotdate;
    uint public votestartdate;
    uint public voteenddate;      
    uint public totalweight;

    struct Voter {
        uint weight; 
        bool voted;  
        uint vote;
        uint votedamount; 
    }

    struct Proposal {
        string name;   
        uint voteCount; 
    }

    address public ProposalCreator;
    address public Proposer;
    bool public SingleVoteType;

    mapping(address => Voter) public voters;

    Proposal[] public proposals;


    constructor(address proposeraddress, string[] memory proposalNames, uint snapshotdate,  uint startdate, uint enddate, bool singlevote) {
        require(startdate>snapshotdate,"Please confirm SnapShotDate and StartDate");
        require(enddate>startdate,"Please confirm StartDate and EndDate");
        ProposalCreator = msg.sender;
        Proposer = proposeraddress;
        SingleVoteType = singlevote;

        voters[ProposalCreator].weight = 1;
        votesnapshotdate = snapshotdate;
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
        //require(!voters[voter].voted,"The voter already added.");
        voters[voter].weight += ticket;
        totalweight +=ticket;
    }

    function MultipleVote(uint[] memory proposal, uint[] memory ticket ) public {
        require(!SingleVoteType, "This is a Single Option Vote Type");
        Voter storage sender = voters[msg.sender];
        require(sender.weight - sender.votedamount > 0, "You don't have enough ticket to vote");
        if (msg.sender != ProposalCreator) {
        require(block.timestamp>votestartdate, "Vote Time Not Yet Begin");
        require(block.timestamp<voteenddate, "Vote Time Ended");
        }

        uint currenttotalvotecheck= 0;
        for (uint j = 0; j < proposal.length; j++) {
             currenttotalvotecheck += ticket[j];
            }

        require(sender.weight - sender.votedamount >= currenttotalvotecheck, "You don't have enough ticket to vote");   

        uint currenttotalvote= 0;
        for (uint k = 0; k < proposal.length; k++) {
             proposals[proposal[k]].voteCount += ticket[k];
             currenttotalvote += ticket[k];
            }
        sender.votedamount += currenttotalvote;
    }

    function SingleVote(uint proposal) public {
        require(SingleVoteType, "This is a Multiple Option Vote Type");
        Voter storage sender = voters[msg.sender];
        require(sender.weight > 0, "Has no right to vote");
        require(!sender.voted,"Already voted");
        if (msg.sender != ProposalCreator) {
        require(block.timestamp>votestartdate, "Vote Time Not Yet Begin");
        require(block.timestamp<voteenddate, "Vote Time Ended");
        }

        sender.voted = true;
        sender.vote=proposal;

        proposals[proposal].voteCount += sender.weight;
        sender.votedamount += sender.weight;
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