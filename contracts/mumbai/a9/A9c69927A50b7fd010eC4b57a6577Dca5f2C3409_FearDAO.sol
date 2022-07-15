//SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;


interface IdaoContract {
    function balanceOf(address, uint256) external view returns(uint256);
    //OpenSea function that returns balance of an Address
}

contract FearDAO {
    address public owner;
    uint256 nextProposal;
    uint[] public validTokens; // Array of the Valid tokens wich can vote
    IdaoContract daoContract;


    constructor(){
        owner = msg.sender;
        nextProposal = 1;

        daoContract = IdaoContract(0x62c53f68Cf80BCD9936376243f7eD02B11Bc94e5);
        validTokens = [44675165668628352954021793880466797725410195503715807873020906732048571432970];
    }

    struct proposal {
        uint256 id;
        bool exists;
        string description;
        uint deadline;
        uint256 votesUp;
        uint256 votesDown;
        address[] canVote;
        uint256 maxVotes; //length of canVote
        mapping(address => bool) voteStatus; //to avoid vote multiple times on same proposal
        bool countConducted;
        bool passed;
    }

    mapping(uint256 => proposal) public Proposals;
        //mapping proposal id to a Proposal struct

    event proposalCreated (
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

    //Check if user owns NFTs and is allowed to vote on the proposal
    function checkProposalEligibility(address _proposalist) private view returns (
        bool
    ){
        // run through all the valid tokens
        for(uint i = 0; i < validTokens.length; i++){
            if(daoContract.balanceOf(_proposalist, validTokens[i]) >= 1){
                return true;
            }
        }
        return false;
    }

    function checkVoteEligibility(uint256 _id, address _voter) private view returns(
        bool
    ){
        for(uint256 i = 0; i < Proposals[_id].canVote.length; i++){
            if(Proposals[_id].canVote[i] == _voter){
                return true;
            }
        }
        return false;
    }

    function createProposal(string memory _description, address[] memory _canVote) public {
        require(checkProposalEligibility(msg.sender), "Only NFT holders can put forth Proposals");        

        proposal storage newProposal = Proposals[nextProposal];
        newProposal.id = nextProposal;
        newProposal.exists = true;
        newProposal.description = _description;
        newProposal.deadline = block.number + 100;
        newProposal.canVote = _canVote;
        newProposal.maxVotes = _canVote.length;
        
        emit proposalCreated(nextProposal, _description, _canVote.length, msg.sender);
        nextProposal++;
    }

    function voteOnProposal(uint256 _id, bool _vote) public {
        require(Proposals[_id].exists, "This Proposal does not exist");
        require(checkVoteEligibility(_id,msg.sender),"You can not vote on this Proposal");
        require(!Proposals[_id].voteStatus[msg.sender], "You already voted on this Proposal");
        require(block.number <= Proposals[_id].deadline, "The deadline has passed for this Proposal");

        proposal storage p = Proposals[_id];

        if(_vote) {
            p.votesUp++;
        } else {
            p.votesDown++;        
        }

        p.voteStatus[msg.sender] = true;

        emit newVote(p.votesUp, p.votesDown, msg.sender, _id, _vote);

    }

    function countVotes(uint256 _id) public {
        require(msg.sender == owner, "Only Owner Can Count Votes");
        require(Proposals[_id].exists, "This Proposal does not exist");
        require(block.number > Proposals[_id].deadline, "Voting has not concluded");
        require(!Proposals[_id].countConducted, "Count already conducted");

        proposal storage p = Proposals[_id];

        if(Proposals[_id].votesDown < Proposals[_id].votesUp){
            p.passed = true;
        }

        p.countConducted = true;

        emit proposalCount(_id, p.passed);

    }

    function addTokenId(uint256 _tokenId) public {
        require(msg.sender == owner, "Only Owner Can Add Tokens");

        validTokens.push(_tokenId);

    }

}