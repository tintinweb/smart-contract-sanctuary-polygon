/**
 *Submitted for verification at polygonscan.com on 2023-02-05
*/

// SPDX-License-Identifier: None
pragma solidity ^0.8.0;

contract Voting {
    // Define the number of candidates in the election
    uint256 public numCandidates;
    
    // Mapping to store the number of votes each candidate has received
    mapping (uint256 => uint256) private votesReceived;
    
    // Mapping to store the state of each voter (voted or not)
    mapping (address => bool) public voters;
    
    // Event to log when a vote is cast
    event VoteCast(address indexed voter, uint256 candidate);
    
    // Function to initialize the contract with the number of candidates
    constructor(uint256 numberOfCandidates) public {
        numCandidates = numberOfCandidates;
    }
    
    // Function to cast a vote
    function vote(uint256 candidate) public {
        require(!voters[msg.sender], "Voter already voted");
        require(candidate <= numCandidates, "Invalid candidate");
        votesReceived[candidate] += 1;
        voters[msg.sender] = true;
        emit VoteCast(msg.sender, candidate);
    }
    
    // Function to retrieve the number of votes received by a candidate
    function getVotes(uint256 candidate) public view returns (uint256) {
        return votesReceived[candidate];
    }
}