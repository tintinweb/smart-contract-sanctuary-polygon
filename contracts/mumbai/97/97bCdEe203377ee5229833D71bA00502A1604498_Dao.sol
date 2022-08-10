// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface IdaoContract {
    function balanceOf(address, uint256) external view returns (uint256);
}

contract Dao {
    
    address public owner;
    uint256 nextProposal;
    uint256[] public validTokens;
    IdaoContract daoContract;

    constructor(){
        owner = msg.sender;
        nextProposal = 1;
        daoContract = IdaoContract(0x2953399124F0cBB46d2CbACD8A89cF0599974963);
        validTokens = [111971127743115773933156899486683070662051120133998587769265069859404540543076];
    }

    struct proposal {
        uint256 id;
        bool exists;
        string description;
        uint deadline;
        uint256 votesUp;
        uint256 votesDown;
        address[] canVote;
        uint256 maxVotes;
        mapping(address => bool) voteStatus;
        bool countConducted;
        bool passed;
    }

    mapping(uint256 => proposal) public Proposals;

    event proposalCreated(
        uint256 id, 
        string description, 
        uint256 maxVotes, 
        address proposer
    );

    event newVote(
        uint256 votesUp, 
        uint256 votesDown,
        address voter, 
        uint256 proposal,
        bool votedFor
    );

    event proposalCount(
        uint256 id, 
        bool passed
    );

    function checkProposalEligibility(address _proposalist) private view returns (
        bool
    ){
        for(uint i = 0; i < validTokens.length; i++){
            if(daoContract.balanceOf(_proposalist, validTokens[i]) >= 1){
                return true;
            }
        }
        return false;
    }

    function checkVoteEligibility(uint256 _proposalId, address _voter) private view returns (
        bool
    ){
        for(uint256 i = 0; i < Proposals[_proposalId].canVote.length; i++){
            if(Proposals[_proposalId].canVote[i] == _voter){
                return true;
            }
        }  
        return false;
    }

    function createProposal(string memory _description, address[] memory _canVote) public {
        require(checkProposalEligibility(msg.sender), "Only NFT holders can put forth Proposals");

        proposal storage newProposal = Proposals[nextProposal];
        newProposal.id = nextProposal;
        newProposal.exists = true;
        newProposal.description = _description;
        newProposal.deadline = block.number + 100;
        newProposal.canVote = _canVote;
        newProposal.maxVotes = _canVote.length;

        emit proposalCreated(nextProposal, _description, _canVote.length, msg.sender);
        nextProposal++;
    }

    function voteOnProposal(uint256 _proposalId, bool _vote) public {
        require(Proposals[_proposalId].exists, "This Proposal does not exist");
        require(checkVoteEligibility(_proposalId, msg.sender), "You can not vote on this Proposal");
        require(!Proposals[_proposalId].voteStatus[msg.sender], "You have already voted on this Proposal");
        require(block.number <= Proposals[_proposalId].deadline, "The deadline has passed for this Proposal");

        proposal storage p = Proposals[_proposalId];

        if(_vote){
            p.votesUp++;
        }else{
            p.votesDown++;
        }

        p.voteStatus[msg.sender] = true;

        emit newVote(p.votesUp, p.votesDown, msg.sender, _proposalId, _vote);
    }

    function countVotes(uint256 _proposalId) public {
        require(msg.sender == owner, "Only owner can count votes");
        require(Proposals[_proposalId].exists, "This proposal does not exist");
        require(block.number > Proposals[_proposalId].deadline, "Voting has not concluded");
        require(!Proposals[_proposalId].countConducted, "Count already conducted");

        proposal storage p = Proposals[_proposalId];

        if(Proposals[_proposalId].votesDown < Proposals[_proposalId].votesUp){
            p.passed = true;
        }

        p.countConducted = true;

        emit proposalCount(_proposalId, p.passed);
    }

    function addTokenId(uint256 _tokenId) public {
        require(msg.sender == owner, "Only owner can add tokens");

        validTokens.push(_tokenId);
    }
}