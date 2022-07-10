//SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

interface IdaoContract {
    //need an interface to the Smart Contract that created the tokens to keep track of tokens
    function balanceOf(address, uint256) external view returns (uint256);
}


contract Dao {
    //Global Variables

    //owner of the smart contract
    address public owner;
    //next proposal's ID to keep track of
    uint256 nextProposal;
    //array that distinguishes which tokens are allowed to vote on the DAO
    uint256[] public validTokens;
    //create refernce to the IdaoCotnract interface
    IdaoContract daoContract;

    constructor() {
        //constructor with variables to initialise the smart contract.
        
        //contract deployer
        owner = msg.sender;
        //set nextProposal to 1, every new proposal will increment this
        nextProposal = 1;
        //this is the contract address on OpenSea - referencing the interface to the contract we will query
        daoContract = IdaoContract(0x2953399124F0cBB46d2CbACD8A89cF0599974963);
        //initialises the validTokens array with the test token created on testnets.opensea.io for the purposes of this project
        validTokens = [36461899886729445886229041418421588246282703725939487903395068677587707363329];
    }

    struct proposal {
        //data structure of the proposal object

        //next proposal ID
        uint256 id;
        //If the proposal actually exists
        bool exists;
        //description of the proposal
        string description;
        //deadline to cast votes
        uint deadLine;
        //total votes up
        uint256 votesUp;
        //total votes down
        uint256 votesDown;
        //array of wallet addresses that can actually vote
        address[] canVote;
        //maximum number of votes = length of address array
        uint256 maxVotes;
        //voting status of any possible address
        mapping(address => bool) voteStatus;
        //when the deadline has passed count the number of votes
        bool countConducted;
        //passed boolean to set to true when count conducted is completed
        bool passed;
    }

    mapping(uint256 => proposal) public Proposals;
    //maps a proposal ID to Proposal Struct

    event proposalCreated(uint256 id, string description, uint256 maxVotes, address proposer);
    //event for log for when a new proposal is created - emits the Proposal ID, Proposal Description, Num of Max Votes and Address of the proposer

    event newVote(uint256 votesUp, uint256 votesDown, address voter, uint256 proposal, bool votedFor);
    //event for log for a new vote - including votes up, down, the most recent voters address, the proposal and boolean for if it was voted for or against

    event proposalCount(uint256 id, bool passed);
    //event for when or after deadline of vote owner calculates the number of votes - vote ID and whether the vote was passed or not


    function checkProposalEligibility(address _proposalList) private view returns(bool) {
        //this is a private function - i.e. only for this smart contract, which checks if the propsoal is eligible
        //i.e. if someone is trying to create a proposal , check if the user creating the proposal actually owns any of the 
        //valid tokens we have whitelisted.
        for(uint i = 0; i < validTokens.length; i++){
            //this for loop runs through all of the valid tokens. the owner of the contract can add more tokens to smart contract
            if(daoContract.balanceOf(_proposalList, validTokens[i]) >= 1) {
                //check if the proposer holds any valid tokens, if this condition is true, it returns 'true'. else false
                return true;
            }
        }
        return false;
    }

    function checkVoteEligibility(uint256 _id, address _voter) private view returns(bool) {
        //checking whether a voter can actually vote on a specific proposal
        for(uint i = 0; i < Proposals[_id].canVote.length; i++) {
            //loop around specific proposals in proposal mapping and loop through all proposals.
            //if the voter is part of the canVote array then they can take part in the voting of a proposal
            if (Proposals[_id].canVote[i] == _voter) {
                return true;
            }
        }
        return false;
    }

    function createProposal(string memory _description, address[] memory _canVote) public {
        //create proposal function which allows the addresses a part of the canVote
        require(checkProposalEligibility(msg.sender), "Only Token Holders can put forth Proposals");
        //this requires that the address making a proposal is eligible

        proposal storage newProposal = Proposals[nextProposal];
        newProposal.id = nextProposal;
        newProposal.exists = true;
        newProposal.description = _description;
        newProposal.deadLine = block.number + 100;
        //deadline for voting set to blocks
        newProposal.canVote = _canVote;
        newProposal.maxVotes = _canVote.length;

        emit proposalCreated(nextProposal, _description, _canVote.length, msg.sender);
        nextProposal++;
        //increment for new proposal ID
    }

    function voteOnProposal(uint256 _id, bool _vote) public {
        require(Proposals[_id].exists, "This Proposal does not exist");
        //require that proposal exists
        require(checkVoteEligibility(_id, msg.sender), "You can not vote on this Proposal");
        //check vote eligibility to ensure the msg sender is in the canVote array
        require(!Proposals[_id].voteStatus[msg.sender], "You have already voted on this Proposal");
        //make sure that the voter cannot vote multiple times
        require(block.number <= Proposals[_id].deadLine);
        //ensure that the block number isnt higher than the deadline that has been set

        proposal storage p = Proposals[_id];

        if(_vote) {
            p.votesUp++;
        }else{
            p.votesDown++;
        }

        p.voteStatus[msg.sender] = true;

        emit newVote(p.votesUp, p.votesDown, msg.sender, _id, _vote);
    }

    function countVotes(uint256 _id) public {
        //function for the onwer to count the votes
        require(msg.sender == owner, "Only the owner can count votes");
        require(Proposals[_id].exists, "This proposal does not exist");
        require(block.number > Proposals[_id].deadLine, "Voting has not concluded");
        require(!Proposals[_id].countConducted, "Count already conducted");

        proposal storage p = Proposals[_id];

        if(Proposals[_id].votesDown < Proposals[_id].votesUp) {
            p.passed = true;
        }

        p.countConducted = true;

        emit proposalCount(_id, p.passed);
    }

    function addTokenId(uint256 _tokenId) public {
        //function to add new tokens to the DAO votes and Proposals
        require(msg.sender == owner, "Only the owner can add new Tokens");

        validTokens.push(_tokenId);
    }
}