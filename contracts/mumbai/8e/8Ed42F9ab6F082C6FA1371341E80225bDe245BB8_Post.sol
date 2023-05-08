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

//SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

/// @title Semaphore contract interface.
interface ISemaphore {
    error Semaphore__CallerIsNotTheGroupAdmin();
    error Semaphore__MerkleTreeDepthIsNotSupported();
    error Semaphore__MerkleTreeRootIsExpired();
    error Semaphore__MerkleTreeRootIsNotPartOfTheGroup();
    error Semaphore__YouAreUsingTheSameNillifierTwice();

    /// It defines all the group parameters, in addition to those in the Merkle tree.
    struct Group {
        address admin;
        uint256 merkleTreeDuration;
        mapping(uint256 => uint256) merkleRootCreationDates;
        mapping(uint256 => bool) nullifierHashes;
    }

    /// @dev Emitted when an admin is assigned to a group.
    /// @param groupId: Id of the group.
    /// @param oldAdmin: Old admin of the group.
    /// @param newAdmin: New admin of the group.
    event GroupAdminUpdated(uint256 indexed groupId, address indexed oldAdmin, address indexed newAdmin);

    /// @dev Emitted when the Merkle tree duration of a group is updated.
    /// @param groupId: Id of the group.
    /// @param oldMerkleTreeDuration: Old Merkle tree duration of the group.
    /// @param newMerkleTreeDuration: New Merkle tree duration of the group.
    event GroupMerkleTreeDurationUpdated(
        uint256 indexed groupId,
        uint256 oldMerkleTreeDuration,
        uint256 newMerkleTreeDuration
    );

    /// @dev Emitted when a Semaphore proof is verified.
    /// @param groupId: Id of the group.
    /// @param merkleTreeRoot: Root of the Merkle tree.
    /// @param nullifierHash: Nullifier hash.
    /// @param externalNullifier: External nullifier.
    /// @param signal: Semaphore signal.
    event ProofVerified(
        uint256 indexed groupId,
        uint256 indexed merkleTreeRoot,
        uint256 nullifierHash,
        uint256 indexed externalNullifier,
        uint256 signal
    );

    /// @dev Saves the nullifier hash to avoid double signaling and emits an event
    /// if the zero-knowledge proof is valid.
    /// @param groupId: Id of the group.
    /// @param merkleTreeRoot: Root of the Merkle tree.
    /// @param signal: Semaphore signal.
    /// @param nullifierHash: Nullifier hash.
    /// @param externalNullifier: External nullifier.
    /// @param proof: Zero-knowledge proof.
    function verifyProof(
        uint256 groupId,
        uint256 merkleTreeRoot,
        uint256 signal,
        uint256 nullifierHash,
        uint256 externalNullifier,
        uint256[8] calldata proof
    ) external;

    /// @dev Creates a new group. Only the admin will be able to add or remove members.
    /// @param groupId: Id of the group.
    /// @param depth: Depth of the tree.
    /// @param admin: Admin of the group.
    function createGroup(uint256 groupId, uint256 depth, address admin) external;

    /// @dev Creates a new group. Only the admin will be able to add or remove members.
    /// @param groupId: Id of the group.
    /// @param depth: Depth of the tree.
    /// @param admin: Admin of the group.
    /// @param merkleTreeRootDuration: Time before the validity of a root expires.
    function createGroup(uint256 groupId, uint256 depth, address admin, uint256 merkleTreeRootDuration) external;

    /// @dev Updates the group admin.
    /// @param groupId: Id of the group.
    /// @param newAdmin: New admin of the group.
    function updateGroupAdmin(uint256 groupId, address newAdmin) external;

    /// @dev Updates the group Merkle tree duration.
    /// @param groupId: Id of the group.
    /// @param newMerkleTreeDuration: New Merkle tree duration.
    function updateGroupMerkleTreeDuration(uint256 groupId, uint256 newMerkleTreeDuration) external;

    /// @dev Adds a new member to an existing group.
    /// @param groupId: Id of the group.
    /// @param identityCommitment: New identity commitment.
    function addMember(uint256 groupId, uint256 identityCommitment) external;

    /// @dev Adds new members to an existing group.
    /// @param groupId: Id of the group.
    /// @param identityCommitments: New identity commitments.
    function addMembers(uint256 groupId, uint256[] calldata identityCommitments) external;

    /// @dev Updates an identity commitment of an existing group. A proof of membership is
    /// needed to check if the node to be updated is part of the tree.
    /// @param groupId: Id of the group.
    /// @param identityCommitment: Existing identity commitment to be updated.
    /// @param newIdentityCommitment: New identity commitment.
    /// @param proofSiblings: Array of the sibling nodes of the proof of membership.
    /// @param proofPathIndices: Path of the proof of membership.
    function updateMember(
        uint256 groupId,
        uint256 identityCommitment,
        uint256 newIdentityCommitment,
        uint256[] calldata proofSiblings,
        uint8[] calldata proofPathIndices
    ) external;

    /// @dev Removes a member from an existing group. A proof of membership is
    /// needed to check if the node to be removed is part of the tree.
    /// @param groupId: Id of the group.
    /// @param identityCommitment: Identity commitment to be removed.
    /// @param proofSiblings: Array of the sibling nodes of the proof of membership.
    /// @param proofPathIndices: Path of the proof of membership.
    function removeMember(
        uint256 groupId,
        uint256 identityCommitment,
        uint256[] calldata proofSiblings,
        uint8[] calldata proofPathIndices
    ) external;
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@semaphore-protocol/contracts/interfaces/ISemaphore.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Post is Ownable {
  ISemaphore public semaphore;
  uint256 public groupId;
  uint public minCommitmentAge;
  uint public maxCommitmentAge;
  mapping(bytes32 => uint) public commitments;
  mapping(bytes32 => string) public postIdToArweaveTxs;

  event Committed(bytes32 commitment);
  event PostSent(bytes32 indexed postId, string indexed arweaveId);

  constructor(address semaphoreAddress, uint256 _groupId, uint _minCommitmentAge, uint _maxCommitmentAge) Ownable() {
    require(_maxCommitmentAge > _minCommitmentAge);
    minCommitmentAge = _minCommitmentAge;
    maxCommitmentAge = _maxCommitmentAge;

    semaphore = ISemaphore(semaphoreAddress);
    groupId = _groupId;

    semaphore.createGroup(groupId, 20, address(this));
  }

  function joinGroup(uint256 identityCommitment) external onlyOwner {
    semaphore.addMember(groupId, identityCommitment);
  }

  function _makeCommitment(bytes32 postId, string memory arweaveId) internal pure returns (bytes32) {
    bytes32 postIdBytes = keccak256(abi.encode(postId));
    bytes32 arweaveIdBytes = keccak256(bytes(arweaveId));
    return keccak256(abi.encode(postIdBytes, arweaveIdBytes));
  }

  function commit(bytes32 commitment) external {
    // if commitments[commitment] is within maxCommitmentAge, don't allow commit (to avoid overwriting other's commitment)
    require(commitments[commitment] + maxCommitmentAge < block.timestamp);
    commitments[commitment] = block.timestamp;
    emit Committed(commitment);
  }

  function _consumeCommitment(bytes32 commitment) internal {
    // Require a valid commitment that wait at least minCommitmentAge
    require(commitments[commitment] + minCommitmentAge <= block.timestamp);

    // If the commitment is too old, stop
    require(commitments[commitment] + maxCommitmentAge > block.timestamp);

    delete (commitments[commitment]);
  }

  // to allow user post multi times, externalNullifier is postId
  function sendPost(
    uint256 signal,
    uint256 merkleTreeRoot,
    uint256 nullifierHash,
    uint256 externalNullifier,
    uint256[8] calldata proof,
    bytes32 postId,
    string memory arweaveId
  ) external {
    // ensure the post commitment is submitted and valid
    bytes32 commitment = _makeCommitment(postId, arweaveId);
    _consumeCommitment(commitment);

    // check if the proof's signal is the post id
    require(postId == bytes32(signal));

    // ensure the postIdToArweaveTxs[postId] is not yet stored
    require(keccak256(bytes(postIdToArweaveTxs[postId])) == keccak256(bytes("")));

    postIdToArweaveTxs[postId] = arweaveId;

    semaphore.verifyProof(groupId, merkleTreeRoot, signal, nullifierHash, externalNullifier, proof);

    require(keccak256(bytes(postIdToArweaveTxs[postId])) == keccak256(bytes(arweaveId)));

    emit PostSent(postId, arweaveId);
  }
}