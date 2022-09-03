// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

// Contract is interface of Daocontract replicates opensea storefront functionality
interface IdaoContract {
        function balanceOf(address, uint256) external view returns (uint256);
    }

contract Dao {

    // Owner of is msg.sender 
    address public owner;
    uint256 nextProposal;
    uint256[] public validTokens;
    // Dao contract refference
    IdaoContract daoContract;

    // Function run at deployment of smart contract dao contract interface
     constructor(){
        owner = msg.sender;
        nextProposal = 1;
        daoContract = IdaoContract(0x2953399124F0cBB46d2CbACD8A89cF0599974963);
        validTokens = [34885103611559094078416375598166902696017567311370712658413208238551126245396];
    }

    // Struct to track proposal variables
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

    // Mapping of proposals/votes/validation of documents ???
    mapping(uint256 => proposal) public Proposals;

    // Document put forward for validation
    event proposalCreated(
        uint256 id,
        string description,
        uint256 maxVotes,
        address proposer
    );

    // New vote/Validation on document
    event newVote(
        uint256 votesUp,
        uint256 votesDown,
        address voter,
        uint256 proposal,
        bool votedFor
    );

    // Counts votes
    event proposalCount(
        uint256 id,
        bool passed
    );

    // Checks if the account putting in a proposal/documents for validation is eligable (do they own and NFT) this will need to change for our use
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

    // Checks if the account trying to vote/validate is part of the DAO
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

    // Function to create a proposal (this will need to be changed to account adding document for validation maybe???)
    function createProposal(string memory _description, address[] memory _canVote) public {
        // Checks to see if msg.sender owns and NFT is part of the DAO, will error if not
        require(checkProposalEligibility(msg.sender), "Only NFT holders can put forth Documents for validation");
        // Counts proposals/documents added for validation
        proposal storage newProposal = Proposals[nextProposal];
        newProposal.id = nextProposal;
        newProposal.exists = true;
        newProposal.description = _description;
        newProposal.deadline = block.number + 100;
        newProposal.canVote = _canVote;
        newProposal.maxVotes = _canVote.length;
        // Emits proposal id the description of, max votes for proposal and who put in proposal
        emit proposalCreated(nextProposal, _description, _canVote.length, msg.sender);
        // Will increment to the next proposal/document for validation
        nextProposal++;
    }


    // Function that takes two parameters the id of the proposal/document and the accounts vote for/against
    function voteOnProposal(uint256 _id, bool _vote) public {
        require(Proposals[_id].exists, "This Document does not exist");
        require(checkVoteEligibility(_id, msg.sender), "You can not vote to validate this document");
        require(!Proposals[_id].voteStatus[msg.sender], "You have already voted on this document");
        require(block.number <= Proposals[_id].deadline, "The deadline has passed for validating this document");

        proposal storage p = Proposals[_id];

        if(_vote) {
            p.votesUp++;
        }else{
            p.votesDown++;
        }

        p.voteStatus[msg.sender] = true;
        // Event that can be read by moralis emits proposal status, its voteup, votes down, 
        // The account that cast the vote, the Id of the proposal/document they voted on
        // And the vote cast by the account which voted
        emit newVote(p.votesUp, p.votesDown, msg.sender, _id, _vote);
        
    }

    // counts votes on a specific proposal/document requires the proposal/document Id
    function countVotes(uint256 _id) public {
        // Only owner requirment
        require(msg.sender == owner, "Only Owner Can Count Votes");
        // Checks the proposal exsisits
        require(Proposals[_id].exists, "This document does not exist");
        // Requires that the block.number is greater then proposal deadline
        // So that even the owner cannot check votes on a documents before vote period concludes
        // This protects users so the owner cannot do any malicous acts
        require(block.number > Proposals[_id].deadline, "Voting has not concluded");
        // Checks to see if the count has already been conducted 
        require(!Proposals[_id].countConducted, "Count already conducted");

        proposal storage p = Proposals[_id];
        
        if(Proposals[_id].votesDown < Proposals[_id].votesUp){
            p.passed = true;            
        }

        p.countConducted = true;

        // Emits the id of the proposal/document and if it was validated
        emit proposalCount(_id, p.passed);
    }

    // Function to add token Ids that can vote in proposals/documents
    function addTokenId(uint256 _tokenId) public {
        require(msg.sender == owner, "Only Owner Can Add Tokens");

        validTokens.push(_tokenId);
    }
    
}