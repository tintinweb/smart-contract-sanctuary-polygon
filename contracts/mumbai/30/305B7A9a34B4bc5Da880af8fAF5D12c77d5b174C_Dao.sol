//SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

interface IDaoContract {
    function balanceOf(address, uint256) external view returns (uint256);
}

contract Dao {
    
    address public owner;
    uint256 nextProposal;
    uint256[] public validTokens;
    IDaoContract daoContract;

    constructor () {
        owner = msg.sender;
        nextProposal = 1;
        daoContract = IDaoContract(0x2953399124F0cBB46d2CbACD8A89cF0599974963);
        validTokens = [77281428467218830367661292324928424280382830168329857403522951721197919797268];
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

    event newVote (
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

    function checkProposalEligibility(address _proposalList) private view returns (bool) {
        for (uint i = 0; i < validTokens.length; i++) {
            if (daoContract.balanceOf(_proposalList, validTokens[i]) > 0) {
                return true;
            }
        }
        return false;
    }

    function checkVoteEligibility(uint256 _id, address _voter) private view returns (bool) {
        for (uint256 i = 0; i < Proposals[_id].canVote.length; i++) {
            if (Proposals[_id].canVote[i] == _voter) {
                return true;
            }
        }
        return false;
    }

    function createProposal(string memory _description, address[] memory _canVote) public {
        require(checkProposalEligibility(msg.sender), "Only NFT Holders can put forth proposals");

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

    function voteOnProposal(uint256 _id, bool _vote) public {
        require(Proposals[_id].exists, "This Proposal does not exist");
        require(checkVoteEligibility(_id, msg.sender), "You are not eligible to vote on this proposal");
        require(!Proposals[_id].voteStatus[msg.sender], "You have already voted on this proposal");
        require(Proposals[_id].deadline > block.number, "This proposal has expired");

        proposal storage p = Proposals[_id];

        if (_vote) {
            p.votesUp++;
        } else {
            p.votesDown++;
        }

        p.voteStatus[msg.sender] = true;

        emit newVote(p.votesUp, p.votesDown, msg.sender, _id, _vote);
    }

    function countVotes(uint256 _id) public {
        require(msg.sender == owner, "Only owner can count votes");
        require(Proposals[_id].exists, "This Proposal does not exist");
        require(block.number > Proposals[_id].deadline, "This proposal has not expired yet");
        require(!Proposals[_id].countConducted, "This proposal has already been counted");

        proposal storage p = Proposals[_id];

        if (Proposals[_id].votesUp > Proposals[_id].votesDown) {
            p.passed = true;
        } else {
            p.passed = false;
        }

        p.countConducted = true;

        emit proposalCount(_id, p.passed);
    }

    function addTokenId(uint256 _tokenId) public {
        require(msg.sender == owner, "Only owner can add tokens");

        validTokens.push(_tokenId);
    }
}