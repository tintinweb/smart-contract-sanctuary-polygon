// SPDX-License-Identifier:MIT

pragma solidity ^0.8.7; // tuve un error de sintaxis

interface IdaoContract{
    function balanceOf(address, uint256) external view returns(uint256);
}

contract EscBlocDao{

    address public owner;
    uint256 nextProposal;
    uint256[] public validTokens;
    IdaoContract daoContract;

    constructor(){
        owner = msg.sender;
        nextProposal = 1;
        daoContract = IdaoContract(0x2953399124F0cBB46d2CbACD8A89cF0599974963);
        validTokens = [111838945568503443126824248095122094659600397918049171101957123075414452862986];
    }
    
    struct proposal{
        uint256 id;
        bool exist;
        string descriptions;
        uint deadLine;
        uint256 votesDown;
        uint256 votesUp;
        address[] canVote;
        uint256 maxVotes;
        mapping(address => bool) voteStatus;
        bool countCounducted;
        bool pased;
    }

    mapping(uint256 => proposal) public Proposals;

    event proposalCreate(
        uint256 id,
        string description,
        uint256 maxVote,
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
    function checkProposalEligibility(address _proposalist) private view returns(bool){
        for(uint256 i = 0; i < validTokens.length; i++){
            if(daoContract.balanceOf(_proposalist, validTokens[i]) >= 1){
                return true;
            }
        }
        return false;
    }
    function checkVoteElegibility(uint256 _id, address _voter)private view returns(bool){
        for(uint256 i = 0; i < Proposals[_id].canVote.length; i++){
            if(Proposals[_id].canVote[i] == _voter){
                return true;
            }
        }
        return false;

    }
    function createProposal(string memory _description, address[] memory _cantVote) public {
        require(checkProposalEligibility(msg.sender) == true, "Only the NFT holders can put forth proposals");
        
        proposal storage newProposal = Proposals[nextProposal];
        newProposal.id = nextProposal;
        newProposal.exist = true;
        newProposal.descriptions = _description;
        newProposal.deadLine = block.number + 100;
        newProposal.canVote = _cantVote;
        newProposal.maxVotes = _cantVote.length;

        emit proposalCreate(nextProposal, _description, _cantVote.length, msg.sender);
        nextProposal++;

    }

    function voteOnProposal(uint256 _id, bool _vote)public{
        require(Proposals[_id].exist, "this proposal does not exist");
        require(checkVoteElegibility(_id, msg.sender), "you cant not vote on this proposal");
        require(!Proposals[_id].voteStatus[msg.sender],"you have already vote on this proposal");
        require(block.number <= Proposals[_id].deadLine, "the deadLine has passed for this proposal");

        proposal storage p = Proposals[_id];
        if(_vote){
            p.votesUp++;
        }else{
            p.votesDown++;
        }
        p.voteStatus[msg.sender] = true;
        emit newVote(p.votesUp,p.votesDown,msg.sender,_id, _vote);
    }

    function countVotes(uint256 _id) public {
        require(msg.sender == owner, "Only Owner can cont votes");
        require(Proposals[_id].exist, "This proposal does not exist");
        require(block.number > Proposals[_id].deadLine,"Voting has not concluded");
        require(!Proposals[_id].countCounducted, "Count already conted");

        proposal storage p = Proposals[_id];

        if(Proposals[_id].votesDown < Proposals[_id].votesUp){
            p.pased = true;
        }
        p.countCounducted = true;
    }

    function addTokenId(uint256 _tokenId)public{
        require(msg.sender == owner, "Only owner can add Tokens");
        validTokens.push(_tokenId);
    }
}