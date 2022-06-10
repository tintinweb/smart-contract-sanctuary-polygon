//SPDX-License-Identifier:MIT


pragma solidity ^0.8.0;


error CanNotvote();
error PropNotAvailable();
error VotedAlready();
error TimeOver();
error notTheOwner();
error NoPropConducted();


interface Idao {
    function Balance(address, uint256) external view returns(uint256);
}



contract Dao{


address public Owner;
uint256 public nextprop;
uint256[] public ValidTokens;


Idao daocontract;

constructor(){
  Owner=msg.sender; 
  nextprop = 1;
  daocontract = Idao(0x2953399124F0cBB46d2CbACD8A89cF0599974963);
  ValidTokens =[93591818639817583336275112853502461865657017876683301261702518973803639341057];


}



// an object with variables
struct proposal {

uint256 id;
bool exists;
string description;
uint deadline;
uint256 votesUp;
uint256 votesDown;
address [] canvote;
uint256 maxVotes;
mapping(address=>bool) voteStatus;
bool countConducted;
bool passed;

}


mapping(uint256=>proposal) public Proposals;


event proposalCreation(

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


function checkpropEli(address _propolist) private view returns(bool){

for(uint i = 0; i <ValidTokens.length; i++){
if(daocontract.Balance(_propolist, ValidTokens[i]) >= 1)
return true;
}
    return false;
}



function checkVotepropEli(uint256 _id , address _voter) private view returns(bool){

for(uint i = 0; i <Proposals[_id].canvote.length; i++){
if(Proposals[_id].canvote[i] == _voter)
return true;
}
    return false;
}


function createProposal(string memory _description, address []memory _canvote ) public {


if(!checkpropEli(msg.sender)){
    revert CanNotvote();
}else{

   proposal storage NewProp = Proposals[nextprop];
   NewProp.id = nextprop;
   NewProp.exists = true;
   NewProp.description = _description;
   NewProp.deadline = block.number + 100;
   NewProp.canvote = _canvote;
   NewProp.maxVotes = _canvote.length;


emit proposalCreation(nextprop, _description, _canvote.length, msg.sender);

nextprop++;

}

}


function VoteOnprop(uint256 _id, bool _vote) public {

if(! Proposals[_id].exists){
   revert  PropNotAvailable();
}

 else if (checkVotepropEli(_id, msg.sender)){

 revert CanNotvote();
}   

 else if (! Proposals[_id].voteStatus[msg.sender]){

 revert VotedAlready();
} 

 else if (block.number <= Proposals[_id].deadline){

 revert TimeOver();
}

else {

// you can vote....

proposal storage props = Proposals[_id];
if(_vote){
props.votesUp ++;
}else {
  props.votesDown++;
}

props.voteStatus[msg.sender] = true;

emit newVote(props.votesUp, props.votesDown, msg.sender, _id, _vote);

}




}

function countVotes(uint256 _id) public Onlyowner{

 if( Owner != msg.sender ){
      revert notTheOwner();
    }

    else if(!Proposals[_id].exists){
revert PropNotAvailable();
    }

     else if(block.number > Proposals[_id].deadline){
revert TimeOver();
    }

  else if(!Proposals[_id].countConducted){
revert NoPropConducted();
    }

    else {

        proposal storage props = Proposals[_id];
        if(Proposals[_id].votesUp > Proposals[_id].votesDown){
            props.passed = true;

        }
      props.countConducted = true;

      emit proposalCount(_id, props.passed);
    }
 
}


function AddvalidToken(uint256 _tokenID) public  {
     if( Owner != msg.sender ){
      revert notTheOwner();
    }
    else{
ValidTokens.push(_tokenID);
    }
}

modifier Onlyowner{

    if( Owner == msg.sender ){
      _;
    }
}


}