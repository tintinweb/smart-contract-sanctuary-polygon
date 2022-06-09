//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

interface IdaoContract {
    function balanceOf(address, uint256) external view returns (uint256);
}

contract Dao {
    address public owner;
    uint256 public nextProposal;
    uint256[] public tokenId;

    IdaoContract internal daoContract;

    constructor() {
        owner = msg.sender;
        daoContract = IdaoContract(0x2953399124F0cBB46d2CbACD8A89cF0599974963);
        tokenId = [
            80671536953280484003266352282760453939964949380992285284436584527232172556298
        ];
        nextProposal = 1;
    }

    struct proposal {
        uint256 id;
        bool exists;
        string description;
        uint256 deadline;
        uint256 votesUp;
        uint256 votesDown;
        address[] canVote;
        uint256 maxtVotes;
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

    function checkProposalEligiblility(address _proposalist)
        private
        view
        returns (bool)
    {
        for (uint256 i = 0; i < tokenId.length; i++) {
            if (daoContract.balanceOf(_proposalist, tokenId[i]) >= 1) {
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
            checkProposalEligiblility(msg.sender),
            "only the NFT holders can put forth a proposals"
        );

        proposal storage newProposal = Proposals[nextProposal];
        newProposal.id = nextProposal;
        newProposal.exists = true;
        newProposal.description = _description;
        newProposal.deadline = block.number + 100;
        newProposal.canVote = _canVote;
        newProposal.maxtVotes = _canVote.length;

        emit proposalCreated(
            nextProposal,
            _description,
            _canVote.length,
            msg.sender
        );
        nextProposal++;
    }

    function countVotes(uint256 _id) public {
        require(msg.sender == owner, "only Owner can cont votes");
        require(Proposals[_id].exists, "this proposals does not exist");
        require(
            block.number > Proposals[_id].deadline,
            "voting has not concluded"
        );
        require(!Proposals[_id].countConducted, "conduct already conducted");

        proposal storage p = Proposals[_id];

        if (Proposals[_id].votesDown < Proposals[_id].votesUp) {
            p.passed = true;
        }

        p.countConducted = true;

        emit proposalCount(_id, p.passed);
    }

    function addTokenId(uint256 _tokenId) public {
        require(msg.sender == owner, "only the owner can add tokens");

        tokenId.push(_tokenId);
    }
}