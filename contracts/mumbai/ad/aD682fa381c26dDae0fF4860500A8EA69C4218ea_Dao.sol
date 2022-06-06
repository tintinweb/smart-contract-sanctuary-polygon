//SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

interface IdaoContract {
    function balanceOf(address, uint256) external view returns (uint256);
}

contract Dao {
    address public owner;
    uint256 nextProposal;
    uint256[] public validTokens;
    IdaoContract public daoContract;

    constructor() {
        owner = msg.sender;
        nextProposal = 1;
        daoContract = IdaoContract(0x2953399124F0cBB46d2CbACD8A89cF0599974963);
        validTokens = [
            29409051856152553132015924021036608190157647152058149000241024651704164941839
        ];
    }

    struct proposal {
        uint256 id;
        bool exists;
        string description;
        uint256 deadline;
        uint256 votesUp;
        uint256 votesDown;
        address[] canVote;
        uint256 maxVotes;
        mapping(address => bool) voteStatus;
        bool countConducted;
        bool isPassed;
    }

    mapping(uint256 => proposal) public Proposals;

    event ProposalCreated(
        uint256 id,
        string description,
        uint256 maxVotes,
        address proposer
    );

    event newVote(
        uint256 proposal,
        address voter,
        bool votedFor,
        uint256 votesUp,
        uint256 votesDown
    );

    event proposalCount(
        uint256 proposal,
        bool passed
    );
    
    function checkProposalEligibility(address _proposalist) private view returns (bool) {
        for(uint i = 0; i < validTokens.length; i++) {
            if(daoContract.balanceOf(_proposalist, validTokens[i]) > 0) {
                return true;
            }
        }
        return false;
    }

    function checkVoteEligibility(uint256 _id, address _voter) private view returns (bool) {
        for(uint i = 0; i < Proposals[_id].canVote.length; i++) {
            if(Proposals[_id].canVote[i] == _voter) {
                return true;
            }
        }
        return false;
    }
    
    function createProposal(string memory _description, address[] memory _canVote) public {
        require(checkProposalEligibility(msg.sender), "Only NFT holders can create proposals");

        proposal storage newProposal = Proposals[nextProposal];
        newProposal.id = nextProposal;
        newProposal.exists = true;
        newProposal.description = _description;
        newProposal.deadline = block.timestamp + 86400; //24h
        newProposal.canVote = _canVote;
        newProposal.maxVotes = _canVote.length;

        emit ProposalCreated(newProposal.id, newProposal.description, newProposal.maxVotes, msg.sender);
        nextProposal++;
    }

    function voteOnProposal(uint256 _id, bool _vote) public {
        require(Proposals[_id].exists, "Proposal does not exist");
        require(checkVoteEligibility(_id, msg.sender), "You are not eligible to vote on this proposal");
        require(Proposals[_id].voteStatus[msg.sender], "You have already voted on this proposal");
        require(Proposals[_id].deadline < block.timestamp, "Proposal has expired");

        proposal storage p = Proposals[_id];
        if(_vote) {
            p.votesUp++;
        } else {
            p.votesDown++;
        }

        p.voteStatus[msg.sender] = true;

        emit newVote(_id, msg.sender, _vote, p.votesUp, p.votesDown);
    }

    function countVotes(uint256 _id) public {
        require(msg.sender == owner, "Only the owner can count votes");
        require(Proposals[_id].exists, "Proposal does not exist");
        require(Proposals[_id].deadline > block.timestamp, "Voting has not concluded");
        require(Proposals[_id].countConducted, "Votes have already been counted");

        proposal storage p = Proposals[_id];

        if(p.votesUp > p.votesDown) {
            p.isPassed = true;
        }

        p.countConducted = true;
        emit proposalCount(_id, p.isPassed);
    }

    function addTokenID(uint256 _tokenID) public {
        require(msg.sender == owner, "Only the owner can add a token ID");

        validTokens.push(_tokenID);
    }

}