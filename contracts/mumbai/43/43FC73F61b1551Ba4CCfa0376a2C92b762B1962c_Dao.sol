/**
 *Submitted for verification at polygonscan.com on 2022-07-31
*/

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

interface IdaoContract {
    function balanceOf(address, uint256) external view returns (uint256);
}

contract Dao {
    //VARIABLES
    address public owner;
    uint256 nextProposal; //next proposal's id b/c every proposal has an ID
    uint256[] public validTokens; //array of tokens we can use to vote on props
    IdaoContract daoContract;

    constructor(){
        owner = msg.sender;
        nextProposal = 1;
        daoContract = IdaoContract(0x2953399124F0cBB46d2CbACD8A89cF0599974963); //NFT storefront address
        validTokens = [14725893287534665031339092326003639872628332571988466885219287800406914105345]; //NFT Token ID number

    }

    struct proposal{
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
    }

    mapping(uint256 => proposal) public Proposals; //mapping for the proposal struct to make it public on the blockchain


//EVENTS
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

    function checkProposalEligibility(address _proposalist) private view returns(bool){
        for(uint256 i = 0; i < validTokens.length; i++){//we loop through the tokens array
            if(daoContract.balanceOf(_proposalist, validTokens[i]) >= 1){ //if our proposalist (ie the address we passed into this fxn) holds our NFT...
                return true; //... we return true ie they are eligible to vote
            }
        }
        return false;

    }

    function checkVoteEligibility(uint256 _id, address _voter) private view returns(bool){
        for (uint256 i = 0; i<Proposals[_id].canVote.length; i++){
            if(Proposals[_id].canVote[i] == _voter){
                return true;
            }
        }
        return false;
    }

    function createProposal(string memory _description, address[] memory _canVote) public {
        require(checkProposalEligibility(msg.sender), "Only NFT holders can send proposals!");

        //creating a new proposal in our Proposals mapping
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
        require(checkVoteEligibility(_id, msg.sender), "You cannot vote on this proposal");
        require(!Proposals[_id].voteStatus[msg.sender], "You have already voted on this proposal!");
        require(block.number <= Proposals[_id].deadline, "The deadline for this proposal has already passed");

        proposal storage p = Proposals[_id];

        if(_vote){
            p.votesUp++;
        }else{
            p.votesDown++;
        }

        p.voteStatus[msg.sender] = true;

        emit newVote(p.votesUp, p.votesDown, msg.sender, _id, _vote);

    }

    //counting the votes
    function countVotes(uint256 _id) public{
        require(msg.sender == owner, "Only the onwer can count votes");
        require(Proposals[_id].exists, "This proposal does not exist");
        require(block.number > Proposals[_id].deadline, "Voting has not concluded yet");
        require(!Proposals[_id].countConducted, "Count already conducted");

        proposal storage p = Proposals[_id];

        if(Proposals[_id].votesDown < Proposals[_id].votesUp){
            p.passed = true;
        }

        p.countConducted = true;

        emit proposalCount(_id, p.passed);
    }

    //function to add extra tokens (ie add more voting NFTs)
    function addTokenId(uint256 _tokenId) public {
        require(msg.sender == owner, "Only the onwer can add tokens");

        validTokens.push(_tokenId);
    }
}