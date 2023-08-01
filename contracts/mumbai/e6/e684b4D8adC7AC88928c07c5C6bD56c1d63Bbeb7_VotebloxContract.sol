/**
 *Submitted for verification at polygonscan.com on 2023-07-31
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

contract VotebloxContract {
    // Struct to represent a candidate
    struct Candidate {
        uint256 orderNumber;
        string name;
    }

    // Struct to represent a vote
    struct Vote {
        bytes32 voterID;
        uint256 candidateIndex;
    }

    // Array to store the list of candidates
    Candidate[] public candidates;

    // Mapping to store votes by voter ID
    mapping(bytes32 => Vote) public votes;

    // Mapping to store registered committee members
    mapping(address => bool) public isCommitteeMember;

    // Mapping to track whether a voter has voted
    mapping(bytes32 => bool) public hasVoted;

    // Mapping to store the vote count for each candidate
    mapping(uint256 => uint256) public candidateVoteCounts;

    // Modifier to check if the sender is a registered committee member
    modifier onlyCommittee() {
        require(isCommitteeMember[msg.sender], "Only registered committee members can cast votes");
        _;
    }

    // Modifier to check if the voter has not voted yet
    modifier onlyOnce(bytes32 _voterID) {
        require(!hasVoted[_voterID], "Voter has already voted");
        _;
    }

    // Modifier to check if the sender is the contract owner
    modifier onlyOwner() {
        require(msg.sender == owner, "Only the contract owner can call this function");
        _;
    }

    // Modifier to check if the voting has started
    modifier votingNotStarted() {
        require(!votingStarted, "Voting has already started");
        _;
    }

    // Modifier to check if the voting has stopped
    modifier votingNotStopped() {
        require(!votingStopped, "Voting has already stopped");
        _;
    }

    // Modifier to check if the voting has started
    modifier votingStartedCheck() {
        require(votingStarted, "Voting has not started yet");
        _;
    }

    address public owner;
    string public votingName; // Name or description of the ongoing voting process
    bool public votingStarted;
    bool public votingStopped;

    event VoteCasted(bytes32 indexed voterID, uint256 candidateIndex);
    event DuplicateVoteAttempt(bytes32 indexed voterID);
    event VotingStarted();
    event VotingStopped();

    // Constructor to set the contract owner and the voting name
    constructor(string memory _votingName) {
        owner = msg.sender;
        votingName = _votingName;
    }

    // Function to add a candidate to the list
    function addCandidate(uint256 _orderNumber, string memory _name) public onlyOwner votingNotStarted {
        candidates.push(Candidate(_orderNumber, _name));
    }

    // Function to remove a candidate from the list
    function removeCandidate(uint256 _candidateIndex) public onlyOwner votingNotStarted {
        require(_candidateIndex < candidates.length, "Invalid candidate index");
        require(_candidateIndex >= 0, "Invalid candidate index");

        // Move the last candidate in the array to the position of the candidate to be removed
        candidates[_candidateIndex] = candidates[candidates.length - 1];
        candidates.pop();
    }

    // Function to register committee members
    function registerCommitteeMember(address _committeeMember) public onlyOwner {
        require(!isCommitteeMember[_committeeMember], "Address is already a committee member");
        isCommitteeMember[_committeeMember] = true;
    }

    // Function to remove committee members
    function removeCommitteeMember(address _committeeMember) public onlyOwner {
        require(isCommitteeMember[_committeeMember], "Address is not a committee member");
        isCommitteeMember[_committeeMember] = false;
    }

    function isVotingStarted() public view returns(bool){
        return votingStarted;
    }

    function isVotingStopped() public view returns(bool){
        return votingStopped;
    }

    // Function to start the voting process
    function startVoting() public onlyOwner votingNotStarted {
        votingStarted = true;
        emit VotingStarted();
    }

    // Function to stop the voting process
    function stopVoting() public onlyOwner votingStartedCheck votingNotStopped {
        votingStopped = true;
        emit VotingStopped();
    }

    // Function to cast a vote by the election committee
    // Function to cast a vote by the election committee
    function castVote(bytes32 _voterID, uint256 _candidateIndex) public onlyCommittee votingStartedCheck onlyOnce(_voterID){
        require(!votingStopped, "Voting has been stopped");
        require(_candidateIndex < candidates.length, "Invalid candidate index");

        // Check if the voter has already voted
        if (hasVoted[_voterID]) {
            // Emit the event to notify that a duplicate vote attempt has been made
            emit DuplicateVoteAttempt(_voterID);
            revert("Voter has already voted");
        }

        // Increment the vote count for the selected candidate
        candidateVoteCounts[_candidateIndex]++;

        votes[_voterID] = Vote(_voterID, _candidateIndex);
        hasVoted[_voterID] = true;

        // Emit the event to notify that a vote has been casted
        emit VoteCasted(_voterID, _candidateIndex);
    }

    // Function to get the candidate information by index
    function getCandidate(uint256 _candidateIndex) public view returns (uint256, string memory) {
        require(_candidateIndex < candidates.length, "Invalid candidate index");

        Candidate memory candidate = candidates[_candidateIndex];
        return (candidate.orderNumber, candidate.name);
    }

    // Function to get the candidate information by order number
    function getCandidateByOrderNumber(uint256 _orderNumber) public view returns (string memory name) {
        require(_orderNumber > 0 && _orderNumber <= candidates.length, "Invalid order number");
        return candidates[_orderNumber - 1].name;
    }

    // Function to get the candidate index for a given voter ID
    function getVote(bytes32 _voterID) public view returns (uint256) {
        return votes[_voterID].candidateIndex;
    }

    // Function to get the number of candidates
    function getNumberOfCandidates() public view returns (uint256) {
        return candidates.length;
    }

    function getVotesForCandidate(uint256 candidateIndex) public view returns (uint256) {
        require(candidateIndex < candidates.length, "Invalid candidate index");
        return candidateVoteCounts[candidateIndex];
    }

    function getVotingResult() public view returns (string memory winnerName, uint256 winnerOrderNumber, uint256 winnerVotes) {
        require(candidates.length > 0, "No candidates registered.");

        // Initialize variables to track the winner and their votes
        uint256 maxVotes = 0;
        uint256 winningCandidateIndex = 0;

        // Iterate through all candidates to find the winner
        for (uint256 i = 0; i < candidates.length; i++) {
            uint256 candidateVotes = getVotesForCandidate(i);
            if (candidateVotes > maxVotes) {
                maxVotes = candidateVotes;
                winningCandidateIndex = i;
            }
        }

        // Get the winner's information
        (uint256 orderNumber, string memory name) = getCandidate(winningCandidateIndex);
        winnerName = name;
        winnerOrderNumber = orderNumber;
        winnerVotes = maxVotes;
    }

    // Function to get the voting result with ordered candidates based on vote counts
    function getOrderedVotingResult() public view returns (string[] memory candidateNames, uint256[] memory candidateOrderNumbers, uint256[] memory voteCounts) {
        uint256 numCandidates = candidates.length;
        require(numCandidates > 0, "No candidates registered.");

        candidateNames = new string[](numCandidates);
        candidateOrderNumbers = new uint256[](numCandidates);
        voteCounts = new uint256[](numCandidates);

        // Get the vote counts for each candidate and populate the arrays
        for (uint256 i = 0; i < numCandidates; i++) {
            (uint256 orderNumber, string memory name) = getCandidate(i);
            candidateNames[i] = name;
            candidateOrderNumbers[i] = orderNumber;
            voteCounts[i] = getVotesForCandidate(i);
        }

        // Perform bubble sort to order candidates based on vote counts (descending order)
        for (uint256 i = 0; i < numCandidates - 1; i++) {
            for (uint256 j = 0; j < numCandidates - i - 1; j++) {
                if (voteCounts[j] < voteCounts[j + 1]) {
                    // Swap the candidates and their vote counts
                    (voteCounts[j], voteCounts[j + 1]) = (voteCounts[j + 1], voteCounts[j]);
                    (candidateNames[j], candidateNames[j + 1]) = (candidateNames[j + 1], candidateNames[j]);
                }
            }
        }
    }
}