//SPDX-License-Identifier: MIT;
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/security/Pausable.sol";

///@dev  ERC20 interface to enable us access ERC20 smart contract functions
interface IERC20 {
    function balanceOf(address owner) external view returns (uint256);
}

///@dev  ERC721 interface to enable us access ERC721 smart contract functions
interface IERC721 {
    function balanceOf(address owner) external view returns (uint256);
}

///@author  Hamid Adewuyi
///@title  Vote -A decentraclized voting contract

contract Vote is Pausable {
    constructor() {
        owner = msg.sender;
    }

    ///========================== STATE VARIABLES ==========================
    ///@dev  The owner of the contract
    address public owner;
    ///@notice keeps track of the number of candidates
    uint public candidateId = 0;
    ///@notice keeps track of the number of elections
    uint public electionId = 0;

    ///@notice The list of all elections
    ///@dev mapping of electionId to election
    mapping(uint => Election) public allElections;
    ///@notice The list of all candidates
    ///@dev mapping of candidateId to candidate
    mapping(uint => Candidate) public allCandidates;
    ///@notice keeps track of people that have voted
    ///@dev mapping of address to bool
    mapping(uint => mapping(address => bool)) public voted;
    ///@notice announce if there is a tie
    string public tie;

    ///@notice struct to hold election details
    struct Election {
        uint electionId;
        address creator;
        address identifier;
        string details;
        bool active;
        Candidate[] candidates;
    }
    ///@notice struct to hold candidate details
    struct Candidate {
        uint electionId;
        uint candidateId;
        string photoHash;
        string name;
        uint vote;
    }
    ///========================== EVENTS ==========================
    event ElectionCreated(
        uint indexed electionId,
        address indexed creator,
        string details
    );
    event ElectionStarted(
        uint indexed electionId,
        address indexed creator,
        string details
    );
    event ElectionEnded(
        uint indexed electionId,
        address indexed creator,
        string details
    );
    event ElectionVoted(
        uint indexed electionId,
        address indexed voter,
        uint indexed candidateId
    );

    ///========================== FUNCTIONS ==========================
    ///@notice function to create an election
    ///@param _identifier the address of the token or NFT contract
    ///@param _details the details of the election
    ///@param _candidate the name of candidates
    function setUp(
        address _identifier,
        string memory _details,
        string[] calldata _candidate,
        string[] calldata _photoHash
    ) public whenNotPaused {
        require(_identifier != address(0), "invalid contract address");
        require(bytes(_details).length > 0, "invalid election details");
        require(_candidate.length > 0, "Please add some candidates");
        require(_photoHash.length > 0, "Please add some photos");
        require(
            _candidate.length == _photoHash.length,
            "Please add the same number of candidates and photos"
        );
        ///@notice increment the electionId
        electionId++;
        ///@notice create a new election
        Election storage election = allElections[electionId];
        ///@notice set the election id
        election.electionId = electionId;
        ///@notice set the creator of the election
        election.creator = msg.sender;
        ///@notice set the identifier of the election
        election.identifier = _identifier;
        ///@notice set the details of the election
        election.details = _details;
        ///@notice set the active status of the election
        election.active = false;

        ///@notice create a new candidate for the election
        ///@dev to loop through the array of candidates and create a new candidate
        for (uint i = 0; i < _candidate.length; i++) {
            ///@notice increment the candidateId
            candidateId++;
            ///@notice create a new candidate
            Candidate memory candidate = Candidate(
                electionId,
                candidateId,
                _photoHash[i],
                _candidate[i],
                0
            );
            allCandidates[candidateId] = candidate;
            election.candidates.push(candidate);
        }

        emit ElectionCreated(electionId, msg.sender, _details);
    }

    ///@notice function to start an election
    ///@param _electionId the id of the election
    function start(uint _electionId) public whenNotPaused {
        ///@notice check if user is the creator of the election
        require(
            allElections[_electionId].creator == msg.sender,
            "only moderator can start an election"
        );
        ///@notice change the status of the election to active
        allElections[_electionId].active = true;

        emit ElectionStarted(
            _electionId,
            msg.sender,
            allElections[_electionId].details
        );
    }

    ///@notice function to vote for a candidate
    ///@param _candidateId is the Id of the candidate
    ///@param _electionId is the Id of the election
    function vote(uint _candidateId, uint _electionId) public whenNotPaused {
        ///@notice check if user has already voted
        require(
            voted[_electionId][msg.sender] == false,
            "you have already voted"
        );
        ///@notice check if the election is active
        require(
            allElections[_electionId].active == true,
            "election have not begun"
        );
        ///@notice address of the identifier of the election

        address identifier = allElections[_electionId].identifier;
        ///@notice check user's identifier's balance
        require(
            IERC20(identifier).balanceOf(msg.sender) > 0 ||
                IERC721(identifier).balanceOf(msg.sender) > 0,
            "only registered voters can vote"
        );

        ///@notice set the user as voted
        voted[_electionId][msg.sender] = true;

        ///@notice increment the vote of the candidate
        allCandidates[_candidateId].vote++;

        emit ElectionVoted(_electionId, msg.sender, _candidateId);
    }

    ///@notice function to get the winner of the election
    ///@param _electionId is the Id of the election

    function getWinner(uint _electionId)
        public
        whenNotPaused
        returns (Candidate[] memory, string memory)
    {
        ///@notice check if the user is the creator of the election
        require(
            allElections[_electionId].creator == msg.sender,
            "only moderators can announce winner"
        );
        ///@notice to set the election status to false
        allElections[_electionId].active = false;

        ///@notice to get the winner of the election
        Candidate[] memory contestants = new Candidate[](candidateId);
        uint winningVoteCount = 0;
        uint256 winnerId;
        uint winningCandidateIndex = 0;
        for (uint i = 0; i < candidateId; i++) {
            if (allCandidates[i + 1].electionId == _electionId) {
                if (allCandidates[i + 1].vote > winningVoteCount) {
                    winningVoteCount = allCandidates[i + 1].vote;
                    uint currentId = allCandidates[i + 1].candidateId;
                    winnerId = currentId;

                    Candidate storage currentItem = allCandidates[currentId];
                    contestants[winningCandidateIndex] = currentItem;
                    winningCandidateIndex += 1;
                    tie = "We have a winner";
                } else if (allCandidates[i + 1].vote == winningVoteCount) {
                    tie = "This ended in a tie";
                }
            }
            emit ElectionEnded(
                _electionId,
                msg.sender,
                allElections[_electionId].details
            );
        }

        return (contestants, tie);
    }

    ///@notice function to get active elections
    function booth() public view whenNotPaused returns (Election[] memory) {
        ///@notice to track active elections
        uint currentIndex = 0;
        ///@notice to store total number of elections
        uint total = electionId;

        ///@dev new instance of election
        Election[] memory booths = new Election[](total);

        /// @notice Loop through all items ever created
        for (uint i = 0; i < electionId; i++) {
            /// @notice Get only active elections
            if (allElections[i + 1].active == true) {
                uint currentId = allElections[i + 1].electionId;
                Election storage currentItem = allElections[currentId];
                booths[currentIndex] = currentItem;
                currentIndex += 1;
            }
        }
        return booths;
    }

    ///notice function to get elections created by user
    function myElections()
        public
        view
        whenNotPaused
        returns (Election[] memory)
    {
        ///@notice to track elections created by user
        uint currentIndex = 0;
        ///@notice to store total number of elections
        uint total = electionId;

        Election[] memory items = new Election[](total);

        /// @notice Loop through all elections ever created
        for (uint i = 0; i < electionId; i++) {
            /// @notice Get only elections created by user
            if (allElections[i + 1].creator == msg.sender) {
                uint currentId = allElections[i + 1].electionId;
                Election storage currentItem = allElections[currentId];
                items[currentIndex] = currentItem;
                currentIndex += 1;
            }
        }
        return items;
    }

    ///@dev function to pause the contract
    function pause() public onlyOwner {
        _pause();
    }

    ///@dev function to unpause the contract
    function unpause() public onlyOwner {
        _unpause();
    }

    ///=================== MODIFIERS ===================

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
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