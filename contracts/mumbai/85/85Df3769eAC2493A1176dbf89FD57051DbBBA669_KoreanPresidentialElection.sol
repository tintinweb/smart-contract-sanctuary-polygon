pragma solidity ^0.8.0;

contract KoreanPresidentialElection {
    
    struct Candidate {
        string name;
        uint256 voteCount;
    }
    
    struct Election {
        string name; // Added name field to specify the name of the election
        mapping(address => bool) voters;
        mapping(uint256 => Candidate) candidates;
        uint256 totalCandidates;
        bool electionClosed;
    }
    
    mapping(uint256 => Election) public elections;
    uint256 public totalElections;
    address public admin;
    
    constructor() {
        totalElections = 0;
        admin = msg.sender; // Set the contract deployer as the admin
    }
    
    modifier onlyAdmin() {
        require(msg.sender == admin, "Only admin can perform this action");
        _;
    }
    
    function createElection(string memory _name) external onlyAdmin { // Added name field to specify the name of the election
        Election storage newElection = elections[totalElections + 1];
        newElection.name = _name;
        newElection.totalCandidates = 0;
        newElection.electionClosed = false;
        totalElections++;
    }
    
    function addCandidate(uint256 _electionId, string memory _name) external onlyAdmin {
        Election storage election = elections[_electionId];
        require(!election.electionClosed, "Election is closed");
        Candidate storage newCandidate = election.candidates[election.totalCandidates + 1];
        newCandidate.name = _name;
        newCandidate.voteCount = 0;
        election.totalCandidates++;
    }
    
    function vote(uint256 _electionId, uint256 _candidateId) external {
        Election storage election = elections[_electionId];
        require(!election.electionClosed, "Election is closed");
        require(!election.voters[msg.sender], "Already voted");
        Candidate storage candidate = election.candidates[_candidateId];
        candidate.voteCount++;
        election.voters[msg.sender] = true;
    }
    
    function closeElection(uint256 _electionId) external onlyAdmin {
        Election storage election = elections[_electionId];
        require(!election.electionClosed, "Election is already closed");
        election.electionClosed = true;
    }
    
    function getCandidate(uint256 _electionId, uint256 _candidateId) external view returns (string memory, uint256) {
        Election storage election = elections[_electionId];
        Candidate storage candidate = election.candidates[_candidateId];
        return (candidate.name, candidate.voteCount);
    }
    
    function getTotalCandidates(uint256 _electionId) external view returns (uint256) {
        Election storage election = elections[_electionId];
        return election.totalCandidates;
    }
    
    function getElectionStatus(uint256 _electionId) external view returns (bool) {
        Election storage election = elections[_electionId];
        return election.electionClosed;
    }
    
    function hasVoted(uint256 _electionId, address _voter) external view returns (bool) {
        Election storage election = elections[_electionId];
        return election.voters[_voter];
    }
    
    function getElections(uint256 _electionId) external view returns (string memory, uint256, bool) {
        Election storage election = elections[_electionId];
        return (election.name, election.totalCandidates, election.electionClosed);
    }
    
    function getCandidates(uint256 _electionId) external view returns (string[] memory) {
        Election storage election = elections[_electionId];
        string[] memory candidateNames = new string[](election.totalCandidates);
        for(uint256 i = 0; i < election.totalCandidates; i++) {
            candidateNames[i] = election.candidates[i + 1].name;
        }
        return candidateNames;
    }
}