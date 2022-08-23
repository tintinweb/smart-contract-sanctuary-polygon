/**
 *Submitted for verification at polygonscan.com on 2022-08-23
*/

// SPDX-License-Identifier: MIT
// File: DAO_flat.sol


pragma solidity ^0.8.6;

contract token { mapping(address=>uint256) public balanceOf; }

contract Admined {
 address public admin;

 function admined() public {
    admin = msg.sender;
 }

 modifier onlyAdmin(){
    require(msg.sender == admin) ;
    _;
 }

 function transferAdminship(address newAdmin) onlyAdmin public {
    admin = newAdmin;
 }

}

contract Association is Admined {

    uint public minimumQuorum;
    uint public debatingPeriodInMinutes;
    
    Proposal[] public proposals;
    uint public numProposals;

    
    token public sharesTokenAddress;

    modifier onlyShareholders {
        require(sharesTokenAddress.balanceOf(msg.sender) != 0) ;
        _;
    }

    struct Proposal {
        address recipient;
        string   text;
        string  jobDescription;
        uint votingDeadline;
        bool executed;
        bool proposalPassed;
        uint numberOfVotes;
        int currentResult;
        bytes32 proposalHash;
        Vote[] votes;
        mapping (address => bool) voted;
    }

    struct Vote {
        bool inSupport;
        address voter;
    }

    /* First time setup */
    function setAssociation(
        address sharesAddress,
        uint minimumSharesToPassAVote,
        uint minutesForDebate,
        address leader) payable public {
        changeVotingRules(sharesAddress, minimumSharesToPassAVote, minutesForDebate);
        if(leader == address(0)) admin = msg.sender;
        else admin = leader;

    }

    /*change rules*/
    function changeVotingRules(
        address sharesAddress,
        uint minimumSharesToPassAVote,
        uint minutesForDebate) onlyAdmin public {
        sharesTokenAddress = token(sharesAddress);
        if(minimumSharesToPassAVote == 0) minimumSharesToPassAVote = 1;
        minimumQuorum = minimumSharesToPassAVote;
        debatingPeriodInMinutes = minutesForDebate;

    }

    /* Function to create a new proposal */
    function newProposal(
        address beneficiary,
        string memory text,
        string memory jobDescription,
        bytes32 transactionBytecode) onlyShareholders public returns (uint256 proposalID){

        proposalID = proposals.length;

        proposals.push();

        Proposal storage p = proposals[proposalID];
        p.recipient= beneficiary;
        p.text=text;
        p.proposalHash= keccak256(abi.encodePacked(beneficiary, text, transactionBytecode));
        p.jobDescription= jobDescription;
        p.votingDeadline= block.timestamp + (debatingPeriodInMinutes * 1 minutes);
        p.proposalPassed=false;
        p.executed=false;
        p.numberOfVotes= 0;
        
        return proposalID;
    }

    /* function to check if a proposal code matches */
    function checkProposalCode(
        uint proposalNumber, 
        address beneficiary, 
        string memory text,
        bytes32 transactionBytecode)  public view returns (bool codeChecksOut){
        Proposal storage p = proposals[proposalNumber];
        return p.proposalHash == keccak256(abi.encodePacked(beneficiary, text, transactionBytecode));
    }

    function vote(
        uint256 proposalNumber,
        bool supportsProposal) onlyShareholders public returns (uint256 voteID){
        
        
        Proposal storage p = proposals[proposalNumber];
        
        p.votes.push();

        //certifica que o emissor nao votou ainda. 
        // TODO: verificar se o emissor pode votar novamente se o voto dele for falso. Caso seja o caso, rever o codigo abaixo.
        require(!p.voted[msg.sender], "You have already voted on this proposal");
        
        p.voted[msg.sender] = true;
        
        voteID = p.votes.length;
        
        //votos tem que ser anonimos? ou devem mostrar quem votou em qual opcao?
        p.votes[voteID] = Vote({inSupport: supportsProposal, voter: msg.sender});

        //atualiza o total de votos registrados na proposta
        p.numberOfVotes++;
        
        return voteID;
    }

    function executeProposal(uint proposalNumber, bytes32 transactionBytecode) public {
        
     Proposal storage p = proposals[proposalNumber];
      
      if(block.timestamp < p.votingDeadline || 
        p.executed ||
        p.proposalHash != keccak256(abi.encodePacked(p.recipient, p.text, transactionBytecode))
        )
      return;

      uint quorum = 0;
      uint yea = 0;
      uint nay = 0;

      for(uint i=0; i< p.votes.length; i++){
        Vote storage v = p.votes[i];
        uint voteWeight = sharesTokenAddress.balanceOf(v.voter);
        quorum +=voteWeight;
        if(v.inSupport){
            yea += voteWeight;
        }
        else{
            nay += voteWeight;
        }
      }

      if(quorum <= minimumQuorum){
        return;
      }
      else if(yea > nay){
        p.executed = true;     
        p.proposalPassed = true;
      }
      else{
        p.proposalPassed = false;
      }
    }

    function getNumProposals()  public view returns (uint256 totalProposals){
        totalProposals = proposals.length;
        return totalProposals;
    }


}