/**
 *Submitted for verification at polygonscan.com on 2022-02-03
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.11;
  

contract Election {


// stores the address of the deployer(owner)
 address public owner;

    struct Candidate {
        string name;      // short name (up to 32 bytes)
        uint voteCount;         // number of accummulated votes
    }

  
    // A dynamically-sized array of 'candidates' structs
    Candidate[] public candidates;

    // A function to register the vote
    function vote(uint candidate) external {
    
    candidates[candidate].voteCount += 1;  // Updating the canditate's votecount

    }

    // /// Creates a new voting candidate to choose one of 'proposalNames'. Initiated at the time of contract deployment

    constructor(string[] memory votingCandidates) {
        // 'candidates({...}) creates a temporary candidates object 
        // candidates.push(...) appends it to the end of the candidates array
             owner = msg.sender;
        for (uint i = 0; i < votingCandidates.length; i++) {
            // `Candidates({...})` creates a temporary
            // Candidates object and `candidates.push(...)`
            // appends it to the end of `candidates`.
            candidates.push(Candidate({ name: votingCandidates[i], voteCount:0}));
        }

    }
    
    // returns winner of the vote .... 
    function winner() public view returns (uint candidate_) {
        uint winningCount = 0; 
        for(uint i=0; i < candidates.length; i++) {
            if(candidates[i].voteCount > winningCount) {
                winningCount = candidates[i].voteCount;
                candidate_ = i;
                }
         }
    }

            // returns winner's name...
    function getWinner() external view returns(string memory winnerName_){
        winnerName_ = candidates[winner()].name;
    }

     function getCandidate1Results() external view returns(uint counts){
            counts = candidates[0].voteCount;
                 }

            function getCandidate2Results() external view returns(uint counts){
            counts = candidates[1].voteCount;
            }

            //resets candidates vote counts...
            
            function endVote() external {
              require(
            msg.sender == owner,
            "Only owner can give right to vote.");
                candidates[0].voteCount = 0;
                candidates[1].voteCount = 0;

            }
}