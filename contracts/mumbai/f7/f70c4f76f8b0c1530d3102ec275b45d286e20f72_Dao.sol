/**
 *Submitted for verification at polygonscan.com on 2022-10-04
*/

// File: contracts/Dao.sol



pragma solidity ^0.8.4;

contract Dao {

    uint256 nextProposal;
    uint256 BlocksPerDay = 43200;


    constructor()  {
         nextProposal = 1;
    }

    struct ProposalInfo{
        uint256 id;
        bool exists;
        string description;
        uint deadline;
        uint256 votesUp;
        uint256 votesDown;
        address[] canVote;
        uint256 maxVotes;
        mapping(address => bool) voteStatus;
        bool countConducted;
        bool passed;
        string proposedBy;
    }

  

    mapping(uint256 => ProposalInfo) public Proposals;

    event proposalCreated(
        uint256 id,
        string description,
        uint256 maxVotes,
        address proposer
    );

    event newVote(
        uint256 votesUp,
        uint256 votesDown,
        address voter,
        uint256 proposal,
        bool votedFor
    );

    event proposalCount(
        uint256 id,
        bool passed
    );

  
    


    // function checkProposalEligibility(address _proposalist) private view returns (
    //     bool
    // ){
    //     for(uint i = 0; i < validTokens.length; i++){
    //         if(daoContract.balanceOf(_proposalist, validTokens[i]) >= 1){
    //             return true;
    //         }
    //     }
    //     return false;
    // }

    function checkVoteEligibility(uint256 _id, address _voter) private view returns (
        bool
    ){
        for (uint256 i = 0; i < Proposals[_id].canVote.length; i++) {
            if (Proposals[_id].canVote[i] == _voter) {
            return true;
            }
        }
        return false;
    }


    function createProposal(string memory _description, string memory creator, address[] memory _canVote) public {
        // require(checkProposalEligibility(msg.sender), "Only NFT holders can put forth Proposals");

        ProposalInfo storage newProposal = Proposals[nextProposal];
        newProposal.id = nextProposal;
        newProposal.exists = true;
        newProposal.description = _description;
        newProposal.deadline = block.number + 100;
        newProposal.canVote = _canVote;
        newProposal.maxVotes = _canVote.length;
        newProposal.proposedBy = creator;

        emit proposalCreated(nextProposal, _description, _canVote.length, msg.sender);
        nextProposal++;
    }
    struct VoterStatus {
        bool voteStatus;
        address voter;
    }
      struct SingleProposal{
        uint256 id;
        bool exists;
        string description;
        uint256 votesUp;
        uint256 votesDown;
        address[] canVote;
        VoterStatus[] voteStatus;
        bool countConducted;
        bool passed;
        string proposedBy;
    }
   
   function getAllProposal() public view returns (SingleProposal[] memory){
         if (nextProposal == 1) {
             // means no data
             return new SingleProposal[](0);
         }
         SingleProposal[] memory briefData = new SingleProposal[]((nextProposal-1));
        for (uint256 i = 0; i < (nextProposal-1); i++) {
            // setup for voter status on proposal
             VoterStatus[] memory vts = new VoterStatus[]((Proposals[i+1].canVote.length));
             for(uint256 k = 0; k < Proposals[i+1].canVote.length; k++){
                 vts[k] = VoterStatus(Proposals[i+1].voteStatus[Proposals[i+1].canVote[k]],Proposals[i+1].canVote[k]);
             }
            briefData[i].id =  Proposals[i+1].id;
            briefData[i].exists =  Proposals[i+1].exists;
            briefData[i].description =  Proposals[i+1].description;
            briefData[i].votesUp =  Proposals[i+1].votesUp;
            briefData[i].votesDown =  Proposals[i+1].votesDown;
            briefData[i].canVote =  Proposals[i+1].canVote;
            briefData[i].voteStatus =  vts;
            briefData[i].countConducted =  Proposals[i+1].countConducted;
            briefData[i].passed =  Proposals[i+1].passed;
            briefData[i].proposedBy =  Proposals[i+1].proposedBy;
         }
     return briefData;
    }

    function voteOnProposal(uint256 _id, bool _vote) public {
        require(Proposals[_id].exists, "This Proposal does not exist");
        require(checkVoteEligibility(_id, msg.sender), "You can not vote on this Proposal");
        require(!Proposals[_id].voteStatus[msg.sender], "You have already voted on this Proposal");
        require(block.number <= Proposals[_id].deadline, "The deadline has passed for this Proposal");

        ProposalInfo storage p = Proposals[_id];

        if(_vote) {
            p.votesUp++;
        }else{
            p.votesDown++;
        }

        p.voteStatus[msg.sender] = true;

        emit newVote(p.votesUp, p.votesDown, msg.sender, _id, _vote);
        
    }

    function countVotes(uint256 _id) public {
        // require(msg.sender == owner, "Only Owner Can Count Votes");
        require(Proposals[_id].exists, "This Proposal does not exist");
        require(block.number > Proposals[_id].deadline, "Voting has not concluded");
        require(!Proposals[_id].countConducted, "Count already conducted");

        ProposalInfo storage p = Proposals[_id];
        
        if(Proposals[_id].votesDown < Proposals[_id].votesUp){
            p.passed = true;            
        }

        p.countConducted = true;

        emit proposalCount(_id, p.passed);
    }


  
    
}