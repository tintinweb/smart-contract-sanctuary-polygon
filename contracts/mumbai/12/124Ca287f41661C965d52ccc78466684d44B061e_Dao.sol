//SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;


interface IdaoContract {
    function balanceOf(address, uint256) external view returns (uint256);
}

contract Dao{

    address public owner;
    uint256 nextProposal;
    uint256[] public validTokens;
    IdaoContract daoContract;

    constructor(){
        owner = msg.sender;
        nextProposal = 1;
        daoContract = IdaoContract(0x2953399124F0cBB46d2CbACD8A89cF0599974963);
        validTokens = [12835986292511335873938670637662345165934733163599367773378791909421020610561];
    }

    struct proposal{
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

//This event shows when a proposal was created
    event proposalCreated(
        uint256 id,
        string description,
        uint256 maxVotes,
        address proposer
    );

//This event tell us when a new vote was casted, why votes up and down?
    event newVote(
        uint256 proposalId,
        uint256 votesUp,
        uint256 votesDown,
        address voter,
        bool votedFor
    );
    
//This event give us information if the proposal was accepted or rejected
    event proposalCount(
        uint256 proposalId,
        bool result
    );

//proposalist is the persion trying to do something in the proposal, then checks if this address owns the nft required to interact with the proposal and return true if does or false if not
    function checkProposalElegibility(address _proposalist) private view returns ( 
        bool 
    ){
        for(uint i = 0; i < validTokens.length; i++ ){
            if(daoContract.balanceOf(_proposalist, validTokens[i]) >= 1){
                return true;
            }   
        }
        return false;
    }

//Checks if the address is inside the proposal for elegibility
    function checkVoteElegibility(uint _id, address _voter) private view returns (
        bool
    ){
        for(uint i = 0; i < Proposals[_id].canVote.length; i++){
            if(Proposals[_id].canVote[i] == _voter){
                return true;
            }
        }
        return false;   
    }


    function createProposal(string memory _description, address[] memory _canVote) public {
        require(checkProposalElegibility(msg.sender), 'Only NFT holders can put forth Proposals');

        proposal storage newProposal = Proposals[nextProposal];
        newProposal.id = nextProposal;
        newProposal.exists = true;
        newProposal.description = _description;
        newProposal.deadline = block.number + 100;
        newProposal.canVote = _canVote;
        newProposal.maxVotes = _canVote.length;

        emit proposalCreated(nextProposal, _description, _canVote.length , msg.sender);
        nextProposal++;
    }

    function voteOnProposal(uint256 _id, bool _vote) public{
        require(Proposals[_id].exists, "This proposal does not exists");
        require(checkVoteElegibility(_id, msg.sender), 'You are not elegibility to vote here');
        require(!Proposals[_id].voteStatus[msg.sender], 'You already voted');
        require(Proposals[_id].deadline >= block.number, 'The deadlines for this proposal is due');

        proposal storage p = Proposals[_id];
        if(_vote){
            p.votesUp++;
        }
        else{
            p.votesDown++;
        }
        p.voteStatus[msg.sender] = true;

        //Emit the event once a new votes was casted
        emit newVote(_id, p.votesUp, p.votesDown, msg.sender, _vote);
    }

    function countVotes(uint256 _id) public {
        require(msg.sender == owner, 'You are not elegible to count te votes');
        require(Proposals[_id].exists, "This proposal does not exists");
        require(Proposals[_id].deadline < block.number, 'The deadline is not due yet');
        require(!Proposals[_id].countConducted, 'Votes already counted');

        proposal storage p = Proposals[_id];

        if(Proposals[_id].votesUp > Proposals[_id].votesDown){
            p.passed = true;
        }else{
            p.passed = false;
        }
        p.countConducted = true;

        emit proposalCount(_id, p.passed);

    }

    function addValidToken(uint256 _tokenId ) public {
        require(msg.sender == owner, 'Only the owner of the contract can add tokens');
        // We could try to check if the tokens are not repeating****

        validTokens.push(_tokenId);
    }

      
}