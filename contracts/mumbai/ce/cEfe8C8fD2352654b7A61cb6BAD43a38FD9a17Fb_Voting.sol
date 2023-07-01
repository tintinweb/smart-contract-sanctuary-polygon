// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

contract Voting {
    // Create a structure template for each candidates
    struct Candidate {
        uint256 id;
        string name;
        uint256 numberOfVotes;
    }

    // Create an array called candidates with Candidate structs as its items
    Candidate[] public candidates;
    // This will assign the owner of the contract or the comelec
    address public owner;
    // Mapping all the address that votes
    mapping(address => bool) public voters;
    address[] public listOfVoters;

    // Create a voting start and end session
    uint256 public votingStart;
    uint256 public votingEnd;

    // Create an election status
    bool public electionStarted;

    // Create a modifier to restrict creating votes to the comelec
    modifier onlyOwner() {
        require(
            msg.sender == owner,
            "You are not authorized to start an election"
        );
        _;
    }

    // Create a modifier to check if there is an election
    modifier electionOngoing() {
        require(electionStarted, "No election yet");
        _;
    }

    // Set the comelec as the person who deployed the contract
    constructor() {
        owner = msg.sender;
    }

    // Start an election
    function startElection(
        string[] memory _candidates,
        uint256 _votingDuration
    ) public onlyOwner {
        require(electionStarted == false, "Election is currently on Going");
        delete candidates;
        resetAllVoterStatus();

        for (uint256 i = 0; i < _candidates.length; i++) {
            candidates.push(
                Candidate({id: i, name: _candidates[i], numberOfVotes: 0})
            );
        }
        electionStarted = true;
        votingStart = block.timestamp;
        votingEnd = block.timestamp + (_votingDuration * 1 minutes);
    }

    // Add a candidate
    function addCandidate(
        string memory _name
    ) public onlyOwner electionOngoing {
        require(checkElectionPeriod(), "Election period has ended");
        candidates.push(
            Candidate({
                id: candidates.length + 1,
                name: _name,
                numberOfVotes: 0
            })
        );
    }

    // Check voter's status
    function voterStatus(
        address _voter
    ) public view electionOngoing returns (bool) {
        if (voters[_voter] == true) {
            return true;
        }
        return false;
    }

    // To Vote
    function voteTo(uint256 _id) public electionOngoing {
        require(checkElectionPeriod(), "Election period has ended");
        require(
            !voterStatus(msg.sender),
            "You already voted. You can only vote once."
        );
        candidates[_id].numberOfVotes++;
        voters[msg.sender] = true;
        listOfVoters.push(msg.sender);
    }

    // get number of Votes
    function retrieveVotes() public view returns (Candidate[] memory) {
        return candidates;
    }

    // Monitor the election time
    function electionTimer() public view electionOngoing returns (uint256) {
        if (block.timestamp >= votingEnd) {
            return 0;
        }
        return votingEnd - block.timestamp;
    }

    // check if election period is still on going
    function checkElectionPeriod() public returns (bool) {
        if (electionTimer() > 0) {
            return true;
        }
        electionStarted = false;
        return false;
    }

    // reset voter status map
    function resetAllVoterStatus() public onlyOwner {
        for (uint256 i = 0; i < listOfVoters.length; i++) {
            voters[listOfVoters[i]] = false;
        }
        delete listOfVoters;
    }
}