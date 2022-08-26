//SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./BountyQuestion.sol";

// Interfaces
import "./interfaces/IClaimController.sol";
import "./interfaces/IQuestionStateController.sol";
import "./interfaces/IActionCostController.sol";

// Enums
import "./Enums/ActionEnum.sol";
import "./Enums/QuestionStateEnum.sol";

// Modifiers
import "./modifiers/NFTLocked.sol";
import "./modifiers/FunctionLocked.sol";

/**
 * @title MetricsDAO question API
 * @author MetricsDAO team
 * @notice This contract is an API for MetricsDAO that allows for interacting with questions & challenges.
 */

contract QuestionAPI is Ownable, NFTLocked, FunctionLocked {
    BountyQuestion private _question;
    IQuestionStateController private _questionStateController;
    IClaimController private _claimController;
    IActionCostController private _costController;

    //------------------------------------------------------ ERRORS

    /// @notice Throw if analysts tries to claim a question that is not published.
    error ClaimsNotOpen();
    /// @notice Throw if a question has not reached the benchmark for being published (yet).
    error NotAtBenchmark();
    /// @notice Throw if address is equal to address(0).
    error InvalidAddress();
    /// @notice Throw if user tries to vote for own question
    error CannotVoteForOwnQuestion();

    //------------------------------------------------------ EVENTS

    /// @notice Emitted when a question is created.
    event QuestionCreated(uint256 indexed questionId, address indexed creator);

    /// @notice Emitted when a challenge is created.
    event ChallengeCreated(uint256 indexed questionId, address indexed challengeCreator);

    /// @notice Emitted when a question is published.
    event QuestionPublished(uint256 indexed questionId, address indexed publisher);

    /// @notice Emitted when a question is claimed.
    event QuestionClaimed(uint256 indexed questionId, address indexed claimant);

    /// @notice Emitted when a question is answered.
    event QuestionAnswered(uint256 indexed questionId, address indexed answerer);

    /// @notice Emitted when a question is disqualified.
    event QuestionDisqualified(uint256 indexed questionId, address indexed disqualifier);

    /// @notice Emitted when a question is upvoted.
    event QuestionUpvoted(uint256 indexed questionId, address indexed voter);

    /// @notice Emitted when a question is unvoted.
    event QuestionUnvoted(uint256 indexed questionId, address indexed voter);

    //------------------------------------------------------ CONSTRUCTOR

    /**
     * @notice Constructor sets the question state controller, claim controller, and action cost controller.
     * @param bountyQuestion BountyQuestion contract instance.
     * @param questionStateController The question state controller address.
     * @param claimController The claim controller address.
     * @param costController The action cost controller address.
     */
    constructor(
        address bountyQuestion,
        address questionStateController,
        address claimController,
        address costController
    ) {
        _question = BountyQuestion(bountyQuestion);
        _questionStateController = IQuestionStateController(questionStateController);
        _claimController = IClaimController(claimController);
        _costController = IActionCostController(costController);
    }

    //------------------------------------------------------ FUNCTIONS

    /**
     * @notice Creates a question.
     * @param uri The IPFS hash of the question.
     * @return The question id
     */
    function createQuestion(string calldata uri) public returns (uint256) {
        // Mint a new question
        uint256 questionId = _question.mintQuestion(_msgSender(), uri);

        // Initialize the question
        _questionStateController.initializeQuestion(questionId);

        // Pay to create a question
        _costController.payForAction(_msgSender(), questionId, ACTION.CREATE);

        emit QuestionCreated(questionId, _msgSender());

        return questionId;
    }

    /**
     * @notice Directly creates a challenge, this is an optional feature for program managers that would like to create challenges directly (skipping the voting stage).
     * @param uri The IPFS hash of the challenge
     * @param claimLimit The limit for the amount of people that can claim the challenge
     * @return questionId The question id
     */
    function createChallenge(string calldata uri, uint256 claimLimit) public onlyHolder(PROGRAM_MANAGER_ROLE) returns (uint256) {
        // Mint a new question
        uint256 questionId = _question.mintQuestion(_msgSender(), uri);

        // Initialize the question
        _questionStateController.initializeQuestion(questionId);
        _claimController.initializeQuestion(questionId, claimLimit);

        // Publish the question
        _questionStateController.publish(questionId);

        emit ChallengeCreated(questionId, _msgSender());

        return questionId;
    }

    /**
     * @notice Upvotes a question.
     * @param questionId The questionId of the question to upvote.
     */
    function upvoteQuestion(uint256 questionId) public {
        if (_question.getAuthorOfQuestion(questionId) == _msgSender()) revert CannotVoteForOwnQuestion();

        // Vote for a question
        _questionStateController.voteFor(_msgSender(), questionId);

        // Pay to upvote a question
        _costController.payForAction(_msgSender(), questionId, ACTION.VOTE);

        emit QuestionUpvoted(questionId, _msgSender());
    }

    /**
     * @notice Unvotes a question.
     * @param questionId The questionId of the question to upvote.
     */
    function unvoteQuestion(uint256 questionId) public {
        _questionStateController.unvoteFor(_msgSender(), questionId);

        emit QuestionUnvoted(questionId, _msgSender());
    }

    /**
     * @notice Publishes a question and allows it to be claimed and receive answers.
     * @param questionId The questionId of the question to publish
     * @param claimLimit The amount of claims per question.
     */

    function publishQuestion(uint256 questionId, uint256 claimLimit) public onlyHolder(ADMIN_ROLE) functionLocked {
        // Publish the question
        _questionStateController.publish(questionId);
        _claimController.initializeQuestion(questionId, claimLimit);

        emit QuestionPublished(questionId, _msgSender());
    }

    /**
     * @notice Allows anm analyst to claim a question and submit an answer before the dealine.
     * @param questionId The questionId of the question to disqualify
     */
    function claimQuestion(uint256 questionId) public functionLocked {
        // Check if the question is published and is therefore claimable
        if (_questionStateController.getState(questionId) != STATE.PUBLISHED) revert ClaimsNotOpen();

        // Claim the question
        _claimController.claim(_msgSender(), questionId);

        // Pay for claiming a question
        _costController.payForAction(_msgSender(), questionId, ACTION.CLAIM);

        emit QuestionClaimed(questionId, _msgSender());
    }

    function releaseClaim(uint256 questionId) public functionLocked {
        _claimController.releaseClaim(_msgSender(), questionId);
    }

    /**
     * @notice Allows a claimed question to be answered by an analyst.
     * @param questionId The questionId of the question to answer.
     * @param answerURL THE IPFS hash of the answer.
     */
    function answerQuestion(uint256 questionId, string calldata answerURL) public functionLocked {
        _claimController.answer(_msgSender(), questionId, answerURL);

        emit QuestionAnswered(questionId, _msgSender());
    }

    /**
     * @notice Allows the owner to disqualify a question.
     * @param questionId The questionId of the question to disqualify.
     */
    function disqualifyQuestion(uint256 questionId) public onlyOwner functionLocked {
        _questionStateController.setDisqualifiedState(questionId);

        emit QuestionDisqualified(questionId, _msgSender());
    }

    //------------------------------------------------------ OWNER FUNCTIONS

    /**
     * @notice Allows the owner to set the BountyQuestion contract address.
     * @param newQuestion The address of the new BountyQuestion contract.
     */
    function setQuestionProxy(address newQuestion) public onlyOwner {
        if (newQuestion == address(0)) revert InvalidAddress();
        _question = BountyQuestion(newQuestion);
    }

    /**
     * @notice Allows the owner to set the QuestionStateController contract address.
     * @param newQuestion The address of the new BountyQuestion contract.
     */
    function setQuestionStateController(address newQuestion) public onlyOwner {
        if (newQuestion == address(0)) revert InvalidAddress();
        _questionStateController = IQuestionStateController(newQuestion);
    }

    /**
     * @notice Allows the owner to set the ClaimController contract address.
     * @param newQuestion The address of the new ClaimController contract.
     */
    function setClaimController(address newQuestion) public onlyOwner {
        if (newQuestion == address(0)) revert InvalidAddress();
        _claimController = IClaimController(newQuestion);
    }

    /**
     * @notice Allows the owner to set the CostController contract address.
     * @param newCost The address of the new CostController contract.
     */
    function setCostController(address newCost) public onlyOwner {
        if (newCost == address(0)) revert InvalidAddress();
        _costController = IActionCostController(newCost);
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

import "../Enums/ActionEnum.sol";

interface IActionCostController {
    function setActionCost(ACTION action, uint256 cost) external;

    function payForAction(
        address _user,
        uint256 questionId,
        ACTION action
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

enum ACTION {
    CREATE,
    VOTE,
    CLAIM
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
pragma solidity 0.8.13;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/interfaces/IERC721.sol";

abstract contract NFTLocked is Ownable {
    bytes32 public constant PROGRAM_MANAGER_ROLE = keccak256("PROGRAM_MANAGER_ROLE");
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");

    mapping(bytes32 => address) private _nfts;

    function addHolderRole(bytes32 role, address nft) public onlyOwner {
        _nfts[role] = nft;
    }

    modifier onlyHolder(bytes32 role) {
        _checkRole(role);
        _;
    }

    error DoesNotHold();

    function _checkRole(bytes32 role) internal view virtual {
        if (IERC721(_nfts[role]).balanceOf(_msgSender()) == 0) revert DoesNotHold();
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "@openzeppelin/contracts/access/Ownable.sol";

abstract contract FunctionLocked is Ownable {
    bool isLocked;

    error FunctionIsLocked();

    function toggleLock() public onlyOwner {
        isLocked = !isLocked;
    }

    modifier functionLocked() {
        if (isLocked) revert FunctionIsLocked();
        _;
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

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "../Structs/QuestionData.sol";

interface IBountyQuestion {
    function getQuestionData(uint256 questionId) external view returns (QuestionData memory);

    function getMostRecentQuestion() external view returns (uint256);

    function updateState(uint256 questionId, STATE newState) external;
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC721.sol)

pragma solidity ^0.8.0;

import "../token/ERC721/IERC721.sol";

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

enum CLAIM_STATE {
    UNINT,
    CLAIMED,
    RELEASED,
    ANSWERED
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}