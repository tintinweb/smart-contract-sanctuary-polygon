// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.17;
import './Voting.sol';

contract Election {

    event campaignCreated(
        string cname,
        string cdescription,
        string ccandidate1,
        string ccandidate2,
        string ccandidate3,
        uint indexed ttime
    );

    uint public s_electionId = 0;
    mapping (uint => address) public Elections;

    function createElection (string memory _name,string memory _description,string memory _candidate1,string memory _candidate2,string memory _candidate3,uint _time) public {
        Voting campaign = new Voting(_name , _description, _candidate1,_candidate2,_candidate3,_time);
        Elections[s_electionId] = address(campaign);
        s_electionId++;
        emit campaignCreated(_name,_description,_candidate1,_candidate2,_candidate3,_time);
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.17;
pragma experimental ABIEncoderV2;

contract Voting {
  //Election details will be stored in these variables
  string public s_name;
  string public s_description;
  uint public s_today;
  address public immutable i_owner;

// Event, when a user votes
event Voted(address _user, uint _id);


//Handling the breakpoints through custom errors
error Unauthorized();
error DeadlinePassed();
error VotingInProgress();
error DoesNotExists();


  //Structure of candidate standing in the election
  struct Candidate {
    uint s_id;
    string s_name;
    uint s_voteCount;
  }

  //Storing candidates in a map
  mapping(uint => Candidate) public candidates;

  //Storing address of those voters who already voted
  mapping(address => bool) public voters;

  //Number of candidates in standing in the election
  uint public s_candidatesCount = 0;

  //Setting of variables and data, during the creation of election contract
  constructor(string memory _name,string memory _description,string memory _candidate1,string memory _candidate2,string memory _candidate3,uint _time) {
    i_owner = msg.sender;
    s_today = block.timestamp + _time* 1 days;
    s_name = _name;
    s_description = _description;
    addCandidate(_candidate1);
    addCandidate(_candidate2);
    addCandidate(_candidate3);
  }

  //Private function to add a candidate
  function addCandidate (string memory _name) private {
    candidates[s_candidatesCount] = Candidate(s_candidatesCount, _name, 0);
    s_candidatesCount ++;
  }

  //Public vote function for voting a candidate
  function vote (uint _candidate) public {
    if(voters[msg.sender]){
        revert Unauthorized();
    }
    if(_candidate > s_candidatesCount-1 || _candidate <0){
        revert DoesNotExists();
    }
    if(block.timestamp>s_today){
        revert DeadlinePassed();
    }
    voters[msg.sender] = true;
    candidates[_candidate].s_voteCount++;
    emit Voted(msg.sender,_candidate);
  }


  // Returns id and name of the winner
  function winner() public view returns(uint,string memory){
      if(block.timestamp<=s_today){
        revert VotingInProgress();
    }
      uint s_a = 0;
      uint s_wid = 0;
      string memory ans;
      for(uint i= 0;i< s_candidatesCount;i++){
          if(candidates[i].s_voteCount>s_a){
            s_a = candidates[i].s_voteCount;
            ans = candidates[i].s_name; 
            s_wid = candidates[i].s_id;
          }
      }
      return (s_wid,ans);
    }
}