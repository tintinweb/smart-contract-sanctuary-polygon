// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

interface IdaoContract {
  function balanceOf(address, uint256) external view returns (uint256);
}

contract RebelDao {
  address public s_owner; // viewable address for contract EOA
  uint256 nextProposal; // unique id for next proposal
  uint256[] public validTokens; // NFT tracker
  IdaoContract daoContract; // reference to OS storefront on Mumbai Testnet for balance queries

  struct proposal {
    uint256 id;
    bool exists;
    string description;
    uint256 deadline;
    uint256 votesUp;
    uint256 votesDown;
    address[] canVote;
    uint256 maxVotes;
    mapping(address => bool) voteStatus;
    bool countConducted;
    bool passed;
  }

  mapping(uint256 => proposal) public s_proposals;

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

  // modifiers

  function checkProposalEligibility(address _proposer) private view returns (bool) {
    // check if proposer owns any DAO NFTs for proposal rights
    for (uint i=0; i<validTokens.length; i++) {
      if (daoContract.balanceOf(_proposer, validTokens[i]) >= 1) {
        return true;
      }
    }
    return false;
  }

  function checkVoteEligibility(uint256 _id, address _voter) private view returns (bool) {
    for (uint256 i=0; i<s_proposals[_id].canVote.length; i++) {
      if (s_proposals[_id].canVote[i] == _voter) {
        return true;
      }
    }
    return false;
  }

  constructor() {
    s_owner = msg.sender;
    nextProposal = 1;
    daoContract = IdaoContract(0x2953399124F0cBB46d2CbACD8A89cF0599974963);
    validTokens = [6978777370776394766532250503622487041558941328143326818190249397291008917514];
  }

  // functions

  function createProposal(string memory _description, address[] memory _canVote) public {
    require(checkProposalEligibility(msg.sender), "Proposals require ownership of valid NFTs");

    proposal storage newProposal = s_proposals[nextProposal];
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
    require(s_proposals[_id].exists, "Proposal ID is invalid");
    require(checkVoteEligibility(_id, msg.sender));
    require(!s_proposals[_id].voteStatus[msg.sender], "You have already voted for this proposal");
    require(block.number <= s_proposals[_id].deadline, "The voting deadline has passed for this proposal");

    proposal storage p = s_proposals[_id];

    if (_vote) {
      p.votesUp++;
    } else {
      p.votesDown++;
    }

    p.voteStatus[msg.sender] = true;

    emit newVote(p.votesUp, p.votesDown, msg.sender, _id, _vote);
  }

  function countVotes(uint256 _id) public {
    require(msg.sender == s_owner, "Only the contract owner can count votes");
    require(s_proposals[_id].exists, "The proposal ID is invalid");
    require(block.number > s_proposals[_id].deadline, "voting is still ongoing");
    require(!s_proposals[_id].countConducted, "vote count already occured");

    proposal storage p = s_proposals[_id];

    if (s_proposals[_id].votesDown < s_proposals[_id].votesUp) {
      p.passed = true;
    }

    p.countConducted = true;

    emit proposalCount(_id, p.passed);
  }

  function addTokenId(uint256 _tokenId) public {
    require(msg.sender == s_owner, "only owner can add tokens");

    validTokens.push(_tokenId);
  }
}