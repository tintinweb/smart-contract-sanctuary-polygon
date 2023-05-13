/**
 *Submitted for verification at polygonscan.com on 2023-05-13
*/

// SPDX-License-Identifier: MIT

pragma solidity >= 0.7.0<0.9.0;



//making a voting contract

//1. We want the  ability to accept proposals and store  them

//Proposal: their name, number


//2. Voters & Voting ability
//Keep track of voting
//Check Voters are authenticated to vote


//3. Chairman (Entity rep)
//authenticate and deploy contract

contract VotersBox {
    // all the code goes here

    //struct is a refrence data type that can hold multiple pieces of data together (data structures)

    //voters: anyvotes? =  bool, access to vote = uint (who gets access to vote), vote index = uint(votes per user)

    struct Voter {

    uint vote;
    bool anyvotes;
    uint value;
    
    
    }

    struct Proposal {
        //bytes are a basic unit measurement of information in computer processing
    bytes32 name; //name of each proposal
    uint voteCount; //Number of accumulated votes

    }

    

    //Array stores data in series
    Proposal [] public proposals;

    //mappings allow to create a store value with keys and indexes
    
    //Keeping record of voters by address

    mapping(address => Voter ) public voters; //Voters gets the address as a key and voter for value.


    //chairman

    address public chairman;

    //should be in an array

    constructor(bytes32[] memory proposalNames) {
 //memory: Defines a temporary data location during runtime
 //we guarantee space for it


 //??? //We want the chairman to be the one signing the contract so we sign him to msg.sender

  //msg.sender = is a global variable that states the person
  //who is currently connecting to the contract

  chairman = msg.sender;


  // add 1 to chairman value
  voters[chairman].value = 1;

 //Types of loops

    //will add proposal names to the smartcontract upon deployment
    for(uint i=0; i < proposalNames.length; i++ ) {
        //accessing the proposal array nd bytes
        proposals.push(Proposal({
            name: proposalNames[i],
            voteCount: 0
            

         }));

    }

    //(first prameter i=0 initiallizes the loop, second tell me how long you want loop to run)
    //for loop allows us to loop through  proposals in arrays

    
  }

  //function authenticate votes

  function giveRightToVote(address voter) public {
      require(msg.sender == chairman,
      'Only the chairman give access to vote');
      //require that the voter hasn't voted yet
      require(!voters[voter].anyvotes,
            'The voter has already voted');
      require(voters[voter].value == 0);

      voters[voter].value = 1;
            
    }

  //function for voting

    function vote(uint proposal) public{

        Voter storage sender = voters[msg.sender];
        require(sender.value != 0, 'Has no right to vote');
        require(!sender.anyvotes, 'Already voted');
        sender.anyvotes = true;
        sender.vote = proposal;

        proposals[proposal].voteCount = proposals[proposal].voteCount + sender.value;

 }


  // functions for showing results

  //1. function that shows the winning proposal by integer

  function winningProposal() public view returns (uint winningProposal_) {

      uint winningVoteCount = 0;
      for(uint i = 0; i < proposals.length; i++ ) {
          if(proposals[i].voteCount > winningVoteCount) {
              winningVoteCount = proposals[i].voteCount;
              winningProposal_ = i;
          }

      }
  } 

  //2. function that shows the winner by name

  function winningName() public view returns (bytes32 winningName_) {

      winningName_ = proposals[winningProposal()].name;

  }

}