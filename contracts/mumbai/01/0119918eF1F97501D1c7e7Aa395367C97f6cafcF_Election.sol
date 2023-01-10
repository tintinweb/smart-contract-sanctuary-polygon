// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

// Uncomment this line to use console.log
// import "hardhat/console.sol";

contract Election {
    struct Candidate {
        string name;
        uint numVotes;
    }

    struct Voter {
        string name;
        bool authorised;
        uint whom;
        bool voted;
    }

    address public owner;

    string public electionName;

    mapping(address => Voter) public voters;
    Candidate[] public candidates;
    uint public totalVotes;

    modifier ownerOnly() {
        require(msg.sender == owner);
        _;
    }

    function startElection(string memory _elctionName) public {
        owner = msg.sender;
        electionName = _elctionName;
    }

    function addCandidate(string memory _candidateName) public ownerOnly {
        candidates.push(Candidate(_candidateName, 0));
    }

    function authorizeVoter(address _voterAddress) public ownerOnly {
        voters[_voterAddress].authorised = true;
    }

    function getNumCandidates() public view returns (uint) {
        return candidates.length;
    }

    function Vote(uint candidateIndex) public {
        require(!voters[msg.sender].voted);
        require(!voters[msg.sender].authorised);
        voters[msg.sender].whom = candidateIndex;
        voters[msg.sender].voted = true;

        candidates[candidateIndex].numVotes++;
    }

    function getTotalVotes() public view returns (uint) {
        return totalVotes;
    }

    function candidateInfo(uint index) public view returns (Candidate memory) {
        return candidates[index];
    }
}