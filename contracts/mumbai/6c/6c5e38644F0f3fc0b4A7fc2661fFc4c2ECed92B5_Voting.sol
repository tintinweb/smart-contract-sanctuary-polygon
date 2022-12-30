/**
 *Submitted for verification at polygonscan.com on 2022-12-29
*/

pragma solidity ^0.8.17;

contract Voting {
    string public name = "Voting webApp";
    uint256 public totalCandidates = 0;
    uint256 public totalVoters = 0;
    uint256 public toRegisterCount = 0;

    struct Candidate {
        uint256 id;
        string name;
        uint256 voteCount;
        address author;
    }

    bool _start=false;
    uint _end;

    event CandidateAdded(
        uint256 id,
        string name,
        uint256 voteCount,
        address author
    );

    modifier myTimer{
        require(_start,"The Voting time has not yet started");
        require(block.timestamp<=_end,"The Voting time is over");
        _;
    }

    mapping(uint256 => Candidate) public candidates;
    mapping(address => bool) public voters;
    mapping(address => bool) public registers;
    mapping(uint256 => address) public toRegister;
    mapping(address => bool) public registered;

    function startVoting() public{
        _end=block.timestamp+10000;
        _start=true;
    }

    function timeLeft() public myTimer view returns(uint){
        return _end-block.timestamp;
    }



    function addCandidate(string memory _name) public myTimer {
        // Increment the count of total candidates
        totalCandidates++;
        candidates[totalCandidates] = Candidate(
            totalCandidates,
            _name,
            0,
            msg.sender
        );

        // trigger an event
        emit CandidateAdded(totalCandidates, _name, 0, msg.sender);
    }

    function deleteCandidate(uint256 _id) public myTimer{
        delete candidates[_id];
    }

    function voter(uint256 _id) public myTimer{
        // Check if the voter has registered
        require(registered[msg.sender]);

        // Check if the voter has already voted
        require(!voters[msg.sender]);

        // Store the record of the voter in map
        voters[msg.sender] = true;

        // Call the vote function
        voteCandidate(_id);
    }

    function registerVoter() public myTimer{
        // check if voter has not registered before already
        require(!registers[msg.sender]);
        toRegisterCount++;
        // Register the voter
        registers[msg.sender] = true;
        toRegister[toRegisterCount] = msg.sender;
    }

    function allowedByAdmin(address _voter) public myTimer{
        // Check if the voter has not already been registered
        require(!registered[_voter]);

        registered[_voter] = true;
    }

    function voteCandidate(uint256 _id) public myTimer{
        // Increment total number of votes
        totalVoters++;
        // Increment Vote Count
        candidates[_id].voteCount = candidates[_id].voteCount + 1;

        // Create a local structure of Candidate
        Candidate memory _candidate = Candidate(
            _id,
            candidates[_id].name,
            candidates[_id].voteCount,
            msg.sender
        );
        // Update
        candidates[_id] = _candidate;
    }
}