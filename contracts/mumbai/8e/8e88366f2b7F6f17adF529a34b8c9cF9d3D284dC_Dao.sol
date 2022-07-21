// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

interface IdaoContract {
  function balanceOf(address, uint256) external view returns (uint256);
}

contract Dao {
  // owner of the smart contract DAO
  address public owner;
  // every proposal has an ID. keep track of the ID to set the next proposal
  uint256 nextProposal;
  // array that distingishes which tokens are allowed to vote
  uint256[] public validTokens;
  IdaoContract daoContract;

  constructor(){
    owner = msg.sender;
    nextProposal = 1;
    // Smart contract for the Opensea storefront
    // We will use the balanceOf function from this smart contract (Opensea's)
    daoContract = IdaoContract(0x2953399124F0cBB46d2CbACD8A89cF0599974963);
    validTokens = [
      44726437838149782084824166820475040793954913472076897533842624768607099289601,
      44726437838149782084824166820475040793954913472076897533842624769706610917377
    ];
  }

  struct proposal {
    uint256 id;
    bool exists;
    string description;
    uint deadline;
    uint256 votesUp;                      // no. of votes up
    uint256 votesDown;
    address[] canVote;                    // array of addresses that can vote
    uint256 maxVotes;
    mapping(address => bool) voteStatus;  // voting status of any address
    bool countConducted;                  // after deadline, the owner counts votes
    bool passed;                          // true of there are more votes up than down
  }

  mapping (uint256 => proposal) public Proposals;

  /* events that be emitted in functions and listened to by Moralis */

  event proposalCreated (
    uint256 id, 
    string description,
    uint256 maxVotes,
    address proposer
  );

  event newVote (
    uint256 votesUp,
    uint256 votesDown,
    address voter,
    uint256 proposal,
    bool votedFor
  );

  // when the owner calculates the votes for the proposal
  event proposalCount (
    uint256 id,
    bool passed 
  );

  /* PRIVATE FUNCTIONS - Only applicable for this smart contract */
  
  // Checks if the user owns the NFT that are part of this DAO, allowing them to vote
  function checkProposalEligibility(address _proposalist) private view returns (bool) {
    for (uint i = 0; i < validTokens.length; i++) {
      if (daoContract.balanceOf(_proposalist, validTokens[i]) >= 1) {
        return true;
      }
    }
    return false;
  }

  // Checks if the voter can vote for a specific proposal
  function checkVoteEligibility(uint256 _id, address _voter) private view returns (bool) {
    for (uint256 i = 0; i < Proposals[_id].canVote.length; i++) {
      if (Proposals[_id].canVote[i] == _voter) {
        return true;
      }
    }
    return false;
  }

  /* PUBLIC FUNCTIONS - Available for use outside of this contract */

  // Create a new proposal
  function createProposal(string memory _description, address[] memory _canVote) public {
    // require that the message sender has the eligibility to vote
    require(checkProposalEligibility(msg.sender), "Only NFT holders can put forth proposals");

    // Create a new proposal in our Proposals mapping
    proposal storage newProposal = Proposals[nextProposal]; // create a temporary proposal
    newProposal.id = nextProposal;
    newProposal.exists = true;
    newProposal.description = _description;
    newProposal.deadline = block.number + 100; // deadline for the poposal
    newProposal.canVote = _canVote;
    newProposal.maxVotes = _canVote.length;

    // Emit event on this smart conract so we can read this proposal being created through Moralis
    emit proposalCreated(
      nextProposal,     // id
      _description,
      _canVote.length,  // max votes
      msg.sender        // the sender
    );
    nextProposal++;
  }

  // Vote on a proposal
  // _vote: true = for, false = against
  function voteOnProsal(uint256 _id, bool _vote) public {

    // Check that the proposal actually exists
    require(Proposals[_id].exists, "This Proposal does not exist");

    // Use checkVoteEligibility function to ensure that the voter is in the proposals' canVote array
    require(checkVoteEligibility(_id, msg.sender), "You can not vote on this Proposal");

    // If the voter already voted, don't allow them to vote again
    require(!Proposals[_id].voteStatus[msg.sender], "You have already voted on this Proposal");

    // Check that the block number isn't higher than the deadline of the proposal
    require(block.number <= Proposals[_id].deadline, "The deadline has passed for this Proposal");

    // Get an instance of the proposal
    proposal storage p = Proposals[_id];

    if(_vote) {
        p.votesUp++;
    }else{
        p.votesDown++;
    }

    // Mark this voter as voted on this proposal
    p.voteStatus[msg.sender] = true;

    // Emit an event when a new vote is casted to view on Moralis
    emit newVote(p.votesUp, p.votesDown, msg.sender, _id, _vote);
  }

  // Counting the votes
  function countVotes(uint256 _id) public {

    // Make sure the caller is the owner, not just anyone
    require(msg.sender == owner, "Only Owner Can Count Votes");

    // Make sure that the proposal exists
    require(Proposals[_id].exists, "This Proposal does not exist");

    // Make sure the owner can't count the vote after the deadline has passed
    require(block.number > Proposals[_id].deadline, "Voting has not concluded");

    // If the count is already conducted, the owner doesn't have to conduct it again
    require(!Proposals[_id].countConducted, "Count already conducted");

    // Get an instance of the proposal
    proposal storage p = Proposals[_id];
    
    if(Proposals[_id].votesDown < Proposals[_id].votesUp){
        p.passed = true;            
    }

    // Change countConducted to true so the proposal can't be counted again
    p.countConducted = true;

    // Emit an event when a new voteCount is done to view on Moralis
    emit proposalCount(_id, p.passed);
  }

  function addTokenId(uint256 _tokenId) public {
    require(msg.sender == owner, "Only Owner Can Add Tokens");

    validTokens.push(_tokenId);
  }
}