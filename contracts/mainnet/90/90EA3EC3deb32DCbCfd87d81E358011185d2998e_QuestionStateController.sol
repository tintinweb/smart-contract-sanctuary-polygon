//SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "@openzeppelin/contracts/access/Ownable.sol";

// Interfaces
import "./interfaces/IQuestionStateController.sol";

// Modifiers
import "./modifiers/OnlyAPI.sol";

contract QuestionStateController is IQuestionStateController, Ownable, OnlyApi {
    // Mapping for all questions that are upvoted by the user?
    mapping(address => mapping(uint256 => bool)) public hasVoted;
    mapping(address => mapping(uint256 => uint256)) public questionIndex;

    mapping(uint256 => QuestionStats) public questionByState;

    //TODO mapping     mapping(STATE => uint256[]) public questionState;

    // TODO do we want user to lose their metric if a question is closed? they voted on somethjing bad

    /**
     * @notice Initializes a question to draft.
     * @param questionId The id of the question
     */
    function initializeQuestion(uint256 questionId, string calldata uri) public onlyApi {
        QuestionStats memory question;

        question.questionId = questionId;
        question.uri = uri;
        question.totalVotes = 1;
        question.questionState = STATE.VOTING;

        questionByState[questionId] = question;
    }

    function publish(uint256 questionId) public onlyApi onlyState(STATE.VOTING, questionId) {
        // if some voting barrier is passed, we can publish the question
        QuestionStats storage _question = questionByState[questionId];
        _question.questionState = STATE.PUBLISHED;
    }

    function voteFor(address _user, uint256 questionId) public onlyApi onlyState(STATE.VOTING, questionId) {
        // Checks
        if (hasVoted[_user][questionId]) revert HasAlreadyVotedForQuestion();

        // Effects
        QuestionStats storage _question = questionByState[questionId];
        _question.totalVotes += 1;

        hasVoted[_user][questionId] = true;
        _question.voters.push(_user);
        questionIndex[_user][questionId] = _question.voters.length - 1;

        // Interactions
    }

    function unvoteFor(address _user, uint256 questionId) public onlyApi onlyState(STATE.VOTING, questionId) {
        // Checks
        if (!hasVoted[_user][questionId]) revert HasNotVotedForQuestion();

        // Effects
        QuestionStats storage _question = questionByState[questionId];
        _question.totalVotes -= 1;

        uint256 index = questionIndex[_user][questionId];
        delete _question.voters[index];

        hasVoted[_user][questionId] = false;

        // Interactions
    }

    function setDisqualifiedState(uint256 questionId) public onlyApi {
        QuestionStats storage _question = questionByState[questionId];
        _question.questionState = STATE.DISQUALIFIED;
    }

    // TODO batch voting and batch operations and look into arrays as parameters security risk

    //------------------------------------------------------ View Functions

    function getState(uint256 questionId) public view returns (uint256 currentState) {
        QuestionStats memory _question = questionByState[questionId];
        return uint256(_question.questionState);
    }

    function getVoters(uint256 questionId) public view returns (address[] memory voters) {
        QuestionStats memory _question = questionByState[questionId];
        return _question.voters;
    }

    function getTotalVotes(uint256 questionId) public view returns (uint256) {
        QuestionStats memory _question = questionByState[questionId];
        return _question.totalVotes;
    }

    function getQuestionsByState(
        STATE currentState,
        uint256 currentQuestionId,
        uint256 offset
    ) public view returns (QuestionStats[] memory) {
        uint256 j = 0;
        uint256 limit;
        uint256 sizeOfArray;
        currentQuestionId -= 1;
        if (currentQuestionId > offset) {
            limit = currentQuestionId - offset;
            sizeOfArray = (currentQuestionId - offset) + 1;
        } else {
            limit = 1;
            sizeOfArray = currentQuestionId;
        }
        QuestionStats[] memory arr = new QuestionStats[](sizeOfArray);
        for (uint256 i = currentQuestionId; i >= limit; i--) {
            if (questionByState[i].questionState == currentState) {
                arr[j] = questionByState[i];
                j++;
            }
        }
        return arr;
    }

    //------------------------------------------------------ Errors
    error HasNotVotedForQuestion();
    error HasAlreadyVotedForQuestion();
    error InvalidStateTransition();

    //------------------------------------------------------ Structs
    modifier onlyState(STATE required, uint256 questionId) {
        if (uint256(required) != getState(questionId)) revert InvalidStateTransition();
        _;
    }

    struct QuestionStats {
        uint256 questionId;
        string uri;
        address[] voters;
        uint256 totalVotes;
        STATE questionState;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
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
pragma solidity 0.8.13;

interface IQuestionStateController {
    function initializeQuestion(uint256 questionId, string calldata uri) external;

    function voteFor(address _user, uint256 questionId) external;

    function unvoteFor(address _user, uint256 questionId) external;

    function publish(uint256 questionId) external;

    // TODO currentState can probably be like a uint8, it depends on how many states we have
    function getState(uint256 quesitonId) external view returns (uint256 currentState);

    function setDisqualifiedState(uint256 questionId) external;

    enum STATE {
        // TODO this where it becomes a challenge, can be claimed and answered
        UNINIT,
        VOTING,
        PUBLISHED, // TODO this where it becomes a challenge, can be claimed and answered
        DISQUALIFIED,
        COMPLETED
    }
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "@openzeppelin/contracts/access/Ownable.sol";

contract OnlyApi is Ownable {
    address public questionApi;

    // ------------------------------- Setter
    /**
     * @notice Sets the address of the question API.
     * @param _newApi The new address of the question API.
     */
    function setQuestionApi(address _newApi) external onlyOwner {
        questionApi = _newApi;
    }

    // ------------------------ Modifiers
    modifier onlyApi() {
        if (_msgSender() != questionApi) revert NotTheApi();
        _;
    }

    // ------------------------ Errors
    error NotTheApi();
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