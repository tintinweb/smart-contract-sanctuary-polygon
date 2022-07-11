// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;


interface OpenSeaInterface {
    function balanceOf(address, uint256) external view returns (uint256);
}

contract ArnoldDAO {

    address nftCollection;
    address public owner;
    uint256 nextProposal;
    uint256[] public validTokenIDs;
    OpenSeaInterface daoContract;


    constructor(){
        owner = msg.sender;
        nextProposal = 1;
        daoContract = OpenSeaInterface(0x2953399124F0cBB46d2CbACD8A89cF0599974963);
        validTokenIDs = [4355215207997603174917320179892390414915335483180348621717618333180470755339];
    }


    struct proposal {
        uint id;
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

    event newVote(
        uint256 votesUp,
        uint256 votesDown,
        address voter,
        uint256 proposal,
        bool voteFor
    );

    event proposalCount(
        uint256 id,
        bool passed
    );


    function checkProposalEligibility(address _proposalist) private view returns (
        bool
    ){
        for(uint i = 0; i < validTokenIDs.length; i++){
            if(daoContract.balanceOf(_proposalist, validTokenIDs[i]) >= 1){
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


    function createProposal(string memory _description, address[] memory _canVote) public {
        require(checkProposalEligibility(msg.sender), "Only NFT holders can put forth Proposals");

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
        require(checkVoteEligibility(_id, msg.sender), "You can not vote on this Proposal");
        require(!Proposals[_id].voteStatus[msg.sender], "You have already voted on this Proposal");
        require(block.number <= Proposals[_id].deadline, "The deadline has passed for this Proposal");

        proposal storage p = Proposals[_id];

        if(_vote) {
            p.votesUp++;
        }else{
            p.votesDown++;
        }

        p.voteStatus[msg.sender] = true;

        emit newVote(p.votesUp, p.votesDown, msg.sender, _id, _vote);
        
    }



}