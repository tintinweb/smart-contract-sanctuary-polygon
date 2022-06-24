//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IdaoContract {
    function balanceOf(address, uint256) external view returns(uint256);
}
contract Dao {
    address public owner; //publicly available token
    uint256 nextProposal; //id of the next proposal
    //need to make an interface to the SC that created these tokens in order to know if order has a balance of them
    //balanceOf(contractId, wallet addr)...
    uint256[] public validTokens; //tokenID numbers of tokens that can vote
    IdaoContract daoContract;

    constructor() {
        owner = msg.sender;
        nextProposal = 1; 
        //in our SC use another smart contracts functions
        daoContract = IdaoContract(0xAd8ec86c8368A785d15411abbcf12270c1980aCf);
        validTokens = [16300100164096370621845451875738325936267288317616745724986671888855277240321];
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

    //all proposals public
    mapping(uint256 => proposal) public Proposals;


    //events

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

    //functions

    //check if proposalist owns any of the specified tokens
    function checkProposalEligibility(address _proposalist) private view returns (
        bool
    ) {
        for(uint i = 0; i< validTokens.length; i++) {
            if(daoContract.balanceOf(_proposalist, validTokens[i]) >= 1) {
                return true;
            }
        }
        return false;
    }

    function checkVoteEligibility(uint256 _id, address _voter) private view returns (bool) {
        for(uint256 i = 0; i < Proposals[_id].canVote.length; i++) {
            if(Proposals[_id].canVote[i] == _voter) {
                return true;
            }
            return false;
        }
    }

    function createPropsal(string memory _description, address[] memory _canVote) public {
        require(checkProposalEligibility(msg.sender), "Only nft holders can put forth proposals");

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
        require(Proposals[_id].exists, "This Proposal does not exist");
        require(checkVoteEligibility(_id, msg.sender), "You cannot vote in this proposal");
        require(!Proposals[_id].voteStatus[msg.sender], "You have already voted in this proposal");
        require(block.number <= Proposals[_id].deadline, "The deadline has passed for this proposal");

        proposal storage p = Proposals[_id];

        if(_vote) {
            p.votesUp++;
        } else {
            p.votesDown++;
        }

        p.voteStatus[msg.sender] = true;

        emit newVote(p.votesUp, p.votesDown, msg.sender, _id, _vote);
    }

    //just for the owner

    function countVotes(uint256 _id) public {
        require(msg.sender == owner, "Only the owner can count votes");
        require(Proposals[_id].exists, "This proposal does not exist");
        require(block.number > Proposals[_id].deadline, "Voting has not concluded");
        require(!Proposals[_id].countConducted, "Counting already conducted");

        proposal storage p = Proposals[_id];

        if(Proposals[_id].votesDown < Proposals[_id].votesUp) {
            p.passed = true;
        }

        p.countConducted = true;

        emit proposalCount(_id, p.passed);
    }

    function addtokenId(uint256 _tokenId) public {
        require(msg.sender == owner, "Only owner can add tokens");
        validTokens.push(_tokenId);
    }

}