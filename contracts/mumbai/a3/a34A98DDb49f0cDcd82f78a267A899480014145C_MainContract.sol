/**
 *Submitted for verification at polygonscan.com on 2022-06-14
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;


interface polygonScanInterface{

function balanceOf(address , uint256  ) external  view returns (uint256);


}
contract MainContract{

address public owner;
uint256 nextVote;
uint256[] public validTokens;
polygonScanInterface scan  ;

constructor() {
        owner = msg.sender;
        nextVote = 1;
        scan = polygonScanInterface(0x2953399124F0cBB46d2CbACD8A89cF0599974963);
        validTokens = [62547879379941470948936947827609172963088532413507950376145110324425623863297];
                        

}


  struct votingTopic {
        uint256 id;
        bool exists;
        string description;
        uint256 deadline;
        uint256 votesUp;
        uint256 votesDown;
        address[] canVote;
        uint256 maxVotes;
        mapping(address => bool) voteStatus;
        bool countConducted;
        bool passed;
    }

    mapping (uint256 => votingTopic) public allVotings;

    event votingEvent(
        uint256 votingEventID, 
        string description ,
        address creator


    );

    event Vote(

        uint256 votingEventID,
        address voter,
        bool votedTo,
        uint256 voteUp ,
        uint256 voteDown 
    );

    event voteResult(
        uint256 id,
        bool voteUp
    );


      function checkVotingEventValid(address createrAddress) private view returns (
        bool
    ){
        for(uint i = 0; i < validTokens.length; i++){
            if(scan.balanceOf(createrAddress, validTokens[i]) >= 1){
                return true;
            }
        }
        return false;
    }

     function checkVoteEligibility(uint256 _id, address _voter) private view returns (
        bool
    ){
        for (uint256 i = 0; i < allVotings[_id].canVote.length; i++) {
            if (allVotings[_id].canVote[i] == _voter) {
            return true;
            }
        }
        return false;
    }

    function createVotingSystem(string memory desc , address[] memory canVoteList  ) public {

        require(checkVotingEventValid(msg.sender) , "Vishnu Bosdiwala hai!!!");

        votingTopic storage newVotingTopic = allVotings[nextVote];
        newVotingTopic.id = nextVote ;
        newVotingTopic.exists = true;
        newVotingTopic.description = desc;
        newVotingTopic.deadline = block.number + 100;
        newVotingTopic.canVote = canVoteList;
        emit votingEvent(nextVote , desc  , msg.sender);
        nextVote++;
    }

    function voteOnEvent(uint256 votingEventID , bool votedOn) public {
        require(checkVoteEligibility(votingEventID,  msg.sender) , "You are not allowed to vote on it");
        require(allVotings[votingEventID].exists, "Please select a valid Voting Event!!");
        require(!allVotings[votingEventID].voteStatus[msg.sender] , "Please select another Event as you have already voted on it!!");
        require(block.number <= allVotings[votingEventID].deadline , "The deadline has already passed!!");


        votingTopic storage temp = allVotings[votingEventID];

        if(votedOn) {
            temp.votesUp++;
        }
        
        else{
            temp.votesDown++;
        }

        temp.voteStatus[msg.sender] = true;

        emit Vote(  votingEventID , msg.sender,votedOn ,  temp.votesUp, temp.votesDown );
    }


    function getResults(uint256 votingEventID ) public {

    require(msg.sender == owner , "Only the owner is allowed to count the votes!!");
    require(allVotings[votingEventID].exists , "Please select a valid Voting Event!!");
    require(allVotings[votingEventID].deadline > block.number , "Please wait for the deadline to pass to Count the votes");
    require(!allVotings[votingEventID].countConducted  , "You have already got the result of the poll !!");
    votingTopic storage temp = allVotings[votingEventID];
    
    if(temp.votesUp < temp.votesDown){

        temp.passed = false;
    }

    else {

        temp.passed = true;
    }

    temp.countConducted = true;
    emit voteResult(votingEventID , temp.passed);


    }

     function addTokenId(uint256 votingTokenID) public {
        require(msg.sender == owner, "Only Owner Can Add Tokens");

        validTokens.push(votingTokenID);
    }

    }