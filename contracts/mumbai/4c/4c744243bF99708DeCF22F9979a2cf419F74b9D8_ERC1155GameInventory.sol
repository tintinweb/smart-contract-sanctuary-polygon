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
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC1155.sol)

pragma solidity ^0.8.0;

import "../token/ERC1155/IERC1155.sol";

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC1155/IERC1155.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155 is IERC165 {
    /**
     * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    /**
     * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
     * transfers.
     */
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

    /**
     * @dev Emitted when `account` grants or revokes permission to `operator` to transfer their tokens, according to
     * `approved`.
     */
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    /**
     * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.
     *
     * If an {URI} event was emitted for `id`, the standard
     * https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[guarantees] that `value` will equal the value
     * returned by {IERC1155MetadataURI-uri}.
     */
    event URI(string value, uint256 indexed id);

    /**
     * @dev Returns the amount of tokens of token type `id` owned by `account`.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) external view returns (uint256);

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);

    /**
     * @dev Grants or revokes permission to `operator` to transfer the caller's tokens, according to `approved`,
     *
     * Emits an {ApprovalForAll} event.
     *
     * Requirements:
     *
     * - `operator` cannot be the caller.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns true if `operator` is approved to transfer ``account``'s tokens.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address account, address operator) external view returns (bool);

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;
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
// OpenZeppelin Contracts (last updated v4.8.0) (utils/cryptography/MerkleProof.sol)

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
    function verify(
        bytes32[] memory proof,
        bytes32 root,
        bytes32 leaf
    ) internal pure returns (bool) {
        return processProof(proof, leaf) == root;
    }

    /**
     * @dev Calldata version of {verify}
     *
     * _Available since v4.7._
     */
    function verifyCalldata(
        bytes32[] calldata proof,
        bytes32 root,
        bytes32 leaf
    ) internal pure returns (bool) {
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
        // This function rebuild the root hash by traversing the tree up from the leaves. The root is rebuilt by
        // consuming and producing values on a queue. The queue starts with the `leaves` array, then goes onto the
        // `hashes` array. At the end of the process, the last hash in the `hashes` array should contain the root of
        // the merkle tree.
        uint256 leavesLen = leaves.length;
        uint256 totalHashes = proofFlags.length;

        // Check proof validity.
        require(leavesLen + proof.length - 1 == totalHashes, "MerkleProof: invalid multiproof");

        // The xxxPos values are "pointers" to the next value to consume in each array. All accesses are done using
        // `xxx[xxxPos++]`, which return the current value and increment the pointer, thus mimicking a queue's "pop".
        bytes32[] memory hashes = new bytes32[](totalHashes);
        uint256 leafPos = 0;
        uint256 hashPos = 0;
        uint256 proofPos = 0;
        // At each step, we compute the next hash using two values:
        // - a value from the "main queue". If not all leaves have been consumed, we get the next leaf, otherwise we
        //   get the next hash.
        // - depending on the flag, either another value for the "main queue" (merging branches) or an element from the
        //   `proof` array.
        for (uint256 i = 0; i < totalHashes; i++) {
            bytes32 a = leafPos < leavesLen ? leaves[leafPos++] : hashes[hashPos++];
            bytes32 b = proofFlags[i] ? leafPos < leavesLen ? leaves[leafPos++] : hashes[hashPos++] : proof[proofPos++];
            hashes[i] = _hashPair(a, b);
        }

        if (totalHashes > 0) {
            return hashes[totalHashes - 1];
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
        // This function rebuild the root hash by traversing the tree up from the leaves. The root is rebuilt by
        // consuming and producing values on a queue. The queue starts with the `leaves` array, then goes onto the
        // `hashes` array. At the end of the process, the last hash in the `hashes` array should contain the root of
        // the merkle tree.
        uint256 leavesLen = leaves.length;
        uint256 totalHashes = proofFlags.length;

        // Check proof validity.
        require(leavesLen + proof.length - 1 == totalHashes, "MerkleProof: invalid multiproof");

        // The xxxPos values are "pointers" to the next value to consume in each array. All accesses are done using
        // `xxx[xxxPos++]`, which return the current value and increment the pointer, thus mimicking a queue's "pop".
        bytes32[] memory hashes = new bytes32[](totalHashes);
        uint256 leafPos = 0;
        uint256 hashPos = 0;
        uint256 proofPos = 0;
        // At each step, we compute the next hash using two values:
        // - a value from the "main queue". If not all leaves have been consumed, we get the next leaf, otherwise we
        //   get the next hash.
        // - depending on the flag, either another value for the "main queue" (merging branches) or an element from the
        //   `proof` array.
        for (uint256 i = 0; i < totalHashes; i++) {
            bytes32 a = leafPos < leavesLen ? leaves[leafPos++] : hashes[hashPos++];
            bytes32 b = proofFlags[i] ? leafPos < leavesLen ? leaves[leafPos++] : hashes[hashPos++] : proof[proofPos++];
            hashes[i] = _hashPair(a, b);
        }

        if (totalHashes > 0) {
            return hashes[totalHashes - 1];
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
// OpenZeppelin Contracts (last updated v4.8.0) (utils/introspection/ERC165Checker.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Library used to query support of an interface declared via {IERC165}.
 *
 * Note that these functions return the actual result of the query: they do not
 * `revert` if an interface is not supported. It is up to the caller to decide
 * what to do in these cases.
 */
library ERC165Checker {
    // As per the EIP-165 spec, no interface should ever match 0xffffffff
    bytes4 private constant _INTERFACE_ID_INVALID = 0xffffffff;

    /**
     * @dev Returns true if `account` supports the {IERC165} interface.
     */
    function supportsERC165(address account) internal view returns (bool) {
        // Any contract that implements ERC165 must explicitly indicate support of
        // InterfaceId_ERC165 and explicitly indicate non-support of InterfaceId_Invalid
        return
            supportsERC165InterfaceUnchecked(account, type(IERC165).interfaceId) &&
            !supportsERC165InterfaceUnchecked(account, _INTERFACE_ID_INVALID);
    }

    /**
     * @dev Returns true if `account` supports the interface defined by
     * `interfaceId`. Support for {IERC165} itself is queried automatically.
     *
     * See {IERC165-supportsInterface}.
     */
    function supportsInterface(address account, bytes4 interfaceId) internal view returns (bool) {
        // query support of both ERC165 as per the spec and support of _interfaceId
        return supportsERC165(account) && supportsERC165InterfaceUnchecked(account, interfaceId);
    }

    /**
     * @dev Returns a boolean array where each value corresponds to the
     * interfaces passed in and whether they're supported or not. This allows
     * you to batch check interfaces for a contract where your expectation
     * is that some interfaces may not be supported.
     *
     * See {IERC165-supportsInterface}.
     *
     * _Available since v3.4._
     */
    function getSupportedInterfaces(address account, bytes4[] memory interfaceIds)
        internal
        view
        returns (bool[] memory)
    {
        // an array of booleans corresponding to interfaceIds and whether they're supported or not
        bool[] memory interfaceIdsSupported = new bool[](interfaceIds.length);

        // query support of ERC165 itself
        if (supportsERC165(account)) {
            // query support of each interface in interfaceIds
            for (uint256 i = 0; i < interfaceIds.length; i++) {
                interfaceIdsSupported[i] = supportsERC165InterfaceUnchecked(account, interfaceIds[i]);
            }
        }

        return interfaceIdsSupported;
    }

    /**
     * @dev Returns true if `account` supports all the interfaces defined in
     * `interfaceIds`. Support for {IERC165} itself is queried automatically.
     *
     * Batch-querying can lead to gas savings by skipping repeated checks for
     * {IERC165} support.
     *
     * See {IERC165-supportsInterface}.
     */
    function supportsAllInterfaces(address account, bytes4[] memory interfaceIds) internal view returns (bool) {
        // query support of ERC165 itself
        if (!supportsERC165(account)) {
            return false;
        }

        // query support of each interface in interfaceIds
        for (uint256 i = 0; i < interfaceIds.length; i++) {
            if (!supportsERC165InterfaceUnchecked(account, interfaceIds[i])) {
                return false;
            }
        }

        // all interfaces supported
        return true;
    }

    /**
     * @notice Query if a contract implements an interface, does not check ERC165 support
     * @param account The address of the contract to query for support of an interface
     * @param interfaceId The interface identifier, as specified in ERC-165
     * @return true if the contract at account indicates support of the interface with
     * identifier interfaceId, false otherwise
     * @dev Assumes that account contains a contract that supports ERC165, otherwise
     * the behavior of this method is undefined. This precondition can be checked
     * with {supportsERC165}.
     * Interface identification is specified in ERC-165.
     */
    function supportsERC165InterfaceUnchecked(address account, bytes4 interfaceId) internal view returns (bool) {
        // prepare call
        bytes memory encodedParams = abi.encodeWithSelector(IERC165.supportsInterface.selector, interfaceId);

        // perform static call
        bool success;
        uint256 returnSize;
        uint256 returnValue;
        assembly {
            success := staticcall(30000, account, add(encodedParams, 0x20), mload(encodedParams), 0x00, 0x20)
            returnSize := returndatasize()
            returnValue := mload(0x00)
        }

        return success && returnSize >= 0x20 && returnValue > 0;
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
pragma solidity 0.8.12;
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165Checker.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import {GameItem, IERC1155GameItem} from "./interfaces/IERC1155GameItem.sol";
import "../interfaces/IManagers.sol";



contract ERC1155GameInventory is Ownable {
    using ERC165Checker for address;
    struct ClaimData {
        string playfabId;
        string playfabTxId;
        address player;
        uint256[] tokenIds;
        uint256[] amounts;
    }
    struct LeafData {
        string playfabId;
        string playfabTxId;
        uint256[] tokenIds;
        uint256[] amounts;
        bytes32[] merkleProof;
    }
    struct AllocationRecord {
        bytes32 merkleRootHash;
        uint256 startTime;
        uint256 endTime;
    }

    struct ClaimRecord {
        uint256[] tokenIds;
        uint256[] amounts;
        uint256 time;
    }
    struct TxDefinition {
        uint256[] tokenIds;
        uint256[] amounts;
    }
    AllocationRecord[] public withdrawDefinitions;
    uint256 public periodCount;
    uint256 public interval = 15 minutes;
    uint256 public distributionOffset = 5 minutes;

    IERC1155GameItem public itemsContract;
    IManagers public managers;

    // mapping(address => mapping(uint256 => uint256)) public playerItemsInInventory;
    mapping(address => mapping(string => TxDefinition)) private playerDeposits; //player=>playfabTxId=>TxDefinition
    mapping(string => bool) public completedTransactions;
    mapping(uint256 => mapping(address => ClaimRecord)) public claimRecords;
    mapping(address => mapping(string => uint256)) public test;
    mapping(address => mapping(string => TxDefinition)) private userClaimDefinitionForItem; //player=>playfabTxId=>TxDefinition

    mapping(uint256 => ClaimData[]) claimedPlayersForPeriods;

    address public authorizedAddress;
    address payable treasury;

    error StartTimeMustBeInTheFuture();
    error InvalidMerkleRootHash();
    error ClaimPeridNotStarted();
    error ThereIsActivePeriod();
    error ClaimPeriodEnded();
    error UsedPlayfabTxId();
    error NoActivePeriod();
    error AlreadyClaimed();
    error NotAuthorized();
    error NoAllocation();
    error AlreadySet();

    event CreateClaim(uint256 period, bytes32 merkleRootHash, uint256 startTime, uint256 endTime);
    event ClaimItems(address indexed player, string playfabId, uint256[] tokenIds, uint256[] amounts);
    event ChangeTreasuryAddress(address manager, address newAddress, bool approved);
	event AddItemsToGameInventory(address player, string playfabTxId, uint256[] tokenIds, uint256[] amounts);
	event SetClaimDefinition(address player, string playfabTxId, uint256[] tokenIds, uint256[] amounts);


    constructor(IManagers _managers, address _authorizedAddress, address payable _treasury) {
        managers = _managers;
        authorizedAddress = _authorizedAddress;
        treasury = _treasury;
    }

    modifier onlyManager() {
        if (!managers.isManager(msg.sender)) {
            revert NotAuthorized();
        }
        _;
    }

    modifier onlyAuthorizedAddress() {
        if (msg.sender != authorizedAddress) {
            revert NotAuthorized();
        }
        _;
    }

    function setItemsContract(IERC1155GameItem _itemsContract) external onlyOwner {
        if (address(itemsContract) != address(0)) {
            revert AlreadySet();
        }
        itemsContract = _itemsContract;
    }

    function setAuthorizedAddress(address _newAddress) external onlyManager {
        authorizedAddress = _newAddress;
        itemsContract.setAuthorizedAddress(_newAddress);
    }

    function setTreasury(address payable _newAddress) external onlyManager {
        string memory _title = "Set Treasury Address";
        bytes memory _encodedValues = abi.encode(_newAddress);
        managers.approveTopic(_title, _encodedValues);
        bool _isApproved = managers.isApproved(_title, _encodedValues);
        if (_isApproved) {
            treasury = _newAddress;
            itemsContract.setTreasury(_newAddress);
            managers.deleteTopic(_title);
        }
        emit ChangeTreasuryAddress(msg.sender, _newAddress, _isApproved);
    }

    function isLastPeriodEnded() public view returns (bool) {
        if (periodCount == 0) return true;
        uint256 _currentPeriod = periodCount - 1;
        AllocationRecord memory _currentPeriodRecord = withdrawDefinitions[_currentPeriod];
        return block.timestamp > _currentPeriodRecord.endTime;
    }

    function createWithdrawDefinition(
        uint256 _startTime,
        bytes32 _merkleRootHash,
        address _nextAuthorizedAddress
    ) external onlyAuthorizedAddress {
        if (_merkleRootHash.length == 0) {
            revert InvalidMerkleRootHash();
        }
        if (_startTime <= block.timestamp) {
            revert StartTimeMustBeInTheFuture();
        }
        if (!isLastPeriodEnded()) {
            revert ThereIsActivePeriod();
        }

        uint256 _endTime = _startTime + interval - distributionOffset;

        withdrawDefinitions.push(
            AllocationRecord({merkleRootHash: _merkleRootHash, startTime: _startTime, endTime: _endTime})
        );
        authorizedAddress = _nextAuthorizedAddress;
        periodCount++;
        emit CreateClaim(periodCount, _merkleRootHash, _startTime, _endTime);
    }

    function claimItems(LeafData calldata _leafData) external {
        if (periodCount == 0) {
            revert NoActivePeriod();
        }
        uint256 _currentPeriod = periodCount - 1;
        AllocationRecord storage _currentPeriodRecord = withdrawDefinitions[_currentPeriod];

        if (block.timestamp < _currentPeriodRecord.startTime) {
            revert ClaimPeridNotStarted();
        }
        if (block.timestamp > _currentPeriodRecord.endTime) {
            revert ClaimPeriodEnded();
        }
        if (claimRecords[_currentPeriod][msg.sender].time != 0) {
            revert AlreadyClaimed();
        }

        if (completedTransactions[_leafData.playfabTxId]) {
            revert UsedPlayfabTxId();
        }

        bytes32 _leaf = keccak256(
            abi.encodePacked(
                msg.sender,
                _currentPeriod,
                _leafData.tokenIds,
                _leafData.amounts,
                _leafData.playfabId,
                _leafData.playfabTxId
            )
        );
        if (!MerkleProof.verifyCalldata(_leafData.merkleProof, _currentPeriodRecord.merkleRootHash, _leaf)) {
            revert NoAllocation();
        }

        completedTransactions[_leafData.playfabTxId] = true;

        claimRecords[_currentPeriod][msg.sender].amounts = _leafData.amounts;
        claimRecords[_currentPeriod][msg.sender].tokenIds = _leafData.tokenIds;
        claimRecords[_currentPeriod][msg.sender].time = block.timestamp;

        claimedPlayersForPeriods[_currentPeriod].push(
            ClaimData({
                playfabId: _leafData.playfabId,
                playfabTxId: _leafData.playfabTxId,
                player: msg.sender,
                tokenIds: _leafData.tokenIds,
                amounts: _leafData.amounts
            })
        );

        itemsContract.transferToPlayer(msg.sender, _leafData.tokenIds, _leafData.amounts);

        emit ClaimItems(msg.sender, _leafData.playfabId, _leafData.tokenIds, _leafData.amounts);
    }


    //Tested
    function addItemsToGameInventory(
        uint256[] calldata _tokenIds,
        uint256[] calldata _amounts,
        string memory _playfabTxId
    ) external {
        if (completedTransactions[_playfabTxId]) {
            revert UsedPlayfabTxId();
        }
        completedTransactions[_playfabTxId] = true;
        itemsContract.transferToGame(msg.sender, _tokenIds, _amounts);
        playerDeposits[msg.sender][_playfabTxId] = TxDefinition({tokenIds: _tokenIds, amounts: _amounts});
		emit AddItemsToGameInventory(msg.sender, _playfabTxId, _tokenIds, _amounts);
    }

    //Tested
    function getPlayerDepositData(
        address _player,
        string calldata _playfabTxId
    ) external view returns (TxDefinition memory) {
        return playerDeposits[_player][_playfabTxId];
    }


    //Tested
    function setClaimDefinition(
        address _player,
        uint256[] calldata _tokenIds,
        uint256[] calldata _amounts,
        string calldata _playfabTxId
    ) external onlyAuthorizedAddress {
        if (completedTransactions[_playfabTxId]) {
            revert UsedPlayfabTxId();
        }
        userClaimDefinitionForItem[_player][_playfabTxId] = TxDefinition({tokenIds: _tokenIds, amounts: _amounts});
		emit SetClaimDefinition(_player, _playfabTxId, _tokenIds, _amounts);
    }

    //Tested
    function claim(string calldata _playfabTxId) external {
        if (userClaimDefinitionForItem[msg.sender][_playfabTxId].amounts.length == 0) {
            revert NoAllocation();
        }
        if (completedTransactions[_playfabTxId]) {
            revert AlreadyClaimed();
        }
        if (completedTransactions[_playfabTxId]) {
            revert UsedPlayfabTxId();
        }
        completedTransactions[_playfabTxId] = true;

        for (uint256 i = 0; i < userClaimDefinitionForItem[msg.sender][_playfabTxId].amounts.length; i++) {
            itemsContract.claimForPlayer(
                msg.sender,
                userClaimDefinitionForItem[msg.sender][_playfabTxId].tokenIds[i],
                userClaimDefinitionForItem[msg.sender][_playfabTxId].amounts[i]
            );
        }
        emit ClaimItems(
            msg.sender,
            _playfabTxId,
            userClaimDefinitionForItem[msg.sender][_playfabTxId].tokenIds,
            userClaimDefinitionForItem[msg.sender][_playfabTxId].amounts
        );
    }

    //Read Functions
    function getPlayerClaimDefinition(
        address _player,
        string calldata _playfabTxId
    ) public view returns (TxDefinition memory) {
        return userClaimDefinitionForItem[_player][_playfabTxId];
    }

    //Tested
    function withdraw() external payable onlyManager {
        itemsContract.withdraw();
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.12;

import "@openzeppelin/contracts/interfaces/IERC1155.sol";
struct GameItem {
    uint256 id;
    string name;
    string uri;
    uint256 totalSupply;
    uint256 maxSupply;
    uint256 mintCost;
    bool inUse;
}

interface IERC1155GameItem is IERC1155 {
    function itemCount() external view returns (uint256);

    function createNewItem(string calldata _name, string calldata _uri, uint256 _maxSupply, uint256 _mintCost) external;

    function removeItem(uint256 _tokenId) external;

    function getItemList() external view returns (GameItem[] memory _returnData);

    function setAuthorizedAddress(address _newAddress) external;

    function setTreasury(address payable _newAddress) external;

    function transferToGame(address _from, uint256[] calldata _tokenIds, uint256[] calldata _amounts) external;

    function transferToPlayer(address _to, uint256[] calldata _tokenIds, uint256[] calldata _amounts) external;

    function claimForPlayer(address _player, uint256 _tokenId, uint256 _amount) external;

    function withdraw() external payable;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.12;

import "@openzeppelin/contracts/access/Ownable.sol";

interface IManagers {
    function isManager(address _address) external view returns (bool);

    function approveTopic(string memory _title, bytes memory _encodedValues) external;

    function cancelTopicApproval(string memory _title) external;

    function deleteTopic(string memory _title) external;

    function isApproved(string memory _title, bytes memory _value) external view returns (bool);

    function changeManager1(address _newAddress) external;

    function changeManager2(address _newAddress) external;

    function changeManager3(address _newAddress) external;

    function changeManager4(address _newAddress) external;

    function changeManager5(address _newAddress) external;

    function isTrustedSource(address _address) external view returns (bool);

    function addAddressToTrustedSources(address _address, string memory _name) external;
}