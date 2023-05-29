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
        uint256 totalVotes;
        mapping(address => Candidate) candidates;
        mapping(address => bool) hasVoted;
    }
    address[] public candiateList;

    address public owner;
    mapping(string => Election) public elections;
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
    function createElection(string memory _name,string memory _election_id) public {
        elections[_election_id].name=_name;
        elections[_election_id].hasVoted[msg.sender]=false;
        elections[_election_id].status=uint256(electionStatus.NotStarted);
        numElections++;
    }

    //REGISTER CANDIDATE
    function registerCandidates(string memory _name, address _candidate ,string memory _electionId) public {
        require(elections[_electionId].status == uint256(electionStatus.NotStarted), "Election already Started or Ended");
        require(elections[_electionId].candidates[_candidate].totalVotesReceived == 0, "Candidate already registered");
        require(elections[_electionId].numCandidates < 5, "Max Candidates Reached");
        elections[_electionId].candidates[_candidate] = Candidate(_name, 0);
        candiateList.push(_candidate);
        elections[_electionId].numCandidates++;
    }

    //SET STATUS
    function setStatus(string memory _election_Id) public {
        require(elections[_election_Id].status == uint256(electionStatus.NotStarted) || elections[_election_Id].status == uint256(electionStatus.Started), "Election already Ended");
        if(elections[_election_Id].status == 0) {
            elections[_election_Id].status = 1;
        } else if(elections[_election_Id].status == 1) {
            elections[_election_Id].status = 2;
        }
    }


    //VOTE CANDIDATE
    function vote(address _candidate, string memory _electionId) public {
        require(elections[_electionId].status == uint256(electionStatus.Started), "Election is not running/active");
        require(!elections[_electionId].hasVoted[msg.sender], "Voter has already voted");
        elections[_electionId].hasVoted[msg.sender] = true;
        elections[_electionId].candidates[_candidate].totalVotesReceived++;
        elections[_electionId].totalVotes++;
    }

    //Check isVoted
    function isVoted(string memory _electionId, address _voter) public view returns(bool){
        return elections[_electionId].hasVoted[_voter];
    }

    //GET ELECTION STATUS
    function getElectionStatus(string memory _electionId) public view returns(uint256){        
        return elections[_electionId].status;
    }
    //result strucure
    struct Result{
        address candidate;
        string name;
        uint256 totalVotesReceived;
    }

    //GET ELECTION RESULTS
    function getElectionResults(string memory _electionId) public view returns(Result[] memory){
        // require(elections[_electionId].status == uint256(electionStatus.Ended), "Election is not Ended");
        // require(elections[_electionId].numCandidates==0, "No Candidates Found");
        Result[] memory results=new Result[](candiateList.length);
        for(uint i=0;i<candiateList.length;i++){
            Result memory result;
            result.candidate=candiateList[i];
            result.name=elections[_electionId].candidates[candiateList[i]].name;
            result.totalVotesReceived=elections[_electionId].candidates[candiateList[i]].totalVotesReceived;
            results[i]=result;
        }
        return results;
    }

    //GET CANDIADTE
    function getCandidate(string memory _electionId, address _candidate) public view returns(Candidate memory){
        return elections[_electionId].candidates[_candidate];
    }

    //Total votes in a election
    function getTotalVotes(string memory _electionId) public view returns(uint256){
        return elections[_electionId].totalVotes;
    }
}