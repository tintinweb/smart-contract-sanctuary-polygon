// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;
import "./VoterRegistration.sol";

contract Voting is VoterRegistration {

    struct Candidate {
        uint256 id;
        string name;
        uint256 voteCount;
        uint256 femaleVoteCount;
        Gender gender;
    }

    address public administrator;
    mapping(uint256 => Candidate) public candidates;
    uint256 public candidateCount;
    uint256 public femaleCandidateCount;
    uint256 public femaleElectedCount;
    uint256 public votingStartTime;
    uint256 public votingEndTime;
    bool public votingEnded;
    mapping(address => bool) public hasVoted;

    // set up events of counting votes and adding candidates
    event Voted(uint256 candidateId);
    event CandidateAdded(uint256 candidateId, string name, Gender gender);

    modifier onlyAdministrator() {
        require(msg.sender == administrator, "Only the administrator can call this function");
        _;
    }

    // set the modifier that voters can only vote when the voting start
    modifier isVotingOpen() {
        require(block.timestamp >= votingStartTime && block.timestamp <= votingEndTime, "Voting is not currently open");
        _;
    }

    constructor() {
        administrator = msg.sender;
    }

    // function to set up voting
    function setupVoting(uint256 _startTime, uint256 _endTime, string[] memory candidateNames, Gender[] memory candidateGenders) public onlyAdministrator {
        require(candidateNames.length == candidateGenders.length, "Names and genders arrays must be of the same length");
        require(_startTime >= block.timestamp, "Start time must be in the future");
        require(_endTime > _startTime, "End time must be after start time");

        votingStartTime = _startTime;
        votingEndTime = _endTime;

        for(uint i = 0; i < candidateNames.length; i++) {
            addCandidate(candidateNames[i], candidateGenders[i]);
        }
    }

    // function to add candidates
    function addCandidate(string memory _name, Gender _gender) public onlyAdministrator {
        candidateCount++;
        candidates[candidateCount] = Candidate(candidateCount, _name, 0, 0, _gender);
        emit CandidateAdded(candidateCount, _name, _gender);
        if (_gender == Gender.Female) {
            femaleCandidateCount++;
        }
    }

    // function to vote
    function vote(uint256 _candidateId) public isVotingOpen {
        require(voters[msg.sender].isRegistered, "Not a registered voter");
        require(!hasVoted[msg.sender], "Voter has already voted");
        require(_candidateId > 0 && _candidateId <= candidateCount, "Invalid candidate");

        candidates[_candidateId].voteCount++;
        if (voters[msg.sender].gender == Gender.Female) {
            candidates[_candidateId].femaleVoteCount++;
        }

        emit Voted(_candidateId);
        hasVoted[msg.sender] = true;
    }

    // voting end
    function endVoting() public onlyAdministrator {
        require(block.timestamp > votingEndTime, "Voting has not yet ended");

        for (uint i = 1; i <= candidateCount; i++) {
            if (candidates[i].voteCount > candidates[femaleElectedCount].voteCount && candidates[i].gender == Gender.Female) {
                femaleElectedCount = i;
            }
        }

        votingEnded = true;
    }

    // get result of how many females are elected
    function getFemaleElected() public view returns (string memory) {
        return candidates[femaleElectedCount].name;
    }

    // get results of total number of votes
    function getTotalVotes() public view returns (uint256) {
        uint256 totalVotes = 0;
        for (uint i = 1; i <= candidateCount; i++) {
            totalVotes += candidates[i].voteCount;
        }
        return totalVotes;
    }

    // Function to calculate and return the percentage of votes a candidate has received.
    // This can be useful in monitoring and evaluating the progress of the voting process.
    // It receives the candidate ID as an argument and returns the percentage of total votes the candidate has.
    function getCandidateVotePercent(uint256 _candidateId) public view returns (uint256) {
        // It calculates the percentage by dividing the candidate's vote count by the total votes and then multiplying by 100.
        // Note that the result will be an integer based on properties of solidity.
        return (candidates[_candidateId].voteCount * 100) / getTotalVotes();
    }

    // Function to return an array of all candidates
    // This can be used for transparency and accountability, allowing anyone to see the full list of candidates.
    function getAllCandidates() public view returns (Candidate[] memory) {
        // We first create a new dynamic array of type Candidate with a size equal to the candidate count.
        Candidate[] memory candidateArray = new Candidate[](candidateCount);

        // Then we iterate over the mapping of candidates and add each one to the new array.
        for (uint i = 1; i <= candidateCount; i++) {
            candidateArray[i-1] = candidates[i];
        }

        // Finally, we return the array.
        return candidateArray;
    }

}