// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

// Replicates the function that opensea storefront uses.
interface IdaoContract {
    function balanceOf(address, uint256) external view returns (uint256);
}

contract Dao {

    address public owner;
    uint256 nextProposal;
    uint256[] public validTokens;
    IdaoContract public daoContract; // reference to the Idao interface
    
    constructor() {
        owner = msg.sender;
        nextProposal = 1;
        daoContract = IdaoContract(0x2953399124F0cBB46d2CbACD8A89cF0599974963); // opensea storefront contract address
        validTokens = [13573777325399119039365754446544011846471218746658644130618490455763196051471];  // comrade builder token
    }

    struct Proposal{
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

    mapping(uint256 => Proposal) public proposals;

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

    /*
    *   Use valid token array list & opensea storefront to Check if the sender is a part of the DAO
    */
    function checkProposalEligibility(address _proposalist) private view returns (bool) {
        
        for(uint i=0; i<validTokens.length; i++) {
            if(daoContract.balanceOf(_proposalist, validTokens[i]) > 0) {
                return true;
            }
        }
        return false;
    }

    function checkVoteEligibility(uint256 _id, address _voter) private view returns (bool) {
        for (uint i = 0; i < proposals[_id].canVote.length; i++) {
            if (proposals[_id].canVote[i] == _voter) {
                return true;
            }
        }
        return false;
    }


    function createProposal(string memory _description, address[] memory _canVote) public {
        require(checkProposalEligibility(msg.sender), "Only NFT holders can create proposals");

        Proposal storage newProposal = proposals[nextProposal];
        newProposal.id = nextProposal;
        newProposal.exists = true;
        newProposal.description = _description;
        newProposal.deadline = block.number + 100;
        newProposal.canVote = _canVote;
        newProposal.maxVotes = _canVote.length;

        emit proposalCreated(nextProposal, _description, _canVote.length, msg.sender);
        nextProposal++; // check for reentrancy
    }


    function voteOnProposal(uint256 _id, bool _vote) public {
        require(proposals[_id].exists, "This Proposal does not exist");
        require(checkVoteEligibility(_id, msg.sender), "You are not eligible to vote on this proposal");
        require(!proposals[_id].voteStatus[msg.sender], "You have already voted on this proposal");
        require(proposals[_id].deadline > block.timestamp, "The deadline has passed for this proposal");

        Proposal storage p = proposals[_id];

        if (_vote) {
            p.votesUp++;
        } else {
            p.votesDown++;
        }

        p.voteStatus[msg.sender] = true;

        emit newVote(p.votesUp, p.votesDown, msg.sender, _id, _vote);
    }


    function countVotes(uint256 _id) public {
        require(msg.sender == owner, "Only the DAO owner can count votes");
        require(proposals[_id].exists, "This Proposal does not exist");
        require(block.number > proposals[_id].deadline, "Voting has not concluded for this proposal");
        require(!proposals[_id].countConducted, "Counting has already been conducted for this proposal");

        Proposal storage p = proposals[_id];

        if (p.votesDown < p.votesUp) {
            p.passed = true;
        } else {
            p.passed = false;
        }

        p.countConducted = true;

        emit proposalCount(_id, p.passed);
    }


    function addTokenId(uint256 _tokenId) public {
        require(msg.sender == owner, "Only the DAO owner can add a token id");
        // require(!validTokens.contains(_tokenId), "This token id is already in the list");

        validTokens.push(_tokenId);
    }

}