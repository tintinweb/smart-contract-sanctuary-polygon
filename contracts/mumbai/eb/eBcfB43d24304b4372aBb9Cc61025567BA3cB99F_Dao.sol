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
            112293014713804941124843793312584530915951492090108009575813402359096131190884
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

    // Main Dao functions

    function checkProposalEligibility(address _proposallist)
        private
        view
        returns (bool)
    {
        for (uint256 i = 0; i < validTokens.length; i++) {
            if (daoContract.balanceOf(_proposallist, validTokens[i]) >= 1) {
                return true;
            }
        }
        return false;
    }

    function checkVoterEligibility(uint256 _id, address _voter)
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
            "Only Trrrue Degen Holders can be parts of ze Futuuure"
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
        require(
            Proposals[_id].exists,
            "This Prposal does not exist, at least not here"
        );
        require(
            checkVoterEligibility(_id, msg.sender),
            "You are not allowed to vote here"
        );
        require(
            !Proposals[_id].voteStatus[msg.sender],
            "You already voted, Stop it !!!"
        );
        require(
            block.number <= Proposals[_id].deadline,
            "The deadline have eneded for this proposal"
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
        require(
            msg.sender == owner,
            "You shall not pass, cause you ain't the damn owner"
        );
        require(
            Proposals[_id].exists,
            "This proposal might exist somewhere else, but def not in here"
        );
        require(
            block.number > Proposals[_id].deadline,
            "Voting daedline isn't over yet"
        );
        require(
            !Proposals[_id].countConducted,
            "Counting votes has alredy been conducted"
        );

        proposal storage p = Proposals[_id];

        if (Proposals[_id].votesDown < Proposals[_id].votesUp) {
            p.passed = true;
        }
        p.countConducted = true;

        emit proposalCount(_id, p.passed);
    }

    function addToken(uint256 _tokenId) public {
        require(
            msg.sender == owner,
            "You shall not pass, cause you ain't the damn owner"
        );

        validTokens.push(_tokenId);
    }
}