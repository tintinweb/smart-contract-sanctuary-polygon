// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

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
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC721/IERC721.sol)

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

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must have been allowed to move this token by either {approve} or {setApprovalForAll}.
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
     * WARNING: Note that the caller is responsible to confirm that the recipient is capable of receiving ERC721
     * or else they may be permanently lost. Usage of {safeTransferFrom} prevents loss, though the caller must
     * understand this adds an external call which potentially creates a reentrancy vulnerability.
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
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
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

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/utils/Context.sol";

contract VotingContract is Context, Ownable {
    struct Question {
        bytes32 questionHash;
        bytes32[] optionHashes;
        uint8 optionCount;
        mapping(uint8 => address[]) votes;
    }

    address public membershipToken;
    uint8 private voteBalance;

    mapping(bytes32 => Question) public questions;
    mapping(bytes32 => uint[]) public questionResults;
    mapping(bytes32 => uint256) public questionStartTimes;
    mapping(bytes32 => uint256) public questionEndTimes;
    mapping(bytes32 => bool) hasVoted;

    event QuestionAdded(bytes32 questionHash);
    event VoteCasted(bytes32 questionHash, bytes32 optionHash, address voter);
    event VotingResultsPublished(bytes32 indexed questionHash);
    event VotingPeriodSet(
        bytes32 indexed questionHash,
        uint startTime,
        uint endTime
    );
    event MembershipTokenChanged(address _newMembershipToken);

    modifier canVote(bytes32 questionHash) {
        require(_canVote(_msgSender()), "Low Balance");
        require(
            !hasVoted[keccak256(abi.encodePacked(questionHash, _msgSender()))],
            "Already Voted"
        );
        _;
    }

    constructor(
        address _membershipToken,
        uint8 _voteBalance
    ) payable Ownable() {
        require(
            _membershipToken != address(0) && _membershipToken != address(this),
            "Invalid Membership token Address"
        );
        voteBalance = _voteBalance;
        membershipToken = _membershipToken;
    }

    function addQuestion(
        bytes32 _questionHash,
        bytes32[] memory _optionHashes
    ) external onlyOwner {
        Question storage newQuestion = questions[_questionHash];
        require(
            newQuestion.questionHash == bytes32(0),
            "Question already exists."
        );
        require(
            _optionHashes.length < type(uint8).max,
            "Option count exceeding"
        );

        newQuestion.questionHash = _questionHash;
        newQuestion.optionHashes = _optionHashes;
        newQuestion.optionCount = uint8(_optionHashes.length);

        emit QuestionAdded(_questionHash);
    }

    function setVotingPeriod(
        bytes32 _questionHash,
        uint256 _startTime,
        uint256 _endTime
    ) external onlyOwner {
        require(
            questions[_questionHash].questionHash != bytes32(0),
            "Question does not exist."
        );

        questionStartTimes[_questionHash] = _startTime;
        questionEndTimes[_questionHash] = _endTime;
        emit VotingPeriodSet(_questionHash, _startTime, _endTime);
    }

    function _isQuestionActive(
        bytes32 _questionHash
    ) internal view returns (bool) {
        return
            questionStartTimes[_questionHash] < block.timestamp &&
            questionEndTimes[_questionHash] > block.timestamp;
    }

    function castVote(
        bytes32 _questionHash,
        bytes32 _optionHash
    ) external canVote(_questionHash) {
        Question storage question = questions[_questionHash];
        require(
            question.questionHash != bytes32(0),
            "Question does not exist."
        );
        require(_isQuestionActive(_questionHash), "Voting period not active");
        require(
            isOptionValid(_questionHash, _optionHash),
            "Invalid option selected."
        );

        question.votes[getOptionIndex(_questionHash, _optionHash)].push(
            _msgSender()
        );
        hasVoted[
            keccak256(abi.encodePacked(_questionHash, _msgSender()))
        ] = true;
        emit VoteCasted(_questionHash, _optionHash, _msgSender());
    }

    function isOptionValid(
        bytes32 _questionHash,
        bytes32 _optionHash
    ) private view returns (bool) {
        Question storage question = questions[_questionHash];
        uint8 i;
        uint8 c = question.optionCount;
        for (i = 0; i < c; ++i) {
            if (question.optionHashes[i] == _optionHash) {
                break;
            }
        }

        return i < c;
    }

    function getOptionIndex(
        bytes32 _questionHash,
        bytes32 _optionHash
    ) private view returns (uint8) {
        Question storage question = questions[_questionHash];
        uint8 i;
        uint c = question.optionCount;
        for (i = 0; i < c; ++i) {
            if (question.optionHashes[i] == _optionHash) {
                break;
            }
        }
        if (i < c) return i;
        revert("Invalid option hash.");
    }

    function getQuestionResult(
        bytes32 _questionHash
    ) external view returns (uint[] memory) {
        Question storage q = questions[_questionHash];
        require(q.questionHash != bytes32(0), "Question does not exist.");
        require(
            !_isQuestionActive(_questionHash),
            "Voting period still active."
        );
        uint[] memory a = questionResults[_questionHash];
        return a;
    }

    function calculateQuestionResult(bytes32 _questionHash) external onlyOwner {
        Question storage question = questions[_questionHash];
        require(
            question.questionHash != bytes32(0),
            "Question does not exist."
        );
        require(
            !_isQuestionActive(_questionHash),
            "Voting period still active"
        );

        uint8 c = question.optionCount;
        uint[] memory qr = new uint[](c);
        for (uint8 i = 0; i < c; ++i) {
            qr[i] = 0;
        }

        for (uint8 i = 0; i < c; ++i) {
            qr[i] += question.votes[i].length;
        }

        questionResults[_questionHash] = qr;

        emit VotingResultsPublished(_questionHash);
    }

    function _canVote(address _user) internal view returns (bool) {
        return IERC721(membershipToken).balanceOf(_user) > voteBalance;
    }

    function changeMembershipToken(
        address _newMembershipToken
    ) external onlyOwner {
        require(
            _newMembershipToken != address(0) ||
                _newMembershipToken != address(this),
            "Invalid Membership token Address"
        );
        membershipToken = _newMembershipToken;
        emit MembershipTokenChanged(_newMembershipToken);
    }
}