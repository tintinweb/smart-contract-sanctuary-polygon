//SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

interface IdaoContract {
    function balanceOf(address, uint256) external view returns (uint256);
}

contract Dao {
    address public owner;
    uint256 nextProposal;
    uint256[] public validTokens;
    IdaoContract daoContract;

    constructor() {
        owner = msg.sender;
        nextProposal = 1;
        daoContract = IdaoContract(0x2953399124F0cBB46d2CbACD8A89cF0599974963); // Opensea Storefront
        validTokens = [
            113107125708003619876690732338878159248903666501314188425620993767531329093732
        ]; // Voter Badge token
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

    mapping(uint256 => Proposal) public proposals;

    event ProposalCreated(
        uint256 id,
        string description,
        uint256 maxVotes,
        address proposer
    );

    event NewVote(
        uint256 votesUp,
        uint256 votesDown,
        address voter,
        uint256 proposal,
        bool votedFor
    ); // votedFor: for or against proposal: true if for

    event ProposalCounted(uint256 id, bool passed);

    function checkProposalEligibility(address _proposalist)
        private
        view
        returns (bool)
    {
        for (uint256 i = 0; i < validTokens.length; i++) {
            if (daoContract.balanceOf(_proposalist, validTokens[i]) >= 1) {
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
        for (uint256 i = 0; i < proposals[_id].canVote.length; i++) {
            if (proposals[_id].canVote[i] == _voter) {
                return true;
            }
        }
        return false;
    }

    function createProposal(
        string memory _description,
        uint256 _deadline,
        address[] memory _canVote
    ) public {
        require(
            checkProposalEligibility(msg.sender),
            "Only Vote Badge holders can put forth proposals"
        );
        Proposal storage newProposal = proposals[nextProposal];
        newProposal.id = nextProposal;
        newProposal.exists = true;
        newProposal.description = _description;
        newProposal.deadline = block.number + _deadline;
        newProposal.canVote = _canVote;
        newProposal.maxVotes = _canVote.length;

        emit ProposalCreated(
            nextProposal,
            _description,
            _canVote.length,
            msg.sender
        );

        nextProposal++;
    }

    function voteOnProposal(uint256 _id, bool _vote) public {
        require(proposals[_id].exists, "This proposal does not exist");
        require(
            checkVoteEligibility(_id, msg.sender),
            "You may not vote on this proposal"
        );
        require(
            !(proposals[_id].voteStatus[msg.sender]),
            "You have already voted on this proposal"
        );
        require(
            block.number <= proposals[_id].deadline,
            "The deadline has passed for this proposal"
        );

        Proposal storage p = proposals[_id];

        if (_vote) {
            p.votesUp++;
        } else {
            p.votesDown++;
        }

        p.voteStatus[msg.sender] = true;

        emit NewVote(p.votesUp, p.votesDown, msg.sender, _id, _vote);
    }

    function countVotes(uint256 _id) public {
        require(msg.sender == owner, "Only the owner can count votes");
        require(proposals[_id].exists, "This proposal does not exist");
        require(
            block.number > proposals[_id].deadline,
            "Proposal has not reached deadline"
        );
        require(!(proposals[_id].countConducted), "Count already conducted");

        Proposal storage p = proposals[_id];

        if (p.votesDown < p.votesUp) {
            p.passed = true;
        }

        p.countConducted = true;

        emit ProposalCounted(_id, p.passed);
    }

    function addTokenId(uint256 _tokenId) public {
        require(msg.sender == owner, "Only the owner can add new token IDs");
        validTokens.push(_tokenId);
    }
}