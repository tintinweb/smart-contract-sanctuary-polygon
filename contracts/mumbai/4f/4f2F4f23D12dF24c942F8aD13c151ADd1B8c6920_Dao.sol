// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IDAOContract {
    function balanceOf(address, uint256) external view returns (uint256);
}

contract Dao {
    
    address public owner;
    uint256 nextProposal;
    uint256[] public validTokens;
    IDAOContract daoContract;

    constructor() {
        owner = msg.sender;
        nextProposal = 1;
        daoContract = IDAOContract(0x2953399124F0cBB46d2CbACD8A89cF0599974963);
        validTokens = [
            10642181781667984026401928742529465917419700736337475289994288086858076258324
        ];
    }

    struct Proposal {
        uint256 id;
        bool exists;
        string description;
        uint deadline;
        uint256 voteUp;
        uint256 voteDown;
        address[] canVote;
        uint256 maxVotes;
        mapping(address => bool) voteStatus;
        bool countCounducted;
        bool passed;
    }

    mapping(uint256 => Proposal) public proposals;

    event ProposalCreated(
        uint256 id,
        string description,
        uint256 maxVotes,
        address proposar
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

    function checkProposalEligibility(address _proposalList)
        private
        view
        returns (bool)
    {
        for (uint i = 0; i < validTokens.length; i++) {
            if (daoContract.balanceOf(_proposalList, validTokens[i]) >= 1) {
                return true;
            }
        }
        return false;
    }

    function checkVoteEligibility(uint256 _id, address _voter)
        private
        view
        returns (bool)
    {
        for (uint i = 0; i < proposals[_id].canVote.length; i++) {
            if (proposals[_id].canVote[i] == _voter) {
                return true;
            }
        }
        return false;
    }


    function createProposal(string memory _description,address[] memory _canVote) public {
        require(checkProposalEligibility(msg.sender),"Only NFT Holders can put forth proposal");

        Proposal storage newProposal = proposals[nextProposal];
        newProposal.id=nextProposal;
        newProposal.exists = true;
        newProposal.description = _description;
        newProposal.deadline = block.number + 100;
        newProposal.canVote = _canVote;
        newProposal.maxVotes=_canVote.length;
    
        emit ProposalCreated(nextProposal,_description,_canVote.length,msg.sender);
        nextProposal++;
    }

    function voteOnProposal(uint256 _id,bool _vote) public {
        require(proposals[_id].exists,"This Proposal does not exists");
        require(checkVoteEligibility(_id,msg.sender),"You can not vote on this proposal");
        require(!proposals[_id].voteStatus[msg.sender],"You have already voted on this proposal");
        require(block.number<=proposals[_id].deadline,"The deadline has passed for this proposal");


        Proposal storage p = proposals[_id];

        p.voteStatus[msg.sender]=true;

        if(_vote){
            p.voteUp++;
        }else{
            p.voteDown++;
        }


        p.voteStatus[msg.sender]=true;

        emit newVote(p.voteUp,p.voteDown,msg.sender,_id,_vote);

    }

    function countVotes(uint256 _id) public {
        require(msg.sender==owner,"Only owner can count the votes");
        require(proposals[_id].exists,"This proposal do not exist");
        require(block.number>proposals[_id].deadline,"Voting has not yet concluded");
        require(!proposals[_id].countCounducted,"Count already counducted");


        if(proposals[_id].voteUp>proposals[_id].voteDown){
            proposals[_id].passed=true;
            proposals[_id].countCounducted=true;
            emit proposalCount(_id,true);
        
        } else{
            proposals[_id].passed=false;
            proposals[_id].countCounducted=true;
            emit proposalCount(_id,false);
        }
    }

    function addTokenId(uint256 _tokenId) public {
        require(msg.sender==owner,"Only owner can add new token Id");
        validTokens.push(_tokenId);
    }
    
}