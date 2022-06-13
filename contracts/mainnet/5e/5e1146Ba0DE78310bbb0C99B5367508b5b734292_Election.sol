/**
 *Submitted for verification at polygonscan.com on 2022-06-12
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.13;
  

contract Election {

        struct Candidate {
           string name;      // short name (up to 32 bytes)
           uint voteCount;         // number of accummulated votes
        }

  
    // A dynamically-sized array of 'candidates' structs
    Candidate[] public candidates;
    uint[] public count;
   
   
    //Creates a new voting candidate to choose one of 'proposalNames'. Initiated at the time of contract deployment
    constructor(string[] memory votingCandidates) {
             // 'candidates({...}) creates a temporary candidates object 
             // candidates.push(...) appends it to the end of the candidates array
            for (uint i = 0; i < votingCandidates.length; i++) {
            // `Candidates({...})` creates a temporary
            // Candidates object and `candidates.push(...)`
            // appends it to the end of `candidates`.
                  candidates.push(Candidate({ name: votingCandidates[i], voteCount:0}));
                 } 
        }

   
     // A function to register the vote
    function vote(uint candidate,uint vote_variable) external {

      candidates[candidate].voteCount += vote_variable;  // Updating the canditate's votecount
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

            // returns each candidates voting results, to be updated soon!
            function getCandidate1Results() external view returns(uint counts){
                counts = candidates[0].voteCount;
            }

            function getCandidate2Results() external view returns(uint counts){
                counts = candidates[1].voteCount;
            }
            
            function getCandidate3Results() external view returns(uint counts){
                counts = candidates[2].voteCount;
            }
            
            function getCandidate4Results() external view returns(uint counts){
                counts = candidates[3].voteCount;
            }
            
            function getCandidate5Results() external view returns(uint counts){
                counts = candidates[4].voteCount;
            }
             
            function getCandidate6Results() external view returns(uint counts){
                counts = candidates[5].voteCount;
            }
             
            function getCandidate7Results() external view returns(uint counts){
                counts = candidates[6].voteCount;
            }
             
            function getCandidate8Results() external view returns(uint counts){
                counts = candidates[7].voteCount;
            }
             
             function getCandidate9Results() external view returns(uint counts){
                counts = candidates[8].voteCount;
            }

             function getCandidate10Results() external view returns(uint counts){
                counts = candidates[9].voteCount;
            }

             function getCandidate11Results() external view returns(uint counts){
                counts = candidates[10].voteCount;
            }

            function getCandidate12Results() external view returns(uint counts){
                counts = candidates[11].voteCount;
            }
            
            function getCandidate13Results() external view returns(uint counts){
                counts = candidates[12].voteCount;
            }

            function getCandidate14Results() external view returns(uint counts){
                counts = candidates[13].voteCount;
            }

            function getCandidate15Results() external view returns(uint counts){
                counts = candidates[14].voteCount;
            }

            function getCandidate16Results() external view returns(uint counts){
                counts = candidates[15].voteCount;
            }
            
            function getCandidate17Results() external view returns(uint counts){
                counts = candidates[16].voteCount;
            }

            function getCandidate18Results() external view returns(uint counts){
                counts = candidates[17].voteCount;
            }
             
            function getCandidate19Results() external view returns(uint counts){
                counts = candidates[18].voteCount;
            }

            function getCandidate20Results() external view returns(uint counts){
                counts = candidates[19].voteCount;
            }

            //resets candidates vote counts...
            function endVote() external {
             for(uint i = 0; i<candidates.length; i++)
                candidates[i].voteCount = 0;
        }
}