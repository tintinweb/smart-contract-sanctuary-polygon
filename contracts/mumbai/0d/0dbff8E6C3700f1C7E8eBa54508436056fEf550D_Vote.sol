/**
 *Submitted for verification at polygonscan.com on 2023-04-20
*/

//SPDX-License-Identifier: GPL-3.0
pragma experimental ABIEncoderV2;
pragma solidity 0.8.17;

contract Vote {
    struct Voter {
        string name;
        uint256 age;
        uint256 stateCode;
        uint256 voterIdNumber;
        uint256 constituencyCode;
        address voterAddress;
        uint256 voted;
    }

    struct Contestant {
        string name;
        string platform;
        uint256 voteCount;
        uint256 contestantId; // unique ID of candidate
        uint256 stateCode;
        uint256 constituencyCode;
        uint256 electionID;
    }

    struct ElectionScore {
        string name;
        string platform;
        uint256 voteCount; // number of accumulated votes
        uint256 contestantId; // unique ID of candidate
        uint256 stateCode;
        uint256 constituencyCode;
    }

    struct Election {
        string electionName;
        uint256 electionDate;
        uint256 startTime;
        uint256 endTime;
        uint256 electionId;
    }

    mapping(uint256 => Contestant) public contestants;
    mapping(uint256 => bool) usedContestantIds;

    Contestant[] private contestantarr;
    Contestant[] public filteredContestants;
    mapping(uint256 => uint256) internal votesCount;
    uint256 contestantIndex;
    uint256 contestantID;

    mapping(address => Voter) public voters;
    uint256 voterIndex;

    mapping(string => uint256) public electionNames;
    Election[] public elections;
    uint256 electionIndex;
    uint256 electionId;

    address registrar;

    modifier onlyregistrar() {
        require(msg.sender == registrar);
        _;
    }

    constructor() {
        registrar = msg.sender;
    }

    function ChangeOfOwnership(address _newAddress) public onlyregistrar {
        require(_newAddress != address(0), "Enter a valid address");
        registrar = _newAddress;
    }

    // // Get Registrar

    function getRegistrar() external view returns (address) {
        return registrar;
    }

    // create elections

    function registerElection(
        string memory _electionName,
        uint256 _electionDate,
        uint256 _startTime,
        uint256 _endTime
    ) public onlyregistrar {
        require(
            electionNames[_electionName] == 0,
            "Election already registered"
        );
        // Create a new election struct
        // Assign the struct to

        electionId = electionIndex;
        Election memory newElection = Election(
            _electionName,
            _electionDate,
            _startTime,
            _endTime,
            electionId
        );
        elections.push(newElection);
        electionIndex++;
    }

    // View Election Details
    function getAllElections() public view returns (Election[] memory) {
        return elections;
    }

    // Get all Elections

    function getElectionNames() public view returns (string[] memory) {
        string[] memory registeredElections = new string[](elections.length);
        for (uint256 i = 0; i < elections.length; i++) {
            registeredElections[i] = elections[i].electionName;
        }
        return registeredElections;
    }

    // RegisterContestants

    modifier isNotExist() {
        require(contestants[contestantID].contestantId == 0);
        _;
    }

    function registerContestant(
    string memory _name,
    string memory _platform,
    uint256 _stateCode,
    uint256 _constituencyCode,
    uint256 _electionID
) public isNotExist onlyregistrar {
    // Check if the election exists
    require(_electionID < elections.length, "Election does not exist");
    
    uint256 newId = 0;
    while (usedContestantIds[newId]) {
        newId++;
    }
    // Create a new contestant struct
    Contestant memory newContestant = Contestant(
        _name,
        _platform,
        0,
        newId,
        _stateCode,
        _constituencyCode,
        _electionID
    );
    // Assign the struct to the contestants mapping
    contestants[newContestant.contestantId] = newContestant;
    // Assign struct to an Array
    contestantarr.push(newContestant);
    // Mark the ID as used
    usedContestantIds[newId] = true;
    contestantIndex++;
}


    function getContestantInfo(uint256 _contestantId)
        public
        view
        returns (
            string memory,
            string memory,
            uint256,
            uint256,
            uint256,
            uint256
        )
    {
        // Retrieve the contestant's struct from the mapping
        Contestant storage contestant = contestants[_contestantId];

        // Return the contestant's information
        return (
            contestant.name,
            contestant.platform,
            contestant.contestantId,
            contestant.stateCode,
            contestant.constituencyCode,
            contestant.electionID
        );
    }

    // Get All contestants
    function getAllContestants() public view returns (Contestant[] memory) {
        return contestantarr;
    }

    // Get contestantsby election id
    function clearFilteredContestants() internal {
        delete filteredContestants;
        filteredContestants = new Contestant[](0);
    }

    function getFilteredContestantsByElectionID(uint256 _electionID)
        internal
        returns (Contestant[] memory)
    {
        clearFilteredContestants();
        Contestant[] memory allContestants = getAllContestants();
        for (uint256 i = 0; i < allContestants.length; i++) {
            if (allContestants[i].electionID == _electionID) {
                filteredContestants.push(allContestants[i]);
            }
        }
        return filteredContestants;
    }

    // Register Voter

    modifier voterDoesNotExist(address _voterAddress) {
        require(voters[_voterAddress].voterIdNumber == 0);
        _;
    }

    function registerVoter(
        string memory _name,
        uint256 _age,
        uint256 _stateCode,
        uint256 _voterIdNumber,
        uint256 _constituencyCode,
        address _voterAddress
    ) public voterDoesNotExist(_voterAddress) {
        voterIndex;
        require(_age >= 18, "You must be above 18 to vote");
        // Create a new voter struct
        Voter memory newVoter = Voter(
            _name,
            _age,
            _stateCode,
            _voterIdNumber,
            _constituencyCode,
            _voterAddress,
            0
        );

        // Assign the struct to the voter's unique ID in the mapping
        voters[_voterAddress] = newVoter;

        voterIndex++;
    }

    //  get number of Voters
    function getNumOfVoters() public view returns (uint256) {
        return voterIndex;
    }

    // Get voter profile

    function getVoterInfo(address _voterAddress)
        public
        view
        returns (Voter memory)
    {
        // Retrieve the voter's struct from the mapping
        Voter storage voter = voters[_voterAddress];

        // Return the voter's information
        return voter;
    }

    //    Cast Vote Function

    function castVote(
        // uint256 _electionId,
        uint256 _contestantId,
        address _voterAddress
    ) public {
        // require(
        //     block.timestamp > elections[_electionId].startTime,
        //     "Voting has not started."
        // );
        // require(
        //     block.timestamp > elections[_electionId].startTime &&
        //         block.timestamp < elections[_electionId].endTime,
        //     "Voting has already ended."
        // );

        // Check if voter is registered
        require(
            voters[_voterAddress].voterIdNumber != 0,
            "Voter is not registered"
        );

        // Check if voter has already voted
        require(voters[_voterAddress].voted == 0, "Voter has already voted");

        // Retrieve the contestant's struct from the mapping
        Contestant storage contestant = contestants[_contestantId];

        // Check if voter is eligible to vote in that constituency by comparing contestant constituency and state code with that of the voter

        require(
            voters[_voterAddress].constituencyCode ==
                contestant.constituencyCode &&
                voters[_voterAddress].stateCode == contestant.stateCode,
            "Voter is not eligible to vote in this constituency"
        );

        // Increment the vote count for the candidate
        contestant.voteCount++;

        // Mark the voter as having voted
        voters[_voterAddress].voted = 1;
    }

    function getElectionScore() public view returns (ElectionScore[] memory) {
        // require(
        //     block.timestamp >= elections[_electionId].endTime,
        //     "Election results not yet available"
        // );
        ElectionScore[] memory scores = new ElectionScore[](contestantIndex);

        for (uint256 i = 0; i < contestantIndex; i++) {
            scores[i] = ElectionScore({
                name: contestants[i].name,
                platform: contestants[i].platform,
                voteCount: contestants[i].voteCount,
                contestantId: contestants[i].contestantId,
                stateCode: contestants[i].stateCode,
                constituencyCode: contestants[i].constituencyCode
            });
        }
        return scores;
    }
}