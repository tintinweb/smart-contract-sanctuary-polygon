/**
 *Submitted for verification at polygonscan.com on 2023-05-29
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Voting {
    struct Voter {
        bool voted;  // if true, that person already voted
        uint vote;   // index of the voted candidate
        address userAddress;
    }

    struct Candidate {
        string name;   // candidate name
        uint voteCount; // number of accumulated votes
    }

    address public owner;
    Candidate[] public candidates;
    mapping(address => Voter) public voters;

    constructor(string[] memory candidateNames) {
        owner = msg.sender;
        for(uint i = 0; i < candidateNames.length; i++) {
            candidates.push(Candidate({
                name: candidateNames[i],
                voteCount: 0
            }));
        }
    }

    function vote(uint candidateIndex) public {
        Voter storage sender = voters[msg.sender];
        require(!sender.voted, "Already voted.");
        sender.voted = true;
        sender.vote = candidateIndex;
        candidates[candidateIndex].voteCount += 1;
    }

    function getNumOfCandidates() public view returns(uint) {
        return candidates.length;
    }

    function getCandidate(uint candidateIndex) public view returns(string memory, uint) {
        return (candidates[candidateIndex].name, candidates[candidateIndex].voteCount);
    }
}