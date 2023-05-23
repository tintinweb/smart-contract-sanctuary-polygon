/**
 *Submitted for verification at polygonscan.com on 2023-05-22
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

contract Voting {

    struct Candidate {
        uint256 id;
        string name;
        string party;
        string imageUri;
        uint256 votes;
    }

    struct Voter{
        string name;
        uint256 cnic;
        uint256 qr;
        bool casted;
    }

    uint256[] private candidateIds;
    Candidate[] private resultData;
    mapping(uint256 => Candidate) private candidates;
    mapping(uint256 => Voter) private voters;
    mapping (uint256 => bool) private verifyCandidate;
    mapping (uint256 => bool) private verifyVoter;
    uint256 public candidateCount;
    uint256 public voterCount;

    address public owner;
    bool public electionStarted;

    mapping(uint256 => uint256) private votes;
    uint256 public totalVotes;

    constructor() {
        owner = msg.sender;
    }

    function startElection() public
    {
        require(owner == msg.sender, "Not the owner of the contract");
        require(electionStarted == false, "Election already started!!");
        electionStarted = true;
    }

    function stopElection() public
    {
        require(owner == msg.sender, "Not the owner of the contract");
        require(electionStarted == true, "Election Not Started!!!");
        electionStarted = false;
        for (uint256 i = 0; i< candidateIds.length ;i++)
        {
            Candidate memory person = Candidate({id: candidateIds[i],
                                                name: candidates[candidateIds[i]].name,
                                                party: candidates[candidateIds[i]].party,
                                                imageUri: candidates[candidateIds[i]].imageUri,
                                                votes: candidates[candidateIds[i]].votes});

            resultData.push(person);
        }
    }

    function addCandidate(uint256 _id, string calldata _name, string calldata _party, string calldata _imageUri) public {
        require(owner == msg.sender, "Not the owner of the contract");
        require(verifyCandidate[_id] == false, "Already Candidate");
        candidateCount++;
        Candidate memory person = Candidate({id: _id, name: _name, party: _party, imageUri: _imageUri, votes:0});
        candidates[_id] = person;
        candidateIds.push(_id);
        verifyCandidate[_id] = true;
    }

    function addVoter(uint256 _id, string calldata _name, uint _cnic, uint _qr) public {
        require(owner == msg.sender, "Not the owner of the contract");
        require(verifyVoter[_id] == false, "Already Voter");
        voterCount++;
        Voter memory newVoter = Voter({ name: _name, cnic: _cnic, qr: _qr , casted: false});
        voters[_id] = newVoter;
        verifyVoter[_id] = true;
    }

    function vote(uint256 _candidateId, uint256 _voterId) public {
        require(electionStarted == true, "Election Not Started!!!");
        require(verifyCandidate[_candidateId] == true, "Not A Candidate");
        require(verifyVoter[_voterId] == true, "Not registered as Voter");
        require(voters[_voterId].casted == false, "Already Casted Vote!!!");
        voters[_voterId].casted = true;
        votes[_candidateId]++;
        candidates[_candidateId].votes += 1;
        totalVotes++;
    }

    function getResult() external view returns (Candidate[] memory)
    {
        require(electionStarted == false, "Election not yet Ended!!");
        return (resultData);
    }

    function getCandidateDetailsByID (uint256 _id
    ) external view returns ( uint256, string memory, string memory, string memory, uint256)
    {
        return (candidates[_id].id, candidates[_id].name, candidates[_id].party, candidates[_id].imageUri, candidates[_id].votes);
    }

    

}