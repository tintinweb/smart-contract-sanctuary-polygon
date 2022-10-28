// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;


//This is an interface for the ERC721 contract. It is used to check if the user has a token.
interface IdaoContract {
        function balanceOf(address, uint256) external view returns (uint256);
    }

contract Dao {

    //This is declaring the variables that will be used in the contract.
    address public owner;
    uint256 nextProposal;
    uint256[] public validTokens;
    IdaoContract daoContract;

    //This is the constructor function. It is called when the contract is deployed. It sets the owner of the contract to the address that deployed it. It sets the nextProposal to 1. It sets the daoContract to the address of the ERC721 contract. It sets the validTokens to the tokenId of the NFT.
    constructor(){
        owner = msg.sender;
        nextProposal = 1;
        daoContract = IdaoContract(0x2953399124F0cBB46d2CbACD8A89cF0599974963);
        validTokens = [2503853622491165696884660557781400500786545987337355258391150324055311122442];
    }

   //This is a struct that is used to store the data for each proposal.
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

   //This is a mapping that is used to store the data for each proposal.
    mapping(uint256 => proposal) public Proposals;

    //This is an event that is emitted when a proposal is created. It is used to log the data of the proposal.
    event proposalCreated(
        uint256 id,
        string description,
        uint256 maxVotes,
        address proposer
    );

    //This is an event that is emitted when a vote is cast. It is used to log the data of the vote.
    event newVote(
        uint256 votesUp,
        uint256 votesDown,
        address voter,
        uint256 proposal,
        bool votedFor
    );

   //This is an event that is emitted when a proposal is counted. It is used to log the data of the proposal.
    event proposalCount(
        uint256 id,
        bool passed
    );


    //This function is checking if the address that is passed to it has a token.
    function checkProposalEligibility(address _proposalist) private view returns (
        bool
    ){
        for(uint i = 0; i < validTokens.length; i++){
            if(daoContract.balanceOf(_proposalist, validTokens[i]) >= 1){
                return true;
            }
        }
        return false;
    }

    //This function is checking if the address that is passed to it has a token.
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


    //This function is creating a new proposal. It is checking if the address that is passed to it has a token. It is then creating a new proposal and setting the variables for the proposal. It is then emitting an event that is used to log the data of the proposal.
    function createProposal(string memory _description, address[] memory _canVote) public {
        require(checkProposalEligibility(msg.sender), "Only NFT holders can put forth Proposals");

       //This is creating a new proposal and setting the variables for the proposal.
        proposal storage newProposal = Proposals[nextProposal];
        newProposal.id = nextProposal;
        newProposal.exists = true;
        newProposal.description = _description;
        newProposal.deadline = block.number + 100;
        newProposal.canVote = _canVote;
        newProposal.maxVotes = _canVote.length;

       //This is emitting an event that is used to log the data of the proposal. It is then incrementing the nextProposal variable.
        emit proposalCreated(nextProposal, _description, _canVote.length, msg.sender);
        nextProposal++;
    }


    //This function is checking if the proposal exists. It is then checking if the address that is passed to it has a token. It is then checking if the address that is passed to it has already voted. It is then checking if the deadline has passed. It is then incrementing the votesUp or votesDown variable. It is then setting the voteStatus variable to true. It is then emitting an event that is used to log the data of the vote.
    function voteOnProposal(uint256 _id, bool _vote) public {
        require(Proposals[_id].exists, "This Proposal does not exist");
        require(checkVoteEligibility(_id, msg.sender), "You can not vote on this Proposal");
        require(!Proposals[_id].voteStatus[msg.sender], "You have already voted on this Proposal");
        require(block.number <= Proposals[_id].deadline, "The deadline has passed for this Proposal");

        proposal storage p = Proposals[_id];

        if(_vote) {
            p.votesUp++;
        }else{
            p.votesDown++;
        }

        p.voteStatus[msg.sender] = true;

        emit newVote(p.votesUp, p.votesDown, msg.sender, _id, _vote);
        
    }

   // This function is counting the votes for a proposal. It is checking if the address that is passed to it is the owner. It is then checking if the proposal exists. It is then checking if the deadline has passed. It is then checking if the count has already been conducted. It is then checking if the votesDown is less than the votesUp. It is then setting the passed variable to true. It is then setting the countConducted variable to true. It is then emitting an event that is used to log the data of the proposal.
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


   //This function is adding a tokenId to the validTokens array.
    function addTokenId(uint256 _tokenId) public {
        require(msg.sender == owner, "Only Owner Can Add Tokens");

        validTokens.push(_tokenId);
    }
    
}