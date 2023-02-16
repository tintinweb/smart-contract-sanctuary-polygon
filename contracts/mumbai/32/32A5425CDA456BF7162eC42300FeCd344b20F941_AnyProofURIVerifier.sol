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

// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.9;

interface IGoal {
    function getVerificationData(
        uint256 tokenId,
        string memory key
    ) external view returns (string memory);
}

// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.9;

interface IHub {
    function getGoalAddress() external view returns (address);

    function getUsageAddress() external view returns (address);

    function getBioAddress() external view returns (address);

    function getVerifierAddress(
        string memory verifierName
    ) external view returns (address);
}

// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.9;

interface IVerifier {
    function verify(uint256 goalTokenId) external;

    function getVerificationStatus(
        uint256 goalTokenId
    ) external view returns (bool isAchieved, bool isFailed);
}

// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.9;

library Errors {
    // Common
    string internal constant TOKEN_DOES_NOT_EXIST = "Token does not exist";
    string internal constant TOKEN_IS_NON_TRANSFERABLE =
        "Token is non-transferable";
    string internal constant ARRAYS_MUST_HAVE_THE_SAME_LENGTH =
        "Arrays must have the same length";
    string internal constant UNABLE_TO_TRANSFER = "Unable to transfer";

    // Goal contract
    string internal constant STAKE_MUST_BE_EQUAL_TO_MESSAGE_VALUE =
        "Stake must equal to message value";
    string internal constant STAKE_MUST_BE_GREATER_THAN_ZERO =
        "Stake must be greater than zero";
    string
        internal constant MUST_BE_MORE_THAN_24_HOURS_BEFORE_DEADLINE_TIMESTAMP =
        "Must be more than 24 hours before deadline timestamp";
    string
        internal constant NOT_FOUND_VERIFIER_FOR_GOAL_VERIFICATION_REQUIREMENT =
        "Not found verifier for goal verification requirement";
    string internal constant GOAL_IS_CLOSED = "Goal is closed";
    string internal constant GOAL_AUTHOR_CAN_NOT_BE_A_WATCHER =
        "Goal author can not be a watcher";
    string internal constant SENDER_IS_ALREADY_WATCHER =
        "Sender is already watcher";
    string internal constant SENDER_IS_NOT_GOAL_AUTHOR =
        "Sender is not goal author";
    string internal constant GOAL_VERIFICATION_STATUS_IS_NOT_ACHIEVED =
        "Goal verification status is not achieved";
    string internal constant WATCHER_IS_NOT_FOUND = "Watcher is not found";
    string internal constant WATCHER_IS_ALREADY_ACCEPTED =
        "Watcher is already accepted";
    string internal constant FAIL_TO_RETURN_AUTHOR_STAKE =
        "Fail to return author stake";
    string internal constant FAIL_TO_SEND_PART_OF_STAKE_TO_WATCHER =
        "Fail send a part of stake to watcher";

    // Verifier contracts
    string internal constant SENDER_IS_NOT_GOAL_CONTRACT =
        "Sender is not goal contract";
    string internal constant GOAL_DOES_NOT_HAVE_ANY_PROOF_URI =
        "Goal does not any proof URI";
    string
        internal constant GOAL_DOES_NOT_HAVE_GITHUB_USERNAME_OR_ACTIVITY_DAYS =
        "Goal does not have github username or activity days";
}

// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.9;

/**
 * String utils.
 */
library Strings {
    /**
     * Returns true if the two strings are equal.
     *
     * Source - https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/Strings.sol
     */
    function equal(
        string memory a,
        string memory b
    ) internal pure returns (bool) {
        return keccak256(bytes(a)) == keccak256(bytes(b));
    }
}

// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.9;

import "./Verifier.sol";
import "../libraries/Strings.sol";
import "../interfaces/IHub.sol";
import "../interfaces/IGoal.sol";
import "../libraries/Errors.sol";

/**
 * Contract to verify a goal by any proof uri.
 */
contract AnyProofURIVerifier is Verifier {
    string _anyProofUriKey = "ANY_PROOF_URI";

    constructor(address hubAddress) Verifier(hubAddress) {}

    function verify(uint256 goalTokenId) public override {
        // Check sender
        require(
            msg.sender == IHub(_hubAddress).getGoalAddress(),
            Errors.SENDER_IS_NOT_GOAL_CONTRACT
        );
        // Check verification data
        string memory anyProofUri = IGoal(IHub(_hubAddress).getGoalAddress())
            .getVerificationData(goalTokenId, _anyProofUriKey);
        require(
            !Strings.equal(anyProofUri, ""),
            Errors.GOAL_DOES_NOT_HAVE_ANY_PROOF_URI
        );
        // Update verification status
        _goalsVerifiedAsAchieved[goalTokenId] = true;
        _goalsVerifiedAsFailed[goalTokenId] = true;
    }
}

// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "../interfaces/IVerifier.sol";

/**
 * Contract to verify a goal that shoul be extended.
 */
contract Verifier is IVerifier, Ownable {
    address internal _hubAddress;
    mapping(uint256 => bool) internal _goalsVerifiedAsAchieved;
    mapping(uint256 => bool) internal _goalsVerifiedAsFailed;

    constructor(address hubAddress) {
        _hubAddress = hubAddress;
    }

    function verify(uint256 goalTokenId) public virtual {}

    function getVerificationStatus(
        uint256 goalTokenId
    ) public view returns (bool isAchieved, bool isFailed) {
        return (
            _goalsVerifiedAsAchieved[goalTokenId],
            _goalsVerifiedAsFailed[goalTokenId]
        );
    }

    function getHubAddress() public view returns (address) {
        return _hubAddress;
    }

    function setHubAddress(address hubAddress) public onlyOwner {
        _hubAddress = hubAddress;
    }
}