// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./QuestionStateController.sol";
import "./BountyQuestion.sol";

// Interfaces
import "./interfaces/IQuestionStateController.sol";
import "./interfaces/IClaimController.sol";

// Enums
import "./Enums/VaultEnum.sol";
import "./Enums/QuestionStateEnum.sol";
import "./Enums/ClaimEnum.sol";

// Modifiers
import "./modifiers/OnlyCostController.sol";

contract Vault is Ownable, OnlyCostController {
    IERC20 public metric;
    IQuestionStateController public questionStateController;
    IClaimController public claimController;
    BountyQuestion private _question;

    STATUS public status;

    /// @notice Address to the MetricsDAO treasury.
    address public treasury;

    /// @notice Keeps track of the quantity of deposits per user.
    mapping(address => uint256[]) public depositsByWithdrawers;

    /// @notice Keeps track of the amount of METRIC locked per question
    mapping(uint256 => uint256) public lockedMetricByQuestion;

    /// @notice Keeps track of total amount in vault for a given user.
    mapping(address => uint256) public totalLockedInVaults;

    /// @notice Keeps track of the quantity of withdrawals per user.
    mapping(uint256 => mapping(STAGE => mapping(address => lockAttributes))) public lockedMetric;

    //------------------------------------------------------ ERRORS

    /// @notice Throw if user tries to withdraw Metric from a question it does not own.
    error NotTheDepositor();
    /// @notice Throw if user tries to withdraw Metric without having first deposited.
    error NoMetricDeposited();
    /// @notice Throw if user tries to lock Metric for a question that has a different state than UNINT.
    error QuestionHasInvalidStatus();
    /// @notice Throw if user tries to claim Metric for unvoting on a question that is not in the VOTING state.
    error QuestionNotInVoting();
    /// @notice Throw if user tries to claim Metric for a question that has not been published (yet).
    error QuestionNotPublished();
    /// @notice Throw if user tries to claim Metric for a question that was not unvoted
    error UserHasNotUnvoted();
    /// @notice Throw if user tries to withdraw Metric from a question that is not in the review state.
    error QuestionNotInReview();
    /// @notice Throw if user tries to withdraw Metric from a claim that is not released.
    error ClaimNotReleased();
    /// @notice Throw if creator of question tries to unvote
    error CannotUnvoteOwnQuestion();
    /// @notice Throw if the same question is slashed twice.
    error AlreadySlashed();
    /// @notice Throw if address is equal to address(0).
    error InvalidAddress();
    /// @notice Throw if user tries to lock METRIC for a stage that does not require locking.
    error InvalidStage();

    //------------------------------------------------------ STRUCTS

    struct lockAttributes {
        address user;
        uint256 amount;
        STATUS status;
    }

    //------------------------------------------------------ EVENTS

    /// @notice Event emitted when Metric is withdrawn.
    event Withdraw(address indexed user, uint256 indexed amount);
    /// @notice Event emitted when a question is slashed.
    event Slashed(address indexed user, uint256 indexed questionId);

    //------------------------------------------------------ CONSTRUCTOR

    /**
     * @notice Constructor sets the question Metric token, QuestionStateController and the treasury.
     * @param metricTokenAddress The Metric token address
     * @param questionStateControllerAddress The QuestionStateController address.
     * @param treasuryAddress The treasury address.
     */
    constructor(
        address metricTokenAddress,
        address questionStateControllerAddress,
        address treasuryAddress
    ) {
        metric = IERC20(metricTokenAddress);
        questionStateController = IQuestionStateController(questionStateControllerAddress);
        treasury = treasuryAddress;
    }

    //------------------------------------------------------ FUNCTIONS

    /**
     * @notice Locks METRIC for creating a question
     * @param user The address of the user locking the METRIC
     * @param amount The amount of METRIC to lock
     * @param questionId The question id'
     * @param stage The stage for which METRIC is locked
     */
    function lockMetric(
        address user,
        uint256 amount,
        uint256 questionId,
        STAGE stage
    ) external onlyCostController {
        // Checks if METRIC is locked for a valid stage.
        if (uint8(stage) >= 5) revert InvalidStage();
        // Checks if there has not been a deposit yet
        if (lockedMetric[questionId][stage][user].status != STATUS.UNINT) revert QuestionHasInvalidStatus();

        depositAccounting(user, amount, questionId, stage);
    }

    /**
     * @notice Allows a user to withdraw METRIC locked for a question, after the question is published.
     * @param questionId The question id
     * @param stage The stage for which the user is withdrawing metric from a question.
     */
    function withdrawMetric(uint256 questionId, STAGE stage) external {
        // Checks if Metric is withdrawn for a valid stage.
        if (uint8(stage) >= 5) revert InvalidStage();

        if (stage == STAGE.CREATE_AND_VOTE) {
            // Checks that the question is published
            if (questionStateController.getState(questionId) != STATE.PUBLISHED) revert QuestionNotPublished();

            // Accounting & changes
            withdrawalAccounting(questionId, STAGE.CREATE_AND_VOTE);
        } else if (stage == STAGE.UNVOTE) {
            // Check that user has a voting index, has not voted and the question state is VOTING.
            if (_question.getAuthorOfQuestion(questionId) == _msgSender()) revert CannotUnvoteOwnQuestion();
            if (questionStateController.getHasUserVoted(_msgSender(), questionId) == true) revert UserHasNotUnvoted();
            if (questionStateController.getState(questionId) != STATE.VOTING) revert QuestionNotInVoting();

            // Accounting & changes
            withdrawalAccounting(questionId, STAGE.CREATE_AND_VOTE);

            lockedMetric[questionId][STAGE.CREATE_AND_VOTE][_msgSender()].status = STATUS.UNINT;
        } else if (stage == STAGE.CLAIM_AND_ANSWER) {
            if (questionStateController.getState(questionId) != STATE.COMPLETED) revert QuestionNotInReview();

            withdrawalAccounting(questionId, STAGE.CLAIM_AND_ANSWER);
        } else if (stage == STAGE.RELEASE_CLAIM) {
            if (questionStateController.getState(questionId) != STATE.PUBLISHED) revert QuestionNotPublished();
            if (claimController.getQuestionClaimState(questionId, _msgSender()) != CLAIM_STATE.RELEASED) revert ClaimNotReleased();

            withdrawalAccounting(questionId, STAGE.CLAIM_AND_ANSWER);

            lockedMetric[questionId][STAGE.CLAIM_AND_ANSWER][_msgSender()].status = STATUS.UNINT;
        } else {
            // if (reviewPeriod == active) revert ReviewPeriodActive();
        }
    }

    function depositAccounting(
        address user,
        uint256 amount,
        uint256 questionId,
        STAGE stage
    ) internal {
        // Accounting & changes
        lockedMetric[questionId][stage][user].user = user;
        lockedMetric[questionId][stage][user].amount += amount;

        lockedMetricByQuestion[questionId] += amount;

        lockedMetric[questionId][stage][user].status = STATUS.DEPOSITED;

        totalLockedInVaults[user] += amount;
        depositsByWithdrawers[user].push(questionId);

        // Transfers Metric from the user to the vault.
        metric.transferFrom(user, address(this), amount);
    }

    function withdrawalAccounting(uint256 questionId, STAGE stage) internal {
        if (_msgSender() != lockedMetric[questionId][stage][_msgSender()].user) revert NotTheDepositor();
        if (lockedMetric[questionId][stage][_msgSender()].status != STATUS.DEPOSITED) revert NoMetricDeposited();

        uint256 toWithdraw = lockedMetric[questionId][stage][_msgSender()].amount;

        lockedMetric[questionId][stage][_msgSender()].status = STATUS.WITHDRAWN;
        lockedMetric[questionId][stage][_msgSender()].amount = 0;

        lockedMetricByQuestion[questionId] -= toWithdraw;
        totalLockedInVaults[_msgSender()] -= toWithdraw;

        // Transfers Metric from the vault to the user.
        metric.transfer(_msgSender(), toWithdraw);

        emit Withdraw(_msgSender(), toWithdraw);
    }

    /**
     * @notice Allows onlyOwner to slash a question -- halfing the METRIC locked for the question.
     * @param questionId The question id
     */
    // function slashMetric(uint256 questionId) external onlyOwner {
    //     // Check that the question has not been slashed yet.
    //     if (lockedMetric[questionId][0].status == STATUS.SLASHED) revert AlreadySlashed();

    //     lockedMetric[questionId][0].status = STATUS.SLASHED;

    //     // Send half of the Metric to the treasury
    //     metric.transfer(treasury, lockedMetricByQuestion[questionId] / 2);

    //     // Return the other half of the Metric to the user
    //     metric.transfer(lockedMetric[questionId][0].user, lockedMetric[questionId][0].amount / 2);

    //     emit Slashed(lockedMetric[questionId][0].user, questionId);
    // }

    /**
     * @notice Gets the questions that a user has created.
     * @param user The address of the user.
     * @return The questions that the user has created.
     */
    function getVaultsByWithdrawer(address user) external view returns (uint256[] memory) {
        return depositsByWithdrawers[user];
    }

    /**
     * @notice Gets the information about the vault attributes of a question.
     * @param questionId The question id.
     * @param stage The stage of the question.
     * @param user The address of the user.
     * @return A struct containing the attributes of the question (withdrawer, amount, status).
     */
    function getVaultById(
        uint256 questionId,
        STAGE stage,
        address user
    ) external view returns (lockAttributes memory) {
        return lockedMetric[questionId][stage][user];
    }

    function getLockedMetricByQuestion(uint256 questionId) public view returns (uint256) {
        return lockedMetricByQuestion[questionId];
    }

    function getUserFromProperties(
        uint256 questionId,
        STAGE stage,
        address user
    ) public view returns (address) {
        return lockedMetric[questionId][stage][user].user;
    }

    function getAmountFromProperties(
        uint256 questionId,
        STAGE stage,
        address user
    ) public view returns (uint256) {
        return lockedMetric[questionId][stage][user].amount;
    }

    function getLockedPerUser(address _user) public view returns (uint256) {
        return totalLockedInVaults[_user];
    }

    /**
     * @notice Gets the total amount of Metric locked in the vault.
     * @return The total amount of Metric locked in the vault.
     */
    function getMetricTotalLockedBalance() external view returns (uint256) {
        return metric.balanceOf(address(this));
    }

    //------------------------------------------------------ OWNER FUNCTIONS

    /**
     * @notice Allows owner to update the QuestionStateController.
     */
    function setQuestionStateController(address _questionStateController) public onlyOwner {
        if (_questionStateController == address(0)) revert InvalidAddress();
        questionStateController = IQuestionStateController(_questionStateController);
    }

    function setClaimController(address _claimController) public onlyOwner {
        if (_claimController == address(0)) revert InvalidAddress();
        claimController = IClaimController(_claimController);
    }

    /**
     * @notice Allows owner to update the treasury address.
     */
    function setTreasury(address _treasury) public onlyOwner {
        treasury = _treasury;
    }

    function setBountyQuestion(address _bountyQuestion) public onlyOwner {
        _question = BountyQuestion(_bountyQuestion);
    }

    /**
     * @notice Allows owner to update the Metric token address.
     */
    function setMetric(address _metric) public onlyOwner {
        if (_metric == address(0)) revert InvalidAddress();
        metric = IERC20(_metric);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
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

//SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "@openzeppelin/contracts/access/Ownable.sol";

// Interfaces
import "./interfaces/IQuestionStateController.sol";
import "./interfaces/IBountyQuestion.sol";

// Enums
import "./Enums/QuestionStateEnum.sol";

// Structs
import "./Structs/QuestionData.sol";

// Modifiers
import "./modifiers/OnlyAPI.sol";

contract QuestionStateController is IQuestionStateController, Ownable, OnlyApi {
    // Mapping for all questions that are upvoted by the user?
    mapping(address => mapping(uint256 => bool)) public hasVoted;

    /// @notice For a given address and a given question, tracks the index of their vote in the votes[]
    mapping(address => mapping(uint256 => uint256)) public questionIndex; // TODO userVoteIndex

    mapping(uint256 => Votes) public votes;

    IBountyQuestion private _bountyQuestion;

    // TODO do we want user to lose their metric if a question is closed? they voted on something bad

    constructor(address bountyQuestion) {
        _bountyQuestion = IBountyQuestion(bountyQuestion);
    }

    /**
     * @notice Initializes a question to draft.
     * @param questionId The id of the question
     */
    function initializeQuestion(uint256 questionId) public onlyApi {
        _bountyQuestion.updateState(questionId, STATE.VOTING);

        votes[questionId].totalVotes = 1;
    }

    function publish(uint256 questionId) public onlyApi onlyState(STATE.VOTING, questionId) {
        // if some voting barrier is passed, we can publish the question
        _bountyQuestion.updateState(questionId, STATE.PUBLISHED);
    }

    function voteFor(address _user, uint256 questionId) public onlyApi onlyState(STATE.VOTING, questionId) {
        // Checks
        if (hasVoted[_user][questionId]) revert HasAlreadyVotedForQuestion();

        // Effects
        hasVoted[_user][questionId] = true;

        votes[questionId].totalVotes++;
        votes[questionId].voters.push(_user);

        questionIndex[_user][questionId] = votes[questionId].voters.length - 1;

        // Interactions
    }

    function unvoteFor(address _user, uint256 questionId) public onlyApi onlyState(STATE.VOTING, questionId) {
        // Checks
        if (!hasVoted[_user][questionId]) revert HasNotVotedForQuestion();

        // Effects
        votes[questionId].totalVotes--;

        uint256 index = questionIndex[_user][questionId];
        delete votes[questionId].voters[index];

        hasVoted[_user][questionId] = false;

        // Interactions
    }

    function setDisqualifiedState(uint256 questionId) public onlyApi {
        _bountyQuestion.updateState(questionId, STATE.DISQUALIFIED);
    }

    // TODO batch voting and batch operations and look into arrays as parameters security risk

    //------------------------------------------------------ View Functions

    function getState(uint256 questionId) public view returns (STATE currentState) {
        return _bountyQuestion.getQuestionData(questionId).questionState;
    }

    function getVoters(uint256 questionId) public view returns (address[] memory voters) {
        return votes[questionId].voters;
    }

    function getTotalVotes(uint256 questionId) public view returns (uint256) {
        return votes[questionId].totalVotes;
    }

    function getHasUserVoted(address user, uint256 questionId) external view returns (bool) {
        return hasVoted[user][questionId];
    }

    function getQuestions(
        STATE state,
        uint256 offset,
        uint256 limit
    ) public view returns (QuestionData[] memory questions) {
        uint256 highestQuestion = _bountyQuestion.getMostRecentQuestion();
        if (limit > highestQuestion) limit = highestQuestion;
        if (offset > highestQuestion) offset = highestQuestion;

        questions = new QuestionData[](limit);

        uint256 found = 0;
        QuestionData memory cur;

        for (uint256 i = 0; i < highestQuestion; i++) {
            cur = _bountyQuestion.getQuestionData(i);
            if (cur.questionState == state) {
                questions[found] = cur;
                found++;
                if (found == limit) break;
            }
        }

        return questions;
    }

    function getQuestionsByState(
        STATE currentState,
        uint256 currentQuestionId,
        uint256 offset
    ) public view returns (QuestionData[] memory found) {
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
        found = new QuestionData[](sizeOfArray);
        for (uint256 i = currentQuestionId; i >= limit; i--) {
            if (_bountyQuestion.getQuestionData(i).questionState == currentState) {
                found[j] = _bountyQuestion.getQuestionData(i);
                found[j].totalVotes = votes[i].totalVotes;
                j++;
            }
        }
        return found;
    }

    //------------------------------------------------------ OWNER FUNCTIONS

    /**
     * @notice Allows the owner to set the BountyQuestion contract address.
     * @param newQuestion The address of the new BountyQuestion contract.
     */
    function setQuestionProxy(address newQuestion) public onlyOwner {
        if (newQuestion == address(0)) revert InvalidAddress();
        _bountyQuestion = IBountyQuestion(newQuestion);
    }

    //------------------------------------------------------ Errors
    error HasNotVotedForQuestion();
    error HasAlreadyVotedForQuestion();
    error InvalidStateTransition();
    error InvalidAddress();

    //------------------------------------------------------ Structs
    modifier onlyState(STATE required, uint256 questionId) {
        if (required != getState(questionId)) revert InvalidStateTransition();
        _;
    }

    struct Votes {
        address[] voters;
        uint256 totalVotes;
    }
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "./modifiers/OnlyAPI.sol";
import "./modifiers/OnlyStateController.sol";
import "./Structs/QuestionData.sol";
import "./interfaces/IBountyQuestion.sol";

/// @custom:security-contact [email protected]
contract BountyQuestion is IBountyQuestion, Ownable, OnlyApi, OnlyStateController {
    using Counters for Counters.Counter;

    Counters.Counter private _questionIdCounter;

    // This maps the author to the list of question IDs they have created
    mapping(address => uint256[]) public authors;

    mapping(uint256 => QuestionData) public questionData;

    constructor() {
        _questionIdCounter.increment();
    }

    function mintQuestion(address author, string calldata uri) public onlyApi returns (uint256) {
        uint256 questionId = _questionIdCounter.current();
        _questionIdCounter.increment();

        questionData[questionId].author = author;
        questionData[questionId].questionId = questionId;
        questionData[questionId].uri = uri;

        authors[author].push(questionId);
        return questionId;
    }

    function updateState(uint256 questionId, STATE newState) public onlyStateController {
        QuestionData storage question = questionData[questionId];
        question.questionState = newState;
    }

    function getAuthor(address user) public view returns (QuestionData[] memory) {
        uint256[] memory created = authors[user];

        QuestionData[] memory ret = new QuestionData[](created.length);

        for (uint256 i = 0; i < created.length; i++) {
            ret[i] = questionData[created[i]];
        }
        return ret;
    }

    function getAuthorOfQuestion(uint256 questionId) public view returns (address) {
        return questionData[questionId].author;
    }

    function getMostRecentQuestion() public view returns (uint256) {
        return _questionIdCounter.current();
    }

    function getQuestionData(uint256 questionId) public view returns (QuestionData memory) {
        return questionData[questionId];
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "../Enums/QuestionStateEnum.sol";

interface IQuestionStateController {
    function initializeQuestion(uint256 questionId) external;

    function voteFor(address _user, uint256 questionId) external;

    function unvoteFor(address _user, uint256 questionId) external;

    function publish(uint256 question) external;

    function getState(uint256 quesitonId) external view returns (STATE currentState);

    function getHasUserVoted(address user, uint256 questionId) external view returns (bool);

    function setDisqualifiedState(uint256 questionId) external;
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

enum STAGE {
    CREATE_AND_VOTE,
    UNVOTE,
    CLAIM_AND_ANSWER,
    RELEASE_CLAIM,
    REVIEW
}

enum STATUS {
    UNINT,
    DEPOSITED,
    WITHDRAWN,
    SLASHED
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

enum STATE {
    UNINIT,
    VOTING,
    PUBLISHED,
    DISQUALIFIED,
    COMPLETED
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

enum CLAIM_STATE {
    UNINT,
    CLAIMED,
    RELEASED,
    ANSWERED
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "@openzeppelin/contracts/access/Ownable.sol";

contract OnlyCostController is Ownable {
    address public costController;

    // ------------------------------- Setter
    /**
     * @notice Sets the address of the ActionCostController.
     * @param _newCostController The new address of the ActionCostController.
     */
    function setCostController(address _newCostController) external onlyOwner {
        costController = _newCostController;
    }

    // ------------------------ Modifiers
    modifier onlyCostController() {
        if (_msgSender() != costController) revert NotTheCostController();
        _;
    }

    // ------------------------ Errors
    error NotTheCostController();
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

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "../Structs/QuestionData.sol";

interface IBountyQuestion {
    function getQuestionData(uint256 questionId) external view returns (QuestionData memory);

    function getMostRecentQuestion() external view returns (uint256);

    function updateState(uint256 questionId, STATE newState) external;
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "../Enums/QuestionStateEnum.sol";

struct QuestionData {
    uint256 questionId;
    address author;
    string uri;
    // TODO this is only used for our bulk read functions and is not actively tracked, it shouldn't be here.
    uint256 totalVotes;
    STATE questionState;
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

//SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "@openzeppelin/contracts/access/Ownable.sol";

contract OnlyStateController is Ownable {
    address public stateController;

    // ------------------------------- Setter
    /**
     * @notice Sets the address of the QuestionStateController.
     * @param _newStateController The new address of the QuestionStateController.
     */
    function setStateController(address _newStateController) external onlyOwner {
        stateController = _newStateController;
    }

    // ------------------------ Modifiers
    modifier onlyStateController() {
        if (_msgSender() != stateController) revert NotTheStateController();
        _;
    }

    // ------------------------ Errors
    error NotTheStateController();
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