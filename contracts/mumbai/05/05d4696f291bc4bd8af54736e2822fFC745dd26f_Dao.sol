// SPDX-License-Identifier: MIT
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
        uint deadline;
        uint256 votesUp;
        uint256 votesDown;
        uint256 maxVotes;
        address[] canVote;
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
        bool votedFor
    );

    event proposalCount(uint256 id, bool passed);

    constructor() {
        owner = msg.sender;
        nextProposal = 1;
        daoContract = IdaoContract(0x2953399124F0cBB46d2CbACD8A89cF0599974963);
        validTokens = [
            15910513496540592213683314899643983720831298888776300021297866013968145842276
        ];
    }

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

    function checkVoteElegibility(uint256 _id, address _voter)
        private
        view
        returns (bool)
    {
        for (uint i = 0; i < Proposals[_id].canVote.length; i++) {
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
        require(Proposals[_id].exists, "This Proposal does not exist");
        require(
            checkVoteElegibility(_id, msg.sender),
            "You can not vote on this Proposal"
        );
        require(
            !Proposals[_id].voteStatus[msg.sender],
            "You have already voted on this Proposal"
        );
        require(
            block.number <= Proposals[_id].deadline,
            "This deadline has passed for this Proposal"
        );

        proposal storage currentProposal = Proposals[_id];

        if (_vote) {
            currentProposal.votesUp++;
        } else {
            currentProposal.votesDown++;
        }

        currentProposal.voteStatus[msg.sender] = true;

        emit newVote(
            currentProposal.votesUp,
            currentProposal.votesDown,
            msg.sender,
            _id,
            _vote
        );
    }

    function countVotes(uint256 _id) public {
        require(msg.sender == owner, "Only Owner Can Count Votes");
        require(Proposals[_id].exists, "This Proposal does not exist");
        require(
            block.number > Proposals[_id].deadline,
            "Voting has not concluded"
        );
        require(Proposals[_id].countConducted, "Can already conducted");

        proposal storage currentProposal = Proposals[_id];

        if (Proposals[_id].votesDown < Proposals[_id].votesUp) {
            currentProposal.passed = true;
        } else {
            currentProposal.passed = false;
        }

        currentProposal.countConducted = true;

        emit proposalCount(_id, currentProposal.passed);
    }

    function addTokenId(uint256 _tokenId) public {
        require(msg.sender == owner, "Only Owner Can Add Tokens");

        validTokens.push(_tokenId);
    }
}