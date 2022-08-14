// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/utils/Counters.sol";
import "./Election.sol";
import "./IElection.sol";

/**
 * @title ElectionAdmin
 * @notice ElectionAdmin is a Election factory contract.
 */
contract ElectionAdmin is IElection {
    using Counters for Counters.Counter;
    Counters.Counter private electionIds;

    mapping(uint256 => address) private lutElectionById;
    mapping(address => address) private lutElectionByOwner;

    constructor() {
        electionIds.increment(); // first election id is 1
    }

    /**
     * @notice create a election
     * @param _name election name
     * @param _description election description
     * @param _durationDays election duration in days
     * @dev deploy election contract and increment electionIds
     */
    function createElection(
        string memory _name,
        string memory _description,
        uint256 _durationDays
    ) public {
        address _electionAddress = address(
            new Election(_name, _description, _durationDays)
        );
        lutElectionById[electionIds.current()] = _electionAddress;
        lutElectionByOwner[msg.sender] = _electionAddress;
        electionIds.increment();
    }

    /**
     * @notice get elections
     * @dev get all elections
     */

    function getElections() public view returns (ElectionDetails[] memory) {
        uint256 _electionsCount = electionIds.current() - 1;
        // initialize elections array
        ElectionDetails[] memory _elections = new ElectionDetails[](
            _electionsCount
        );

        // set elections from lutElectionById
        for (uint256 _i = 0; _i < _electionsCount; _i++) {
            Election _election = Election(lutElectionById[_i + 1]);
            _elections[_i] = ElectionDetails(
                _election.name(),
                _election.description(),
                _election.durationDays(),
                _election.deadline(),
                _election.isElectionPeriod()
            );
        }
        return _elections;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Counters.sol)

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/utils/Counters.sol";
import "./IElection.sol";

/**
 * @title Election
 * @notice Election is a struct that contains election name and duration days.
 */
contract Election is IElection {
    string public name; // voting event name
    string public description; // voting event description
    uint256 public durationDays; // voting event duration in days
    uint256 public deadline; // voting event deadline

    using Counters for Counters.Counter;
    Counters.Counter private candidateIds;

    mapping(uint256 => Candidate) private lutCandidateById;
    mapping(address => uint256) public lutCadidateIdByCandidateAddress;
    mapping(address => uint256) private lutCandidateIdByVoterAddress;

    constructor(
        string memory _name,
        string memory _description,
        uint256 _durationDays
    ) {
        name = _name;
        description = _description;
        durationDays = _durationDays;
        candidateIds.increment(); // first candidate id is 1
    }

    /**
     * @notice create a candidate and set deadline if it is the first time
     * @param _name candidate name
     * @param _publicPromise public publicPromise
     * @dev deploy candidate contract and set deadline if it is the first time
     */
    function runningForElection(
        string memory _name,
        string memory _publicPromise,
        string memory _imageUrl
    ) external onlyNotCandidate onlyBeforeDeadline {
        uint256 _candidateId = candidateIds.current();
        // create candidate
        Candidate memory _candidate = Candidate(
            _candidateId,
            _name,
            _publicPromise,
            _imageUrl,
            block.timestamp,
            0 // votesCount
        );
        lutCandidateById[_candidateId] = _candidate;
        lutCadidateIdByCandidateAddress[msg.sender] = _candidateId;

        // if candidate is created at the first time, deadline is set
        if (_candidateId == 1) {
            deadline = calcDeadline(_candidate.createdAt);
        }
        // increment candidate id for next candidate
        candidateIds.increment();
    }

    /**
     * @notice vote to a candidate if it is not voted yet
     * @param _candidateId candidate id to vote to
     * @dev add msg.sender to list of voted addresses and add vote to list of votes
     */
    function vote(uint256 _candidateId)
        external
        onlyNotVoted
        onlyBeforeDeadline
    {
        require(isValidCandidateId(_candidateId), "Invalid candidate id");
        lutCandidateById[_candidateId].votesCount++;
        // lutCandidateIdByVoterAddress will be used to check if voter has voted
        lutCandidateIdByVoterAddress[msg.sender] = _candidateId;
    }

    /**
     * @dev get list of candidates
     */
    function getCadidates() external view returns (Candidate[] memory) {
        uint256 _candidatesCount = candidateIds.current() - 1;
        // initialize candidates array
        Candidate[] memory _candidates = new Candidate[](_candidatesCount);

        // set candidates from lutCandidateById
        for (uint256 _i = 0; _i < _candidatesCount; _i++) {
            _candidates[_i] = lutCandidateById[_i + 1];
        }

        return _candidates;
    }

    /**
     * @notice Return the candidate with the highest number of votes. In case of a tie vote, the candidate who ran first is the winner.
     * @dev get winner candidate
     */
    function getWinner() external view returns (Candidate memory) {
        Candidate memory _interimWinner;
        // return empty candidate if election is not finished
        if (deadline == 0 || isBeforeDeadline()) {
            return _interimWinner;
        }

        uint256 _candidatesCount = candidateIds.current() - 1;
        for (uint256 _i = 0; _i < _candidatesCount; _i++) {
            Candidate memory _candidate = lutCandidateById[_i + 1];
            // set interim winner if candidate has more votes than interim winner
            if (_candidate.votesCount > _interimWinner.votesCount) {
                _interimWinner = _candidate;
            }
        }
        return _interimWinner;
    }

    /**
     * @dev check if deadline is set and bock.timestamp is before deadline
     */
    function isElectionPeriod() public view returns (bool) {
        return deadline > 0 && isBeforeDeadline();
    }

    /***************************
     * private functions
     ***************************/
    /**
     * @param _candidateCreatedAt candidate created at
     * @dev deadline is set to _candidateCreatedAt + 24 * 60 * 60 * durationDays
     */
    function calcDeadline(uint256 _candidateCreatedAt)
        private
        view
        returns (uint256)
    {
        return _candidateCreatedAt + 60 * 60 * 24 * durationDays;
    }

    /**
     * @dev check if msg.sender is a candidate owner
     */
    function isValidAddressForCandidancy() private view returns (bool) {
        return lutCadidateIdByCandidateAddress[msg.sender] == 0;
    }

    /**
     * @dev check if msg.sender has already voted
     */
    function isValidVoterAddress() private view returns (bool) {
        // return !includeAddress(votedAddresses, msg.sender);
        return lutCandidateIdByVoterAddress[msg.sender] == 0;
    }

    /**
     * @dev check if _candidateAddress is included in candidateAddresses
     */
    function isValidCandidateId(uint256 _candidateId)
        private
        view
        returns (bool)
    {
        return lutCandidateById[_candidateId].id != 0;
    }

    /**
     * @dev check if bock.timestamp is before deadline
     */
    function isBeforeDeadline() private view returns (bool) {
        return block.timestamp < deadline;
    }

    /***************************
     * modifiers
     ***************************/
    /**
     * @dev stop processing that function if msg.sender is already running for
     */
    modifier onlyNotCandidate() {
        require(
            isValidAddressForCandidancy(),
            "Invalid address for candidancy"
        );
        _;
    }

    /**
     * @dev stop processing that function if msg.sender has already voted
     */
    modifier onlyNotVoted() {
        require(isValidVoterAddress(), "Invalid voter address");
        _;
    }

    /**
     * @dev stop processing that function if block.timestamp is after deadline
     */
    modifier onlyBeforeDeadline() {
        if (deadline > 0) {
            require(isBeforeDeadline(), "Out of period");
        }
        _;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

interface IElection {
    struct Candidate {
        uint256 id;
        string name;
        string publicPromise;
        string imageUrl;
        uint256 createdAt;
        uint256 votesCount;
    }

    struct ElectionDetails {
        string name;
        string description;
        uint256 durationDays;
        uint256 deadline;
        bool isElectionPeriod;
    }
}