//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.7;

// Using a function from another Smart Contract
// https://mumbai.polygonscan.com/address/0x2953399124f0cbb46d2cbacd8a89cf0599974963#code
interface IDaoContract {
    function balanceOf(address, uint256) external view returns (uint256);
}

contract Dao {
    // Owner of the DAO contract
    address public owner;
    // Next Proposal Id
    uint256 nextProposal;
    // Distinguish which tokens are allowed to vote
    uint256[] public validTokens;
    IDaoContract daoContract;

    constructor() {
        owner = msg.sender;
        nextProposal = 1;
        daoContract = IDaoContract(0x2953399124F0cBB46d2CbACD8A89cF0599974963);
        validTokens = [
            80637283970769485187833267031457596276434478453917901267714982981803549130753
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

    // Make the proposals public
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

    // Check if the address is part of the Dao
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
        newProposal.deadline = block.timestamp + 100;
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
            checkVoteEligibility(_id, msg.sender),
            "You are not eligible to vote on this Proposal!"
        );
        require(
            !Proposals[_id].voteStatus[msg.sender],
            "You have already voted on this Proposal!"
        );
        require(
            block.number <= Proposals[_id].deadline,
            "This Proposal has expired!"
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

    function countVote(uint256 _id) public {
        require(msg.sender == owner, "Only owner can count votes");
        require(Proposals[_id].exists, "This Proposal does not exist");
        require(
            block.number > Proposals[_id].deadline,
            "Voting has not concluded yet"
        );
        require(
            Proposals[_id].countConducted,
            "This Proposal has already been counted!"
        );

        proposal storage p = Proposals[_id];

        if (Proposals[_id].votesDown < Proposals[_id].votesUp) {
            p.passed = true;
        }
        p.countConducted = true;

        emit proposalCount(_id, p.passed);
    }

    function addTokenId(uint256 _tokenId) public {
        require(msg.sender == owner, "Only owner can add token id");

        validTokens.push(_tokenId);
    }
}