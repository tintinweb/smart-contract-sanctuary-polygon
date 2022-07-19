// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

interface IdaoContract {
    function balanceOf(address) external view returns (uint256);
}

contract Dao {
    address public owner;
    uint256 nextProposal;
    IdaoContract daoContract;

    constructor() {
        owner = msg.sender;
        nextProposal = 1;
        daoContract = IdaoContract(0xaA1c804A207b58d15b1Fe2a779EB4B44Ca683342);
    }

    struct Proposal {
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
        bool passed;
    }

    mapping(uint256 => Proposal) public Proposals;

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

    event proposalCount(uint256 id, bool passed);

    function checkProposalEligibility(address _proposalist)
        private
        view
        returns (bool)
    {
        if (daoContract.balanceOf(_proposalist) >= 1) {
            return true;
        } else {
            return false;
        }
    }

    function checkVoteEligibility(address _voter) private view returns (bool) {
        if (daoContract.balanceOf(_voter) >= 1) {
            return true;
        } else {
            return false;
        }
    }

    function createProposal(string memory _description) public {
        require(
            checkProposalEligibility(msg.sender),
            "Only NFT holders can create proposals!"
        );

        Proposal storage newProposal = Proposals[nextProposal];
        newProposal.id = nextProposal;
        newProposal.exists = true;
        newProposal.description = _description;
        newProposal.deadline = block.number + 100;
        newProposal.maxVotes = 333;

        emit proposalCreated(nextProposal, _description, 333, msg.sender);
        nextProposal++;
    }

    function voteOnProposal(uint256 _id, bool _vote) public {
        require(Proposals[_id].exists, "This proposal doesn't exist!");
        require(
            checkVoteEligibility(msg.sender),
            "You can't vote on this proposal!"
        );
        require(
            !Proposals[_id].voteStatus[msg.sender],
            "You have already voted for this proposal!"
        );
        require(
            block.number <= Proposals[_id].deadline,
            "The deadline has passed for this proposal!"
        );

        Proposal storage p = Proposals[_id];

        if (_vote) {
            p.votesUp += daoContract.balanceOf(msg.sender);
        } else {
            p.votesDown += daoContract.balanceOf(msg.sender);
        }

        p.voteStatus[msg.sender] = true;

        emit newVote(p.votesUp, p.votesDown, msg.sender, _id, _vote);
    }

    function countVotes(uint256 _id) public {
        require(msg.sender == owner, "Only the owner can count votes");
        require(Proposals[_id].exists, "This proposal does not exist");
        require(
            block.number > Proposals[_id].deadline,
            "Voting has not been concluded yet"
        );
        require(!Proposals[_id].countConducted, "Count already concluded");

        Proposal storage p = Proposals[_id];

        if (Proposals[_id].votesDown < Proposals[_id].votesUp) {
            p.passed = true;
        }

        p.countConducted = true;

        emit proposalCount(_id, p.passed);
    }
}