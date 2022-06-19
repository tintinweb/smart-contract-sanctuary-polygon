// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

contract Votaric {
    address public chairPerson;
    uint256 proposalCount;
    mapping(address => bool) public membership;

    constructor() {
        chairPerson = msg.sender;
        proposalCount += 1;
        membership[msg.sender] = true;
    }

    struct Proposal {
        uint256 id;
        bool exists;
        uint256 deadline;
        string description;
        uint256 votesUp;
        uint256 votesDown;
        uint256 totalVoteCount;
        mapping(address => bool) voteStatus;
        bool countsConducted;
        bool passed;
    }

    mapping(uint256 => Proposal) public proposals;

    event proposalCreated(uint256 id, string description, address proposer);

    event newVote(
        uint256 votesUp,
        uint256 votesDown,
        address voter,
        uint256 proposal,
        bool votedFor
    );

    event countProposal(uint256 id, bool passed);

    // check if the caller of the function is a member of the organisation
    function checkMembership(address _caller) private view returns (bool) {
        if (membership[_caller] == true) {
            return true;
        } else {
            return false;
        }
    }

    // check if a member has voted
    function checkHasVoted(uint256 _id, address _voter)
        private
        view
        returns (bool)
    {
        if (proposals[_id].voteStatus[_voter] == true) {
            return true;
        } else {
            return false;
        }
    }

    // create proposal function
    function createProposal(string memory _description) public {
        require(
            checkMembership(msg.sender),
            "You are not a member of this organization"
        );

        Proposal storage newProposal = proposals[proposalCount];
        newProposal.id = proposalCount;
        newProposal.exists = true;
        newProposal.description = _description;
        newProposal.deadline = block.number + 100;

        emit proposalCreated(proposalCount, _description, msg.sender);
        proposalCount++;
    }

    // vote function
    function voteOnProposal(uint256 _id, bool _vote) public {
        require(proposals[_id].exists, "There is no proposal with this id");
        require(checkMembership(msg.sender), "only Members can vote");
        require(
            !checkHasVoted(_id, msg.sender),
            "You already have a vote on this proposal"
        );
        require(
            block.number <= proposals[_id].deadline,
            "Voting time has passed"
        );

        Proposal storage existingProposal = proposals[_id];

        if (_vote) {
            existingProposal.votesUp++;
            existingProposal.totalVoteCount++;
        } else {
            existingProposal.votesDown++;
            existingProposal.totalVoteCount++;
        }

        existingProposal.voteStatus[msg.sender] = true;

        emit newVote(
            existingProposal.votesUp,
            existingProposal.votesDown,
            msg.sender,
            _id,
            _vote
        );
    }

    function finalProposalDecision(uint256 _id) public {
        require(
            msg.sender == chairPerson,
            "Only the ChairPerson can check the final decision"
        );
        require(proposals[_id].exists, "There is no proposal with that id");
        require(
            block.number > proposals[_id].deadline,
            "Deadline has not been met"
        );
        require(
            !proposals[_id].countsConducted,
            "Final Decision has been made on the proposal"
        );

        Proposal storage existingProposal = proposals[_id];

        if (existingProposal.votesUp > existingProposal.votesDown) {
            existingProposal.passed = true;
        } else {
            existingProposal.passed = false;
        }
        existingProposal.countsConducted = true;

        emit countProposal(_id, existingProposal.passed);
    }

    function addMember() public {
        membership[msg.sender] = true;
    }
}