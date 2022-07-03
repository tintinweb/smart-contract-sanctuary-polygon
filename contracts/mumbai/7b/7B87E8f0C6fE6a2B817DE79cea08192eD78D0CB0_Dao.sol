// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

interface IdaoContract {
    //Calling smart contract of NFT to verify transaction
    //input parameters : owner address, token id of the nft => returns balance as uint256
    function balanceOf(address, uint256) external view returns (uint256);
}

/// @title Sample DAO Contract
/// @author Rishabh Malik
/// @notice This is a basic contract implementing a DAO Voting procedure
/// @dev All function calls are currently implemented without side effects
/// @custom:experimental This is an experimental contract.
contract Dao {
    
    address public owner;
    uint256 nextProposal;
    uint256[] public validTokens;
    IdaoContract daoContract;

    constructor(){
        owner = msg.sender;
        nextProposal = 1;
        daoContract = IdaoContract(0x3b9bA781797b57872687Ce5d5219A1A4Bc0e85ea); // linking nft smart contract to use it's functions
        validTokens = [21538727925602867906929485588529430632937334277200419000954926339556563222529]; //token id of nft
    }

    struct proposal {
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
    // this mapping maps a proposal id to the proposal struct
    mapping(uint256 => proposal) public Proposals;

    /// @notice New Proposal is created
    /// @dev Creates an event after creating a new Proposal
    /// @param id Id of the proposal
    /// @param description Description of the proposal
    /// @param maxVotes Max Votes allowed on the proposal
    /// @param proposer Address of the proposer
    event proposalCreated(
        uint256 id, 
        string description,
        uint256 maxVotes,
        address proposer
    );

    /// @notice New vote on the proposal
    /// @dev Creates an event after counting the votes on propsal
    /// @param votesUp Total number of UP Votes
    /// @param votesDown Total number of Down Votes
    /// @param voter Address of the Voter
    /// @param proposal Id of theProposal on which user wants to vote on
    /// @param votedFor Voter's vote, UP or Down
    event newVote(
        uint256 votesUp,
        uint256 votesDown,
        address voter,
        uint256 proposal,
        bool votedFor
    );

    /// @notice Voting result of the Proposal
    /// @dev Creates an event after counting the votes on propsal
    /// @param id Id of the proposal
    /// @param passed Result of the voting on proposal, passed defines that the proposal is accepted by the voters
    event proposalCount(
        uint256 id, 
        bool passed
    );

    /// @notice Check the valid tokens array to confirm proposer eligibility
    /// @dev Iterating through the array and confirming the validity for proposer address
    /// @param _proposer Address of the proposer who wants to create a new proposal
    /// @return PEligible Eligibility of the proposer as a boolean value
    function checkProposerEligibility(address _proposer) private view returns (
        bool PEligible
        ){
        for(uint i = 0; i < validTokens.length; i++){
            if(daoContract.balanceOf(_proposer, validTokens[i]) >= 1){
                return true;
            }
        }
    }

    /// @notice Check the Proposal canVote array to confirm voter eligibility
    /// @dev Iterating through the array and confirming the validity for voter address
    /// @param _id Id of the proposal, voter wants to vote on
    /// @param _voter Address of the user who wants to vote on the proposal
    /// @return VEligible Eligibility of the voter as a boolean value
    function checkVoteEligibility(uint256 _id, address _voter) private view returns (
        bool VEligible
    ){
        for (uint256 i = 0; i < Proposals[_id].canVote.length; i++){
            if(Proposals[_id].canVote[i] == _voter){
                return true;
            }
        }
    }

    /// @notice Creates a new Proposal by creating a newProposal object
    /// @dev Initializes the proposal object and increment the index for next Proposal
    /// @param _description Description of the Proposal
    /// @param _canVote CanVote array of the porposal to confirm the voters eligibility
    function createProposal(string memory _description, address[] memory _canVote) public {
        require(checkProposerEligibility(msg.sender), "Only NFT holders can put forth Proposals");

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

    /// @notice Votes on the proposal up or down, true or false
    /// @dev Check the eligibility of the voter for the proposal and updates the votes
    /// @param _id Id of the Proposal
    /// @param _vote Vote from the user up or down, true or false
    function voteOnPropsal(uint256 _id, bool _vote) public {
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

    /// @notice Counts votes of a Proposal
    /// @dev Only Owner can count votes of the proposal, function compares Votes Down and Votes Up with min 50% to favour the vote. Count can be performed only once.
    /// @param _id Id of the Proposal
    function countVotes(uint256 _id) public {
        require(msg.sender == owner, "Only Owner can count votes");
        require(Proposals[_id].exists, "This Proposal does not exists");
        require(block.number > Proposals[_id].deadline, "Voting has not concluded");
        require(!Proposals[_id].countConducted, "Count already conducted");

        proposal storage p = Proposals[_id];

        if(Proposals[_id].votesDown < Proposals[_id].votesUp){
            p.passed = true;
        }

        p.countConducted = true;
        emit proposalCount(_id, p.passed);
    }

    /// @notice Adds Proposer to the list of Valid Tokens
    /// @dev Only Owner of the contract can add the Proposer to the Valid Tokens list
    /// @param _tokenId NFT token id of the Proposer
    function addTokenId(uint256 _tokenId) public {
        require(msg.sender == owner, "Only Owner Can Add Tokens");

        validTokens.push(_tokenId);
    }
}