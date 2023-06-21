// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

/**
 * @title FacultyElection
 * @dev A smart contract for conducting a faculty election.
 */
contract FacultyElection {
    struct Candidate {
        string name;
        string matriculationNumber;
        string department;
        string position;
        uint voteCount;
    }

    struct Voter {
        bool hasVoted;
        string department;
        string matriculationNumber;
    }

    address private admin;
    mapping(address => Voter) private voters;
    mapping(uint => Candidate) private candidates;
    uint private candidateCount;
    bool private isElectionOpen;
    uint private electionEndTime;

    mapping(address => uint) private voteTimestamps; // Stores the timestamp of when a voter casts a vote

    event VoteCasted(uint candidateId, uint voteCount); // Event to indicate that a vote has been casted

    modifier onlyAdmin() {
        require(msg.sender == admin, "Only admin can perform this operation");
        _;
    }

    modifier onlyVoter() {
        require(!voters[msg.sender].hasVoted, "You have already voted");
        _;
    }

    modifier onlyDuringElection() {
        require(isElectionOpen && block.timestamp <= electionEndTime, "Voting is closed");
        _;
    }

    /**
     * @dev Constructor function.
     * @param _electionDuration The duration of the election in seconds.
     */
    constructor(uint _electionDuration) {
        admin = msg.sender;
        electionEndTime = block.timestamp + _electionDuration;
    }

    /**
     * @dev Registers a candidate for the election.
     * @param _name The name of the candidate.
     * @param _matriculationNumber The matriculation number of the candidate.
     * @param _department The department of the candidate.
     * @param _position The position of the candidate.
     */
    function registerCandidate(
        string memory _name,
        string memory _matriculationNumber,
        string memory _department,
        string memory _position
    ) public onlyAdmin {
        require(bytes(_name).length > 0, "Invalid candidate name");
        require(bytes(_matriculationNumber).length > 0, "Invalid matriculation number");
        require(bytes(_department).length > 0, "Invalid department name");
        require(bytes(_position).length > 0, "Invalid position name");

        candidateCount++;
        candidates[candidateCount] = Candidate(_name, _matriculationNumber, _department, _position, 0);
    }

    /**
     * @dev Retrieves the details of a candidate.
     * @param _candidateId The ID of the candidate.
     * @return name The name of the candidate.
     * @return matriculationNumber The matriculation number of the candidate.
     * @return department The department of the candidate.
     * @return position The position of the candidate.
     * @return voteCount The number of votes received by the candidate.
     */
    function getCandidate(uint _candidateId) public view returns (
        string memory name,
        string memory matriculationNumber,
        string memory department,
        string memory position,
        uint voteCount
    ) {
        require(_candidateId > 0 && _candidateId <= candidateCount, "Invalid candidate ID");

        Candidate memory candidate = candidates[_candidateId];
        return (
            candidate.name,
            candidate.matriculationNumber,
            candidate.department,
            candidate.position,
            candidate.voteCount
        );
    }

    /**
     * @dev Retrieves the total number of candidates registered.
     * @return candidateCount The total number of candidates.
     */
    function getCandidateCount() public view returns (uint) {
        return candidateCount;
    }

    /**
     * @dev Starts the election.
     */
    function startElection() public onlyAdmin {
        require(candidateCount > 0, "No candidates registered");
        require(!isElectionOpen, "Election is already open");

        isElectionOpen = true;
    }

    /**
     * @dev Casts a vote for a candidate.
     * @param _candidateId The ID of the candidate being voted for.
     * @param _department The department of the voter.
     * @param _matriculationNumber The matriculation number of the voter.
     */
    function castVote(uint _candidateId, string memory _department, string memory _matriculationNumber) public onlyVoter onlyDuringElection {
        require(_candidateId > 0 && _candidateId <= candidateCount, "Invalid candidate ID");
        require(isValidVoterDepartment(_department, _matriculationNumber), "Invalid voter department or matriculation number");

        voters[msg.sender].hasVoted = true;
        voters[msg.sender].department = _department;
        voters[msg.sender].matriculationNumber = _matriculationNumber;
        
        candidates[_candidateId].voteCount++;
        emit VoteCasted(_candidateId, candidates[_candidateId].voteCount);

        voteTimestamps[msg.sender] = block.timestamp;
    }

    /**
     * @dev Checks if the voter department is valid based on the matriculation number.
     * @param _department The department of the voter.
     * @param _matriculationNumber The matriculation number of the voter.
     * @return isValid True if the voter department is valid, false otherwise.
     */
    function isValidVoterDepartment(string memory _department, string memory _matriculationNumber) private pure returns (bool isValid) {
        if (compareStrings(_department, "Anatomy")) {
            // Valid matriculation number ranges for Anatomy department
            string[6] memory csRanges = ["18/04144", "19/04144", "20/04144", "21/04144", "22/04144", "23/ABC44"];
            return isValidMatriculationNumber(_matriculationNumber, csRanges);
        } else if (compareStrings(_department, "Biochemistry")) {
            // Valid matriculation number ranges for Biochemistry department
            string[6] memory eeRanges = ["18/04244", "19/04244", "20/04244", "21/04244", "22/04244", "23/ABD44"];
            return isValidMatriculationNumber(_matriculationNumber, eeRanges);
        } else if (compareStrings(_department, "Physiology")) {
            // Valid matriculation number ranges for Physiology department
            string[6] memory meRanges = ["18/04344", "19/04344", "20/04344", "21/04344", "22/04344", "23/ABE44"];
            return isValidMatriculationNumber(_matriculationNumber, meRanges);
        } else if (compareStrings(_department, "Human Nutrition and Dietetics")) {
            // Valid matriculation number ranges for Human Nutrition and Dietetics department
            string[6] memory ceRanges = ["18/04444", "19/04444", "20/04444", "21/04444", "22/04444", "23/ABF44"];
            return isValidMatriculationNumber(_matriculationNumber, ceRanges);
        } else if (compareStrings(_department, "Pharmacology")) {
            // Valid matriculation number ranges for Pharmacology department
            string[6] memory cheRanges = ["18/04544", "19/04544", "20/04544", "21/04544", "22/04544", "23/ABG44"];
            return isValidMatriculationNumber(_matriculationNumber, cheRanges);
        } else {
            return false;
        }
    }

    /**
     * @dev Checks if a matriculation number is valid based on a list of valid ranges.
     * @param _matriculationNumber The matriculation number to check.
     * @param _validRanges The array of valid matriculation number ranges.
     * @return isValid True if the matriculation number is valid, false otherwise.
     */
    function isValidMatriculationNumber(string memory _matriculationNumber, string[6] memory _validRanges) private pure returns (bool isValid) {
        for (uint i = 0; i < _validRanges.length; i++) {
            if (startsWith(_matriculationNumber, _validRanges[i])) {
                return true;
            }
        }

        return false;
    }

    /**
     * @dev Ends the election and retrieves the winner(s) of the election.
     * @return winners The array of candidate IDs who received the highest votes.
     */
    function endElection() public onlyAdmin returns (uint[] memory winners) {
        require(isElectionOpen, "Election is not open");
        require(block.timestamp > electionEndTime, "Election is still ongoing");

        uint maxVotes = 0;
        uint winnerCount = 0;

        // Find the maximum number of votes after election
        for (uint i = 1; i <= candidateCount; i++) {
            if (candidates[i].voteCount > maxVotes) {
                maxVotes = candidates[i].voteCount;
                winnerCount = 1;
            } else if (candidates[i].voteCount == maxVotes) {
                winnerCount++;
            }
        }

        // Store the IDs of the winners
        uint[] memory winnersArray = new uint[](winnerCount);
        uint index = 0;
        for (uint i = 1; i <= candidateCount; i++) {
            if (candidates[i].voteCount == maxVotes) {
                winnersArray[index] = i;
                index++;
            }
        }

        isElectionOpen = false;
        return winnersArray;
    }

    /**
     * @dev Gets the remaining time (in seconds) until the end of the election.
     * @return remainingTime The remaining time in seconds.
     */
    function getRemainingTime() public view returns (uint remainingTime) {
        if (block.timestamp > electionEndTime) {
            return 0;
        } else {
            return electionEndTime - block.timestamp;
        }
    }

    /**
     * @dev Checks if the voting period has ended.
     * @return hasEnded True if the voting period has ended, false otherwise.
     */
    function hasVotingEnded() public view returns (bool hasEnded) {
        return !isElectionOpen || block.timestamp > electionEndTime;
    }

    /**
     * @dev Checks if a voter has already voted.
     * @param _voterAddress The address of the voter.
     * @return Voted True if the voter has voted, false otherwise.
     */
    function hasVoted(address _voterAddress) public view returns (bool Voted) {
        return voters[_voterAddress].hasVoted;
    }

    /**
     * @dev Compares two strings and checks if they are equal.
     * @param a The first string.
     * @param b The second string.
     * @return isEqual True if the strings are equal, false otherwise.
     */
    function compareStrings(string memory a, string memory b) private pure returns (bool isEqual) {
        return (keccak256(abi.encodePacked((a))) == keccak256(abi.encodePacked((b))));
    }

    /**
     * @dev Checks if a string starts with a specific prefix.
     * @param str The string to check.
     * @param prefix The prefix to check.
     * @return starts True if the string starts with the prefix, false otherwise.
     */
    function startsWith(string memory str, string memory prefix) private pure returns (bool starts) {
        bytes memory strBytes = bytes(str);
        bytes memory prefixBytes = bytes(prefix);

        if (strBytes.length < prefixBytes.length) {
            return false;
        }

        for (uint i = 0; i < prefixBytes.length; i++) {
            if (strBytes[i] != prefixBytes[i]) {
                return false;
            }
        }

        return true;
    }
}