/**
 *Submitted for verification at polygonscan.com on 2023-05-02
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

contract Voting {

    struct Candidate {
        string name;
        string party;
        string imageUri;
    }

    struct Voter{
        string name;
        uint cnic;
        uint qr;
        bool casted;
    }


    mapping(address => Candidate) public candidates;
    mapping(address => Voter) public voters;
    mapping (address => bool) private verifyCandidate;
    mapping (address => bool) private verifyVoter;
    uint256 public candidateCount;
    uint256 public voterCount;

    address public owner;

    mapping(address => uint256) public votes;
    uint256 public totalVotes;

    constructor() {
        owner = msg.sender;
    }

    function addCandidate(address _address, string calldata name, string calldata party, string calldata imageUri) public {
        require(owner == msg.sender, "Not the owner of the contract");
        require(verifyCandidate[msg.sender] == false, "Already Candidate");
        candidateCount++;
        Candidate memory person = Candidate({ name: name, party: party, imageUri: imageUri});
        candidates[_address] = person;
        verifyCandidate[_address] = true;
    }

    function addVoter(address _address, string calldata _name, uint _cnic, uint _qr) public {
        require(owner == msg.sender, "Not the owner of the contract");
        require(verifyVoter[msg.sender] == false, "Already Voter");
        voterCount++;
        Voter memory newVoter = Voter({ name: _name, cnic: _cnic, qr: _qr , casted: false});
        voters[_address] = newVoter;
        verifyVoter[msg.sender] = true;
    }

    function vote(address _candidate) public {
        require(verifyCandidate[_candidate] == true, "Not A Candidate");
        require(verifyVoter[msg.sender] == true, "Not registered as Voter");
        require(voters[msg.sender].casted == false, "Already Casted Vote!!!");
        voters[msg.sender].casted = true;
        votes[_candidate]++;
        totalVotes++;
    }

}