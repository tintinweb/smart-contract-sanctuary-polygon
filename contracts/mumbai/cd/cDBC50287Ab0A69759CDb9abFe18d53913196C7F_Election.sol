// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

/**
 * Solidity contract that handles the election
 * of Nigeria.
 * Votes are casted by citizens and each vote is
 * tallied and stored on polygon testnet; 
 */

contract Election {
    /* ------- VARIABLES ------- */

    // ELECTION DETAILS
    uint startTimestamp;
    uint endTimestamp;

    // ADMIN
    // can add/remove candidates
    // can add/remove election officials
    // can extend the election period
    address public admin;

    // ELECTION OFFICIALS
    // help citizens with no wallet address to cast their vote
    // using the election official's address
    address[] public officials;
    mapping(address => bool) isOfficial;

    // CANDIDATES
    uint candidatesCount = 0; // incremented anytime a candidate is added, and also used to give candidates their unique id
    struct Candidate {
        string name;
        string politicalParty;
        uint id;
        uint votes;
    }
    Candidate[] public candidates;
    mapping(uint => bool) isCandidate;

    // VOTERS
    struct Voter {
        uint256 nin; // National Id Number
        Candidate choice;
    }
    Voter[] public voters;
    mapping(address => bool) addressUsed; // to ensure addresses are used once
    mapping(uint => bool) hasVoted; // track citizens that voted


    /* ------- EVENTS ------- */
    event AdminCreated(address indexed admin);
    event OfficialAdded(address indexed official);
    event OfficialRemoved(address indexed official);
    event CandidateAdded(string name, string party);
    event CandidateDisqualified(string name, string party);
    event VoteCasted(uint voter, string choice, string party);
    event EndElection();


    /* ------- CONSTRUCTOR ------- */
    // sets election admin, start date and end date
    constructor(address _admin, uint _startTimestamp, uint _endTimestamp) {
        require(_admin != address(0), "Admin has to be a valid address");
        admin = _admin;
        emit AdminCreated(admin);

        startTimestamp = _startTimestamp;
        endTimestamp = _endTimestamp;
    }


    /* ------- MODIFIERS ------- */
    // onlyAdmin Modifier
    modifier onlyAdmin() {
        require(msg.sender == address(admin), "Only Admin can invoke this function");
        _;
    }
    // onlyOfficial Modifier
    modifier onlyOfficial() {
        require(isOfficial[msg.sender], "Only Election Official can invoke this function");
        _;
    }
    // only elligible voter Modifier
    modifier isElligible() {
        require(!addressUsed[msg.sender] || isOfficial[msg.sender]);
        _;
    }
    // only when election is ongoing Modifier
    modifier electionOngoing() {
        require(block.timestamp < endTimestamp, "Sorry, election has ended");
        _;
    }
    // only when there is at least one candidate contesting
    modifier candidatesNotEmpty() {
        require(candidates.length != 0, "There are no contestants");
        _;
    }

    /* ------- VOTE FUNCTION ---- */
    // called to cast a vote
    struct VoteReturnType {
        bool success;
        string message;
    }
    function vote(Voter memory _voter) 
        public 
        electionOngoing 
        isElligible
        returns(VoteReturnType memory)
    {
        uint candidateId = _voter.choice.id;
        if (hasVoted[_voter.nin] || !isCandidate[candidateId]) {
            VoteReturnType memory errorResponse;
            errorResponse.success = false;
            errorResponse.message = "Citizen has already voted or candidate does not exist";
            return errorResponse;
        } 

        // vote;
        _voter.choice.votes++;
        voters.push(_voter);
        hasVoted[_voter.nin] = true;
        addressUsed[msg.sender] = true;
        emit VoteCasted(_voter.nin, _voter.choice.name, _voter.choice.politicalParty);

        VoteReturnType memory successResponse;
        successResponse.success = true;
        successResponse.message = "You have successfully voted. God bless Nigeria!";
        return successResponse;
    }


    /* ------- GETTER FUNCTIONS ------- */
    
    // Get total votes casted
    function getTotalVotesCasted()
        public
        view
        returns(uint)
    {
        return voters.length;
    }

    // Get all candidates
    function getAllCandidates() 
        public 
        candidatesNotEmpty
        view 
        returns(Candidate[] memory)
    {
        return candidates;
    }

    // Get candidate's votes
    function getCandidateVotes(uint id)
        public
        candidatesNotEmpty
        view
        returns(uint)
    {
        uint votes;
        for (uint i = 0; i < candidates.length - 1; i++) {
                if (id == candidates[i].id) {
                    votes = candidates[i].votes;
                    break;
            }
        }
        return votes;
    }

    // Get top voted candidate
    function getTopVotedCandidate()
        public
        candidatesNotEmpty
        view
        returns(Candidate memory)
    {
        Candidate memory topvotedCandidate = candidates[0];
        for (uint i = 0; i < candidates.length - 1; i++) {
                if (candidates[i].votes > topvotedCandidate.votes) {
                    topvotedCandidate = candidates[i];
            }
        }

        return topvotedCandidate;
    }

    // Get election start date
    function getElectionCommencementDate()
        public
        view
        returns(uint)
    {
        return startTimestamp;
    }

    // Get election end date
    function getElectionEndDate()
        public
        view
        returns(uint)
    {
        return endTimestamp;
    }

    // Check if address is admin
    function isAdmin()
        public
        view
        returns(bool) 
    {
        return msg.sender == admin;
    }

    // Check if address is official
    function checkIfOfficial()
        public
        view
        returns(bool) 
    {
        return isOfficial[msg.sender];
    }

    // Check if voter has voted
    function checkIfVoted(uint nin)
        public
        view
        returns(bool)
    {
        return hasVoted[nin];
    }

    // Check if address has been used to vote
    // each address should be used once; unless it is an official's address
    function checkIfAddressUsed()
        public
        view
        returns(bool)
    {
        return addressUsed[msg.sender];
    }

    /* -------- ADMIN FUNCTIONS ------ */

    // Edit Election Start Timestamp
    function editStartTimestamp(uint newTimestamp) public onlyAdmin {
        startTimestamp = newTimestamp;
    }
    // Edit Election End Timestamp
    function editEndTimestamp(uint newTimestamp) public onlyAdmin {
        require(block.timestamp < newTimestamp, "Can't use a time in the past");
        endTimestamp = newTimestamp;
    }
    // End Election
    function endElection() public onlyAdmin {
        endTimestamp = block.timestamp;

        emit EndElection();
    }
    
    // Add Election Official
    function addOfficial(address official) public onlyAdmin {
        officials.push(official);
        isOfficial[official] = true;

        emit OfficialAdded(official);
    }
     // Remove Election Official
    function removeOfficial(address official) public onlyAdmin {
        require(isOfficial[official], "You can only remove already added officials");
        isOfficial[official] = false;
        for (uint i = 0; i < officials.length - 1; i++) {
            if (officials[i] == official) {
                officials[i] = officials[officials.length - 1];
                break;
            }
        }
        officials.pop();

        emit OfficialRemoved(official);
    }

    // Add Candidate
    function addCandidate(string memory _name, string memory _party) public onlyAdmin {
        Candidate memory candidate;
        candidate.name = _name;
        candidate.politicalParty = _party;
        candidate.votes = 0;
        candidate.id = candidatesCount + 1;
        isCandidate[candidate.id] = true;
        candidates.push(candidate);
        candidatesCount++;

        emit CandidateAdded(candidate.name, candidate.politicalParty);
    }
    // Remove Candidate
    function removeCandidate(uint id) public onlyAdmin {
        require(isCandidate[id], "You can only remove already added candidates");
        isCandidate[id] = false;
        for (uint i = 0; i < candidates.length - 1; i++) {
                if (id == candidates[i].id) {
                    emit CandidateDisqualified(candidates[i].name, candidates[i].politicalParty);
                    candidates[i] = candidates[candidates.length - 1];
                    break;
            }
        }
        candidates.pop();
    }

}