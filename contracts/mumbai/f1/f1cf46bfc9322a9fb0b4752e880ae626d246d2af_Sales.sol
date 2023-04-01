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
// OpenZeppelin Contracts (last updated v4.8.0) (security/ReentrancyGuard.sol)

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
pragma solidity 0.8.18;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

abstract contract IEditions {
    struct Edition {
        bool frozenMetadata;
        uint256 maxSupply;
        string uri;
    }

    function editionExists(uint256 __id) external view virtual returns (bool);

    function mint(
        address __account,
        uint256 __id,
        uint256 __amount
    ) external virtual;

    function maxSupply(uint __id) external virtual returns (uint256);
}

contract Sales is Ownable, ReentrancyGuard {
    error AmountExceedsTransactionLimit();
    error AmountExceedsWalletLimit();
    error EditionNotFound();
    error HasEnded();
    error HasNotStarted();
    error HasStarted();
    error IncorrectPrice();
    error InvalidProof();
    error InvalidStart();
    error InvalidTimeframe();
    error LimitGreaterThanSupply();
    error MerkleRootNotSet();
    error ProofIsRequired();
    error SaleNotFound();
    error WithdrawFailed();

    event SaleCreated(uint256 __tokenID, uint256 __saleID);
    event SalePriceUpdated(
        uint256 __tokenID,
        uint256 __saleID,
        uint256 __price
    );
    event SaleStartUpdated(
        uint256 __tokenID,
        uint256 __saleID,
        uint256 __start
    );
    event SaleEndUpdated(uint256 __tokenID, uint256 __saleID, uint256 __end);
    event SaleWalletLimitUpdated(
        uint256 __tokenID,
        uint256 __saleID,
        uint256 __walletLimit
    );
    event SaleMerkleRootUpdated(
        uint256 __tokenID,
        uint256 __saleID,
        bytes32 __merkleRoot
    );

    struct Sale {
        uint256 price;
        uint256 start;
        uint256 end;
        uint256 walletLimit;
        bytes32 merkleRoot;
    }

    IEditions private _editionsContract;

    uint256 public transactionLimit = 100;

    // Mapping of sales
    mapping(uint256 => Sale[]) private _sales;

    // Mapping of wallet sales
    mapping(uint256 => mapping(uint256 => mapping(address => uint256)))
        private _walletSales;

    /**
     * @dev Sets editions contract using contract address upon construction.
     */
    constructor(address __editionsContractAddress) {
        _editionsContract = IEditions(__editionsContractAddress);
    }

    ////////////////////////////////////////////////////////////////////////////
    // MODIFIERS
    ////////////////////////////////////////////////////////////////////////////

    /**
     * @dev Checks if sale exists.
     *
     * Requirements:
     *
     * - `__id` must be of existing edition.
     */
    modifier onlyExistingSale(uint256 __tokenID, uint256 __saleID) {
        if (__saleID >= _sales[__tokenID].length) {
            revert SaleNotFound();
        }
        _;
    }

    ////////////////////////////////////////////////////////////////////////////
    // INTERNALS
    ////////////////////////////////////////////////////////////////////////////

    /**
     * @dev Used to complete purchase.
     *
     * Requirements:
     *
     * - `__tokenID` must be of existing edition.
     * - `__saleID` must be of existing sale.
     * - `__amount` plus current wallet sales cannot exceed wallet limit.
     * - `msg.value` must be correct price of sale.
     * - `block.timestampe` must be within sale timeframe.
     */
    function _buy(
        uint256 __tokenID,
        uint256 __saleID,
        uint256 __amount
    ) internal {
        Sale memory sale = _sales[__tokenID][__saleID];

        if (__amount > transactionLimit) revert AmountExceedsTransactionLimit();

        if (sale.walletLimit != 0) {
            if (
                _walletSales[__tokenID][__saleID][_msgSender()] + __amount >
                sale.walletLimit
            ) revert AmountExceedsWalletLimit();
        }

        if (sale.price * __amount != msg.value) {
            revert IncorrectPrice();
        }

        if (sale.start > 0 && block.timestamp < sale.start) {
            revert HasNotStarted();
        }

        if (sale.end > 0 && block.timestamp > sale.end) {
            revert HasEnded();
        }

        _walletSales[__tokenID][__saleID][_msgSender()] =
            _walletSales[__tokenID][__saleID][_msgSender()] +
            __amount;

        _editionsContract.mint(_msgSender(), __tokenID, __amount);
    }

    /**
     * @dev Used to verify merkle proof.
     *
     * Requirements:
     *
     * - Sale's `merkleRoot` must be set.
     */
    function _verifyProof(
        address __sender,
        uint256 __tokenID,
        uint256 __saleID,
        bytes32[] calldata __proof
    ) internal view {
        if (_sales[__tokenID][__saleID].merkleRoot == 0x0)
            revert MerkleRootNotSet();

        bool verified = MerkleProof.verify(
            __proof,
            _sales[__tokenID][__saleID].merkleRoot,
            keccak256(abi.encodePacked(__sender))
        );

        if (!verified) revert InvalidProof();
    }

    ////////////////////////////////////////////////////////////////////////////
    // ADMIN
    ////////////////////////////////////////////////////////////////////////////

    /**
     * @dev Used to create a new sale.
     *
     * Requirements:
     *
     * - `__tokenID` must be of existing edition.
     * - `__start` must be later than current time.
     * - `__start` must be earlier than `__end`.
     * - `__walletLimit` must be less or equal to max supply of edition.
     *
     * Emits a {SaleCreated} event.
     *
     */
    function createSale(
        uint256 __tokenID,
        uint256 __price,
        uint256 __start,
        uint256 __end,
        uint256 __walletLimit,
        bytes32 __merkleRoot
    ) external onlyOwner {
        if (!_editionsContract.editionExists(__tokenID)) {
            revert EditionNotFound();
        }

        if (__start > 0 && block.timestamp > __start) revert InvalidStart();

        if (__end > 0 && __start > __end) revert InvalidTimeframe();

        if (
            _editionsContract.maxSupply(__tokenID) > 0 &&
            __walletLimit > _editionsContract.maxSupply(__tokenID)
        ) revert LimitGreaterThanSupply();

        _sales[__tokenID].push(
            Sale({
                price: __price,
                start: __start,
                end: __end,
                walletLimit: __walletLimit,
                merkleRoot: __merkleRoot
            })
        );

        emit SaleCreated(__tokenID, _sales[__tokenID].length - 1);
    }

    ////////////////////////////////////////////////////////////////////////////
    // OWNER
    ////////////////////////////////////////////////////////////////////////////

    /**
     * @dev Used to update the merkle root of a sale.
     *
     * Emits a {SaleMerkleRootUpdated} event.
     *
     */
    function editMerkleRoot(
        uint256 __tokenID,
        uint256 __saleID,
        bytes32 __merkleRoot
    ) external onlyOwner onlyExistingSale(__tokenID, __saleID) {
        _sales[__tokenID][__saleID].merkleRoot = __merkleRoot;

        emit SaleMerkleRootUpdated(__tokenID, __saleID, __merkleRoot);
    }

    /**
     * @dev Used to update the price of a sale.
     *
     * Emits a {SalePriceUpdated} event.
     *
     */
    function editPrice(
        uint256 __tokenID,
        uint256 __saleID,
        uint256 __price
    ) external onlyOwner onlyExistingSale(__tokenID, __saleID) {
        _sales[__tokenID][__saleID].price = __price;

        emit SalePriceUpdated(__tokenID, __saleID, __price);
    }

    /**
     * @dev Used to update the start/end timeframe of a sale.
     *
     * Requirements:
     *
     * - Sale must not have already started.
     * - `__start` must be later than current time.
     * - `__start` must be earlier than sale end.
     *
     * Emits a {SaleStartUpdated} event.
     *
     */
    function editStart(
        uint256 __tokenID,
        uint256 __saleID,
        uint256 __start
    ) external onlyOwner onlyExistingSale(__tokenID, __saleID) {
        if (block.timestamp >= _sales[__tokenID][__saleID].start)
            revert HasStarted();

        if (__start > 0 && block.timestamp > __start) revert InvalidStart();

        if (
            _sales[__tokenID][__saleID].end > 0 &&
            __start > _sales[__tokenID][__saleID].end
        ) revert InvalidTimeframe();

        _sales[__tokenID][__saleID].start = __start;

        emit SaleStartUpdated(__tokenID, __saleID, __start);
    }

    /**
     * @dev Used to update the start/end timeframe of a sale.
     *
     * Requirements:
     *
     * - Sale must not have already ended.
     * - `__end` must be later than sale start.
     *
     * Emits a {SaleEndUpdated} event.
     *
     */
    function editEnd(
        uint256 __tokenID,
        uint256 __saleID,
        uint256 __end
    ) external onlyOwner onlyExistingSale(__tokenID, __saleID) {
        if (
            _sales[__tokenID][__saleID].end > 0 &&
            block.timestamp >= _sales[__tokenID][__saleID].end
        ) revert HasEnded();

        if (__end > 0 && _sales[__tokenID][__saleID].start > __end)
            revert InvalidTimeframe();

        _sales[__tokenID][__saleID].end = __end;

        emit SaleEndUpdated(__tokenID, __saleID, __end);
    }

    /**
     * @dev Used to update the wallet limit of a sale.
     *
     * Requirements:
     *
     * - `__walletLimit` must be less or equal to max supply of edition.
     *
     * Emits a {SaleWalletLimitUpdated} event.
     *
     */
    function editWalletLimit(
        uint256 __tokenID,
        uint256 __saleID,
        uint256 __walletLimit
    ) external onlyOwner onlyExistingSale(__tokenID, __saleID) {
        if (
            _editionsContract.maxSupply(__tokenID) > 0 &&
            __walletLimit > _editionsContract.maxSupply(__tokenID)
        ) revert LimitGreaterThanSupply();

        _sales[__tokenID][__saleID].walletLimit = __walletLimit;

        emit SaleWalletLimitUpdated(__tokenID, __saleID, __walletLimit);
    }

    /**
     * @dev Used to end a sale immediately.
     *
     * Requirements:
     *
     * - Sale must not have already ended.
     *
     * Emits a {SaleEndUpdated} event.
     *
     */
    function endSale(
        uint256 __tokenID,
        uint256 __saleID
    ) external onlyOwner onlyExistingSale(__tokenID, __saleID) {
        if (
            _sales[__tokenID][__saleID].end > 0 &&
            block.timestamp >= _sales[__tokenID][__saleID].end
        ) revert HasEnded();

        _sales[__tokenID][__saleID].end = block.timestamp;

        emit SaleEndUpdated(__tokenID, __saleID, block.timestamp);
    }

    /**
     * @dev Used to withdraw funds from the contract.
     */
    function setTransactionLimit(
        uint256 __transactionLimit
    ) external onlyOwner {
        transactionLimit = __transactionLimit;
    }

    /**
     * @dev Used to withdraw funds from the contract.
     */
    function withdraw(uint256 amount) external onlyOwner {
        (bool success, ) = owner().call{value: amount}("");

        if (!success) revert WithdrawFailed();
    }

    /**
     * @dev Used to withdraw all funds from the contract.
     */
    function withdrawAll() external onlyOwner {
        (bool success, ) = owner().call{value: address(this).balance}("");

        if (!success) revert WithdrawFailed();
    }

    ////////////////////////////////////////////////////////////////////////////
    // WRITES
    ////////////////////////////////////////////////////////////////////////////

    /**
     * @dev Buys an edition.
     */
    function buy(
        uint256 __tokenID,
        uint256 __saleID,
        uint256 __amount
    ) external payable nonReentrant onlyExistingSale(__tokenID, __saleID) {
        if (_sales[__tokenID][__saleID].merkleRoot != 0x0)
            revert ProofIsRequired();

        _buy(__tokenID, __saleID, __amount);
    }

    /**
     * @dev Buys an edition with a merkle proof.
     */
    function buyWithProof(
        uint256 __tokenID,
        uint256 __saleID,
        uint256 __amount,
        bytes32[] calldata __proof
    ) external payable nonReentrant onlyExistingSale(__tokenID, __saleID) {
        _verifyProof(_msgSender(), __tokenID, __saleID, __proof);

        _buy(__tokenID, __saleID, __amount);
    }

    ////////////////////////////////////////////////////////////////////////////
    // READS
    ////////////////////////////////////////////////////////////////////////////

    /**
     * @dev Returns an edition sale.
     */
    function getSale(
        uint256 __tokenID,
        uint256 __saleID
    )
        external
        view
        onlyExistingSale(__tokenID, __saleID)
        returns (Sale memory)
    {
        return _sales[__tokenID][__saleID];
    }

    /**
     * @dev Returns number of wallet sales per edition.
     */
    function getWalletSales(
        address __account,
        uint256 __tokenID,
        uint256 __saleID
    ) external view onlyExistingSale(__tokenID, __saleID) returns (uint256) {
        return _walletSales[__tokenID][__saleID][__account];
    }

    /**
     * @dev Returns number of sales per edition.
     */
    function totalSales(uint256 __tokenID) external view returns (uint256) {
        return _sales[__tokenID].length;
    }
}