// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface DaoContract {
    function balanceOf(address, uint256) external view returns (uint256);
}

contract DAO {
    address public owner;
    uint256 nextProposal;
    uint256[] public validTokens;
    DaoContract daoContract;

    constructor() {
        owner = msg.sender; //set owner to sender
        nextProposal = 1; //set first proposal an id of 1
        daoContract = DaoContract(0x2953399124F0cBB46d2CbACD8A89cF0599974963);
        validTokens = [
            //set valid NFT
            5093251051194344911178778181154259876839883413338465059259597433663167397889
        ];
    }

    struct proposal {
        uint256 id;
        bool exists;
        string description;
        uint deadline;
        uint256 upVotes;
        uint256 downVotes;
        address[] canVote;
        uint256 maxVotes;
        mapping(address => bool) voteStatus;
        bool countConducted;
        bool passed;
    }

    mapping(uint256 => proposal) public Proposals; //connection between proposal id to proposal

    //events
    event ProposalCreated(
        uint256 id,
        string description,
        uint256 maxVotes,
        address proposer
    );

    event newVote(
        uint256 upVotes,
        uint256 downVotes,
        address voter,
        uint256 proposal,
        bool votedFor
    );

    event proposalCount(uint256 id, bool passed);

    //private functions

    //checks if a proposal is eligible to be created
    function checkProposalElig(address _proposalist)
        private
        view
        returns (bool)
    {
        for (uint i = 0; i < validTokens.length; i++) {
            if (daoContract.balanceOf(_proposalist, validTokens[i]) >= 1) {
                return true;
            }
        }
        return false;
    }

    //checks if a voter can vote on a proposal
    function checkVoteElig(uint256 _id, address _voter)
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

    //function to create a new proposal
    function createProposal(
        string memory _description,
        address[] memory _canVote
    ) public {
        require(
            checkProposalElig(msg.sender),
            "Only NFT holders can put forth proposals"
        );

        proposal storage newProposal = Proposals[nextProposal];
        newProposal.id = nextProposal;
        newProposal.exists = true;
        newProposal.description = _description;
        newProposal.deadline = block.number + 100; //current block number + 100 blocks
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

    //function to vote on a proposal
    function voteOnProposal(uint256 _id, bool _vote) public {
        require(Proposals[_id].exists, "This proposal is not real");
        require(
            checkVoteElig(_id, msg.sender),
            "You cannot vote on this proposal"
        );
        require(
            !Proposals[_id].voteStatus[msg.sender],
            "You have already voted on this"
        );
        require(
            block.number <= Proposals[_id].deadline,
            "This proposal has finished"
        );

        proposal storage p = Proposals[_id];

        if (_vote) {
            p.upVotes++;
        } else {
            p.downVotes++;
        }

        p.voteStatus[msg.sender] = true;

        emit newVote(p.upVotes, p.downVotes, msg.sender, _id, _vote);
    }

    function countVotes(uint256 _id) public {
        require(msg.sender == owner, "Only owner can count votes");
        require(Proposals[_id].exists, "This Proposal does not exist");
        require(
            block.number > Proposals[_id].deadline,
            "Voting has not concluded"
        );
        require(!Proposals[_id].countConducted, "Count already conducted");

        proposal storage p = Proposals[_id];

        if (Proposals[_id].downVotes < Proposals[_id].upVotes) {
            p.passed = true;
        }

        p.countConducted = true;

        emit proposalCount(_id, p.passed);
    }

    function addTokenId(uint256 _tokenId) public {
        require(msg.sender == owner, "Only Owner can add tokens");

        validTokens.push(_tokenId);
    }
}