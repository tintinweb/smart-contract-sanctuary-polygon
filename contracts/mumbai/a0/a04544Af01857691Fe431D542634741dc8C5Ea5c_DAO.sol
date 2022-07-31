// SPDX-License-Identifier: MIT
// Aidan Davy 7/14/22

pragma solidity  ^0.8.7;

interface IDAOContract {
    function balanceOf(address, uint256) external view returns (uint256);
}

contract DAO {

    address public owner;
    uint256 nextProposal;
    uint256[] public validTokens;
    IDAOContract daoContract;
    // state variables for proposal initailization

    constructor() {
        // initiation of smart contract && valid proposals
        owner = msg.sender;
        nextProposal = 1;
        daoContract = IDAOContract(0x2953399124F0cBB46d2CbACD8A89cF0599974963);
        validTokens = [66320545467467551512058706667886240702397686527561347894872379692868616323087];
    }

    struct proposal {
        // core of a proposal, all data needed to create one 
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

    mapping(uint256 => proposal) public Proposals;

    event proposalCreated(
        uint256 id,
        string description,
        uint256 maxVotes,
        address proposer
    );
    // broadcasts when a new proposal is created so web page can display new proposals

    event newVote(
        uint256 votesUp,
        uint256 votesDown,
        address voter,
        uint256 proposal,
        bool votedFor
    );
    // broadcasts when votes are cast in order to count votes

    event proposalCount(
        uint256 id,
        bool passed
    );
    // broadcasts which side won proposal

    function checkProposalEligability(address _proposalList) private view returns (bool) {
        // ensures that proposal is valid and NFT exists to vote on it
        for(uint i = 0; i < validTokens.length; i++){
            if(daoContract.balanceOf(_proposalList, validTokens[i]) >= 1) {
                return true;
            }
        }
        return false;
    }

    function checkVoteEligibility(uint256 _id, address _voter) private view returns(bool) {
        // ensures users are eligible to vote ie they have the NFT 
        for(uint i = 0; i < Proposals[_id].canVote.length; i++){
            if(Proposals[_id].canVote[i] == _voter) {
                return true;
            }
        }
        return false;
    }

    function createProposal(string memory _description, address[] memory _canVote) public {
        // initiates proposal and fills out state variable data that was initialized above
        require(checkProposalEligability(msg.sender), "Only NFT holders can put forth Proposals");

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
        // ensures users are eligible to vote on a proposal then casts users vote
        require(Proposals[_id].exists, "This proposal does not exist");
        require(checkVoteEligibility(_id, msg.sender), "You can not vote on this Proposal");
        require(!Proposals[_id].voteStatus[msg.sender], "You have already voted on this Proposal");
        require(block.number <= Proposals[_id].deadline, "The deadline for this Proposal has passed");

        proposal storage p = Proposals[_id];

        if(_vote) {
            p.votesUp++;
        } else {
            p.votesDown++;
        }

        p.voteStatus[msg.sender] = true;

        emit newVote(p.votesUp, p.votesDown, msg.sender, _id, _vote);
    }

    function countVotes(uint256 _id) public {
        require(msg.sender == owner, "Only owner can count votes");
        require(Proposals[_id].exists, "This Proposal does not exist");
        require(block.number > Proposals[_id].deadline, "Voting has not concluded");
        require(!Proposals[_id].countConducted, "Count already conducted");

        proposal storage p = Proposals[_id];

        if(Proposals[_id].votesDown < Proposals[_id].votesUp){
            p.passed = true;
        } 

        p.countConducted = true;

        emit proposalCount(_id, p.passed);
    }

    function addTokenId(uint256 _tokenId) public {
        require(msg.sender == owner, "Only owner can add tokens");

        validTokens.push(_tokenId);
    }

}