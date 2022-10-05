/**
 *Submitted for verification at polygonscan.com on 2022-10-05
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract CrytoTwinVoting {

    struct Voter {
        uint weight; // weight is accumulated by delegation
        bool voted;  // if true, that person already voted
        address delegate; // person delegated to
        bool vote;   // index of the voted proposal
    }

    struct ProposalOptions {

        string option_name;   // short name (up to 32 bytes)
        uint voteCount; // number of accumulated votes
    }

    struct ProposalId {
        uint id;
        string proposal_description;
        string proposed_art_url;
        uint yescount;
        uint nocount;
    }

    uint public latest_proposal_id = 0;
    string public art_cryptotwindao;

    address public chairperson;

    mapping(address => Voter) public voters;
    
    uint prevProposalTime;
    //uint public waitingPeriod = 2 days; (Final Proposal)
    uint public waitingPeriod = 15 seconds;

    function changeWaitingPeriodHrs(uint newPeriodinHrs) public {
        waitingPeriod = newPeriodinHrs * 60*60;
    }

    ProposalId[] public proposallist; 

    constructor(string memory default_arturl) {
        chairperson = msg.sender;
        voters[chairperson].weight = 1;
        art_cryptotwindao = default_arturl;

    }
  
    function new_Proposal(string memory describe, string memory art_url) public {
        require(block.timestamp > prevProposalTime + waitingPeriod, "Not Elegible, Proposal waiting period active");
        prevProposalTime = block.timestamp;
        latest_proposal_id += 1;
        proposallist.push(
            ProposalId({
                id : latest_proposal_id,
                proposal_description : describe,
                proposed_art_url : art_url,
                yescount :0,
                nocount:0
            })
        );  
    }
    
    function giveRightToVote(address voter) public {
        require(
            msg.sender == chairperson,
            "Only chairperson can give right to vote."
        );
        require(
            !voters[voter].voted,
            "The voter already voted."
        );
        require(voters[voter].weight == 0);
        voters[voter].weight = 1;
    }

    
    function delegate(address to) public {
        Voter storage sender = voters[msg.sender];
        require(!sender.voted, "You already voted.");
        require(to != msg.sender, "Self-delegation is disallowed.");

        while (voters[to].delegate != address(0)) {
            to = voters[to].delegate;
            require(to != msg.sender, "Found loop in delegation.");
        }
        sender.voted = true;
        sender.delegate = to;
        Voter storage delegate_ = voters[to];
        if (delegate_.voted) {
            
            // if delegate already voted           
            if (delegate_.vote) {
                    proposallist[latest_proposal_id-1].yescount += sender.weight;
                } else {
                    proposallist[latest_proposal_id-1].nocount += sender.weight;
                } 
        } else {
            
            delegate_.weight += sender.weight;
        }
    }

    function vote(bool votefavour) public {
        Voter storage sender = voters[msg.sender];
        require(sender.weight != 0, "Has no right to vote");
        require(!sender.voted, "Already voted.");
        sender.voted = true;
        sender.vote = votefavour;
        if (votefavour) {
            proposallist[latest_proposal_id-1].yescount += sender.weight;
        } else {
            proposallist[latest_proposal_id-1].nocount += sender.weight;
        }     
    }

   
    function makeProposalDecision() public 
            returns (string memory propoal_status)
    {   
        
        if (proposallist[latest_proposal_id-1].yescount > proposallist[latest_proposal_id-1].nocount){
            propoal_status = "Passed";
            art_cryptotwindao = proposallist[latest_proposal_id-1].proposed_art_url;

        } else {
            propoal_status = "Failed";
        }
        
    }
    
    function timepastlastProposal() public view returns (uint){
        return (block.timestamp - prevProposalTime);
    }

    function currentProposalInfo() public view
            returns (uint proposal_id , string memory proposal_description, string memory proposal_arturl )
    {
        proposal_id = proposallist[latest_proposal_id-1].id;
        proposal_description = proposallist[latest_proposal_id-1].proposal_description;
        proposal_arturl = proposallist[latest_proposal_id-1].proposed_art_url;
    }


}