// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

contract VotingSystem {
    address public owner;
    struct Proposal {
        string question;
        uint256 yesVotes;
        uint256 noVotes;
    }

    Proposal[] public proposals;
    mapping(uint256 => mapping(address => bool)) public hasVoted;
    mapping(address => bool) public canVote;
    mapping(address => bool) public cannotVote;

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only contract owner can perform this action.");
        _;
    }

    function createProposal(string memory _question) public {
        proposals.push(Proposal({
            question: _question,
            yesVotes: 0,
            noVotes: 0
        }));
    }
    
    function vote(uint256 _proposalIndex, bool _voteYes) public{
        require(canVote[msg.sender], "You do not have the authority to vote.");
        require(!cannotVote[msg.sender],"Your voting rights have been removed by the owner");
        require(!hasVoted[_proposalIndex][msg.sender], "You have already voted.");
        if(_voteYes){
            proposals[_proposalIndex].yesVotes +=1;
        }else{
            proposals[_proposalIndex].noVotes +=1;
        }

        hasVoted[_proposalIndex][msg.sender] = true;
    }

    function getProposalResult(uint256 _proposalIndex) public view returns(string memory,uint256, uint256){
        return(
            proposals[_proposalIndex].question,
            proposals[_proposalIndex].yesVotes,
            proposals[_proposalIndex].noVotes
        );
    }

    function grantVotingPower(address _address) public onlyOwner {
        canVote[_address] = true;
        cannotVote[_address] = false;
    }

    function revokeVotingPower(address _address) public onlyOwner {
        canVote[_address] = false;
        cannotVote[_address] = true;
    }

    function getVotingPowerList() public view onlyOwner returns(address[] memory) {
        address[] memory votingPowerList = new address[](proposals.length);
        uint256 index = 0;
        for (uint256 i = 0; i < votingPowerList.length; i++) {
            if (canVote[votingPowerList[i]]) {
                votingPowerList[index] = votingPowerList[i];
                index++;
            }
        }
        return votingPowerList;
    }

    function getNonVotingList() public view onlyOwner returns(address[] memory) {
        address[] memory nonVotingList = new address[](proposals.length);
        uint256 index = 0;
        for (uint256 i = 0; i < nonVotingList.length; i++) {
            if (cannotVote[nonVotingList[i]]) {
                nonVotingList[index] = nonVotingList[i];
                index++;
            }
        }
        return nonVotingList;
    }
}