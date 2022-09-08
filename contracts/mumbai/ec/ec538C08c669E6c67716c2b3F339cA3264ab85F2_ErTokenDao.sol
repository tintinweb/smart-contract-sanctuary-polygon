// SPDX-License-Identifier: MIT

pragma solidity 0.8.11;

interface IdaoContract {
  function balanceOf(address, uint256) external view returns (uint256);
}

contract ErTokenDao {

  address public owner;
  uint256 nextProposal;
  uint256[] public validTokens;
  IdaoContract daoContract;

  constructor() {
    owner = msg.sender;
    nextProposal = 1;
    daoContract = IdaoContract(0x2953399124F0cBB46d2CbACD8A89cF0599974963);
    validTokens = [10767527961072460609707326236249391169159199720874440232410320380703363039247];
  }

  struct proposal {
    uint256 id;
    bool exists;
    string description;
    uint deadline;
    uint256 votesUp;
    uint256 votesDown;
    uint256 votesAbstain;
    address[] canVote;
    uint256 maxVotes;
    mapping(address => bool) voteStatus;
    bool countConducted;
    bool passed;
  }

  mapping(uint256 => proposal) public Proposals;

  event proposalCreated(
    uint256 id,
    string description,
    uint256 maxVotes,
    address proposer
  );

  event newVote(
    uint256 votesUp,
    uint256 votesDown,
    uint256 votesAbstain,
    address voter,
    uint256 porposal,
    bool votedFor
  );

  event proposalCount(
    uint256 id,
    bool passed
  );

  function checkProposalEligibility(address _proposalist) private view returns (bool) {
    for(uint i = 0; i < validTokens.length; i++) {
      if(daoContract.balanceOf(_proposalist, validTokens[i]) >= 1) {
        return true;
      }
    }
    return false;
  }

  function checkVoteEligibility(uint256 _id, address _voter) private view returns (bool) {
    for(uint256 i = 0; i < Proposals[_id].canVote.length; i++) {
      if (Proposals[_id].canVote[i] == _voter) {
        return true;
      }
    }
    return false;
  }

  function createProposal(string memory _description, address[] memory _canVote) public {
    require(checkProposalEligibility(msg.sender), "Only NFT Holders Can Put Forth Proposals");

    proposal storage newProposal = Proposals[nextProposal];
    newProposal.id = nextProposal;
    newProposal.exists = true;
    newProposal.description = _description;
    newProposal.deadline = block.number + 16;
    newProposal.canVote = _canVote;
    newProposal.maxVotes = _canVote.length;

    emit proposalCreated(nextProposal, _description, _canVote.length, msg.sender);
    nextProposal++;
  }

  function voteOnProposal(uint256 _id, bool _vote) public {
    require(Proposals[_id].exists, "This Proposal Doesn't Exists");
    require(checkVoteEligibility(_id, msg.sender), "You Can't Vote on This Proposal");
    require(!Proposals[_id].voteStatus[msg.sender], "You Have Already Voted on This Proposal");
    require(block.number <= Proposals[_id].deadline, "The Deadline Has Passed For This Proposal");

    proposal storage p = Proposals[_id];

    if(_vote) {
      p.votesUp++;
    } else if(!_vote) {
      p.votesDown++;
    } else {
      p.votesAbstain++;
    }

    p.voteStatus[msg.sender] = true;

    emit newVote(p.votesUp, p.votesDown, p.votesAbstain, msg.sender, _id, _vote);
  }

  function countVotes(uint256 _id) public {
    require(msg.sender == owner, "Only Owner Can Count Votes");
    require(Proposals[_id].exists, "This Proposal Doesn't Exist");
    require(block.number > Proposals[_id].deadline, "Voting Has Not Concluded");
    require(!Proposals[_id].countConducted, "Count Already Conducted");

    proposal storage p = Proposals[_id];

    if(Proposals[_id].votesDown < Proposals[_id].votesUp) {
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