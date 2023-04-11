// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

error BallotVote__NotChairperson();
error BallotVote__AlreadyVoted();
error BallotVote__AlreadyPermittedToVote();
error BallotVote__NoRightToVote();

contract BallotVote {
    struct Voter {
        uint256 vote;
        bool voted;
        uint256 weight;
    }

    struct Proposal {
        bytes32 name; // the name of each proposal
        uint256 voteCount; // number of accumulated votes
    }

    Proposal[] public proposals;
    mapping(address => Voter) public voters; // key: address, value: Voter

    address public chairperson;

    modifier onlyChairperson(address voter) {
        if (voter != chairperson) {
            revert BallotVote__NotChairperson();
        }
        _;
    }

    modifier notVoted(address voter) {
        if (voters[voter].voted) {
            revert BallotVote__AlreadyVoted();
        }
        _;
    }

    modifier notPermitted(address voter) {
        if (voters[voter].weight == 1) {
            revert BallotVote__AlreadyPermittedToVote();
        }
        _;
    }

    modifier permitted(address voter) {
        if (voters[voter].weight == 0) {
            revert BallotVote__NoRightToVote();
        }
        _;
    }

    constructor(bytes32[] memory proposalNames) {
        chairperson = msg.sender;

        // add 1 to chairperson weight
        voters[chairperson].weight = 1;

        // will add the proposal names to the contract upon deployment
        for (uint256 i = 0; i < proposals.length; i++) {
            proposals.push(Proposal({name: proposalNames[i], voteCount: 0}));
        }
    }

    function giveRightToVote(address voter)
        public
        onlyChairperson(msg.sender)
        notVoted(msg.sender)
        notPermitted(msg.sender)
    {
        voters[voter].weight = 1;
    }

    function vote(uint256 proposal) public permitted(msg.sender) notVoted(msg.sender) {
        Voter storage sender = voters[msg.sender];
        sender.voted = true;
        sender.vote = proposal;
        proposals[proposal].voteCount += sender.weight;
    }

    function winningProposal() public view returns (uint256 winningProposal_) {
        uint256 winningVoteCount = 0;
        for (uint256 i = 0; i < proposals.length; i++) {
            if (proposals[i].voteCount > winningVoteCount) {
                winningVoteCount = proposals[i].voteCount;
                winningProposal_ = i;
            }
        }
    }

    function winningName() public view returns (bytes32 winningName_) {
        winningName_ = proposals[winningProposal()].name;
    }
}