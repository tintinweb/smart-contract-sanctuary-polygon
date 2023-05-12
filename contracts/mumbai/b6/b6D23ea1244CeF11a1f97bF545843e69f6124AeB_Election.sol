// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

contract Election {
    address public admin;
    uint256 candidateCount;
    uint256 voterCount;
    bool start;
    bool end;

    constructor() {
        // Initilizing default values
        admin = msg.sender;
        candidateCount = 0;
        voterCount = 0;
        start = false;
        end = false;
    }

    function getAdmin() public view returns (address) {
        // Returns account address used to deploy contract (i.e. admin)
        return admin;
    }

    modifier onlyAdmin() {
        // Modifier for only admin access
        require(msg.sender == admin);
        _;
    }
    // Modeling a candidate
    struct Candidate {
        uint256 candidateId;
        string header;
        string slogan;
        uint256 voteCount;
    }
    mapping(uint256 => Candidate) public candidateDetails;

    event CandidateAdded(uint256 candidateId, string header, string slogan);

    // Adding new candidates
    function addCandidate(
        string memory _header,
        string memory _slogan
    )
        public
        // Only admin can add
        onlyAdmin
    {
        Candidate memory newCandidate = Candidate({
            candidateId: candidateCount,
            header: _header,
            slogan: _slogan,
            voteCount: 0
        });
        candidateDetails[candidateCount] = newCandidate;
        candidateCount += 1;
        emit CandidateAdded(
            newCandidate.candidateId,
            newCandidate.header,
            newCandidate.slogan
        );
    }

    // Modeling a Election Details
    struct ElectionDetails {
        string adminName;
        string adminEmail;
        string adminTitle;
        string electionTitle;
        string organizationTitle;
    }
    ElectionDetails electionDetails;

    event ElectionDetailsSet(
        string adminName,
        string adminEmail,
        string adminTitle,
        string electionTitle,
        string organizationTitle
    );

    function setElectionDetails(
        string memory _adminName,
        string memory _adminEmail,
        string memory _adminTitle,
        string memory _electionTitle,
        string memory _organizationTitle
    )
        public
        // Only admin can add
        onlyAdmin
    {
        electionDetails = ElectionDetails(
            _adminName,
            _adminEmail,
            _adminTitle,
            _electionTitle,
            _organizationTitle
        );
        start = true;
        end = false;
        emit ElectionDetailsSet(
            _adminName,
            _adminEmail,
            _adminTitle,
            _electionTitle,
            _organizationTitle
        );
    }

    // Get Elections details
    function getAdminName() public view returns (string memory) {
        return electionDetails.adminName;
    }

    function getAdminEmail() public view returns (string memory) {
        return electionDetails.adminEmail;
    }

    function getAdminTitle() public view returns (string memory) {
        return electionDetails.adminTitle;
    }

    function getElectionTitle() public view returns (string memory) {
        return electionDetails.electionTitle;
    }

    function getOrganizationTitle() public view returns (string memory) {
        return electionDetails.organizationTitle;
    }

    // Get candidates count
    function getTotalCandidate() public view returns (uint256) {
        // Returns total number of candidates
        return candidateCount;
    }

    // Get voters count
    function getTotalVoter() public view returns (uint256) {
        // Returns total number of voters
        return voterCount;
    }

    // Modeling a voter
    struct Voter {
        address voterAddress;
        string name;
        string phone;
        bool isVerified;
        bool hasVoted;
        bool isRegistered;
    }
    address[] public voters; // Array of address to store address of voters
    mapping(address => Voter) public voterDetails;

    event VoterRegistered(address voterAddress, string name, string phone);

    // Request to be added as voter
    function registerAsVoter(string memory _name, string memory _phone) public {
        Voter memory newVoter = Voter({
            voterAddress: msg.sender,
            name: _name,
            phone: _phone,
            hasVoted: false,
            isVerified: false,
            isRegistered: true
        });
        voterDetails[msg.sender] = newVoter;
        voters.push(msg.sender);
        voterCount += 1;
        emit VoterRegistered(
            newVoter.voterAddress,
            newVoter.name,
            newVoter.phone
        );
    }

    event VoterVerified(address voterAddress, bool isVerified);

    // Verify voter
    function verifyVoter(
        bool _verifedStatus,
        address voterAddress
    )
        public
        // Only admin can verify
        onlyAdmin
    {
        voterDetails[voterAddress].isVerified = _verifedStatus;

        emit VoterVerified(voterAddress, _verifedStatus);
    }

    mapping(address => bool) public voted;

    event Voted(address voterAddress);

    // Vote
    function vote(uint256 candidateId) public {
        require(!voted[msg.sender], "You already voted.");
        require(voterDetails[msg.sender].hasVoted == false);
        require(voterDetails[msg.sender].isVerified == true);
        require(start == true);
        require(end == false);
        voterDetails[msg.sender].hasVoted = true;
        candidateDetails[candidateId].voteCount += 1;
        voted[msg.sender] = true;
        emit Voted(msg.sender);
    }

    // End election
    function endElection() public onlyAdmin {
        uint maxVotes = 0;
        uint maxVotesId = 0;
        for (uint i = 0; i < candidateCount; i++) {
            if (candidateDetails[i].voteCount > maxVotes) {
                maxVotes = candidateDetails[i].voteCount;
                maxVotesId = i;
            }
        }

        uint equalVotes = 0;
        for (uint i = 0; i < candidateCount; i++) {
            if (candidateDetails[i].voteCount == maxVotes) {
                equalVotes++;
            }
        }

        require(equalVotes == 1, "Election cannot end with equal vote count.");

        end = true;
        start = false;
    }

    // Get election start and end values
    function getStart() public view returns (bool) {
        return start;
    }

    function getEnd() public view returns (bool) {
        return end;
    }
}