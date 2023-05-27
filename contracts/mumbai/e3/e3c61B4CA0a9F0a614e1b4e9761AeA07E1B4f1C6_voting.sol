// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

contract voting{

    enum electionStatus {NotStarted, Started, Ended}

    struct Candidate {
        string name;
        uint256 totalVotesReceived;
    }

    struct Election {
        string name;
        uint256 status;
        uint256 numCandidates;
        mapping(address => Candidate) candidates;
        mapping(address => bool) hasVoted;
    }

    address public owner;
    mapping(uint256 => Election) public elections;
    uint256 public numElections;

    constructor() {
        owner = msg.sender;
        numElections=0;
    }

    modifier OnlyOwner{
        if(msg.sender == owner) {
            _;
        }
    }

    //CREATE ELECTION
    function createElection(string memory _name) public {
        elections[numElections].name=_name;
        elections[numElections].status=uint256(electionStatus.NotStarted);
        numElections++;
    }

    //REGISTER CANDIDATE
    function registerCandidates(string memory _name, address _candidate ,uint _electionId) public {
        require(elections[_electionId].status == uint256(electionStatus.NotStarted), "Election already Started or Ended");
        require(elections[_electionId].candidates[_candidate].totalVotesReceived == 0, "Candidate already registered");
        require(elections[_electionId].numCandidates < 5, "Max Candidates Reached");
        elections[_electionId].candidates[_candidate] = Candidate(_name, 0);
        elections[_electionId].numCandidates++;
    }

    //SET STATUS
    function setStatus(uint _election_Id) public {
        require(elections[_election_Id].status == uint256(electionStatus.NotStarted) || elections[_election_Id].status == uint256(electionStatus.Started), "Election already Ended");
        if(elections[_election_Id].status == 0) {
            elections[_election_Id].status = 1;
        } else if(elections[_election_Id].status == 1) {
            elections[_election_Id].status = 2;
        }
    }

    //VOTE CANDIDATE
    function vote(address _candidate, uint _electionId) public {
        require(elections[_electionId].status == uint256(electionStatus.Started), "Election is not running/active");
        require(elections[_electionId].candidates[_candidate].totalVotesReceived != 0, "Candidate not registered");
        require(!elections[_electionId].hasVoted[msg.sender], "Voter has already voted");
        elections[_electionId].hasVoted[msg.sender] = true;
        elections[_electionId].candidates[_candidate].totalVotesReceived++;
    }

    //GET ELECTION STATUS
    function getElectionStatus(uint _electionId) public view returns(uint256){        
        return elections[_electionId].status;
    }

    //GET ELECTION RESULTS
    function getElectionResults(uint _electionId, address _candidate) public view returns(Candidate memory){
        require(elections[_electionId].status == uint256(electionStatus.Ended), "Election is not Ended");
        require(elections[_electionId].numCandidates==0, "No Candidates Found");
        return elections[_electionId].candidates[_candidate];
    }
}