/**
 *Submitted for verification at polygonscan.com on 2023-06-02
*/

//SPDX-License-Identifier:MIT

pragma solidity ^0.8.9;

contract Voting{
    address public owner;
    uint256 public uniqueCandidateId;
    struct Candidate{
        uint256 Id;
        string name;
        uint age;
        uint256 noOfCount;
    }

    mapping(uint256=> Candidate)public candidateDetails;
    mapping(address=> bool) public Voters;
    mapping(address=>bool) public isVoted;
    modifier _onlyOwner{
        require(owner==msg.sender,"Only owner can register the candidate");
        _;
    }
    constructor(){
        owner=msg.sender;
    }

    function registerTheCandidate(string memory _name,uint _age) public  {
        require(_age>=35,"Age should be above 35");
        uint256 candidateId=generateCandidateId();
        candidateDetails[candidateId]=Candidate(candidateId,_name,_age,0);
    }

    function generateCandidateId() private returns(uint256){
        return uniqueCandidateId++;
    }

    function registerVoter() public {
        require(!Voters[msg.sender],"You have already registered as a voter");
        Voters[msg.sender]=true;
    }


    function castVote(uint256 _candidateId) public {
        require(_candidateId<=uniqueCandidateId,"No candidate found with that ID");
        require(Voters[msg.sender],"You are not registered as a voter");
        require(!isVoted[msg.sender],"You have already Voted");
        candidateDetails[_candidateId].noOfCount++;
        isVoted[msg.sender]=true;
    }

    function getWinnerCandidate() public _onlyOwner returns (uint256) {
        uint256 voteCount=0;
        uint256 winnerCandidateId=0;
        for(uint i=0;i<generateCandidateId();i++){
            if(candidateDetails[i].noOfCount > voteCount){
                voteCount=candidateDetails[i].noOfCount;
                winnerCandidateId=candidateDetails[i].Id;
            }
        }
        return winnerCandidateId;
    }

}