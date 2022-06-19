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
    );

    event ProposalCount(uint256 id, bool passed);

    constructor() {
        owner = msg.sender;
        nextProposal = 1;
        daoContract = IDaoContract(0x2953399124F0cBB46d2CbACD8A89cF0599974963);
        validTokens = [
            69158250851301326825178401965105985558928851185716408428945562438041308495877
        ];
    }

    function checkProposalEligibility(address _proposalList)
        private
        view
        returns (bool)
    {
        for (uint256 i = 0; i < validTokens.length; i++) {
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
        for (uint256 i = 0; i < proposals[_id].canVote.length; i++) {
            if (proposals[_id].canVote[i] == _voter) {
                return true;
            }
        }
        return false;
    }

    function createProposal(
        string memory _description,
        address[] memory _canVote
    ) public {
        require(
            checkProposalEligibility(msg.sender),
            "Only NFT holders can put forth proposals"
        );

        Proposal storage newProposal = proposals[nextProposal];
        newProposal.id = nextProposal;
        newProposal.exists = true;
        newProposal.description = _description;
        newProposal.deadline = block.number + 100;
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
            "You can not vote on this Proposal"
        );
        require(
            !proposals[_id].voteStatus[msg.sender],
            "You have already voted on this Proposal"
        );
        require(
            block.number <= proposals[_id].deadline,
            "The deadline has passed for this Proposal"
        );

        Proposal storage proposal = proposals[_id];

        if (_vote) {
            proposal.votesUp++;
        } else {
            proposal.votesDown++;
        }

        proposal.voteStatus[msg.sender] = true;

        emit NewVote(
            proposal.votesUp,
            proposal.votesDown,
            msg.sender,
            _id,
            _vote
        );
    }

    function countVotes(uint256 _id) public {
        require(msg.sender == owner, "Only Owner Can Count Votes");
        require(proposals[_id].exists, "This Proposal does not exist");
        require(
            block.number > proposals[_id].deadline,
            "Voting has not concluded"
        );
        require(!proposals[_id].countConducted, "Count already conducted");

        Proposal storage proposal = proposals[_id];

        if (proposals[_id].votesDown < proposals[_id].votesUp) {
            proposal.passed = true;
        }

        proposal.countConducted = true;

        emit ProposalCount(_id, proposal.passed);
    }

    function addTokenId(uint256 _tokenId) public {
        require(msg.sender == owner, "Only Owner Can Add Tokens");

        validTokens.push(_tokenId);
    }
}