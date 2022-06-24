//SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

interface IdaoContract{
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
        validTokens = [50339288417056221045414187304347026307671309564300934784097246832678938869761];
    }

    struct proposal {
        uint256 id;
        bool exists;
        string description;
        uint256 votesUp;
        uint256 votesDown;
        address[] canVote;
        uint256 maxVotes;
        mapping(address => bool) voteStatus;
        bool countConducted;
        bool passed;
        uint256 deadLine;
    }

    mapping(uint256 => proposal) public Proposals;

    event propsalCreated(
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

    function checkProposalEligibility(address _user) private view returns (bool){
        for(uint i=0; i < validTokens.length; i++){
            if(daoContract.balanceOf(_user, validTokens[i]) >= 1){
                return true;
            }
        }
        return false;
    }

    function checkVoteEligibility(uint256 _proposalId, address _voter) private view returns (bool) {
        for(uint256 i = 0; i < Proposals[_proposalId].canVote.length; i++){
            if(Proposals[_proposalId].canVote[i] == _voter){
                return true;
            }
        }
        return false;
    }

    function createProposal(string memory _description, address[] memory _canVote ) public {
        require(checkProposalEligibility(msg.sender), "Only NFT holders can initiate Proposals");

        proposal storage newProposal = Proposals[nextProposal];
        newProposal.id = nextProposal;
        newProposal.exists = true;
        newProposal.description = _description;
        newProposal.deadLine = block.number + 100;
        newProposal.canVote = _canVote;
        newProposal.maxVotes = _canVote.length;

        emit propsalCreated(nextProposal, _description, _canVote.length, msg.sender);
        nextProposal++;
    }

    function voteOnProposal(uint256 _proposalId, bool _vote) public {
        require(Proposals[_proposalId].exists, "This Propsal does not exists");
        require(checkVoteEligibility(_proposalId, msg.sender), "You can not vote on this Propsal");
        require(!Proposals[_proposalId].voteStatus[msg.sender], "You have already voted on this Propsal");
        require(block.number <= Proposals[_proposalId].deadLine, "The deadline has passed for this Proposal");

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
        require(msg.sender == owner, "Only Owner can count Votes");
        require(Proposals[_proposalId].exists, "This Propsal does not exist");
        require(block.number > Proposals[_proposalId].deadLine, "Voting has not concluded");
        require(!Proposals[_proposalId].countConducted, "Count already conducted");

        proposal storage p = Proposals[_proposalId];

        if(p.votesDown < p.votesUp){
            p.passed = true;
        }

        p.countConducted = true;

        emit proposalCount(_proposalId, p.passed);

    }

    function addTokenId(uint256 _tokenId) public {
        require(msg.sender == owner,"Only Owner can add token");
        validTokens.push(_tokenId);
    }
}