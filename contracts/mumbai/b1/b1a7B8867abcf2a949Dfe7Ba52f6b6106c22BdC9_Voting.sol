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

    event CandidateAdded(
        uint256 id,
        string name,
        uint256 voteCount,
        address author
    );

    mapping(uint256 => Candidate) public candidates;
    mapping(address => bool) public voters;
    mapping(address => bool) public registers;
    mapping(uint256 => address) public toRegister;
    mapping(address => bool) public registered;

    function addCandidate(string memory _name) public {
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

    function deleteCandidate(uint256 _id) public {
        delete candidates[_id];
    }

    function voter(uint256 _id) public {
        // Check if the voter has registered
        require(registered[msg.sender]);

        // Check if the voter has already voted
        require(!voters[msg.sender]);

        // Store the record of the voter in map
        voters[msg.sender] = true;

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

    function registerVoter() public {
        // check if voter has not registered before already
        require(!registers[msg.sender]);
        toRegisterCount++;
        // Register the voter
        registers[msg.sender] = true;
        toRegister[toRegisterCount] = msg.sender;
    }

    function allowedByAdmin(address _voter) public {
        // Check if the voter has not already been registered
        require(!registered[_voter]);

        registered[_voter] = true;
    }
}