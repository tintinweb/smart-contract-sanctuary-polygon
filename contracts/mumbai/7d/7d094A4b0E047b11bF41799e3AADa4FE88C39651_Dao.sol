// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

interface IdaoContract {
        function balanceOf(address) external view returns (uint256);
    }
//0x2CC0F54Da3eAF7A6a24E8178D9CE5F17116B9D12
contract Dao {

    address public owner;
    uint256 nextProposal;
    address[] public validTokens;
    IdaoContract daoContract;

    constructor(address _contractAddress, address _validTokens){
        owner = msg.sender;
        nextProposal = 1;
        daoContract = IdaoContract(_contractAddress);
        validTokens = [_validTokens];
    }

    struct proposal{
        uint256 id;
        string offChainId;
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
        string category;
    }

    mapping(uint256 => proposal) public Proposals;

    event proposalCreated(
        uint256 id,
        string offChainId,
        string description,
        uint256 maxVotes,
        address proposer,
        uint256 createdOn,
        string categogry,
        uint deadline
    );

    event newVote(
        uint256 votesUp,
        uint256 votesDown,
        address voter,
        uint256 proposal,
        bool votedFor,
        uint256 createdOn
    );

    event proposalCount(
        uint256 id,
        bool passed,
        uint256 votesUp,
        uint256 votesDown,
        uint256 createdOn
    );


    function checkProposalEligibility(address _proposalist) private view returns (
        bool
    ){
        for(uint i = 0; i < validTokens.length; i++){
            if(daoContract.balanceOf(_proposalist) >= 1){
                return true;
            }
        }
        return false;
    }

    function checkVoteEligibility(uint256 _id, address _voter) private view returns (
        bool
    ){
        for (uint256 i = 0; i < Proposals[_id].canVote.length; i++) {
            if (Proposals[_id].canVote[i] == _voter) {
            return true;
            }
        }
        return false;
    }


    function createProposal(string memory _description, string memory _offChainId, address[] memory _canVote, uint _deadline, string memory _category) public {
        //require(msg.sender == owner,"Only owner can create proposal");
        require(checkProposalEligibility(msg.sender), "Only Token holders can put Proposals");

        proposal storage newProposal = Proposals[nextProposal];
        newProposal.id = nextProposal;
        newProposal.offChainId = _offChainId;
        newProposal.exists = true;
        newProposal.description = _description;
        newProposal.deadline = block.number + _deadline;
        newProposal.canVote = _canVote;
        newProposal.maxVotes = _canVote.length;
        newProposal.category = _category;

        emit proposalCreated(nextProposal,_offChainId, _description, _canVote.length, msg.sender, block.timestamp, _category, (block.number + _deadline));
        nextProposal++;
    }


    function voteOnProposal(uint256 _id, bool _vote) public {
        require(Proposals[_id].exists, "This Proposal does not exist");
        require(checkVoteEligibility(_id, msg.sender), "You can not vote on this Proposal");
        require(checkProposalEligibility(msg.sender), "Only Token holders can vote on Proposals");
        require(!Proposals[_id].voteStatus[msg.sender], "You have already voted on this Proposal");
        require(block.number <= Proposals[_id].deadline, "The deadline has passed for this Proposal");

        proposal storage p = Proposals[_id];

        if(_vote) {
            p.votesUp++;
        }else{
            p.votesDown++;
        }

        p.voteStatus[msg.sender] = true;

        emit newVote(p.votesUp, p.votesDown, msg.sender, _id, _vote, block.timestamp);
        
    }

    function countVotes(uint256 _id) public {
        require(msg.sender == owner, "Only Owner Can Count Votes");
        require(Proposals[_id].exists, "This Proposal does not exist");
        require(block.number > Proposals[_id].deadline, "Voting has not concluded");
        require(!Proposals[_id].countConducted, "Count already conducted");

        proposal storage p = Proposals[_id];
        
        if(Proposals[_id].votesDown < Proposals[_id].votesUp){
            p.passed = true;            
        }

        p.countConducted = true;

        emit proposalCount(_id, p.passed,Proposals[_id].votesUp,Proposals[_id].votesDown,block.timestamp);
    }


    function addTokenId(address _tokenId) public {
        require(msg.sender == owner, "Only Owner Can Add Tokens");

        validTokens.push(_tokenId);
    }
    
}