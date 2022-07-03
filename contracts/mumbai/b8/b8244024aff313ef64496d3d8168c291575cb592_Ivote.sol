/**
 *Submitted for verification at polygonscan.com on 2022-07-02
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;


contract Ivote {

    struct Participant {
        string name;
        uint256 age;
        string team;
        bool isParticipant;
    }

    struct Voter {
        string name;
        uint256 age;
        bool isVoter;
        address votedFor;
    }

    struct Election {

        mapping(address => Voter) voters;
        mapping(address => Participant) participants;

        mapping(address => uint256 ) votes;

        uint256 startTime;
        uint256 endTime;

        string description;       
    }

    mapping (bytes32 => Election) public _elections;


    event NewElection(
        bytes32 _electionID,
        uint256 _startTime,
        uint256 _endTime,
        string _description
    );

    event participantAdded(
        bytes32 _electionID,
        address _participant,
        string _name,
        string _team,
        uint _age
    );

    event VoterAdded(
        bytes32 _electionID,
        address _voter,
        string _name,
        uint _age
    );

    event NewVote(
        bytes32 _electionID,
        address _voter,
        address _participant,
        uint _timestamp
    );


    function startElection(
        uint256 _startTime,
        uint256 _endTime,
        string memory _description
    ) public {

        require(_startTime >= block.timestamp && _endTime >= block.timestamp, "ENTER VALID END TIME");

        bytes32 _electionID = keccak256(abi.encodePacked(
            block.timestamp,
            msg.sender,
            block.difficulty
        ));

        Election storage election = _elections[_electionID];

        election.startTime = _startTime;
        election.endTime = _endTime;
        election.description = _description;
    
        emit NewElection(_electionID, _startTime, _endTime, _description);
    }

    function addParticipants(
        bytes32 _electionID,
        address _participant,
        string memory _name,
        string memory _team,
        uint256 _age
    ) public {

        require(_elections[_electionID].startTime >= block.timestamp);

        Election storage election = _elections[_electionID];

        election.participants[_participant] = Participant({name: _name, team: _team, age: _age, isParticipant: true}); 
    
        emit participantAdded(_electionID, _participant, _name, _team, _age);
    }

    function addVoters(
        bytes32 _electionID,
        address _voter,
        string memory _name,
        uint256 _age
    ) public {

        require(_elections[_electionID].startTime >= block.timestamp);

        Election storage election = _elections[_electionID];

        election.voters[_voter] = Voter(_name, _age, true, address(0)); 

        emit VoterAdded(_electionID, _voter, _name, _age);
    }

    function vote(
        bytes32 _electionID,
        address _participant
    ) public {

        require(_elections[_electionID].startTime >= block.timestamp && _elections[_electionID].startTime <= block.timestamp);

        Election storage election = _elections[_electionID];

        require(election.participants[_participant].isParticipant && election.voters[msg.sender].isVoter);


        election.votes[_participant] += 1;

        emit NewVote(_electionID, msg.sender, _participant, block.timestamp);
    }

}