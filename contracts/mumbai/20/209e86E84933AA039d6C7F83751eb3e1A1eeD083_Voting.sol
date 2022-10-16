// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.4;

contract Voting {
    uint totalCandidate;
    uint totalVoter;
    uint totalVoted;

    struct Candidate {
        bytes32 candidateName;
        bytes32 partyName;
        uint votes;
    }

    struct Voter {
        // bytes32 name;
        uint candidateVoteId;
        bytes32 votedTo;
        bool voted;
        bool eligible;
    }

    address owner;

    function VotOwner() public {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    function showOwner() public view returns (address) {
        return owner;
    }

    bytes32[] public canArr;
    mapping(uint => Candidate) public candidates;
    //mapping(uint => Candidate[]) public candidates;

    mapping(address => Voter) public voters;
    // Candidate[] public carr;

    event addEvent(uint i);

    function addCandidate(bytes32 _name, bytes32 _party) public onlyOwner {
        uint i = totalCandidate++;
        // candidates[i].push(Candidate(_name, _party, 0));
        candidates[i] = Candidate(_name, _party, 0);
        canArr[i] = _party;
        //carr[i] = 0;
        emit addEvent(i);
    }

    event rightEvent(uint totalVoter);

    function getRightToVote(address voterID) public {
        // check eligible
        require(!voters[voterID].eligible, "Already Eligible");
        require(!voters[voterID].voted, "The voter already voted");
        voters[voterID].eligible = true;
        totalVoter++;
        emit rightEvent(totalVoter);
    }

    event toVoteEvent(uint totalVoted);

    function toVote(uint candidateID) public {
        Voter storage sender = voters[msg.sender];
        require(sender.eligible, "Not Eligible to Vote");
        require(!sender.voted, "Already Voted");

        sender.voted = true;
        sender.votedTo = candidates[candidateID].partyName;
        candidates[candidateID].votes += 1;
        totalVoted += 1;

        emit toVoteEvent(totalVoted);
    }

    function votersLeftTOVote() public view returns (uint) {
        return totalVoter - totalVoted;
    }

    function voterVotedTo() public view returns (bytes32) {
        Voter storage sender = voters[msg.sender];
        return sender.votedTo;
    }

    function getNumOfCandidates() public view returns (uint) {
        return totalCandidate;
    }

    function getNumOfVoters() public view returns (uint) {
        return totalVoter;
    }

    function getList() public view returns (bytes32[] memory) {
        return canArr;
    }

    // function voterName()public returns(uint vvv){
    //     for(uint i=0; i<voters.length; i++){
    //         if(voters[i].voted == true){
    //             vvv = i;
    //         }
    //     }
    // }

    //decide to make is onlyOwner
    function checkWinner() public view returns (uint wins) {
        uint winCount = 0;
        for (uint i = 0; i <= totalCandidate; i++) {
            if (winCount < candidates[i].votes) {
                winCount = candidates[i].votes;
                wins = i;
            }
        }
    }

    function winnerVotes() public view returns (uint vot) {
        vot = candidates[checkWinner()].votes;
    }

    function winnerName() public view returns (bytes32 name) {
        name = candidates[checkWinner()].candidateName;
    }
}