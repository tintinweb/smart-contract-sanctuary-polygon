//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.4;

interface IDAOContract {
    function balanceOf(address, uint256) external view returns (uint256);
}

contract DaoSmartContract {
    address public owner;
    uint256 currentProposalId;
    uint256[] public validTokens;

    IDAOContract daoContract;

    constructor(address nftAddress, uint256[] memory _tokenIds) {
        owner = msg.sender;
        currentProposalId = 1; // Current Proposal ID
        validTokens = _tokenIds; // Valid Token ID's Array
        daoContract = IDAOContract(nftAddress);
    }

    struct proposal {
        uint256 id;
        bool exists;
        string description;
        uint256 deadline;
        uint256 voteUp;
        uint256 voteDown;
        address[] canVote;
        uint256 maxVotes;
        mapping(address => bool) voteStatus;
        bool countConducted;
        bool passed;
    }

    mapping(uint256 => proposal) public Proposals;

    event proposalCreated(
        uint256 proposalId,
        string description,
        uint256 maxVotes,
        address proposer
    );

    event newVote(
        uint256 upVote,
        uint256 downVote,
        address voter,
        uint256 proposal,
        bool isVoted
    );

    event proposalCount(uint256 Id, bool isPassed);

    function isProposalValid(address _proposalList)
        private
        view
        returns (bool)
    {
        for (uint256 j = 0; j < validTokens.length; j++) {
            if (daoContract.balanceOf(_proposalList, validTokens[j]) >= 1) {
                return true;
            }
        }

        return false;
    }

    function isVoterEligible(uint256 _id, address _voter)
        private
        view
        returns (bool)
    {
        for (uint256 k = 0; k < Proposals[_id].canVote.length; k++) {
            if (Proposals[_id].canVote[k] == _voter) {
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
            isProposalValid(msg.sender),
            "Only NFT Holder Can Create Proposal"
        );

        proposal storage newProposal = Proposals[currentProposalId];
        newProposal.id = currentProposalId;
        newProposal.exists = true;
        newProposal.description = _description;
        newProposal.deadline = block.number + 100;
        newProposal.canVote = _canVote;
        newProposal.maxVotes = _canVote.length;

        emit proposalCreated(
            currentProposalId,
            _description,
            _canVote.length,
            msg.sender
        );
        currentProposalId++;
    }

    function voteOnProposal(uint256 _id, bool _vote) public {
        require(Proposals[_id].exists, "ID Not Exists");
        require(
            isVoterEligible(_id, msg.sender),
            "You can't vote on this Proposal"
        );
        require(
            !Proposals[_id].voteStatus[msg.sender],
            "Already Vote for This Proposal"
        );
        require(
            block.number <= Proposals[_id].deadline,
            "Deadline Passed for This Proposal"
        );

        proposal storage p = Proposals[_id];

        if (_vote) {
            p.voteUp++;
        } else {
            p.voteDown++;
        }

        p.voteStatus[msg.sender] = true;

        emit newVote(p.voteUp, p.voteDown, msg.sender, _id, _vote);
    }

    function countVote(uint256 _proposalId) public {
        require(msg.sender == owner, "Only Owner");
        require(Proposals[_proposalId].exists, "Proposal Not Exists");
        require(
            block.number > Proposals[_proposalId].deadline,
            "Voting Not Concluded Yet"
        );
        require(
            Proposals[_proposalId].countConducted,
            "Count Already Conducted"
        );

        proposal storage p = Proposals[_proposalId];

        if (Proposals[_proposalId].voteDown < Proposals[_proposalId].voteUp) {
            p.passed = true;
        }
        p.countConducted = true;
        emit proposalCount(_proposalId, p.passed);
    }

    function addTokenId(uint256 _tokenId) public {
        require(msg.sender == owner, "Only Owner");
        validTokens.push(_tokenId);
    }
}