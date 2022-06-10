//SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

//import "hardhat/console.sol"

interface IdaoContract {
    function balanceOf(address, uint256) external view returns (uint256);
}

contract Dao {

    address public owner;
    uint256 nextProposal;
    uint256[] public validTokens;
    IdaoContract daoContract;

    constructor() {
        owner = msg.sender; // Who ever deplos the Smart Contract is the owner
        nextProposal = 1;
        daoContract = IdaoContract(0x2953399124F0cBB46d2CbACD8A89cF0599974963); // How to use other Smart Contract Functions within our SC
        validTokens = [65507296301157764366578223450846077985624877617105947692936320161199765323777]; // List of token IDs that can vote on this DAO
    }

    // This is a Solidity object
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

    mapping(uint256 => proposal) public Proposals;


    // Capture different events that triggers our smart contract
    event proposalCreated(
        uint256 id,
        string description,
        uint256 maxVotes,
        address proposal
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

    // Functions only available to the owner
    function checkProposalEligibility(address _proposalist) private view returns (bool) {
        for(uint i=0; i < validTokens.length; i++) {
            if(daoContract.balanceOf(_proposalist, validTokens[i]) >= 1) {
                return true;
            }
        }

        return false;
    }

    function checkVoteEligibility(uint256 _id, address _voter) private view returns (bool) {
        for(uint i=0; i < Proposals[_id].canVote.length; i++) {
            if(Proposals[_id].canVote[i] == _voter) {
                return true;    
            }
        }

        return false;
    }
    
    // Public functions
    function createProposal(string memory _description, address[] memory _canVote) public {
        require(checkProposalEligibility(msg.sender), "Only NFT holders can create a proposal!");

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
        require(Proposals[_id].exists, "Only NFT holders can create a proposal!");
        require(checkProposalEligibility(msg.sender), "You can't vote on this proposal!");
        require(!Proposals[_id].voteStatus[msg.sender], "You voted already!");
        require(block.number <= Proposals[_id].deadline, "It's too late to vote on this proposal!");

        proposal storage p = Proposals[_id];

        if(_vote){
            p.votesUp++;
        } else {
            p.votesDown++;
        }

        p.voteStatus[msg.sender] = true;

        emit newVote(p.votesUp, p.votesDown, msg.sender, _id, _vote);
    }

    // Owner functions
    function countVotes(uint256 _id) public {
        require(msg.sender == owner, "Only owner can count votes!");
        require(Proposals[_id].exists, "This proposal doesn't exist!");
        require(block.number > Proposals[_id].deadline, "Voting is still ongoing!");
        require(!Proposals[_id].countConducted, "Count already conducted!");

        proposal storage p = Proposals[_id];

        if(Proposals[_id].votesDown < Proposals[_id].votesUp){
            p.passed = true;
        }

        p.countConducted = true;

        emit proposalCount(_id, p.passed);
    }

    function addTokenId(uint256 _tokenId) public {
        require(msg.sender == owner, "Only owner can add tokens!");
        validTokens.push(_tokenId);
    }

}