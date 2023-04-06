//SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;
contract Voting{
    address public electionOrganizer;
    uint id=1;
    bool public electionStarted=false;
    bool public electionEnded=false;
    uint public allowed=0;
    struct Candidate{
        uint candidateId;
        string candidateName;
        uint candidateAge;
        string partyName;
        address candiadateAddress;
        uint    votesRececieved;
    }
    mapping(address=>bool) public candidateExists;
    address[] public allCandidateAddresses;
    mapping(address=>Candidate) public candidates;

    struct  Voter {
        uint voterId;
        string voterName;
        address voterAddress;
        uint voterAge;
        uint votedTo;
        bool hasVoted;
    }
    address[] public allVoterAddresses;
    address[] public votedList;
    mapping(address=>Voter) public voters;

    constructor(){
        electionOrganizer=msg.sender;
        
    }
    modifier isElectionOrganizer(){
        _;
        require(msg.sender==electionOrganizer,"Only election organizer is allowed");
    }
    modifier electionHasStarted(){
        _;
        require(electionStarted,"Election not started yet");
    }
  
    function startVoting() public isElectionOrganizer{
        electionStarted=true;
    }
       function endVoting() public isElectionOrganizer{
        electionEnded=true;
        electionStarted=false;
    }
    function setCandidate(string memory _name, uint _age, string memory _partyName, address _address) public isElectionOrganizer{
        require(!candidateExists[_address],"Already candidate exists");
        Candidate storage candidate=candidates[_address] ;
        id=id+1;
        candidate.candidateId=id;
        candidate.candidateName=_name;
        candidate.candidateAge=_age;
        candidate.partyName=_partyName;
        candidate.candiadateAddress=_address;
        allCandidateAddresses.push(_address);
        candidateExists[_address]=true;
    }
   
    function addVoter(string memory _name,uint _age,address _address) public isElectionOrganizer{
        require(_age>=18,"Not eligible to vote");
        id=id+1;
        Voter storage voter = voters[_address];
        voter.voterId=id;
        voter.voterName=_name;
        voter.voterAge=_age;
        voter.voterAddress=_address;
        voter.hasVoted=false;
        allVoterAddresses.push(_address);
    }   
    function voteTo(uint _candidateId, address _candidateAddress) public electionHasStarted  {
        require(msg.sender!=electionOrganizer,"Organizer can't vote");
        Voter storage voter=voters[msg.sender];
        voter.votedTo=_candidateId;
        require(!voter.hasVoted,"Already Voted");
        candidates[_candidateAddress].votesRececieved+=1;
        voter.hasVoted=true;
        votedList.push(msg.sender);
        allowed=1;
        
    }
     function getCandidateVotes(address _candidateAdress)public view returns (uint) {
       return candidates[_candidateAdress].votesRececieved;
    }
   
    function showWinner() public view returns(address)   {
        uint256 winningVotes = 0;
        uint256 winningCandidateIndex = 0;
        require(electionEnded,"Election didn't end");
        for (uint256 i = 0; i < allCandidateAddresses.length; i++) {
            if (candidates[allCandidateAddresses[i]].votesRececieved > winningVotes) {
                winningVotes = candidates[allCandidateAddresses[i]].votesRececieved;
                winningCandidateIndex = i;
            }
        }  
        
         return allCandidateAddresses[winningCandidateIndex];
    }
}