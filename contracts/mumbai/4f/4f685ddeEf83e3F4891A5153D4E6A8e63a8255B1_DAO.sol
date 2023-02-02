/**
 *Submitted for verification at polygonscan.com on 2023-02-01
*/

// SPDX-License-Identifier : MIT
pragma solidity ^0.8.0;

contract DAO {
  address public owner;
  mapping (address => bool) public members;
  mapping (address => mapping (uint => bool)) public userVotes;
  mapping (uint => bool) public votingStatus;
  mapping(uint => uint) public totalVotes;
  string[] public proposals;

  constructor() public {
    owner = msg.sender;
  }

  function applyForMembership() public {
    require(msg.sender != owner, "Cannot apply for membership as the owner.");
    members[msg.sender] = false;
  }

  function approveMembership(address _member) public {
    require(msg.sender == owner, "Only the owner can approve membership.");
    require(members[_member] == false, "Membership already approved.");
    members[_member] = true;
  }

  function isMember(address _member) public view returns (bool) {
    return members[_member];
  }

  function addProposal(string memory _proposal) public {
    require(members[msg.sender] || msg.sender == owner, "Only members or admins can add add proposals.");
    proposals.push(_proposal);
    votingStatus[proposals.length-1] = true;
  }

  function vote(uint _proposalIndex, bool _vote) public {
    require(votingStatus[_proposalIndex], "Voting is closed for this proposals.");
    require(members[msg.sender], "Only members can vote.");
    require(_proposalIndex < proposals.length, "Invalid proposal index.");
    require(!userVotes[msg.sender][_proposalIndex], "You have already voted for this proposal");
    totalVotes[_proposalIndex] += _vote ? 1 : 0;
    userVotes[msg.sender][_proposalIndex] = true;
  }

//    Here Along with close voting the admin also declare results, 
//    which will be return after the transaction completes.
  function closeVoting(uint _proposalIndex) public  returns (uint){
    require(msg.sender == owner, "Only the owner can close voting.");
    votingStatus[_proposalIndex] = false;
    return totalVotes[_proposalIndex];
  }

  function viewProposals() public view returns(string[] memory){
      return proposals;
  }
}