// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

contract Voting {
    address public electionCommission;
    uint256 public minimumVotingAge;
    address[] public registeredVoters; // Maintain a list of registered voter addresses

    constructor() {
        electionCommission = msg.sender;
    }

    modifier OnlyCommission() {
        require(
            msg.sender == electionCommission,
            "Only Election Commission has the authorized to perform this action."
        );
        _;
    }

    event VoterRegistered(
        address voterAddress,
        string fullName,
        uint256 age,
        string addr,
        string city,
        string state,
        uint256 constituency
    );
    event PartyCreated(
        uint256 partyId,
        string name,
        string logo,
        string slogan,
        uint256 stateId,
        bool isNationalLevel
    );
    event CandidateAdded(
        uint256 candidateId,
        string name,
        uint256 partyId,
        uint256 voterId
    );
    event PartyLeaderAppointed(uint256 partyId, address leader);

    struct Voter {
        uint256 id; // Added voter ID
        string fullName;
        uint256 age;
        string addr;
        uint256 constituency;
        string city;
        uint256 stateId; // Modified to store the state ID instead of the state name
        string faceImageIpfsUrl;
        bool verified;
    }

    struct Constituency {
        string name;
    }

    struct State {
        uint256 id;
        string name;
        uint256[] registeredConstituencies;
    }

    struct Party {
        uint256 id;
        string name;
        string logo;
        string slogan;
        address leader;
        uint256 stateId;
        bool isNationalLevel;
    }

    struct Candidate {
        uint256 id;
        string name;
        uint256 partyId;
        uint256 voterId; // Added voter ID
    }

    mapping(address => Voter) public voters;
    mapping(uint256 => State) public states;
    mapping(uint256 => Constituency) public constituencies;
    mapping(uint256 => Party) public parties;
    mapping(uint256 => Candidate) public candidates;
    uint256 public voterCount; // Added voter count
    uint256 public stateCount;
    uint256 public constituencyCount;
    uint256 public partyCount;
    uint256 public candidateCount;

    function createNewState(string memory _name) public OnlyCommission {
        uint256 newStateId = stateCount;
        states[newStateId].id = newStateId; // Assign the ID
        states[newStateId].name = _name;
        stateCount++;
    }

    function createNewConstituency(
        string memory _name,
        uint256 _stateId
    ) public OnlyCommission {
        require(_stateId < stateCount, "Invalid state ID.");

        uint256 newConstituencyId = constituencyCount;
        constituencies[newConstituencyId] = Constituency(_name);
        states[_stateId].registeredConstituencies.push(newConstituencyId);
        constituencyCount++;
    }

    function setMinimumVotingAge(uint _age) public OnlyCommission {
        minimumVotingAge = _age;
    }

    function registerVoter(
        string memory _fullName,
        uint256 _age,
        string memory _addr,
        string memory _city,
        uint256 _stateId,
        uint256 _constituency
    ) public {
        require(
            _age >= minimumVotingAge,
            "Voter does not meet the minimum voting age requirement."
        );
        require(_stateId < stateCount, "Invalid state ID.");
        require(
            _constituency < states[_stateId].registeredConstituencies.length,
            "Invalid constituency ID."
        );

        uint256 voterId = voterCount; // Assign the voter ID
        uint256 constituencyId = states[_stateId].registeredConstituencies[
            _constituency
        ];

        voters[msg.sender] = Voter(
            voterId, // Assign the voter ID
            _fullName,
            _age,
            _addr,
            constituencyId,
            _city,
            _stateId,
            "",
            true
        );

        registeredVoters.push(msg.sender); // Add the registered voter address to the list
        emit VoterRegistered(
            msg.sender,
            _fullName,
            _age,
            _addr,
            _city,
            states[_stateId].name,
            constituencyId
        );

        voterCount++; // Increment the voter count
    }

    function createParty(
        string memory _name,
        string memory _logo,
        string memory _slogan,
        uint256 _stateId,
        bool _isNationalLevel
    ) public OnlyCommission {
        require(_stateId < stateCount, "Invalid state ID.");

        uint256 partyId = partyCount;
        parties[partyId] = Party(
            partyId,
            _name,
            _logo,
            _slogan,
            address(0),
            _stateId,
            _isNationalLevel
        );
        partyCount++;

        emit PartyCreated(
            partyId,
            _name,
            _logo,
            _slogan,
            _stateId,
            _isNationalLevel
        );
    }

    function setPartyLeader(
        uint256 _partyId,
        address _leader
    ) public OnlyCommission {
        require(_partyId < partyCount, "Invalid party ID.");
        parties[_partyId].leader = _leader;

        emit PartyLeaderAppointed(_partyId, _leader);
    }

    function togglePartyNationalLevel(
        uint256 _partyId,
        bool _isNationalLevel
    ) public OnlyCommission {
        require(_partyId < partyCount, "Invalid party ID.");

        parties[_partyId].isNationalLevel = _isNationalLevel;
    }

    function addCandidate(string memory _name, uint256 _partyId) public {
        require(_partyId < partyCount, "Invalid party ID.");

        uint256 candidateId = candidateCount;
        uint256 voterId = voters[msg.sender].id; // Get the voter ID

        candidates[candidateId] = Candidate(
            candidateId,
            _name,
            _partyId,
            voterId
        );
        candidateCount++;

        emit CandidateAdded(candidateId, _name, _partyId, voterId);
    }

    function getVoters() public view returns (Voter[] memory) {
        Voter[] memory voterList = new Voter[](voterCount);

        for (uint256 i = 0; i < voterCount; i++) {
            voterList[i] = voters[registeredVoters[i]];
        }

        return voterList;
    }

    function getStates() public view returns (State[] memory) {
        State[] memory stateList = new State[](stateCount);

        for (uint256 i = 0; i < stateCount; i++) {
            stateList[i] = states[i];
        }

        return stateList;
    }

    function getConstituencies(
        uint256 _stateId
    ) public view returns (Constituency[] memory) {
        require(_stateId < stateCount, "Invalid state ID.");

        uint256 constituencyLength = states[_stateId]
            .registeredConstituencies
            .length;
        Constituency[] memory constituencyList = new Constituency[](
            constituencyLength
        );

        for (uint256 i = 0; i < constituencyLength; i++) {
            uint256 constituencyId = states[_stateId].registeredConstituencies[
                i
            ];
            constituencyList[i] = constituencies[constituencyId];
        }

        return constituencyList;
    }

    function getParties() public view returns (Party[] memory) {
        Party[] memory partyList = new Party[](partyCount);

        for (uint256 i = 0; i < partyCount; i++) {
            partyList[i] = parties[i];
        }

        return partyList;
    }

    function getCandidates() public view returns (Candidate[] memory) {
        Candidate[] memory candidateList = new Candidate[](candidateCount);

        for (uint256 i = 0; i < candidateCount; i++) {
            candidateList[i] = candidates[i];
        }

        return candidateList;
    }

    function getPartyDetails(
        uint256 _partyId
    ) public view returns (Party memory, Candidate[] memory, Voter memory) {
        require(_partyId < partyCount, "Invalid party ID.");

        Party memory party = parties[_partyId];

        Candidate[] memory partyCandidates = new Candidate[](candidateCount);
        uint256 candidateIndex = 0;

        for (uint256 i = 0; i < candidateCount; i++) {
            if (candidates[i].partyId == _partyId) {
                partyCandidates[candidateIndex] = candidates[i];
                candidateIndex++;
            }
        }

        Voter memory partyLeader = voters[party.leader];

        return (party, partyCandidates, partyLeader);
    }
}