// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

contract Voting {
    // Create a structure template for each of the candidates
    struct Candidate {
        uint256 id;
        string name;
        uint256 numberOfVotes;
    }
    // List of all candidates
    Candidate[] public candidates;
    // This will be the owner's address
    address public owner;
    // Mapp all voters' addresses
    mapping(address => bool) public voters;
    // List of voters
    address[] public listOfVoters;

    // Create a voting start and end session
    uint256 public votingStart;
    uint256 public votingEnd;

    // Create an election status
    bool public electionStarted;

    // Restrict creating election to the owner only
    modifier onlyOwner() {
        require(
            msg.sender == owner,
            "You are not authorized to start an election"
        );
        _;
    }

    // Check if an election is ongoing
    modifier electionOngoing() {
        require(electionStarted, "No election yet");
        _;
    }

    // create a constructor
    constructor() {
        owner = msg.sender;
    }

    // to start an election
    function startElection(
        string[] memory _candidates,
        uint256 _votingDuration
    ) public onlyOwner {
        require(electionStarted == false, "Election is currently ongoing");
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

    // to add a new candidate
    function addCandidate(
        string memory _name
    ) public onlyOwner electionOngoing {
        require(checkElectionPeriod(), "Election period has ended");
        candidates.push(
            Candidate({id: candidates.length, name: _name, numberOfVotes: 0})
        );
    }

    // check voter's status
    function voterStatus(
        address _voter
    ) public view electionOngoing returns (bool) {
        if (voters[_voter] == true) {
            return true;
        }
        return false;
    }

    // to vote function
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

    // get the number of Votes
    function retrieveVotes() public view returns (Candidate[] memory) {
        return candidates;
    }

    // monitor the election time
    function electionTimer() public view returns (uint256) {
        if (block.timestamp >= votingEnd) {
            return 0;
        }
        return (votingEnd - block.timestamp);
    }

    // check if election period is still ongoing
    function checkElectionPeriod() public returns (bool) {
        if (electionTimer() > 0) {
            return true;
        }
        electionStarted = false;
        return false;
    }

    // reset all voters status
    function resetAllVoterStatus() public onlyOwner {
        for (uint256 i = 0; i < listOfVoters.length; i++) {
            voters[listOfVoters[i]] = false;
        }
        delete listOfVoters;
    }
}