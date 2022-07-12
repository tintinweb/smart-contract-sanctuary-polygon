// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

//interface is a way to access outside smartcontracts' methodes.
interface IdaoContract {
    // gets owner address and the tokenID then returns the amount.
    function balanceOf(address, uint256) external view returns (uint256);
}

contract DAO {
    address public owner;
    uint256 nextProposal;
    uint256[] public validTokens;
    IdaoContract daoContract;

    constructor() {
        owner = msg.sender;
        nextProposal = 1;
        daoContract = IdaoContract(0x2953399124F0cBB46d2CbACD8A89cF0599974963);
        validTokens = [
            100198286704761475537941125281850464199989398951877382975443395561633248968719
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
        mapping(address => bool) votedWallets;
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

    // anyone with at least one nft of the Contract is eligible to propose
    function checkProposalEligibility(address _proposalist)
        private
        view
        returns (bool)
    {
        for (uint256 i = 0; i < validTokens.length; i++)
            if (daoContract.balanceOf(_proposalist, validTokens[i]) > 0)
                return true;

        return false;
    }

    function checkVoteEligibility(uint256 _id, address _voter)
        private
        view
        returns (bool)
    {
        for (uint256 i = 0; i < Proposals[_id].canVote.length; i++)
            if (Proposals[_id].canVote[i] == _voter) return true;

        return false;
    }

    function createProposal(
        string memory _description,
        address[] memory _canVote
    ) public {
        require(
            checkProposalEligibility(msg.sender),
            "Only NFT holders can put forth Proposals."
        );
        proposal storage newProposal = Proposals[nextProposal];
        newProposal.id = nextProposal;
        newProposal.exists = true;
        newProposal.description = _description;
        newProposal.deadline = block.timestamp + (5 * 60 * 1);
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
        require(Proposals[_id].exists, "This proposal doesn't exist.");
        require(
            checkVoteEligibility(_id, msg.sender),
            "You can't vote on this proposal"
        );
        require(
            Proposals[_id].votedWallets[msg.sender],
            "You have already voted on this proposal."
        );
        require(
            Proposals[_id].deadline >= block.timestamp,
            "The deadline for this proposal has passed."
        );

        proposal storage p = Proposals[_id];
        if (_vote) p.votesUp++;
        else p.votesDown--;

        p.votedWallets[msg.sender] = true;

        emit newVote(p.votesUp, p.votesDown, msg.sender, _id, _vote);
    }

    function countVotes(uint256 _id) public {
        require(msg.sender == owner, "Only the owner can count votes.");
        require(Proposals[_id].exists, "This proposal doesn't exist.");
        require(
            Proposals[_id].deadline < block.timestamp,
            "Voting has not been concluded."
        );
        require(!Proposals[_id].countConducted, "Count already conducted");
        proposal storage p = Proposals[_id];
        if (p.votesDown < p.votesUp) p.passed = true;
        p.countConducted = true;

        emit proposalCount(_id, p.passed);
    }

    function addTokenId(uint256 _tokenId) public {
        require(
            msg.sender == owner,
            "Only Owner can add valid tokens to the DAO."
        );

        validTokens.push(_tokenId);
    }
}