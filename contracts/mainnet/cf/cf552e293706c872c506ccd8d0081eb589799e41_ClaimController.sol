//SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "@openzeppelin/contracts/access/Ownable.sol";

// Interfaces
import "./interfaces/IClaimController.sol";

// Enums
import "./Enums/ClaimEnum.sol";

// Structs
import "./Structs/AnswerStruct.sol";

// Modifiers
import "./modifiers/OnlyAPI.sol";

contract ClaimController is Ownable, IClaimController, OnlyApi {
    /// @notice Keeps track of claim limits per question
    mapping(uint256 => uint256) public claimLimits;

    /// @notice Keeps track of claim counts per question
    mapping(uint256 => uint256) public claimCounts;

    /// @notice maps answers to the question they belong to
    mapping(uint256 => mapping(address => Answer)) public answers;

    /// @notice maps all claimers to a question
    mapping(uint256 => address[]) public claims;

    //------------------------------------------------------ ERRORS

    /// @notice Throw if user tries to claim a question that is past its limit
    error ClaimLimitReached();

    /// @notice Throw if a analyst tries to answer a question that it has not claimed
    error NeedClaimToAnswer();

    /// @notice Throw if analyst tries to claim a question multiple times
    error AlreadyClaimed();

    /// @notice Throw if analyst tries to release a claim it did not claim
    error NoClaimToRelease();

    // ------------------------------------------------------ FUNCTIONS

    /**
     * @notice Initializes a question to receive claims
     * @param questionId The id of the question
     * @param claimLimit The limit for the amount of people that can claim the question
     */
    function initializeQuestion(uint256 questionId, uint256 claimLimit) public onlyApi {
        claimLimits[questionId] = claimLimit;
    }

    function claim(address user, uint256 questionId) public onlyApi {
        if (claimCounts[questionId] >= claimLimits[questionId]) revert ClaimLimitReached();
        if (answers[questionId][user].author == user) revert AlreadyClaimed();

        ++claimCounts[questionId];
        Answer memory _answer = Answer({state: CLAIM_STATE.CLAIMED, author: user, answerURL: "", scoringMetaDataURI: "", finalGrade: 0});
        answers[questionId][user] = _answer;
    }

    function releaseClaim(address user, uint256 questionId) public onlyApi {
        if (answers[questionId][user].author != user) revert NoClaimToRelease();

        answers[questionId][user].state = CLAIM_STATE.RELEASED;
        answers[questionId][user].author = address(0);

        --claimCounts[questionId];
    }

    function answer(
        address user,
        uint256 questionId,
        string calldata answerURL
    ) public onlyOwner {
        if (answers[questionId][user].state != CLAIM_STATE.CLAIMED) revert NeedClaimToAnswer();
        answers[questionId][user].answerURL = answerURL;
    }

    function getClaims(uint256 questionId) public view returns (address[] memory _claims) {
        return claims[questionId];
    }

    function getClaimLimit(uint256 questionId) public view returns (uint256) {
        return claimLimits[questionId];
    }

    function getClaimDataForUser(uint256 questionId, address user) public view returns (Answer memory _answer) {
        return answers[questionId][user];
    }

    function getQuestionClaimState(uint256 questionId, address user) public view returns (CLAIM_STATE claimState) {
        return answers[questionId][user].state;
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

import "../Structs/AnswerStruct.sol";

interface IClaimController {
    function initializeQuestion(uint256 questionId, uint256 claimLimit) external;

    function claim(address user, uint256 questionId) external;

    function releaseClaim(address user, uint256 questionId) external;

    function answer(
        address user,
        uint256 questionId,
        string calldata answerURL
    ) external;

    function getClaimDataForUser(uint256 questionId, address user) external view returns (Answer memory _answer);

    function getQuestionClaimState(uint256 questionId, address user) external view returns (CLAIM_STATE claimState);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

enum CLAIM_STATE {
    UNINT,
    CLAIMED,
    RELEASED,
    ANSWERED
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "../Enums/ClaimEnum.sol";

struct Answer {
    CLAIM_STATE state;
    address author;
    string answerURL;
    uint256 finalGrade;
    string scoringMetaDataURI;
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