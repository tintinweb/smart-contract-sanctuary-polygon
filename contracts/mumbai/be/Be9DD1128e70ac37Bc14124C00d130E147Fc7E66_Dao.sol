// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

//interface to use other smart contracts balance of function 
interface IdaoContract {
    function balanceOf(address, uint256) external view returns (uint256);
}
contract Dao {
    //owner fo the smart contract
    address public owner;
    //unique ID for each proposal
    uint256 nextProposal;
    //array for which addresses are allowed to vote in the DAO
    uint256[] public validTokens;
    IdaoContract daoContract;

    //defaults when contract is created
    constructor() {
        owner = msg.sender;
        //id of proposal intiate at 1
        nextProposal = 1;
        //smart contract created from open sea collection
        daoContract = IdaoContract(0x2953399124F0cBB46d2CbACD8A89cF0599974963);
        //array of id tokens from the open sea collection
        validTokens = [89524774268331956089764817884660409575568244269276324058864185676450483929108];
    }
    //structs are similar to objects
    struct proposal{
        uint256 id;
        bool exists;
        string description;
        //deadline to cast a vote
        uint deadline;
        //votes for yes(up) and no(down)
        uint256 votesUp;
        uint256 votesDown;
        //array of wallet address that hold the validTokens value
        address[] canVote;
        uint256 maxVotes;
        //voting status for each address
        mapping(address => bool) voteStatus;
        //when voting finishes and if it passes
        bool countConducted;
        bool passed;
    }

    //storing all proposals in a mapping. making public to access
    mapping(uint256 => proposal) public Proposals;

    //events for functions that will get stored in Moralis Database
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

    //function to check if the address making the proposal has a valid id token
    function checkProposalEligibility(address _proposalist) private view returns(bool) {
        for(uint i=0; i < validTokens.length; i++) {
            if(daoContract.balanceOf(_proposalist, validTokens[i]) >= 1) {
                return true;
            }
        }
        return false;
    }
    //function to check if voter is allowed to vote in a specific proposal
    function checkVoterEligibility(uint256 _proposalId, address _voter) private view returns(bool) {
        for(uint i=0; i < Proposals[_proposalId].canVote.length; i++) {
           if(Proposals[_proposalId].canVote[i] == _voter) {
               return true;
           }
        }
        return false;
    }
    //function to create a proposal uses, checks if person creating it is eligble to create one
    function createProposal(string memory _description, address[] memory _canVote) public {
        require(checkProposalEligibility(msg.sender), "Only NFT holder can create a proposal");
        
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

    //function to vote on the proposal. increment vopeUp or voteDown
    function voteOnProposal(uint _proposalId, bool _vote) public { 
        //validations
        require(Proposals[_proposalId].exists, "This Proposal does not exist");
        require(checkVoterEligibility(_proposalId, msg.sender), "You are not eligible to vote in this proposal");
        require(!Proposals[_proposalId].voteStatus[msg.sender], "You have already voted on this proposal");
        require(block.number <= Proposals[_proposalId].deadline, "The deadline has passed for this Proposal");

        proposal storage p = Proposals[_proposalId];
        if(_vote) {
            p.votesUp++;
        }else {
            p.votesDown++;
        }
        p.voteStatus[msg.sender] == true;

        emit newVote(p.votesUp, p.votesDown, msg.sender, _proposalId, _vote);
    }

    //function that rounds up the votes and checks if the proposal passed
    //Update the passed value in the proposal passed in
    function checkVotes(uint256 _proposalId) public {
        //validations
        require(msg.sender == owner, "Only owner can count Votes");
        require(Proposals[_proposalId].exists, "This proposal does not exist");
        require(block.number > Proposals[_proposalId].deadline, "Voting has not concluded");
        require(!Proposals[_proposalId].countConducted, "Count already conducted");

        proposal storage p = Proposals[_proposalId];
        if(Proposals[_proposalId].votesDown < Proposals[_proposalId].votesUp) {
            p.passed = true;
        }

        p.countConducted = true;
        emit proposalCount(_proposalId, p.passed);
    }

    //function to add a valid token to the tokens array so they are allowed to create proposals
    function addTokenId(uint256 _tokenId) public {
        require(msg.sender == owner, "Only Owner Can add Tokens");
        validTokens.push(_tokenId);
    }

}