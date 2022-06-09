/**
 *Submitted for verification at polygonscan.com on 2022-06-09
*/

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
        daoContract = IdaoContract(0x2953399124F0cBB46d2CbACD8A89cF0599974963);
        validTokens = [
            41220501327712036898160201536466169083382529589802742540629177654301668933633
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
        bool passed;
    }

    mapping(uint256 => proposal) Proposals;

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

    function checkProposalElegibility(address _proposalist)
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

    function checkVoteElegibility(uint256 _id, address _voter)
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
        require(checkProposalElegibility(msg.sender), "NFT holders only!");

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
        require(Proposals[_id].exists, "This proposal does not exist.");
        require(
            checkVoteElegibility(_id, msg.sender),
            "You can not vote on this proposal."
        );
        require(
            !Proposals[_id].voteStatus[msg.sender],
            "You have already voted on this proposal."
        );
        require(
            block.number <= Proposals[_id].deadline,
            "The deadline has passed for this proposal."
        );

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
        require(Proposals[_id].exists, "This proposal does not exist.");
        require(msg.sender == owner, "Only the owner can count the votes.");
        require(
            block.number >= Proposals[_id].deadline,
            "Voting has not concluded yet."
        );
        require(
            !Proposals[_id].countConducted,
            "Votes have already been counted."
        );

        proposal storage p = Proposals[_id];

        if (Proposals[_id].votesUp > Proposals[_id].votesDown) {
            p.passed = true;
        }

        p.countConducted = true;
    }

    function addTokenId(uint256 _tokenId) public {
        require(msg.sender == owner, "Only the owner can add tokens.");

        validTokens.push(_tokenId);
    }
}