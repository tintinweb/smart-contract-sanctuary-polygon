// SPDX-License-Identifier:MIT
pragma solidity ^0.8.7;

//using interface to access the function of other smart contract. Here we accessing the balance function to check the balance.
interface IdaoContract{
    function balanceOf(address, uint256) external view returns (uint256);
    
}

contract Dao {
    address public owner; // Address to define the owner of the contract who set the proposals.
    uint256 nextProposal; // Every proposal must contains the proposal number to identify the proposal. 
    uint256[] public validTokens; // This is the list of address who holds the 
    IdaoContract daoContract; // Defining the variable to access the smart contract from where the functions has been accessed through interface.

constructor(){
    owner = msg.sender; 
    nextProposal = 1;
    daoContract = IdaoContract(0x6c92624A68c4D71593fdbBC9b6558a4DC49dF0fE); // Here we mentioning the contract whoes funtion we are accessing through interface. 
    validTokens = [0]; // The address of the token been mentoined here
}
// The struct is defining the variables of the specifications of the proposal. 
struct proposal{
    uint256 id; 
    bool exists; // To check the contract ID or Name exists or not. 
    string description; // Tel about the proposal.
    uint deadline; // Deadline untill voting is live. 
    uint256 votesUp;
    uint256 votesDown;
    address[] canVote; //  List of addresess who hold the valid NFT tokens
    uint256 maxVotes; // The max votes is just the length of canVote array.
    mapping(address => bool) voteStatus; // To check the status of the proposal is still live or deadline is over. 
    bool countConducted; // 
    bool passed; // If most of the votes are up then passed be true. 
}
mapping (uint256 => proposal) public Proposals; // To make the proposal struct public, we mapped the proposal id to proposal

// This event will be emited after the proposal will be created. This shows the necessary information regarding the proposal.
// proposer means to show who is the owner of the contract.
event proposalCreated(
    uint256 id,
    string description,
    uint256 maxVotes,
    address proposer 
);

// This will be emited right after any voter votes for proposal. 
// It shows the current votesUp and votesDown along with the voter address, proposal ID and voter voted for votesUp or votesDown.
event newVote(
    uint256 votesUp,  
    uint256 votesDown,   
    address voter,
    uint256 proposal,
    bool votedFor
);

// This will be emited after the owner counts the voter. This simply records the proposal ID and shows the proposal is passed or not
event proposalCount(
    uint256 id,
    bool passed
);

// Private function is generated to check the eligibility of voter to vote.
// It check the balance of listed validTokens.
function checkProposalEligibility(address _proposalist) private view returns ( bool  ){
    for(uint i = 0; i < validTokens.length; i++){ 
        if (daoContract.balanceOf(_proposalist, validTokens[i] ) >= 1){ 
            return true;
        }
        return false;
    }
}

// Through this private function we check the voter is in the canVote list who are allowed to vote on specific proposal.
function checkVoteEligibility(uint256 _id, address _voter) private view returns (bool){
    for(uint i = 0; i < Proposals[_id].canVote.length; i++){
        if(Proposals[_id].canVote[i] == _voter ){
            return true;
        } else {
        return false;
        }
    }

}



// Function to create proposal.
function createProposal(string memory _description, address[] memory _canVote)  public {

    require (checkProposalEligibility(msg.sender), "Only NFT holders can put forth Proposals"); // Check condition the owner contains the balance of tokens.

    proposal storage newProposal = Proposals[nextProposal]; // Set the Proposal id to proposal mapping.
    newProposal.id = nextProposal;
    newProposal.description = _description;
    newProposal.exists = true;
    newProposal.canVote = _canVote;
    newProposal.deadline = block.number + 50;
    newProposal.maxVotes = _canVote.length; // Set the addresses who can participates in proposals voting.

    emit proposalCreated(nextProposal, _description, _canVote.length, msg.sender);
    nextProposal++;

}

function createVote(uint256 _id, bool _vote) public {
    require (Proposals[_id].exists, "Proposal does not exists");
    require(!Proposals[_id].voteStatus[msg.sender], "You have already voted for the proposal");
    require(checkVoteEligibility(_id, msg.sender), "Only the listed accounts can vote ");
    require(block.number <= block.number + 50, "Deadline Over");

    proposal storage p = Proposals[_id];
    if(_vote) {
        p.votesUp++;
    } else {
    p.votesDown++;
    
    }

    p.voteStatus[msg.sender] = true;

    emit newVote(p.votesUp, p.votesDown, msg.sender, _id,  _vote);

}



function countVotes(uint256 _id) public {
    require(msg.sender == owner, "Only owner can count votes");
    require(Proposals[_id].exists, "This proposal does not exist");
    require(block.number > Proposals[_id].deadline, "Voting has not conducted");
    require(!Proposals[_id].countConducted, "Count already conducted");

    proposal storage p = Proposals[_id];

    if(Proposals[_id].votesDown < Proposals[_id].votesUp){
        p.passed = true ;
    }

    p.countConducted = true;

    emit proposalCount(_id, p.passed);

}


function addTokenId(uint256 _tokenId) public {
require(msg.sender == owner, "Only owner can add tokens");

validTokens.push(_tokenId);
}

}