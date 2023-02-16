/**
 *Submitted for verification at polygonscan.com on 2023-02-15
*/

// SPDX-License-Identifier:MIT

pragma solidity >0.8.0;

contract DAO{

    address internal owner;

      // store proposals
    struct proposalInfo{
        uint proposalCount;
        string metadataUri;
        address createdBy;
        uint yesVote;
        uint noVote;
        mapping(address=>bool) hasVoted;
        bool proposalFinished;
        bool proposalStarted;
    }
    //store all proposals
    mapping(uint =>proposalInfo) public allProposals;

    //applied users
    mapping(uint=>address) public AppliedAddress;

    //verified users for Voting
    mapping(address=>bool) public approvedUsers;  

    uint public totalAppliedUsers;
    uint public totalProposals;

    //modifier
    modifier onlyOwner(){
        require(msg.sender==owner,"Not the owner");
        _;
    }
    modifier onlyApprovedUser(){
         require(approvedUsers[msg.sender],"Not a verified Dao User.");
         _;
    }

    //events
     
     event NewMember( address user);
     event NewProposal(uint proposalId,string metadataUri,address createdBy);
     event Voted(uint proposalId,bool vote);
     event VotingClosed(uint proposalId,uint yesVote,uint noVote);


    constructor(){
        owner=msg.sender;
        totalAppliedUsers =0;
        totalProposals =0;
    }

    //users can apply for Dao
    function applyForDAO() public {
        require(!approvedUsers[msg.sender],"Already Verified");

        totalAppliedUsers++;
        AppliedAddress[totalAppliedUsers]=msg.sender;
        emit NewMember(msg.sender);
    }

    //only owner can approve the dao membership and saved data in approvedUsers mapping
    function approveForDAO(address _userAddress) onlyOwner public{
        require(!approvedUsers[_userAddress],"Already Verified");
        approvedUsers[_userAddress]=true;
        emit NewMember(_userAddress);
    }

    //Any approved user can create proposal
    function createProposal(string calldata _metadataUri) public onlyApprovedUser{
       
        totalProposals++;
        proposalInfo storage p=allProposals[totalProposals];
        p.metadataUri=_metadataUri;
        p.createdBy=msg.sender;
        p.proposalCount=totalProposals;
        p.proposalStarted=true;

        emit NewProposal(totalProposals,_metadataUri,msg.sender);
    }

    //Vote for the proposal
    function voteForProposal(uint proposalId,uint vote) public onlyApprovedUser{

        proposalInfo storage p=allProposals[proposalId];
        require(p.proposalStarted,"Proposal has not started yet");
        require(!p.proposalFinished,"Proposal has Already been Closed");
        require(p.createdBy!=msg.sender,"You can't vote on your own proposal");
        require(!p.hasVoted[msg.sender],"You already Voted");
        require(vote==1||vote==0,"Wrong info for vote");
        if(vote==1) p.yesVote+=1;
        else if(vote ==0) p.noVote+=1;
        
        p.hasVoted[msg.sender]=true;        

        emit Voted(proposalId,true);
    }

    //close voting by admin

     function closeVoting(uint proposalId) public onlyOwner{

        proposalInfo storage p=allProposals[proposalId];
         require(p.proposalStarted,"Proposal has not started yet");
        require(!p.proposalFinished,"Proposal has Already been Closed");
        p.proposalFinished=true;

        uint yesVote=p.yesVote;
        uint noVote=p.noVote;

        emit VotingClosed(proposalId,yesVote,noVote);

    }


}