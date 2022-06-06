// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

//  $$$$$$\   $$$$$$\  $$$$$$$\
// $$  __$$\ $$  __$$\ $$  __$$\
// $$ /  \__|$$ /  $$ |$$ |  $$ |
// $$ |$$$$\ $$ |  $$ |$$$$$$$  |
// $$ |\_$$ |$$ |  $$ |$$  __$$<
// $$ |  $$ |$$ |  $$ |$$ |  $$ |
// \$$$$$$  | $$$$$$  |$$ |  $$ |
//  \______/  \______/ \__|  \__|

// @title : TGC - GoR contract
// @desc: Rexxie DAO contract
// @author: @ass77
// @team: https://instagram.com/generation_of_rexxie
// @team: https://twitter.com/tgcollective777
// @url: https://tgcollective.xyz

// TODO change name
interface ItestconndaoContract {
    function balanceOf(address) external view returns (uint256);
}

contract TestConnDao {
    address public owner;
    uint256 nextProposal;
    ItestconndaoContract daoContract;

    constructor() {
        owner = msg.sender;
        nextProposal = 1;
        // TODO rexx smart contract
        daoContract = ItestconndaoContract(
            0xc8860Ebad4Bb6a857B5618ec348F71B6E9c23588
        );
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

    function checkProposalEligibility(address _proposalist)
        private
        view
        returns (bool)
    {
        if (daoContract.balanceOf(_proposalist) >= 1) {
            return true;
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
            "Only TGC-GoR NFT holders can put forth Rexx-Proposals"
        );

        proposal storage newProposal = Proposals[nextProposal];
        newProposal.id = nextProposal;
        newProposal.exists = true;
        newProposal.description = _description;
        // TODO make it dynamic
        // block number + limit REXX NFT per wallet
        newProposal.deadline = block.number + 7;
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
        require(Proposals[_id].exists, "This REXX-Proposal does not exist");
        require(
            checkVoteEligibility(_id, msg.sender),
            "You can not vote on this REXX-Proposal"
        );
        require(
            !Proposals[_id].voteStatus[msg.sender],
            "You have already voted on this REXX-Proposal"
        );
        require(
            block.number <= Proposals[_id].deadline,
            "The deadline has passed for this REXX-Proposal"
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
        require(msg.sender == owner, "Only Owner Can Count Votes");
        require(Proposals[_id].exists, "This REXX-Proposal does not exist");
        require(
            block.number > Proposals[_id].deadline,
            "Voting has not concluded"
        );
        require(!Proposals[_id].countConducted, "Count already conducted");

        proposal storage p = Proposals[_id];

        if (Proposals[_id].votesDown < Proposals[_id].votesUp) {
            p.passed = true;
        }

        p.countConducted = true;

        emit proposalCount(_id, p.passed);
    }
}