//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// Star Sailors (Astroanuts) DAO Contract for skinetics.tech

interface IdaoContract {
    function balanceOf(address, uint256) external view returns (uint256);
}

contract Sailors { // SailorsDAO
    address public owner;
    uint256 nextProposal;
    uint256[] public validTokens; // What tokens are allowed to be used for voting? Cross-chain/network?
    IdaoContract daoContract;

    constructor() {
        owner = msg.sender;
        nextProposal = 1;
        daoContract = IdaoContract(0x67A8fE17Db4d441f96f26094677763a2213a3B5f);
        validTokens = [72764254490465410872480155950423590290196157005391788272990870059575402299393]; // token id of the nft in the contract/collection
    }

    struct proposal {
        uint256 id;
        bool exists;
        string description;
        uint deadline;
        uint256 votesUp;
        uint256 votesDown;
        address[] canVote;
        uint256 maxVotes;
        mapping(address => bool) voteStatus;
        bool countConducted;
        bool passed; 
    }

    mapping (uint256 => proposal) public Proposals;

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

    event proposalCount(
        uint256 id,
        bool passed
    );

    // Check if the user is eligible to vote on a proposal
    function checkProposalEligibility(address _proposalist) private view returns (
        bool
    ){
        for(uint i = 0; i < validTokens.length; i++) {
            if (daoContract.balanceOf(_proposalist, validTokens[i]) >= 1){
                return true;
            }
        }
        return false;
    }

    function checkVoteEligibility(uint256 _id, address _voter) private view returns (
        bool
    ) {
        for (uint256 i = 0; i < Proposals[_id].canVote.length; i++) {
            if (Proposals[_id].canVote[i] == _voter) {
                return true;
            }
        }
        return false;
    }

    // Create proposal
    function createProposal(string memory _description, address[] memory _canVote) public {
        require(checkProposalEligibility(msg.sender), "Only NFT holders can create proposals");

        proposal storage newProposal = Proposals[nextProposal];
        newProposal.id = nextProposal;
        newProposal.exists = true;
        newProposal.description = _description;
        newProposal.deadline = block.number + 100;
        newProposal.canVote = _canVote;
        newProposal.maxVotes = _canVote.length;

        emit proposalCreated(nextProposal, _description, _canVote.length, msg.sender);
        nextProposal++;
    }

    function voteOnProposal(uint256 _id, bool _vote) public {
        require(Proposals[_id].exists, "This proposal does not exist");
        require(checkVoteEligibility(_id, msg.sender), "You cannot vote on this Proposal");
        require(!Proposals[_id].voteStatus[msg.sender], "You have already voted on this Proposal");
        require(block.number <= Proposals[_id].deadline, "The deadline has passed for this Proposal");

        proposal storage p = Proposals[_id];

        if(_vote) {
            p.votesUp++;
        } else {
            p.votesDown++;
        }

        p.voteStatus[msg.sender] = true;

        // Emit a new vote being cast (event) -> send this to Moralis
        emit newVote(p.votesUp, p.votesDown, msg.sender, _id, _vote);
    }

    function countVotes(uint256 _id) public {
        require(msg.sender == owner, "Only Owner Can Count Votes");
        require(Proposals[_id].exists, "This Proposal does not exist");
        require(block.number > Proposals[_id].deadline, "Voting has not concluded");
        require(!Proposals[_id].countConducted, "Count already conducted");

        proposal storage p = Proposals[_id];

        if(Proposals[_id].votesDown < Proposals[_id].votesUp) {
            p.passed = true; // this proposal has been passed
        }

        p.countConducted = true; 
        emit proposalCount(_id, p.passed);
    }

    function addTokenId(uint256 _tokenId) public {
        require(msg.sender == owner, "Only Owner can add tokens to the DAO");

        validTokens.push(_tokenId);
    }
}