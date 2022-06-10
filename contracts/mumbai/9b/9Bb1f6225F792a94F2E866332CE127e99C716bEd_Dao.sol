//SPDX-License-Indentifier: MIT

pragma solidity ^0.8.7;

interface IdaoContract {
    function balanceOf(address, uint256) external view returns (uint256);
}

contract Dao {
    address public owner;
    uint256 nextProposal;
    uint256[] public validTokens;
    IdaoContract daoContract;

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
        bool passed;
    }

    mapping(uint256 => proposal) public Proposals;

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
        bool voteFor
    );

    event proposalCount(uint256 id, bool passed);

    constructor() {
        owner = msg.sender;
        nextProposal = 1;
        daoContract = IdaoContract(0x36cE46828B44BCb6AD659207aA306A45753fB675);
        validTokens = [0];
    }

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
        for (uint256 i = 0; i < Proposals[_id].canVote.length; i++) {
            if (Proposals[_id].canVote[i] == _voter) {
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
            "Only NFT holders can put forth Proposals"
        );

        proposal storage newProposal = Proposals[nextProposal];
        newProposal.id = nextProposal;
        newProposal.exists = true;
        newProposal.description = _description;
        newProposal.deadline = block.number + 100;
        newProposal.canVote = _canVote;
        newProposal.maxVotes = _canVote.length;

        emit proposalCreated(
            nextProposal,
            _description,
            _canVote.length,
            msg.sender
        );

        nextProposal++;
    }

    function voteOnProposal(uint256 _id, bool _vote) public {
        require(Proposals[_id].exists, "Proposal does not exist");
        require(
            checkVoteEligibility(_id, msg.sender),
            "You are not allowed to Vote on this Proposal"
        );
        require(
            !Proposals[_id].voteStatus[msg.sender],
            "You have already voted on this proposal"
        );
        require(
            block.number <= Proposals[_id].deadline,
            "Time is up, no more voting for this proposal"
        );

        proposal storage votingOn = Proposals[_id];

        if (_vote) {
            votingOn.votesUp++;
        } else {
            votingOn.votesDown++;
        }

        votingOn.voteStatus[msg.sender] = true;

        emit newVote(
            votingOn.votesUp,
            votingOn.votesDown,
            msg.sender,
            _id,
            _vote
        );
    }

    function countVotes(uint256 _id) public {
        require(msg.sender == owner);
        require(Proposals[_id].exists);
        require(block.number > Proposals[_id].deadline);
        require(!Proposals[_id].countConducted);

        proposal storage p = Proposals[_id];

        if (p.votesUp > p.votesDown) {
            p.passed = true;
        } else {
            p.passed = false;
        }

        p.countConducted = true;

        emit proposalCount(_id, p.passed);
    }

    function addValidTokens(uint256 _tokenId) public {
        require(msg.sender == owner);

        validTokens.push(_tokenId);
    }
}