// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

interface DAOContaract{
    function balanceOf(address, uint256) external view returns (uint256);
}

contract BreakTheSilence{
    address public owner;
    uint256 public count;
    uint256[] public validToken;
    DAOContaract daoContract;

    constructor(){
        owner=msg.sender;
        count=1;
        daoContract=DAOContaract(0x2953399124F0cBB46d2CbACD8A89cF0599974963);
        validToken=[95032267718629296870623058939124075516787682296016123954102296925738549379084];
    }

    struct proposal{
        uint256 id;
        string description;
        bool exists;
        uint256 deadline;
        uint256 votesUp;
        uint256 votesDown;
        uint256 maxVotes;
        mapping(address=> bool) voteStatus;
        bool countConducted;
        bool passed;
    }

    mapping (uint256=> proposal) public Proposals;

    event ProposalCreated(
        uint256 id,
        string description,
        uint256 maxVotes,
        address proposer
    );

    event newVote(
        uint256 votesUp,
        uint256 votesDown,
        uint256 proposal,
        bool votedFor,
        address voter
    );

    event conductCount(
        uint256 proposal,
        bool passed
    );

    function _checkEligiblity(address _voter) private view returns(bool){
        for (uint i = 0; i < validToken.length; i++){
            if( daoContract.balanceOf(_voter, validToken[i]) > 0 ){
                return true;
            }
        }
        return false;
    }

    function createProposal(string memory _description, uint256 _maxVotes) public {
        require(_checkEligiblity(msg.sender), "You DON'T Have A TOKEN");

        proposal storage p=Proposals[count];
        p.id=count;
        p.description=_description;
        p.exists=true;
        p.deadline= block.number + 150;
        p.maxVotes= _maxVotes;
        emit ProposalCreated(p.id, p.description,   p.maxVotes, msg.sender);
        count++;
    }

    function _maxVoteCount(uint256 _id) private view returns (bool){
        proposal storage p=Proposals[_id];
        uint voteStatusNow= p.votesDown +p.votesUp;
        if (voteStatusNow < p.maxVotes){
            return true;
        }else{
            return false;
        }
    }

    function vote (bool _vote, uint256 _id) public{
        require (Proposals[_id].exists, "The Proposal Doesn't Exists");
        require (Proposals[_id].deadline > block.number, "Proposal Deadline Has Passed");
        require (!Proposals[_id].voteStatus[msg.sender], "You Have Already Voted");
        require(_checkEligiblity(msg.sender), "You DON'T Have A TOKEN");
        require(_maxVoteCount(_id), "Vote Limit Reached");

        proposal storage p=Proposals[_id];

        if(_vote){
            p.votesUp++;
        }else{
            p.votesDown++;
        }
        p.voteStatus[msg.sender]= true;

        emit newVote( p.votesUp, p.votesDown, _id, _vote, msg.sender );
    }

    function startCount( uint256 _id) public{
        require (Proposals[_id].deadline < block.number, "Proposal Deadline Has NOT Passed");
        require (owner == msg.sender, "You Are Not Owner");
        require (Proposals[_id].exists==true, "The Proposal Doesn't Exists");
        require (Proposals[_id].countConducted==false, "The Proposal Already Counted");

        proposal storage p=Proposals[_id];

    if (p.votesUp>=p.votesDown){
        p.passed= true;
    }

    p.countConducted= true;
    emit conductCount(_id,p.passed);

    }
    function addTokenId(uint256 _tokenId) public {
        require(msg.sender == owner, "Only Owner Can Add Tokens");

        validToken.push(_tokenId);
    }

}