/**
 *Submitted for verification at polygonscan.com on 2022-08-27
*/

// SPDX-License-Identifier: MIT

// File: Congress_flat.sol





pragma solidity ^0.8.16;

abstract contract token  {  mapping(address=>uint256) public balanceOfMember; }


contract Admined {
 address public admin;
 
 event AdminSet(address indexed oldAdmin, address indexed newAdmin);


    constructor() {
        admin = msg.sender; 
        emit AdminSet(address(0), admin);
    }


 modifier onlyAdmin(){
    require(msg.sender == admin) ;
    _;
 }

 function transferAdminship(address newAdmin) onlyAdmin public {
    admin = newAdmin;
 }

}

contract Congress is Admined {

    uint public minimumQuorum;
    uint public minimumDebatingPeriodInMinutes;
    
    Proposal[] public proposals;
    ProposalResponse[] public proposalResponse;
    uint public numProposals;

    
    token public sharesTokenAddress;


    modifier onlyShareholders {
        require(sharesTokenAddress.balanceOfMember(msg.sender) != 0) ;
        _;
    }
    struct Proposal {
        address creator;
        string   text;
        string  ipfsLink;
        uint votingDeadline;
        bool executed;
        bool proposalPassed;
        uint256 minutesForDebate;
        uint numberOfVotes;
        address leader;
        int256 currentResult;
        bytes32 proposalHash;
        Vote[] votes;
        mapping (address => bool) voted;
    }


    struct ProposalResponse {
        address creator;
        string   text;
        string  ipfsLink;
        uint votingDeadline;
        bool executed;
        bool proposalPassed;
        uint256 minutesForDebate;
        uint numberOfVotes;
        address leader;
        int256 currentResult;
        bytes32 proposalHash;
    }

    struct Vote {
        bool inSupport;
        address voter;
    }

    /* First time setup */
    constructor (
        address sharesAddress,
        uint256 _minimumSharesToPassAVote,
        uint256 _minimumDebatePeriod)   {
        setMinimumQuorumNeeded(_minimumSharesToPassAVote);
        setMinimumDebatePeriod( _minimumDebatePeriod);
        sharesTokenAddress = token(sharesAddress);
    }


    function getProposal(uint index) public view returns(ProposalResponse memory, Vote[] memory ){
        ProposalResponse memory resp;
        Vote[] memory respVotes;
        resp.creator = proposals[index].creator;
        resp.text = proposals[index].text;
        resp.ipfsLink = proposals[index].ipfsLink;
        resp.votingDeadline = proposals[index].votingDeadline;
        resp.executed = proposals[index].executed;
        resp.proposalPassed = proposals[index].proposalPassed;
        resp.minutesForDebate = proposals[index].minutesForDebate;
        resp.numberOfVotes = proposals[index].numberOfVotes;
        resp.leader = proposals[index].leader;
        resp.currentResult = proposals[index].currentResult;
        resp.proposalHash = proposals[index].proposalHash;
        respVotes = proposals[index].votes;
        return (resp, respVotes);
    }
    /*change rules*/
    function setMinimumQuorumNeeded(uint256 _minimumSharesToPassAVote) onlyAdmin public {        
        if(_minimumSharesToPassAVote == 0){
            minimumQuorum = 1;
        }else{
            minimumQuorum = _minimumSharesToPassAVote;
        }
    }
     function setMinimumDebatePeriod(uint256 _minimumDebatePeriod)onlyAdmin public {
        minimumDebatingPeriodInMinutes = _minimumDebatePeriod;
     }
    /* Function to create a new proposal */
    function createProposal(
        string memory _text,
        string memory _ipfsLink,
        uint256 _minutesForDebate,
        address _leader
       ) onlyShareholders public returns (uint256 proposalID){

        require(_minutesForDebate >= minimumDebatingPeriodInMinutes, "Minutes for debate is too short, it should be greater than allowed, check the Minimum Debating Period In Minutes");


        proposalID = proposals.length;

        proposals.push();


        Proposal storage p = proposals[proposalID];

        
    
        p.leader = _leader;        
        p.creator = msg.sender;
        p.text = _text;
        p.minutesForDebate = _minutesForDebate;
        p.proposalHash = keccak256(abi.encodePacked(msg.sender, _text, _ipfsLink));
        // This is the link of the proposal attachments uploaded in the ipfs.
        p.ipfsLink = _ipfsLink;
        p.votingDeadline = block.timestamp + (_minutesForDebate * 1 minutes);
        p.proposalPassed = false;
        p.executed = false;
        p.numberOfVotes = 0;
        
        return proposalID ; 
  
    }

    /* function to check if a proposal code matches */
    function checkProposalCode(
        uint proposalNumber, 
        address beneficiary, 
        string memory text )  public view returns (bool codeChecksOut){
        Proposal storage p = proposals[proposalNumber];
        return p.proposalHash == keccak256(abi.encodePacked(beneficiary, text, p.ipfsLink));
    }

    // function to vote in a proposal
    function vote(
        uint256 proposalNumber,
        bool supportsProposal) onlyShareholders public returns (uint256 voteID){
        
      require(supportsProposal == true || supportsProposal == false, "Input should only be true or false. No other text is accepted!");
        
        Proposal storage p = proposals[proposalNumber];
        voteID = p.votes.length;
        p.votes.push();

        //certifica que o emissor nao votou ainda. 
        // TODO: verificar se o emissor pode votar novamente se o voto dele for falso. Caso seja o caso, rever o codigo abaixo.
        require(!p.voted[msg.sender], "You have already voted on this proposal");
        
        p.voted[msg.sender] = true;
        
        
        
        //record the vote (in support or against support).
        p.votes[voteID].inSupport= supportsProposal;

        //record the voter user.
        p.votes[voteID].voter= msg.sender;

        //if vote is in support, updates the current result by + 1 vote.
        if(supportsProposal==true){
            p.currentResult++;
        }

        //update total number of votes in the proposal
        p.numberOfVotes++;
        
        //returns the vote id
        return voteID;
    }

    function executeProposal(uint proposalNumber) public {
        
     Proposal storage p = proposals[proposalNumber];
      
      require(block.timestamp > p.votingDeadline, "The Proposal can only be executed after deadline is finished.") ;
      require(p.executed == false , "This proposal has already been executed.") ;
      require(p.proposalHash == keccak256(abi.encodePacked(p.creator, p.text, p.ipfsLink)) , "The proposal hash is incorrect, please check the correct one.") ;
      

      uint quorum = 0;
      uint yea = 0;
      uint nay = 0;

      for(uint i=0; i< p.votes.length; i++){
        Vote storage v = p.votes[i];

        //TODO: Uncomment this lines if you want weighted votig power.
        //Need to check the business rule here, if each member will have only one vote or if they will have multiple weighted voting power.
        // uint voteWeight = sharesTokenAddress.balanceOfMember(v.voter);\

        uint voteWeight = 1;
        quorum += voteWeight;
        if(v.inSupport){
            yea += voteWeight;
        }
        else{
            nay += voteWeight;
        }
      }

      require(quorum>=minimumQuorum, "The minimum quorum has not been achieved yet. Proposal cannot be executed!");
      
       if(yea > nay){
        p.executed = true;     
        p.proposalPassed = true;
      }
      else{
        p.proposalPassed = false;
      }
    }

    function checkIfUserHasAlreadyVoted(address _voter, uint256 _proposalNumber ) public view returns(string memory result){

        Proposal storage p = proposals[_proposalNumber];
        
        if(  p.voted[_voter]){
            result=  "User has already voted";
        }else{
            result= "User has not voted yet";
        }
        return result;
    }

    


}