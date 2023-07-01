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
// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

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
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        _requireNotPaused();
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
        _requirePaused();
        _;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Throws if the contract is paused.
     */
    function _requireNotPaused() internal view virtual {
        require(!paused(), "Pausable: paused");
    }

    /**
     * @dev Throws if the contract is not paused.
     */
    function _requirePaused() internal view virtual {
        require(paused(), "Pausable: not paused");
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
// OpenZeppelin Contracts (last updated v4.9.0) (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        // On the first call to nonReentrant, _status will be _NOT_ENTERED
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Returns true if the reentrancy guard is currently set to "entered", which indicates there is a
     * `nonReentrant` function in the call stack.
     */
    function _reentrancyGuardEntered() internal view returns (bool) {
        return _status == _ENTERED;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
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
// OpenZeppelin Contracts (last updated v4.9.2) (utils/cryptography/MerkleProof.sol)

pragma solidity ^0.8.0;

/**
 * @dev These functions deal with verification of Merkle Tree proofs.
 *
 * The tree and the proofs can be generated using our
 * https://github.com/OpenZeppelin/merkle-tree[JavaScript library].
 * You will find a quickstart guide in the readme.
 *
 * WARNING: You should avoid using leaf values that are 64 bytes long prior to
 * hashing, or use a hash function other than keccak256 for hashing leaves.
 * This is because the concatenation of a sorted pair of internal nodes in
 * the merkle tree could be reinterpreted as a leaf value.
 * OpenZeppelin's JavaScript library generates merkle trees that are safe
 * against this attack out of the box.
 */
library MerkleProof {
    /**
     * @dev Returns true if a `leaf` can be proved to be a part of a Merkle tree
     * defined by `root`. For this, a `proof` must be provided, containing
     * sibling hashes on the branch from the leaf to the root of the tree. Each
     * pair of leaves and each pair of pre-images are assumed to be sorted.
     */
    function verify(bytes32[] memory proof, bytes32 root, bytes32 leaf) internal pure returns (bool) {
        return processProof(proof, leaf) == root;
    }

    /**
     * @dev Calldata version of {verify}
     *
     * _Available since v4.7._
     */
    function verifyCalldata(bytes32[] calldata proof, bytes32 root, bytes32 leaf) internal pure returns (bool) {
        return processProofCalldata(proof, leaf) == root;
    }

    /**
     * @dev Returns the rebuilt hash obtained by traversing a Merkle tree up
     * from `leaf` using `proof`. A `proof` is valid if and only if the rebuilt
     * hash matches the root of the tree. When processing the proof, the pairs
     * of leafs & pre-images are assumed to be sorted.
     *
     * _Available since v4.4._
     */
    function processProof(bytes32[] memory proof, bytes32 leaf) internal pure returns (bytes32) {
        bytes32 computedHash = leaf;
        for (uint256 i = 0; i < proof.length; i++) {
            computedHash = _hashPair(computedHash, proof[i]);
        }
        return computedHash;
    }

    /**
     * @dev Calldata version of {processProof}
     *
     * _Available since v4.7._
     */
    function processProofCalldata(bytes32[] calldata proof, bytes32 leaf) internal pure returns (bytes32) {
        bytes32 computedHash = leaf;
        for (uint256 i = 0; i < proof.length; i++) {
            computedHash = _hashPair(computedHash, proof[i]);
        }
        return computedHash;
    }

    /**
     * @dev Returns true if the `leaves` can be simultaneously proven to be a part of a merkle tree defined by
     * `root`, according to `proof` and `proofFlags` as described in {processMultiProof}.
     *
     * CAUTION: Not all merkle trees admit multiproofs. See {processMultiProof} for details.
     *
     * _Available since v4.7._
     */
    function multiProofVerify(
        bytes32[] memory proof,
        bool[] memory proofFlags,
        bytes32 root,
        bytes32[] memory leaves
    ) internal pure returns (bool) {
        return processMultiProof(proof, proofFlags, leaves) == root;
    }

    /**
     * @dev Calldata version of {multiProofVerify}
     *
     * CAUTION: Not all merkle trees admit multiproofs. See {processMultiProof} for details.
     *
     * _Available since v4.7._
     */
    function multiProofVerifyCalldata(
        bytes32[] calldata proof,
        bool[] calldata proofFlags,
        bytes32 root,
        bytes32[] memory leaves
    ) internal pure returns (bool) {
        return processMultiProofCalldata(proof, proofFlags, leaves) == root;
    }

    /**
     * @dev Returns the root of a tree reconstructed from `leaves` and sibling nodes in `proof`. The reconstruction
     * proceeds by incrementally reconstructing all inner nodes by combining a leaf/inner node with either another
     * leaf/inner node or a proof sibling node, depending on whether each `proofFlags` item is true or false
     * respectively.
     *
     * CAUTION: Not all merkle trees admit multiproofs. To use multiproofs, it is sufficient to ensure that: 1) the tree
     * is complete (but not necessarily perfect), 2) the leaves to be proven are in the opposite order they are in the
     * tree (i.e., as seen from right to left starting at the deepest layer and continuing at the next layer).
     *
     * _Available since v4.7._
     */
    function processMultiProof(
        bytes32[] memory proof,
        bool[] memory proofFlags,
        bytes32[] memory leaves
    ) internal pure returns (bytes32 merkleRoot) {
        // This function rebuilds the root hash by traversing the tree up from the leaves. The root is rebuilt by
        // consuming and producing values on a queue. The queue starts with the `leaves` array, then goes onto the
        // `hashes` array. At the end of the process, the last hash in the `hashes` array should contain the root of
        // the merkle tree.
        uint256 leavesLen = leaves.length;
        uint256 proofLen = proof.length;
        uint256 totalHashes = proofFlags.length;

        // Check proof validity.
        require(leavesLen + proofLen - 1 == totalHashes, "MerkleProof: invalid multiproof");

        // The xxxPos values are "pointers" to the next value to consume in each array. All accesses are done using
        // `xxx[xxxPos++]`, which return the current value and increment the pointer, thus mimicking a queue's "pop".
        bytes32[] memory hashes = new bytes32[](totalHashes);
        uint256 leafPos = 0;
        uint256 hashPos = 0;
        uint256 proofPos = 0;
        // At each step, we compute the next hash using two values:
        // - a value from the "main queue". If not all leaves have been consumed, we get the next leaf, otherwise we
        //   get the next hash.
        // - depending on the flag, either another value from the "main queue" (merging branches) or an element from the
        //   `proof` array.
        for (uint256 i = 0; i < totalHashes; i++) {
            bytes32 a = leafPos < leavesLen ? leaves[leafPos++] : hashes[hashPos++];
            bytes32 b = proofFlags[i]
                ? (leafPos < leavesLen ? leaves[leafPos++] : hashes[hashPos++])
                : proof[proofPos++];
            hashes[i] = _hashPair(a, b);
        }

        if (totalHashes > 0) {
            require(proofPos == proofLen, "MerkleProof: invalid multiproof");
            unchecked {
                return hashes[totalHashes - 1];
            }
        } else if (leavesLen > 0) {
            return leaves[0];
        } else {
            return proof[0];
        }
    }

    /**
     * @dev Calldata version of {processMultiProof}.
     *
     * CAUTION: Not all merkle trees admit multiproofs. See {processMultiProof} for details.
     *
     * _Available since v4.7._
     */
    function processMultiProofCalldata(
        bytes32[] calldata proof,
        bool[] calldata proofFlags,
        bytes32[] memory leaves
    ) internal pure returns (bytes32 merkleRoot) {
        // This function rebuilds the root hash by traversing the tree up from the leaves. The root is rebuilt by
        // consuming and producing values on a queue. The queue starts with the `leaves` array, then goes onto the
        // `hashes` array. At the end of the process, the last hash in the `hashes` array should contain the root of
        // the merkle tree.
        uint256 leavesLen = leaves.length;
        uint256 proofLen = proof.length;
        uint256 totalHashes = proofFlags.length;

        // Check proof validity.
        require(leavesLen + proofLen - 1 == totalHashes, "MerkleProof: invalid multiproof");

        // The xxxPos values are "pointers" to the next value to consume in each array. All accesses are done using
        // `xxx[xxxPos++]`, which return the current value and increment the pointer, thus mimicking a queue's "pop".
        bytes32[] memory hashes = new bytes32[](totalHashes);
        uint256 leafPos = 0;
        uint256 hashPos = 0;
        uint256 proofPos = 0;
        // At each step, we compute the next hash using two values:
        // - a value from the "main queue". If not all leaves have been consumed, we get the next leaf, otherwise we
        //   get the next hash.
        // - depending on the flag, either another value from the "main queue" (merging branches) or an element from the
        //   `proof` array.
        for (uint256 i = 0; i < totalHashes; i++) {
            bytes32 a = leafPos < leavesLen ? leaves[leafPos++] : hashes[hashPos++];
            bytes32 b = proofFlags[i]
                ? (leafPos < leavesLen ? leaves[leafPos++] : hashes[hashPos++])
                : proof[proofPos++];
            hashes[i] = _hashPair(a, b);
        }

        if (totalHashes > 0) {
            require(proofPos == proofLen, "MerkleProof: invalid multiproof");
            unchecked {
                return hashes[totalHashes - 1];
            }
        } else if (leavesLen > 0) {
            return leaves[0];
        } else {
            return proof[0];
        }
    }

    function _hashPair(bytes32 a, bytes32 b) private pure returns (bytes32) {
        return a < b ? _efficientHash(a, b) : _efficientHash(b, a);
    }

    function _efficientHash(bytes32 a, bytes32 b) private pure returns (bytes32 value) {
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0x00, a)
            mstore(0x20, b)
            value := keccak256(0x00, 0x40)
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

/**
 * @dev Interface of the Polling Contract for OnChain Voting System.
 */
interface PollingInterface {
    /**
     * @dev Emitted when a poll is created, along with created poll id.
     */
    event PollCreated(uint256 pollId);

    /**
     * @dev Emitted when a poll is created, along with created poll id.
     */
    event PollsCreated(uint256[] pollId);

    /**
     * @dev Emitted when the polls is ended, along with ended poll ids.
     */
    event PollEnded(uint256[] pollIds);

    /**
     * @dev Emitted when the poll fee is updated, along with updated poll fee.
     */
    event PollFeesUpdated(uint256 fees);

    /**
     * @dev Emitted when the TOKN contract is updated, along with updated TOKN contract address.
     */
    event ToknContractUpdated(address toknContract);

    event ClaimTransferSuccessful(uint256[] pollIds);

    /**
     * @dev Creates a new poll with the specified parameters.
     * @dev Only owner can call this function.
     * @param pollId The unique identifier of the poll.
     * @param pollTitle The title of the poll.
     * @param pollDescription The description of the poll.
     * @param pollChoices An array of choices for the poll.
     * @param pollCreator The address of the poll creator.
     * @param startDate The start date of the poll.
     * @param endDate The end date of the poll.
     */
    function createPoll(
        uint256 pollId,
        string memory pollTitle,
        string memory pollDescription,
        string[] calldata pollChoices,
        address pollCreator,
        uint256 startDate,
        uint256 endDate
    ) external;

    /**
     * @dev Creates a new poll with the specified parameters.
     * @dev Only owner can call this function.
     * @param pollId The unique identifier of the poll.
     * @param pollTitle The title of the poll.
     * @param pollDescription The description of the poll.
     * @param pollChoices An array of choices for the poll.
     * @param pollCreator The address of the poll creator.
     * @param startDate The start date of the poll.
     * @param endDate The end date of the poll.
     */
    function createPolls(
        uint256[] calldata pollId,
        string[] memory pollTitle,
        string[] memory pollDescription,
        string[][] calldata pollChoices,
        address[] calldata pollCreator,
        uint256[] calldata startDate,
        uint256[] calldata endDate
    ) external;

    /**
     * @dev Ends the specified polls by providing the necessary information.
     * @dev Only owner can call this function.
     * @param pollingIds An array of poll IDs to be ended.
     * @param winningMerkle An array of winning Merkle roots for each poll.
     * @param results An array of content IDs associated with the winning Merkle roots.
     * @param winningChoice An array of choices winning choice for each poll.
     */
    function endPolls(
        uint256[] calldata pollingIds,
        bytes32[] calldata winningMerkle,
        string[] calldata results,
        string[] calldata winningChoice
    ) external;

    // /**
    //  * @dev Allows a user to claim their reward if user choice is won.
    //  * @param amount The amount of reward to be claimed.
    //  * @param merkleProof Merkle proof for verifying winning user and amount.
    //  * @param pollId The poll id for which the reward is being claimed.
    //  */
    // function claimReward(
    //     uint256 amount,
    //     bytes32[] calldata merkleProof,
    //     uint256 pollId
    // ) external;

    /**
     * @dev Allows a user to claim multiple reward if user choice is won.
     * @param amount An array of rewared amount to be claimed.
     * @param merkleProofs An array of Merkle proof for verifying winning user and amount.
     * @param pollIds An array of poll ids for which the reward is being claimed.
     */
    function claimAllRewards(
        uint256[] calldata amount,
        bytes32[][] calldata merkleProofs,
        uint256[] calldata pollIds
    ) external;

    /**
     * @dev Updates the poll fees with the specified amount.
     * @dev Only owner can call this function.
     * @param fees The new amount of fees for creation of a poll.
     */
    function updatePollFees(uint256 fees) external;

    /**
     * @dev Updates the TOKN contract address with the specified address.
     * @dev Only owner can call this function.
     * @param toknContractAddress The new address of the TOKN contract.
     */
    function updateToknContract(address toknContractAddress) external;

    /**
     * @dev Retrieves the address of the TOKN contract.
     * @return The address of the TOKN contract.
     */
    function getTOKNAddress() external returns (address);

    /**
     * @dev Retrieves the poll fees.
     * @return The poll fees.
     */
    function getPollFees() external view returns (uint256);

    /**
     * @dev Pauses the contract, preventing certain functions from being executed.
     * @dev Only owner can call this function.
     */
    function pause() external;

    /**
     * @dev Unpauses the contract, allowing the execution of all functions.
     * @dev Only owner can call this function.
     */
    function unpause() external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

/**
 * @title Polling Contract for OnChain Voting System
 * @author The Tech Alchemy Team
 * @notice You can use this contract for creation and ending of a poll, user can claim their poll rewards
 * @dev All function calls are currently implemented without side effects
 */

import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

import "./interface/PollingInterface.sol";

contract Polling is PollingInterface, Pausable, Ownable, ReentrancyGuard {
    /**
     *  @dev Zero Address
     */
    address internal constant ZERO_ADDRESS = address(0);

    /**
     * @dev Zero Bytes
     */
    bytes32 internal constant ZERO_BYTES_32 = bytes32(0);

    /**
     * @dev User pay this poll fee for creating polls
     */
    uint256 internal pollFees;

    /**
     * @dev TOKN contract address
     */
    IERC20 internal toknContract;

    /**
     * @dev Struct containing details about a poll.
     */
    struct PollingDetail {
        string title;
        string description;
        string[] choices;
        string winningChoice;
        bool isPollEnded;
        bytes32 winnerMerkle;
        string result;
        address creator;
        uint256 startDate;
        uint256 endDate;
    }

    /**
     * @dev mapping to store polling details
     */
    mapping(uint256 => PollingDetail) public pollingDetails;

    /**
     * @dev Keep track of claimed user based on polling id
     */
    mapping(uint256 => mapping(address => bool)) public isPollRewardClaimed;

    /**
     * @dev The constructor sets the owner of the contract at the time of deployment
     * @param feesForPoll - Fees for the poll creation, User pays this fee at the time of poll creation.
     * @param toknContractAddress - Address of the TOKN contract used for paying the poll fees and reward transfer.
     */
    constructor(uint256 feesForPoll, address toknContractAddress) {
        require(feesForPoll > 0, "Polling: Fees should be greater than zero");
        require(
            toknContractAddress != ZERO_ADDRESS,
            "Polling: Invalid address"
        );
        pollFees = feesForPoll;
        toknContract = IERC20(toknContractAddress);
    }

    /**
     * @dev Creates a new poll with the specified parameters.
     * @dev Only owner can call this function.
     * @param pollId The unique identifier of the poll.
     * @param pollTitle The title of the poll.
     * @param pollDescription The description of the poll.
     * @param pollChoices An array of choices for the poll.
     * @param pollCreator The address of the poll creator.
     * @param startDate The start date of the poll.
     * @param endDate The end date of the poll.
     */
    function createPoll(
        uint256 pollId,
        string memory pollTitle,
        string memory pollDescription,
        string[] calldata pollChoices,
        address pollCreator,
        uint256 startDate,
        uint256 endDate
    ) external override onlyOwner whenNotPaused nonReentrant {
        require(pollId > 0, "Polling: Invalid poll id");
        require(bytes(pollTitle).length > 0, "Polling: Empty poll title");
        require(pollChoices.length > 0, "Polling: No choices provided");
        require(pollCreator != ZERO_ADDRESS, "Polling: Invalid creator");
        require(startDate != 0, "Polling: Invalid start date");
        require(endDate != 0, "Polling: Invalid end date");
        require(
            startDate < endDate,
            "Polling: The start date must be less than the end date."
        );
        require(
            pollingDetails[pollId].startDate == 0,
            "Polling: Polling id already exists"
        );

        pollingDetails[pollId] = PollingDetail({
            title: pollTitle,
            description: pollDescription,
            choices: pollChoices,
            winningChoice: "",
            winnerMerkle: "",
            result: "",
            creator: pollCreator,
            startDate: startDate,
            endDate: endDate,
            isPollEnded: false
        });
        emit PollCreated(pollId);
    }

    /**
     * @dev Creates a new poll with the specified parameters.
     * @dev Only owner can call this function.
     * @param pollingIds The unique identifier of the poll.
     * @param pollTitle The title of the poll.
     * @param pollDescription The description of the poll.
     * @param pollChoices An array of choices for the poll.
     * @param pollCreator The address of the poll creator.
     * @param startDate The start date of the poll.
     * @param endDate The end date of the poll.
     */
    function createPolls(
        uint256[] calldata pollingIds,
        string[] memory pollTitle,
        string[] memory pollDescription,
        string[][] calldata pollChoices,
        address[] calldata pollCreator,
        uint256[] calldata startDate,
        uint256[] calldata endDate
    ) external override onlyOwner whenNotPaused nonReentrant {
        require(
            pollingIds.length == pollTitle.length &&
                pollingIds.length == pollDescription.length &&
                pollingIds.length == pollChoices.length &&
                pollingIds.length == pollCreator.length &&
                pollingIds.length == startDate.length &&
                pollingIds.length == endDate.length,
            "Polling: length does not match"
        );

        require(
            pollingIds.length > 0,
            "Polling: Poll ids length should be greater than zero"
        );

        uint256[] memory successPollIds = new uint256[](pollingIds.length);
        uint256 successIndex = 0;

        for (uint8 index = 0; index < pollingIds.length; index++) {
            uint256 pollId = pollingIds[index];
            if (
                pollId > 0 &&
                bytes(pollTitle[index]).length > 0 &&
                pollChoices[index].length > 0 &&
                pollCreator[index] != ZERO_ADDRESS &&
                startDate[index] != 0 &&
                endDate[index] != 0 &&
                startDate[index] < endDate[index] &&
                pollingDetails[pollId].startDate == 0
            ) {
                pollingDetails[pollId] = PollingDetail({
                    title: pollTitle[index],
                    description: pollDescription[index],
                    choices: pollChoices[index],
                    winningChoice: "",
                    winnerMerkle: "",
                    result: "",
                    creator: pollCreator[index],
                    startDate: startDate[index],
                    endDate: endDate[index],
                    isPollEnded: false
                });

                successPollIds[successIndex] = pollId;
                successIndex += 1;
            }
        }

        emit PollsCreated(successPollIds);
    }

    /**
     * @dev Ends the specified polls by providing the necessary information.
     * @dev Only owner can call this function.
     * @param pollingIds An array of poll IDs to be ended.
     * @param winningMerkle An array of winning Merkle roots for each poll.
     * @param results An array of result urls associated with the winning Merkle roots.
     * @param winningChoice An array of winning choice IDs for each poll.
     */
    function endPolls(
        uint256[] calldata pollingIds,
        bytes32[] calldata winningMerkle,
        string[] calldata results,
        string[] calldata winningChoice
    ) external override onlyOwner whenNotPaused nonReentrant {
        require(
            pollingIds.length == winningMerkle.length,
            "Polling: Poll ids length not match with winningMerkle"
        );
        require(
            pollingIds.length == results.length,
            "Polling: Poll ids length not match with results"
        );
        require(
            pollingIds.length == winningChoice.length,
            "Polling: Poll ids length not match with winningChoice"
        );
        require(
            pollingIds.length > 0,
            "Polling: Poll ids length should be greater than zero"
        );

        uint256[] memory successPollIds = new uint256[](pollingIds.length);
        uint256 successIndex = 0;

        for (uint8 index = 0; index < pollingIds.length; index++) {
            if (
                pollingDetails[pollingIds[index]].startDate != 0 &&
                winningMerkle[index] != ZERO_BYTES_32 &&
                bytes(results[index]).length != 0 &&
                bytes(winningChoice[index]).length > 0 &&
                block.timestamp >= pollingDetails[pollingIds[index]].endDate
            ) {
                PollingDetail storage updatePoll = pollingDetails[
                    pollingIds[index]
                ];
                updatePoll.result = results[index];
                updatePoll.winnerMerkle = winningMerkle[index];
                updatePoll.winningChoice = winningChoice[index];
                updatePoll.isPollEnded = true;

                successPollIds[successIndex] = pollingIds[index];
                successIndex += 1;
            }
        }

        emit PollEnded(successPollIds);
    }

    // /**
    //  * @dev Allows a user to claim their reward if user choice is won.
    //  * @param amount The amount of reward to be claimed.
    //  * @param merkleProof Merkle proof for verifying winning user and amount.
    //  * @param pollId The poll id for which the reward is being claimed.
    //  */
    // function claimReward(
    //     uint256 amount,
    //     bytes32[] calldata merkleProof,
    //     uint256 pollId
    // ) external override whenNotPaused nonReentrant {
    //     require(
    //         block.timestamp >= pollingDetails[pollId].endDate,
    //         "Polling: The poll is not ended"
    //     );
    //     require(
    //         toknContract.balanceOf(address(this)) >= amount,
    //         "Polling: Insufficient balance in contract"
    //     );
    //     require(merkleProof.length > 0, "Polling: Empty merkleProof");
    //     require(pollId > 0, "Polling: Invalid id");
    //     require(
    //         !isPollRewardClaimed[pollId][msg.sender],
    //         "Polling: Already claimed"
    //     );
    //     bytes32 encodedLeaf = keccak256(abi.encode(msg.sender, amount));
    //     require(
    //         MerkleProof.verify(
    //             merkleProof,
    //             pollingDetails[pollId].winnerMerkle,
    //             encodedLeaf
    //         ),
    //         "Polling: Invalid proof"
    //     );
    //     isPollRewardClaimed[pollId][msg.sender] = true;
    //     bool status = toknContract.transferFrom(
    //         address(this),
    //         msg.sender,
    //         amount
    //     );
    //     require(status, "Polling: Transfer failed");
    // }

    /**
     * @dev Allows a user to claim multiple reward if user choice is won.
     * @param amount An array of rewared amount to be claimed.
     * @param merkleProofs An array of Merkle proof for verifying winning user and amount.
     * @param pollIds An array of poll ids for which the reward is being claimed.
     */
    function claimAllRewards(
        uint256[] calldata amount,
        bytes32[][] calldata merkleProofs,
        uint256[] calldata pollIds
    ) external override whenNotPaused nonReentrant {
        require(
            amount.length == merkleProofs.length,
            "Polling: Merkle proof length doesn't match with amount"
        );
        require(
            amount.length == pollIds.length,
            "Polling: Poll id length doesn't match with amount"
        );
        require(amount.length > 0, "Polling: Empty amount");

        uint256 balanceOfContract = toknContract.balanceOf(address(this));
        uint256[] memory successPollIds = new uint256[](pollIds.length);
        uint256 successIndex = 0;
        for (uint256 index = 0; index < amount.length; index++) {
            uint256 claimAmount = amount[index];
            uint256 claimPollId = pollIds[index];
            if (
                claimPollId > 0 &&
                !isPollRewardClaimed[claimPollId][msg.sender] &&
                balanceOfContract >= claimAmount &&
                pollingDetails[claimPollId].isPollEnded
            ) {
                bytes32 encodedLeaf = keccak256(
                    abi.encode(msg.sender, claimAmount)
                );
                bool isValid = MerkleProof.verify(
                    merkleProofs[index],
                    pollingDetails[claimPollId].winnerMerkle,
                    encodedLeaf
                );
                if (isValid) {
                    isPollRewardClaimed[claimPollId][msg.sender] = true;
                    bool status = toknContract.transferFrom(
                        address(this),
                        msg.sender,
                        claimAmount
                    );
                    if (status) {
                        balanceOfContract -= claimAmount;
                        successPollIds[successIndex] = claimPollId;
                        successIndex++;
                    }
                }
            }
        }
        emit ClaimTransferSuccessful(successPollIds);
    }

    /**
     * @dev Updates the poll fees with the specified amount.
     * @dev Only owner can call this function.
     * @param feesForPoll The new amount of fees for creation of a poll.
     */
    function updatePollFees(
        uint256 feesForPoll
    ) external override onlyOwner whenNotPaused {
        require(feesForPoll > 0, "Polling: Fees should be greater than zero");
        require(
            feesForPoll != pollFees,
            "Polling: Fees shouldn't be same as previous"
        );
        pollFees = feesForPoll;
        emit PollFeesUpdated(pollFees);
    }

    /**
     * @dev Updates the TOKN contract address with the specified address.
     * @dev Only owner can call this function.
     * @param toknContractAddress The new address of the TOKN contract.
     */
    function updateToknContract(
        address toknContractAddress
    ) external override onlyOwner whenNotPaused {
        require(
            toknContractAddress != ZERO_ADDRESS,
            "Polling: Invalid address"
        );
        require(
            toknContractAddress != address(toknContract),
            "Polling: Same as pervious address"
        );
        toknContract = IERC20(toknContractAddress);
        emit ToknContractUpdated(toknContractAddress);
    }

    /**
     * @dev Retrieves the poll fees.
     * @return The poll fees.
     */
    function getPollFees() external view override returns (uint256) {
        return pollFees;
    }

    /**
     * @dev Retrieves the address of the TOKN contract.
     * @return The address of the TOKN contract.
     */
    function getTOKNAddress() external view override returns (address) {
        return address(toknContract);
    }

    /**
     * @dev Pauses the contract, preventing certain functions from being executed.
     * @dev Only owner can call this function.
     */
    function pause() external override onlyOwner {
        _pause();
    }

    /**
     * @dev Unpauses the contract, allowing the execution of all functions.
     * @dev Only owner can call this function.
     */
    function unpause() external override onlyOwner {
        _unpause();
    }
}