//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

contract VoteSystem {
    // Address of the admin =: vote initiator
    address public admin;

    // Mapping of eligible voters
    mapping(address => bool) public voters;

    // Mapping of vote counts per candidate
    mapping(uint256 => uint256) public votes;

    // Map each voter to a boolean indicating if he voted.
    mapping(address => bool) public voted;

    // Boolean that refers if the vote was initialized
    bool initialized;

    // number of candidates, candidates IDs starts from 0 to numCandidates
    uint256 numCandidates;

    // Total number of voters ( who submitted their votes)
    uint256 votersNumber;

    function initializeVote(
        address[] memory _voters,
        uint256 _numCandidates
    ) public {
        admin = msg.sender;

        // The voting process can only be initialized once
        require(!initialized, "Vote already initialized");

        // The number of candidates must be greater than zero
        require(_numCandidates > 0, "You must have at least one candidate");

        // Add each eligible voter to the voters mapping
        for (uint i = 0; i < _voters.length; i++) {
            voters[_voters[i]] = true;
        }

        // Set the number of candidates and mark the voting process as initialized
        numCandidates = _numCandidates;

        // set initialized to true
        initialized = true;
    }

    function vote(uint256 _candidate) public {
        // The voting process must be initialized
        require(initialized, "Vote has not been initialized");
        // Check that caller is allowed to vote adn didn't vote before
        require(voters[msg.sender], "Caller is not an eligible voter");
        require(!voted[msg.sender], "Caller already voted");
        // The selected candidate must be valid
        require(_candidate < numCandidates, "Invalid candidate");

        // Increment  candidate votes
        votes[_candidate]++;
        // Increment number of voters
        votersNumber++;
        // Mark that voter submitted his vote
        voted[msg.sender] = true;
    }
}