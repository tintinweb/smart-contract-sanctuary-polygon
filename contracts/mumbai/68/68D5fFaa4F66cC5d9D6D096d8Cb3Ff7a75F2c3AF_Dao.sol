// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface Idaocontract{
    function balanceof(address,uint256) external view returns(uint256);
} 

contract Dao {


    address owner;           
    uint256 nextProposal;
    uint256[] validTokens;
    
    Idaocontract daocontract;
    
    struct proposal{

        uint256 id;                                //for unique identification
        bool exists;                               //    
        string description;                           
        uint256 deadline;
        uint256 upVote;
        uint256 downVote;
        address[] canVote;                         //address that can vote
        uint256 maxVote;
        mapping(address=>bool) voteStatus;
        bool countConducted;
        bool passed;
    }

    constructor(){
        owner=msg.sender;
        nextProposal=1;
        daocontract=Idaocontract(0x2953399124F0cBB46d2CbACD8A89cF0599974963);
        validTokens=[11769611392773120373146502657938114886054692203715088867371120654424790269972];
    }

    mapping(uint256=>proposal) public Proposals;
    
    event proposalCreated(
        uint256 id,
        string description,
        uint256 maxVote,
        address proposer
    );
        
    event newVote(
        uint256 upVote,
        uint256 downVote,
        address voter,
        uint256 proposal,
        bool votedFor
    );

    event proposalConclusion(
        uint256 id,
        bool passed
    );

    function checkProposalEligiblity( address _proposalist) private view returns(bool){

        for( uint256 i=0 ;i < validTokens.length ; i++){
            if(daocontract.balanceof(_proposalist,validTokens[i]) >= 1 ){
                return true;
            }
        }
        return false;
    }
     
    function checkVoteEligiblity( uint256 _id, address _voter) private view returns(bool){

        for(uint256 i=0; i< Proposals[_id].canVote.length ;i++){
            if(_voter == Proposals[_id].canVote[i]){
                return true;
            } 
        }
        return false;
    }

    function createProposal( string memory _description,address[] memory _canVote) public {
        
        require(checkProposalEligiblity(msg.sender),"Only NFT holder can forth the proposal");

        proposal storage newProposal = Proposals[nextProposal];
        newProposal.id=nextProposal;
        newProposal.description=_description;
        newProposal.deadline= block.number + 100;
        newProposal.canVote=_canVote;
        newProposal.maxVote=_canVote.length;
        newProposal.exists=true;

        emit proposalCreated(nextProposal,_description,_canVote.length,msg.sender);
        nextProposal++;

    }

    function addVote( uint256 _id,bool _vote) public{

        require(Proposals[_id].exists,"NO such proposal exist");
        require(checkVoteEligiblity(_id, msg.sender),"Only Nft holder can vote");
        require( !Proposals[_id].voteStatus[msg.sender],"You already Voted for this Proposal");
        require(block.number <= Proposals[_id].deadline ,"The deadline has passed for this proposal");

        Proposals[_id].voteStatus[msg.sender]=true;
        if(_vote){
            Proposals[_id].upVote+=1;
        }
        else{
            Proposals[_id].downVote+=1;
        }
        emit newVote(Proposals[_id].upVote,Proposals[_id].downVote,msg.sender,_id,_vote);
    }
    
    function isPassed(uint _id) public{
        require(msg.sender==owner,"only Owner can count votes");
        require(Proposals[_id].exists,"NO such proposal exist");
        require(block.number > Proposals[_id].deadline,"Propsal Not yet reached the deadline");
        require( !Proposals[_id].countConducted ,"Voting has already been done");
         
        proposal storage p = Proposals[_id];
        p.countConducted=true; 
        if(p.upVote > p.downVote){
            p.passed=true;
        }
        emit proposalConclusion(_id,p.passed);

    }

    function addToken(uint256 _tokenID) public{
        require(msg.sender==owner,"Only owner can add token");
        validTokens.push(_tokenID);

    }
}