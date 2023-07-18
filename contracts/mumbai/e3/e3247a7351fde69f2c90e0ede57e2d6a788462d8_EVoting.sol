// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "@openzeppelin/utils/Counters.sol";
import "@openzeppelin/access/Ownable.sol";

contract EVoting is Ownable {
    using Counters for Counters.Counter;
    using Counters for uint256;

    // Counters.Counter private electionId;
    // Counters.Counter private candidateId;

    // user hash => bool: true = whitelisted, false = not whitelisted (can't vote)
    mapping(bytes32 => bool) public isWhitelisted;
    // electionId => ElectionInfo
    mapping(bytes32 => Election) public Elections;
    // electionId => post hash => Candidate hash => Candidate Info
    mapping(bytes32 => mapping(bytes32 => mapping(bytes32 => Candidate)))
        public CandidateStats;
    // electionId => post hash => Candidate hashes
    mapping(bytes32 => mapping(bytes32 => bytes32[])) private CandidateHashes;
    // electionId => voter hash => bool: true = voter has casted a vote, false voter has not casted a vote
    mapping(bytes32 => mapping(bytes32 => bool)) private userVoted;

    enum ElectionType {
        College,
        Department,
        General
    }

    struct Election {
        string title;
        uint256 start;
        uint256 end;
        bool isActive;
        ElectionType election_type;
    }

    struct Candidate {
        bytes32 electionId;
        string candidateName;
        string post;
        uint256 voteCount;
        ElectionType election_type;
    }

    modifier isWhitelistedToVote(string memory _matNo, string memory _email) {
        require(
            isWhitelisted[keccak256(abi.encodePacked(_matNo, _email))],
            "EVoting: Not whitelisted!"
        );
        _;
    }

    modifier hasVoted(
        string memory _electionId,
        string memory _matNo,
        string memory _email
    ) {
        bytes32 electionID = keccak256(abi.encodePacked(_electionId));
        bytes32 _bVoter = keccak256(abi.encodePacked(_matNo, _email));
        require(
            !userVoted[electionID][_bVoter],
            "EVoting: User already voted!"
        );
        _;
    }

    modifier isRegisteredForDifferentOrSameElections(
        string memory _electionId,
        string memory _candidateName,
        string memory _post
    ) {
        bytes32 electionID = keccak256(abi.encodePacked(_electionId));
        bytes32 _cPost = keccak256(abi.encodePacked(_post));
        // bytes32 CandidateID = keccak256(abi.encodePacked(_candidateId));
        bytes32 emptyStringPost = keccak256(abi.encodePacked(""));

        // if (
        //     keccak256(abi.encodePacked(temp.candidateName)) ==
        //     keccak256(abi.encodePacked(_candidateName))
        // ) {
        //     require(
        //         keccak256(abi.encodePacked(_post)) !=
        //             keccak256(abi.encodePacked(temp.post)),
        //         "EVoting: Candidate already registered!"
        //     );
        // }

        // candidate hashes
        bytes32[] memory chashes = CandidateHashes[electionID][_cPost];

        for (uint256 i = 0; i < chashes.length; i++) {
            bytes32 chash = chashes[i];
            Candidate memory tempCandidate = CandidateStats[electionID][_cPost][
                chash
            ];
            if (
                keccak256(abi.encodePacked(tempCandidate.candidateName)) ==
                keccak256(abi.encodePacked(_candidateName))
            ) {
                // require(keccak256(abi.encodePacked(tempCandidate.post)) == emptyStringPost, "EVoting: Candidate registered for a different Post!");
                require(
                    keccak256(abi.encodePacked(_post)) !=
                        keccak256(abi.encodePacked(tempCandidate.post)),
                    "EVoting: Candidate already registered!"
                );
            }
        }
        _;
    }

    event ElectionCreated(
        string indexed _title,
        ElectionType indexed _electionType
    );
    event VoterRegistered(string indexed _matNo);
    event CandidateCreated(
        string indexed _candidateName,
        ElectionType indexed _electionType,
        bytes32 indexed _electionId
    );
    event VoteCasted(bytes32 indexed _electionId, bytes32 indexed _candidateId);

    function createElection(
        string memory _electionId,
        string memory _title,
        uint256 _start,
        uint256 _end,
        uint8 _electionType
    ) public onlyOwner {
        require(
            block.timestamp <= _start && _start < _end,
            "EVoting: Invalid election duration!"
        );
        require(_electionType < 3, "EVoting: Election type!");

        bytes32 electionId = keccak256(abi.encodePacked(_electionId));
        Election memory _temp = Election({
            title: _title,
            start: _start,
            end: _end,
            isActive: false,
            election_type: ElectionType(_electionType)
        });

        Elections[electionId] = _temp;

        emit ElectionCreated(_title, ElectionType(_electionType));
    }

    function registerCandidate(
        string memory _electionId,
        string memory _candidateId,
        string memory _candidateName,
        string memory _post,
        uint8 _electionType
    )
        public
        onlyOwner
        isRegisteredForDifferentOrSameElections(
            _electionId,
            _candidateName,
            _post
        )
    {
        bytes32 electionId = keccak256(abi.encodePacked(_electionId));
        bytes32 candidateId = keccak256(abi.encodePacked(_candidateId));
        bytes32 bPost = keccak256(abi.encodePacked(_post));

        require(
            !Elections[electionId].isActive &&
                Elections[electionId].start > block.timestamp &&
                Elections[electionId].end > block.timestamp,
            "EVoting: Can't register candidate after start or end!"
        );
        require(
            ElectionType(Elections[electionId].election_type) ==
                ElectionType(_electionType),
            "EVoting: Wrong election!"
        );

        Candidate memory _candidate = Candidate({
            electionId: electionId,
            candidateName: _candidateName,
            post: _post,
            voteCount: 0,
            election_type: ElectionType(_electionType)
        });

        CandidateStats[electionId][bPost][candidateId] = _candidate;

        CandidateHashes[electionId][bPost].push(candidateId);

        emit CandidateCreated(
            _candidateName,
            ElectionType(_electionType),
            electionId
        );
    }

    function registerVoter(string memory _matNo, string memory email)
        public
        onlyOwner
    {
        bytes32 voterID = keccak256(abi.encodePacked(_matNo, email));
        isWhitelisted[voterID] = true;

        emit VoterRegistered(_matNo);
    }

    function castVote(
        string memory _electionId,
        string memory _candidateId,
        string memory _candidateName,
        string memory _post,
        string memory _matNo,
        string memory _email
    )
        public
        onlyOwner
        isWhitelistedToVote(_matNo, _email)
        hasVoted(_electionId, _matNo, _email)
    {
        bytes32 _bPost = keccak256(abi.encodePacked(_post));
        bytes32 _bVoter = keccak256(abi.encodePacked(_matNo, _email));
        bytes32 electionId = keccak256(abi.encodePacked(_electionId));
        bytes32 candidateId = keccak256(abi.encodePacked(_candidateId));

        Candidate memory _candidateTemp = CandidateStats[electionId][_bPost][
            candidateId
        ];
        require(
            keccak256(abi.encodePacked(_candidateTemp.candidateName)) ==
                keccak256(abi.encodePacked(_candidateName)),
            "EVoting: Candidate mismatch!"
        );

        userVoted[electionId][_bVoter] = true;
        CandidateStats[electionId][_bPost][candidateId].voteCount++;

        emit VoteCasted(electionId, candidateId);
    }

    function getVotesByElection(string memory _electionId, string memory _post)
        public
        view
        returns (Candidate[] memory)
    {
        bytes32 bPost = keccak256(abi.encodePacked(_post));
        bytes32 electionId = keccak256(abi.encodePacked(_electionId));

        // get candidate hashes
        bytes32[] memory chashes = CandidateHashes[electionId][bPost];

        Candidate[] memory stats = new Candidate[](chashes.length);

        // iterate through chashes and get each candidate stat
        for (uint8 i = 0; i < chashes.length; i++) {
            bytes32 chash = chashes[i];
            stats[i] = CandidateStats[electionId][bPost][chash];
        }

        return stats;
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby disabling any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}