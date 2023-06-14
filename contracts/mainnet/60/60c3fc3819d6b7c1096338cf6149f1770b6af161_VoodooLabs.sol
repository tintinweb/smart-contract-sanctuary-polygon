/**
 *Submitted for verification at polygonscan.com on 2023-06-14
*/

// File: @openzeppelin/contracts/utils/structs/EnumerableSet.sol


// OpenZeppelin Contracts (last updated v4.9.0) (utils/structs/EnumerableSet.sol)
// This file was procedurally generated from scripts/generate/templates/EnumerableSet.js.

pragma solidity ^0.8.0;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```solidity
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 *
 * [WARNING]
 * ====
 * Trying to delete such a structure from storage will likely result in data corruption, rendering the structure
 * unusable.
 * See https://github.com/ethereum/solidity/pull/11843[ethereum/solidity#11843] for more info.
 *
 * In order to clean an EnumerableSet, you can either remove all elements one by one or create a fresh instance using an
 * array of EnumerableSet.
 * ====
 */
library EnumerableSet {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;
        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping(bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) {
            // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            if (lastIndex != toDeleteIndex) {
                bytes32 lastValue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastValue;
                // Update the index for the moved value
                set._indexes[lastValue] = valueIndex; // Replace lastValue's index to valueIndex
            }

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        return set._values[index];
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function _values(Set storage set) private view returns (bytes32[] memory) {
        return set._values;
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(Bytes32Set storage set) internal view returns (bytes32[] memory) {
        bytes32[] memory store = _values(set._inner);
        bytes32[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(AddressSet storage set) internal view returns (address[] memory) {
        bytes32[] memory store = _values(set._inner);
        address[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }

    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(UintSet storage set) internal view returns (uint256[] memory) {
        bytes32[] memory store = _values(set._inner);
        uint256[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }
}

// File: contracts/IOperatorFilterRegistry.sol


pragma solidity ^0.8.13;


interface IOperatorFilterRegistry {
    function isOperatorAllowed(address registrant, address operator) external returns (bool);
    function register(address registrant) external;
    function registerAndSubscribe(address registrant, address subscription) external;
    function registerAndCopyEntries(address registrant, address registrantToCopy) external;
    function updateOperator(address registrant, address operator, bool filtered) external;
    function updateOperators(address registrant, address[] calldata operators, bool filtered) external;
    function updateCodeHash(address registrant, bytes32 codehash, bool filtered) external;
    function updateCodeHashes(address registrant, bytes32[] calldata codeHashes, bool filtered) external;
    function subscribe(address registrant, address registrantToSubscribe) external;
    function unsubscribe(address registrant, bool copyExistingEntries) external;
    function subscriptionOf(address addr) external returns (address registrant);
    function subscribers(address registrant) external returns (address[] memory);
    function subscriberAt(address registrant, uint256 index) external returns (address);
    function copyEntriesOf(address registrant, address registrantToCopy) external;
    function isOperatorFiltered(address registrant, address operator) external returns (bool);
    function isCodeHashOfFiltered(address registrant, address operatorWithCode) external returns (bool);
    function isCodeHashFiltered(address registrant, bytes32 codeHash) external returns (bool);
    function filteredOperators(address addr) external returns (address[] memory);
    function filteredCodeHashes(address addr) external returns (bytes32[] memory);
    function filteredOperatorAt(address registrant, uint256 index) external returns (address);
    function filteredCodeHashAt(address registrant, uint256 index) external returns (bytes32);
    function isRegistered(address addr) external returns (bool);
    function codeHashOf(address addr) external returns (bytes32);
}

// File: contracts/OperatorFilterer.sol


pragma solidity ^0.8.13;


contract OperatorFilterer {
    error OperatorNotAllowed(address operator);

    IOperatorFilterRegistry constant operatorFilterRegistry =
        IOperatorFilterRegistry(0x000000000000AAeB6D7670E522A718067333cd4E);

    constructor(address subscriptionOrRegistrantToCopy, bool subscribe) {
        // If an inheriting token contract is deployed to a network without the registry deployed, the modifier
        // will not revert, but the contract will need to be registered with the registry once it is deployed in
        // order for the modifier to filter addresses.
        if (address(operatorFilterRegistry).code.length > 0) {
            if (subscribe) {
                operatorFilterRegistry.registerAndSubscribe(address(this), subscriptionOrRegistrantToCopy);
            } else {
                if (subscriptionOrRegistrantToCopy != address(0)) {
                    operatorFilterRegistry.registerAndCopyEntries(address(this), subscriptionOrRegistrantToCopy);
                } else {
                    operatorFilterRegistry.register(address(this));
                }
            }
        }
    }

    modifier onlyAllowedOperator() virtual {
        // Check registry code length to facilitate testing in environments without a deployed registry.
        if (address(operatorFilterRegistry).code.length > 0) {
            if (!operatorFilterRegistry.isOperatorAllowed(address(this), msg.sender)) {
                revert OperatorNotAllowed(msg.sender);
            }
        }
        _;
    }
}

// File: contracts/DefaultOperatorFilterer.sol


pragma solidity ^0.8.13;


contract DefaultOperatorFilterer is OperatorFilterer {
    address constant DEFAULT_SUBSCRIPTION = address(0x3cc6CddA760b79bAfa08dF41ECFA224f810dCeB6);

    constructor() OperatorFilterer(DEFAULT_SUBSCRIPTION, true) {}
}

// File: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/cryptography/MerkleProof.sol


// OpenZeppelin Contracts (last updated v4.9.0) (utils/cryptography/MerkleProof.sol)

pragma solidity ^0.8.19;

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
     *@dev The multiproof provided is not valid.
     */
    error MerkleProofInvalidMultiproof();

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
        uint256 totalHashes = proofFlags.length;

        // Check proof validity.
        if (leavesLen + proof.length - 1 != totalHashes) {
            revert MerkleProofInvalidMultiproof();
        }

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
        uint256 totalHashes = proofFlags.length;

        // Check proof validity.
        if (leavesLen + proof.length - 1 != totalHashes) {
            revert MerkleProofInvalidMultiproof();
        }

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

// File: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/math/SignedMath.sol


// OpenZeppelin Contracts (last updated v4.8.0) (utils/math/SignedMath.sol)

pragma solidity ^0.8.19;

/**
 * @dev Standard signed math utilities missing in the Solidity language.
 */
library SignedMath {
    /**
     * @dev Returns the largest of two signed numbers.
     */
    function max(int256 a, int256 b) internal pure returns (int256) {
        return a > b ? a : b;
    }

    /**
     * @dev Returns the smallest of two signed numbers.
     */
    function min(int256 a, int256 b) internal pure returns (int256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two signed numbers without overflow.
     * The result is rounded towards zero.
     */
    function average(int256 a, int256 b) internal pure returns (int256) {
        // Formula from the book "Hacker's Delight"
        int256 x = (a & b) + ((a ^ b) >> 1);
        return x + (int256(uint256(x) >> 255) & (a ^ b));
    }

    /**
     * @dev Returns the absolute unsigned value of a signed value.
     */
    function abs(int256 n) internal pure returns (uint256) {
        unchecked {
            // must be unchecked in order to support `n = type(int256).min`
            return uint256(n >= 0 ? n : -n);
        }
    }
}

// File: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/math/Math.sol


// OpenZeppelin Contracts (last updated v4.9.0) (utils/math/Math.sol)

pragma solidity ^0.8.19;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    /**
     * @dev Muldiv operation overflow.
     */
    error MathOverflowedMulDiv();

    enum Rounding {
        Down, // Toward negative infinity
        Up, // Toward infinity
        Zero // Toward zero
    }

    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v5.0._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v5.0._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v5.0._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v5.0._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v5.0._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a > b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a == 0 ? 0 : (a - 1) / b + 1;
    }

    /**
     * @notice Calculates floor(x * y / denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
     * @dev Original credit to Remco Bloemen under MIT license (https://xn--2-umb.com/21/muldiv)
     * with further edits by Uniswap Labs also under MIT license.
     */
    function mulDiv(uint256 x, uint256 y, uint256 denominator) internal pure returns (uint256 result) {
        unchecked {
            // 512-bit multiply [prod1 prod0] = x * y. Compute the product mod 2^256 and mod 2^256 - 1, then use
            // use the Chinese Remainder Theorem to reconstruct the 512 bit result. The result is stored in two 256
            // variables such that product = prod1 * 2^256 + prod0.
            uint256 prod0; // Least significant 256 bits of the product
            uint256 prod1; // Most significant 256 bits of the product
            assembly {
                let mm := mulmod(x, y, not(0))
                prod0 := mul(x, y)
                prod1 := sub(sub(mm, prod0), lt(mm, prod0))
            }

            // Handle non-overflow cases, 256 by 256 division.
            if (prod1 == 0) {
                // Solidity will revert if denominator == 0, unlike the div opcode on its own.
                // The surrounding unchecked block does not change this fact.
                // See https://docs.soliditylang.org/en/latest/control-structures.html#checked-or-unchecked-arithmetic.
                return prod0 / denominator;
            }

            // Make sure the result is less than 2^256. Also prevents denominator == 0.
            if (denominator <= prod1) {
                revert MathOverflowedMulDiv();
            }

            ///////////////////////////////////////////////
            // 512 by 256 division.
            ///////////////////////////////////////////////

            // Make division exact by subtracting the remainder from [prod1 prod0].
            uint256 remainder;
            assembly {
                // Compute remainder using mulmod.
                remainder := mulmod(x, y, denominator)

                // Subtract 256 bit number from 512 bit number.
                prod1 := sub(prod1, gt(remainder, prod0))
                prod0 := sub(prod0, remainder)
            }

            // Factor powers of two out of denominator and compute largest power of two divisor of denominator. Always >= 1.
            // See https://cs.stackexchange.com/q/138556/92363.

            // Does not overflow because the denominator cannot be zero at this stage in the function.
            uint256 twos = denominator & (~denominator + 1);
            assembly {
                // Divide denominator by twos.
                denominator := div(denominator, twos)

                // Divide [prod1 prod0] by twos.
                prod0 := div(prod0, twos)

                // Flip twos such that it is 2^256 / twos. If twos is zero, then it becomes one.
                twos := add(div(sub(0, twos), twos), 1)
            }

            // Shift in bits from prod1 into prod0.
            prod0 |= prod1 * twos;

            // Invert denominator mod 2^256. Now that denominator is an odd number, it has an inverse modulo 2^256 such
            // that denominator * inv = 1 mod 2^256. Compute the inverse by starting with a seed that is correct for
            // four bits. That is, denominator * inv = 1 mod 2^4.
            uint256 inverse = (3 * denominator) ^ 2;

            // Use the Newton-Raphson iteration to improve the precision. Thanks to Hensel's lifting lemma, this also works
            // in modular arithmetic, doubling the correct bits in each step.
            inverse *= 2 - denominator * inverse; // inverse mod 2^8
            inverse *= 2 - denominator * inverse; // inverse mod 2^16
            inverse *= 2 - denominator * inverse; // inverse mod 2^32
            inverse *= 2 - denominator * inverse; // inverse mod 2^64
            inverse *= 2 - denominator * inverse; // inverse mod 2^128
            inverse *= 2 - denominator * inverse; // inverse mod 2^256

            // Because the division is now exact we can divide by multiplying with the modular inverse of denominator.
            // This will give us the correct result modulo 2^256. Since the preconditions guarantee that the outcome is
            // less than 2^256, this is the final result. We don't need to compute the high bits of the result and prod1
            // is no longer required.
            result = prod0 * inverse;
            return result;
        }
    }

    /**
     * @notice Calculates x * y / denominator with full precision, following the selected rounding direction.
     */
    function mulDiv(uint256 x, uint256 y, uint256 denominator, Rounding rounding) internal pure returns (uint256) {
        uint256 result = mulDiv(x, y, denominator);
        if (rounding == Rounding.Up && mulmod(x, y, denominator) > 0) {
            result += 1;
        }
        return result;
    }

    /**
     * @dev Returns the square root of a number. If the number is not a perfect square, the value is rounded down.
     *
     * Inspired by Henry S. Warren, Jr.'s "Hacker's Delight" (Chapter 11).
     */
    function sqrt(uint256 a) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        // For our first guess, we get the biggest power of 2 which is smaller than the square root of the target.
        //
        // We know that the "msb" (most significant bit) of our target number `a` is a power of 2 such that we have
        // `msb(a) <= a < 2*msb(a)`. This value can be written `msb(a)=2**k` with `k=log2(a)`.
        //
        // This can be rewritten `2**log2(a) <= a < 2**(log2(a) + 1)`
        // → `sqrt(2**k) <= sqrt(a) < sqrt(2**(k+1))`
        // → `2**(k/2) <= sqrt(a) < 2**((k+1)/2) <= 2**(k/2 + 1)`
        //
        // Consequently, `2**(log2(a) / 2)` is a good first approximation of `sqrt(a)` with at least 1 correct bit.
        uint256 result = 1 << (log2(a) >> 1);

        // At this point `result` is an estimation with one bit of precision. We know the true value is a uint128,
        // since it is the square root of a uint256. Newton's method converges quadratically (precision doubles at
        // every iteration). We thus need at most 7 iteration to turn our partial result with one bit of precision
        // into the expected uint128 result.
        unchecked {
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            return min(result, a / result);
        }
    }

    /**
     * @notice Calculates sqrt(a), following the selected rounding direction.
     */
    function sqrt(uint256 a, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = sqrt(a);
            return result + (rounding == Rounding.Up && result * result < a ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 2, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 128;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 64;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 32;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 16;
            }
            if (value >> 8 > 0) {
                value >>= 8;
                result += 8;
            }
            if (value >> 4 > 0) {
                value >>= 4;
                result += 4;
            }
            if (value >> 2 > 0) {
                value >>= 2;
                result += 2;
            }
            if (value >> 1 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 2, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log2(value);
            return result + (rounding == Rounding.Up && 1 << result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 10, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >= 10 ** 64) {
                value /= 10 ** 64;
                result += 64;
            }
            if (value >= 10 ** 32) {
                value /= 10 ** 32;
                result += 32;
            }
            if (value >= 10 ** 16) {
                value /= 10 ** 16;
                result += 16;
            }
            if (value >= 10 ** 8) {
                value /= 10 ** 8;
                result += 8;
            }
            if (value >= 10 ** 4) {
                value /= 10 ** 4;
                result += 4;
            }
            if (value >= 10 ** 2) {
                value /= 10 ** 2;
                result += 2;
            }
            if (value >= 10 ** 1) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log10(value);
            return result + (rounding == Rounding.Up && 10 ** result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 256, rounded down, of a positive value.
     * Returns 0 if given 0.
     *
     * Adding one to the result gives the number of pairs of hex symbols needed to represent `value` as a hex string.
     */
    function log256(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 16;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 8;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 4;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 2;
            }
            if (value >> 8 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 256, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log256(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log256(value);
            return result + (rounding == Rounding.Up && 1 << (result << 3) < value ? 1 : 0);
        }
    }
}

// File: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/Strings.sol


// OpenZeppelin Contracts (last updated v4.9.0) (utils/Strings.sol)

pragma solidity ^0.8.19;



/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev The `value` string doesn't fit in the specified `length`.
     */
    error StringsInsufficientHexLength(uint256 value, uint256 length);

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        unchecked {
            uint256 length = Math.log10(value) + 1;
            string memory buffer = new string(length);
            uint256 ptr;
            /// @solidity memory-safe-assembly
            assembly {
                ptr := add(buffer, add(32, length))
            }
            while (true) {
                ptr--;
                /// @solidity memory-safe-assembly
                assembly {
                    mstore8(ptr, byte(mod(value, 10), _SYMBOLS))
                }
                value /= 10;
                if (value == 0) break;
            }
            return buffer;
        }
    }

    /**
     * @dev Converts a `int256` to its ASCII `string` decimal representation.
     */
    function toString(int256 value) internal pure returns (string memory) {
        return string(abi.encodePacked(value < 0 ? "-" : "", toString(SignedMath.abs(value))));
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        unchecked {
            return toHexString(value, Math.log256(value) + 1);
        }
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        uint256 localValue = value;
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _SYMBOLS[localValue & 0xf];
            localValue >>= 4;
        }
        if (localValue != 0) {
            revert StringsInsufficientHexLength(value, length);
        }
        return string(buffer);
    }

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
    }

    /**
     * @dev Returns true if the two strings are equal.
     */
    function equal(string memory a, string memory b) internal pure returns (bool) {
        return bytes(a).length == bytes(b).length && keccak256(bytes(a)) == keccak256(bytes(b));
    }
}

// File: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/interfaces/draft-IERC6093.sol


pragma solidity ^0.8.19;

/**
 * @dev Standard ERC20 Errors
 * Interface of the ERC6093 custom errors for ERC20 tokens
 * as defined in https://eips.ethereum.org/EIPS/eip-6093
 */
interface IERC20Errors {
    /**
     * @dev Indicates an error related to the current `balance` of a `sender`. Used in transfers.
     * @param sender Address whose tokens are being transferred.
     * @param balance Current balance for the interacting account.
     * @param needed Minimum amount required to perform a transfer.
     */
    error ERC20InsufficientBalance(address sender, uint256 balance, uint256 needed);

    /**
     * @dev Indicates a failure with the token `sender`. Used in transfers.
     * @param sender Address whose tokens are being transferred.
     */
    error ERC20InvalidSender(address sender);

    /**
     * @dev Indicates a failure with the token `receiver`. Used in transfers.
     * @param receiver Address to which tokens are being transferred.
     */
    error ERC20InvalidReceiver(address receiver);

    /**
     * @dev Indicates a failure with the `spender`’s `allowance`. Used in transfers.
     * @param spender Address that may be allowed to operate on tokens without being their owner.
     * @param allowance Amount of tokens a `spender` is allowed to operate with.
     * @param needed Minimum amount required to perform a transfer.
     */
    error ERC20InsufficientAllowance(address spender, uint256 allowance, uint256 needed);

    /**
     * @dev Indicates a failure with the `approver` of a token to be approved. Used in approvals.
     * @param approver Address initiating an approval operation.
     */
    error ERC20InvalidApprover(address approver);

    /**
     * @dev Indicates a failure with the `spender` to be approved. Used in approvals.
     * @param spender Address that may be allowed to operate on tokens without being their owner.
     */
    error ERC20InvalidSpender(address spender);
}

/**
 * @dev Standard ERC721 Errors
 * Interface of the ERC6093 custom errors for ERC721 tokens
 * as defined in https://eips.ethereum.org/EIPS/eip-6093
 */
interface IERC721Errors {
    /**
     * @dev Indicates that an address can't be an owner. For example, `address(0)` is a forbidden owner in EIP-20.
     * Used in balance queries.
     * @param owner Address of the current owner of a token.
     */
    error ERC721InvalidOwner(address owner);

    /**
     * @dev Indicates a `tokenId` whose `owner` is the zero address.
     * @param tokenId Identifier number of a token.
     */
    error ERC721NonexistentToken(uint256 tokenId);

    /**
     * @dev Indicates an error related to the ownership over a particular token. Used in transfers.
     * @param sender Address whose tokens are being transferred.
     * @param tokenId Identifier number of a token.
     * @param owner Address of the current owner of a token.
     */
    error ERC721IncorrectOwner(address sender, uint256 tokenId, address owner);

    /**
     * @dev Indicates a failure with the token `sender`. Used in transfers.
     * @param sender Address whose tokens are being transferred.
     */
    error ERC721InvalidSender(address sender);

    /**
     * @dev Indicates a failure with the token `receiver`. Used in transfers.
     * @param receiver Address to which tokens are being transferred.
     */
    error ERC721InvalidReceiver(address receiver);

    /**
     * @dev Indicates a failure with the `operator`’s approval. Used in transfers.
     * @param operator Address that may be allowed to operate on tokens without being their owner.
     * @param tokenId Identifier number of a token.
     */
    error ERC721InsufficientApproval(address operator, uint256 tokenId);

    /**
     * @dev Indicates a failure with the `approver` of a token to be approved. Used in approvals.
     * @param approver Address initiating an approval operation.
     */
    error ERC721InvalidApprover(address approver);

    /**
     * @dev Indicates a failure with the `operator` to be approved. Used in approvals.
     * @param operator Address that may be allowed to operate on tokens without being their owner.
     */
    error ERC721InvalidOperator(address operator);
}

/**
 * @dev Standard ERC1155 Errors
 * Interface of the ERC6093 custom errors for ERC1155 tokens
 * as defined in https://eips.ethereum.org/EIPS/eip-6093
 */
interface IERC1155Errors {
    /**
     * @dev Indicates an error related to the current `balance` of a `sender`. Used in transfers.
     * @param sender Address whose tokens are being transferred.
     * @param balance Current balance for the interacting account.
     * @param needed Minimum amount required to perform a transfer.
     */
    error ERC1155InsufficientBalance(address sender, uint256 balance, uint256 needed, uint256 tokenId);

    /**
     * @dev Indicates a failure with the token `sender`. Used in transfers.
     * @param sender Address whose tokens are being transferred.
     */
    error ERC1155InvalidSender(address sender);

    /**
     * @dev Indicates a failure with the token `receiver`. Used in transfers.
     * @param receiver Address to which tokens are being transferred.
     */
    error ERC1155InvalidReceiver(address receiver);

    /**
     * @dev Indicates a failure with the `operator`’s approval. Used in transfers.
     * @param operator Address that may be allowed to operate on tokens without being their owner.
     * @param owner Address of the current owner of a token.
     */
    error ERC1155InsufficientApprovalForAll(address operator, address owner);

    /**
     * @dev Indicates a failure with the `approver` of a token to be approved. Used in approvals.
     * @param approver Address initiating an approval operation.
     */
    error ERC1155InvalidApprover(address approver);

    /**
     * @dev Indicates a failure with the `operator` to be approved. Used in approvals.
     * @param operator Address that may be allowed to operate on tokens without being their owner.
     */
    error ERC1155InvalidOperator(address operator);

    /**
     * @dev Indicates an array length mismatch between ids and values in a safeBatchTransferFrom operation.
     * Used in batch transfers.
     * @param idsLength Length of the array of token identifiers
     * @param valuesLength Length of the array of token amounts
     */
    error ERC1155InvalidArrayLength(uint256 idsLength, uint256 valuesLength);
}

// File: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/Context.sol


// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.19;

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

// File: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/access/Ownable.sol


// OpenZeppelin Contracts (last updated v4.9.0) (access/Ownable.sol)

pragma solidity ^0.8.19;


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

    /**
     * @dev The caller account is not authorized to perform an operation.
     */
    error OwnableUnauthorizedAccount(address account);

    /**
     * @dev The owner is not a valid owner account. (eg. `address(0)`)
     */
    error OwnableInvalidOwner(address owner);

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor(address initialOwner) {
        _transferOwnership(initialOwner);
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
        if (owner() != _msgSender()) {
            revert OwnableUnauthorizedAccount(_msgSender());
        }
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
        if (newOwner == address(0)) {
            revert OwnableInvalidOwner(address(0));
        }
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

// File: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/introspection/IERC165.sol


// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.19;

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

// File: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/introspection/ERC165.sol


// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.19;


/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// File: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC1155/IERC1155Receiver.sol


// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC1155/IERC1155Receiver.sol)

pragma solidity ^0.8.19;


/**
 * @dev _Available since v3.1._
 */
interface IERC1155Receiver is IERC165 {
    /**
     * @dev Handles the receipt of a single ERC1155 token type. This function is
     * called at the end of a `safeTransferFrom` after the balance has been updated.
     *
     * NOTE: To accept the transfer, this must return
     * `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
     * (i.e. 0xf23a6e61, or its own function selector).
     *
     * @param operator The address which initiated the transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param id The ID of the token being transferred
     * @param value The amount of tokens being transferred
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` if transfer is allowed
     */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4);

    /**
     * @dev Handles the receipt of a multiple ERC1155 token types. This function
     * is called at the end of a `safeBatchTransferFrom` after the balances have
     * been updated.
     *
     * NOTE: To accept the transfer(s), this must return
     * `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
     * (i.e. 0xbc197c81, or its own function selector).
     *
     * @param operator The address which initiated the batch transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param ids An array containing ids of each token being transferred (order and length must match values array)
     * @param values An array containing amounts of each token being transferred (order and length must match ids array)
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` if transfer is allowed
     */
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external returns (bytes4);
}

// File: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC1155/IERC1155.sol


// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC1155/IERC1155.sol)

pragma solidity ^0.8.19;


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
    function balanceOfBatch(
        address[] calldata accounts,
        uint256[] calldata ids
    ) external view returns (uint256[] memory);

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
     * WARNING: This function can potentially allow a reentrancy attack when transferring tokens
     * to an untrusted contract, when invoking {onERC1155Received} on the receiver.
     * Ensure to follow the checks-effects-interactions pattern and consider employing
     * reentrancy guards when interacting with untrusted contracts.
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
    function safeTransferFrom(address from, address to, uint256 id, uint256 amount, bytes calldata data) external;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {safeTransferFrom}.
     *
     *
     * WARNING: This function can potentially allow a reentrancy attack when transferring tokens
     * to an untrusted contract, when invoking {onERC1155BatchReceived} on the receiver.
     * Ensure to follow the checks-effects-interactions pattern and consider employing
     * reentrancy guards when interacting with untrusted contracts.
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

// File: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC1155/extensions/IERC1155MetadataURI.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC1155/extensions/IERC1155MetadataURI.sol)

pragma solidity ^0.8.19;


/**
 * @dev Interface of the optional ERC1155MetadataExtension interface, as defined
 * in the https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155MetadataURI is IERC1155 {
    /**
     * @dev Returns the URI for token type `id`.
     *
     * If the `\{id\}` substring is present in the URI, it must be replaced by
     * clients with the actual token type ID.
     */
    function uri(uint256 id) external view returns (string memory);
}

// File: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC1155/ERC1155.sol


// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC1155/ERC1155.sol)

pragma solidity ^0.8.19;







/**
 * @dev Implementation of the basic standard multi-token.
 * See https://eips.ethereum.org/EIPS/eip-1155
 * Originally based on code by Enjin: https://github.com/enjin/erc-1155
 *
 * _Available since v3.1._
 */
contract ERC1155 is Context, ERC165, IERC1155, IERC1155MetadataURI, IERC1155Errors {
    // Mapping from token ID to account balances
    mapping(uint256 => mapping(address => uint256)) private _balances;

    // Mapping from account to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    // Used as the URI for all token types by relying on ID substitution, e.g. https://token-cdn-domain/{id}.json
    string private _uri;

    /**
     * @dev See {_setURI}.
     */
    constructor(string memory uri_) {
        _setURI(uri_);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC1155).interfaceId ||
            interfaceId == type(IERC1155MetadataURI).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC1155MetadataURI-uri}.
     *
     * This implementation returns the same URI for *all* token types. It relies
     * on the token type ID substitution mechanism
     * https://eips.ethereum.org/EIPS/eip-1155#metadata[defined in the EIP].
     *
     * Clients calling this function must replace the `\{id\}` substring with the
     * actual token type ID.
     */
    function uri(uint256) public view virtual returns (string memory) {
        return _uri;
    }

    /**
     * @dev See {IERC1155-balanceOf}.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) public view virtual returns (uint256) {
        return _balances[id][account];
    }

    /**
     * @dev See {IERC1155-balanceOfBatch}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(
        address[] memory accounts,
        uint256[] memory ids
    ) public view virtual returns (uint256[] memory) {
        if (accounts.length != ids.length) {
            revert ERC1155InvalidArrayLength(ids.length, accounts.length);
        }

        uint256[] memory batchBalances = new uint256[](accounts.length);

        for (uint256 i = 0; i < accounts.length; ++i) {
            batchBalances[i] = balanceOf(accounts[i], ids[i]);
        }

        return batchBalances;
    }

    /**
     * @dev See {IERC1155-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC1155-isApprovedForAll}.
     */
    function isApprovedForAll(address account, address operator) public view virtual returns (bool) {
        return _operatorApprovals[account][operator];
    }

    /**
     * @dev See {IERC1155-safeTransferFrom}.
     */
    function safeTransferFrom(address from, address to, uint256 id, uint256 amount, bytes memory data) public virtual {
        if (from != _msgSender() && !isApprovedForAll(from, _msgSender())) {
            revert ERC1155InsufficientApprovalForAll(_msgSender(), from);
        }
        _safeTransferFrom(from, to, id, amount, data);
    }

    /**
     * @dev See {IERC1155-safeBatchTransferFrom}.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public virtual {
        if (from != _msgSender() && !isApprovedForAll(from, _msgSender())) {
            revert ERC1155InsufficientApprovalForAll(_msgSender(), from);
        }
        _safeBatchTransferFrom(from, to, ids, amounts, data);
    }

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`. Will mint (or burn) if `from` (or `to`) is the zero address.
     *
     * Emits a {TransferSingle} event if the arrays contain one element, and {TransferBatch} otherwise.
     *
     * Requirements:
     *
     * - If `to` refers to a smart contract, it must implement either {IERC1155Receiver-onERC1155Received}
     *   or {IERC1155Receiver-onERC1155BatchReceived} and return the acceptance magic value.
     */
    function _update(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {
        if (ids.length != amounts.length) {
            revert ERC1155InvalidArrayLength(ids.length, amounts.length);
        }

        address operator = _msgSender();

        for (uint256 i = 0; i < ids.length; ++i) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];

            if (from != address(0)) {
                uint256 fromBalance = _balances[id][from];
                if (fromBalance < amount) {
                    revert ERC1155InsufficientBalance(from, fromBalance, amount, id);
                }
                unchecked {
                    _balances[id][from] = fromBalance - amount;
                }
            }

            if (to != address(0)) {
                _balances[id][to] += amount;
            }
        }

        if (ids.length == 1) {
            uint256 id = ids[0];
            uint256 amount = amounts[0];
            emit TransferSingle(operator, from, to, id, amount);
            if (to != address(0)) {
                _doSafeTransferAcceptanceCheck(operator, from, to, id, amount, data);
            }
        } else {
            emit TransferBatch(operator, from, to, ids, amounts);
            if (to != address(0)) {
                _doSafeBatchTransferAcceptanceCheck(operator, from, to, ids, amounts, data);
            }
        }
    }

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function _safeTransferFrom(address from, address to, uint256 id, uint256 amount, bytes memory data) internal {
        if (to == address(0)) {
            revert ERC1155InvalidReceiver(address(0));
        }
        if (from == address(0)) {
            revert ERC1155InvalidSender(address(0));
        }
        (uint256[] memory ids, uint256[] memory amounts) = _asSingletonArrays(id, amount);
        _update(from, to, ids, amounts, data);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function _safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal {
        if (to == address(0)) {
            revert ERC1155InvalidReceiver(address(0));
        }
        if (from == address(0)) {
            revert ERC1155InvalidSender(address(0));
        }
        _update(from, to, ids, amounts, data);
    }

    /**
     * @dev Sets a new URI for all token types, by relying on the token type ID
     * substitution mechanism
     * https://eips.ethereum.org/EIPS/eip-1155#metadata[defined in the EIP].
     *
     * By this mechanism, any occurrence of the `\{id\}` substring in either the
     * URI or any of the amounts in the JSON file at said URI will be replaced by
     * clients with the token type ID.
     *
     * For example, the `https://token-cdn-domain/\{id\}.json` URI would be
     * interpreted by clients as
     * `https://token-cdn-domain/000000000000000000000000000000000000000000000000000000000004cce0.json`
     * for token type ID 0x4cce0.
     *
     * See {uri}.
     *
     * Because these URIs cannot be meaningfully represented by the {URI} event,
     * this function emits no events.
     */
    function _setURI(string memory newuri) internal virtual {
        _uri = newuri;
    }

    /**
     * @dev Creates `amount` tokens of token type `id`, and assigns them to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function _mint(address to, uint256 id, uint256 amount, bytes memory data) internal {
        if (to == address(0)) {
            revert ERC1155InvalidReceiver(address(0));
        }
        (uint256[] memory ids, uint256[] memory amounts) = _asSingletonArrays(id, amount);
        _update(address(0), to, ids, amounts, data);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_mint}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function _mintBatch(address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data) internal {
        if (to == address(0)) {
            revert ERC1155InvalidReceiver(address(0));
        }
        _update(address(0), to, ids, amounts, data);
    }

    /**
     * @dev Destroys `amount` tokens of token type `id` from `from`
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `from` must have at least `amount` tokens of token type `id`.
     */
    function _burn(address from, uint256 id, uint256 amount) internal {
        if (from == address(0)) {
            revert ERC1155InvalidSender(address(0));
        }
        (uint256[] memory ids, uint256[] memory amounts) = _asSingletonArrays(id, amount);
        _update(from, address(0), ids, amounts, "");
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_burn}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     */
    function _burnBatch(address from, uint256[] memory ids, uint256[] memory amounts) internal {
        if (from == address(0)) {
            revert ERC1155InvalidSender(address(0));
        }
        _update(from, address(0), ids, amounts, "");
    }

    /**
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Emits an {ApprovalForAll} event.
     */
    function _setApprovalForAll(address owner, address operator, bool approved) internal virtual {
        if (owner == operator) {
            revert ERC1155InvalidOperator(operator);
        }
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    function _doSafeTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) private {
        if (to.code.length > 0) {
            try IERC1155Receiver(to).onERC1155Received(operator, from, id, amount, data) returns (bytes4 response) {
                if (response != IERC1155Receiver.onERC1155Received.selector) {
                    // Tokens rejected
                    revert ERC1155InvalidReceiver(to);
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                // non-ERC1155Receiver implementer
                revert ERC1155InvalidReceiver(to);
            }
        }
    }

    function _doSafeBatchTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) private {
        if (to.code.length > 0) {
            try IERC1155Receiver(to).onERC1155BatchReceived(operator, from, ids, amounts, data) returns (
                bytes4 response
            ) {
                if (response != IERC1155Receiver.onERC1155BatchReceived.selector) {
                    // Tokens rejected
                    revert ERC1155InvalidReceiver(to);
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                // non-ERC1155Receiver implementer
                revert ERC1155InvalidReceiver(to);
            }
        }
    }

    function _asSingletonArrays(
        uint256 element1,
        uint256 element2
    ) private pure returns (uint256[] memory array1, uint256[] memory array2) {
        /// @solidity memory-safe-assembly
        assembly {
            array1 := mload(0x40)
            mstore(array1, 1)
            mstore(add(array1, 0x20), element1)

            array2 := add(array1, 0x40)
            mstore(array2, 1)
            mstore(add(array2, 0x20), element2)

            mstore(0x40, add(array2, 0x40))
        }
    }
}

// File: contracts/VoodooLabs.sol



pragma solidity ^ 0.8.19;






/*
██╗   ██╗ ██████╗  ██████╗ ██████╗  ██████╗  ██████╗ 
██║   ██║██╔═══██╗██╔═══██╗██╔══██╗██╔═══██╗██╔═══██╗
██║   ██║██║   ██║██║   ██║██║  ██║██║   ██║██║   ██║
╚██╗ ██╔╝██║   ██║██║   ██║██║  ██║██║   ██║██║   ██║
 ╚████╔╝ ╚██████╔╝╚██████╔╝██████╔╝╚██████╔╝╚██████╔╝
  ╚═══╝   ╚═════╝  ╚═════╝ ╚═════╝  ╚═════╝  ╚═════╝ 
                                                     
                    ██╗      █████╗ ██████╗ ███████╗ 
                    ██║     ██╔══██╗██╔══██╗██╔════╝ 
                    ██║     ███████║██████╔╝███████╗ 
                    ██║     ██╔══██║██╔══██╗╚════██║ 
                    ███████╗██║  ██║██████╔╝███████║ 
                    ╚══════╝╚═╝  ╚═╝╚═════╝ ╚══════╝ 
*/
/// @author developer's website 🐸 https://www.halfsupershop.com/ 🐸
contract VoodooLabs is ERC1155, Ownable, DefaultOperatorFilterer {
    string public name = "Voodoo Labs";
    string public symbol = "VDLS";
    string private hiddenURI;
    uint256 public collectionEndID = 3333;
    uint256 private cost = 13 ether;
    uint256 public maxMintAmount = 20;
    uint256 public maxBatchMintAmount = 20;
    mapping(uint256 => uint256) public batchLimit;
    mapping(address => mapping(uint256 => uint256)) public walletMinted;

    bool public paused = true;
    mapping(uint256 => bool) public pausedBatch;

    mapping(uint256 => uint) private batchMintDateStart;

    uint256 public randomCounter = 1;
    mapping(uint => string) private tokenToURI;
    mapping(uint256 => uint256) private currentSupply;
    mapping(uint256 => uint256) public maxSupply;
    mapping(uint256 => uint256) public maxSupplyForBatch;
    mapping(uint256 => bool) private createdToken;
    mapping(uint256 => bool) private mintInOrder;

    mapping(uint256 => bool) public rollSwapAllow;
    mapping(uint256 => bool) public rollInUse;
    mapping(uint256 => string) public roll;
    mapping(uint256 => uint256) public rollLimitMin; //excluded
    mapping(uint256 => uint256) public rollLimitMax; //included
    mapping(uint256 => uint256) public rollCost;

    mapping(uint256 => uint256[]) public requirementTokens;
    mapping(uint256 => uint256[]) public requirementTokenAmounts;
    mapping(uint256 => uint256[]) public batchRequirementTokens;
    mapping(uint256 => uint256[]) public batchRequirementTokenAmounts;

    uint256[] public collectionBatchEndID;
    uint256[] public tokenNextToMintInBatch;
    string[] public ipfsCIDBatch;
    string[] public uriBatch;
    uint256[] public batchCost;
    mapping(uint256 => uint256) public batchTriggerPoint;
    mapping(uint256 => uint256) public batchCostNext;
    mapping(uint256 => bool) public revealedBatch;
    
    struct Tier {
        uint256 tLimit;
        uint256 tCost;
        bytes32 tRoot;
    }
    Tier[] public tiers;
    string public tierURI;
    mapping(address => mapping(uint256 => uint256)) public tierMinted;

    address payable public payments;
    address public projectLeader;
    address[] public admins;

    mapping(uint256 => bool) public bindOnMintBatch; //BOM or BOMB are the tokens that cannot be moved after being minted
    mapping(uint256 => bool) public flagged; //flagged tokens cannot be moved
    mapping(address => bool) public restricted; //restricted addresses cannot move tokens

    /* 
    address(0) = 0x0000000000000000000000000000000000000000

    ERROR KEY:
    !D = Not The Date
    BLE = Batch Limit Exceeded
    WLE = Wallet Limit Exceeded
    PWLE = Presale Wallet Limit Exceeded
    !WL = Not Whitelisted
    LE = Limit Exceeded
    $? = Insufficient Funds
    !Batch = Not A Batch
    !B = ID Not Found in Batch
    OOS = Out Of Stock
    !MINT = Cannot Mint
    !A = Amount Cannot Be 0
    MMA = Max Mint Amount Exceeded
    !ID = ID Does Not Exist Yet
    IDs> = IDs Cannot Exceed Max Mint Amount
    IDs != Amounts = IDs List Does Not Match Amounts List
    EID > PB? = End ID Parameter Must Be Greater Than Previous Batch End ID
    MIN <= MAX? = Min Must Be Less Than Or Equal To Max
    NOoPL = Not Owner Or Project Leader
    FID = Flagged ID
    */

    constructor() ERC1155("") Ownable(msg.sender){
        collectionBatchEndID.push(collectionEndID);
        ipfsCIDBatch.push("");
        uriBatch.push("");
        maxSupply[1] = 1;
        createdToken[1] = true;
        currentSupply[1] = 1;
        tokenNextToMintInBatch.push(2);
        _mint(msg.sender, 1, 1, "");

        rollLimitMax[0] = 2;
        roll[1] = "VoodooQueens";
        rollInUse[0] = true;
        mintInOrder[0] = true;
        batchCost.push(cost);
        batchCostNext[0] = cost;
    }

    /**
    @dev Admin can set the PAUSE state for all or just a batch.
    @param _pauseAll Whether to pause all batches.
    @param _fromBatch The ID of the batch to pause.
    @param _state Whether to set the batch or all batches as paused or unpaused.
    true = closed to Admin Only
    false = open for Presale or Public
    */
    function pause(bool _pauseAll, uint _fromBatch, bool _state) public onlyAdmins {
        if(_pauseAll){
            paused = _state;
        }
        else{
            pausedBatch[_fromBatch] = _state;
        }
    }

    /**
    @dev Admin can set the state of an OPTION for a batch.
    @param _option The OPTION to set the state of:
    1 = Set the REVEALED state.
    2 = Set the USING ROLLS state allowing Mints to pick a roll randomly within a set range.
    3 = Set the MINT IN ORDER state.     
    4 = Set the BIND on mint state. Note: Bound tokens cannot be moved once minted.
    //5 = Set the PRESALE state.
    6 = Set ROLL SWAP ALLOW state.
    @param _state The new state of the option:
    true = revealed, on
    false = hidden, off
    @param _fromBatch The batch ID to update the state for.
    */
    function setStateOf(uint _option, bool _state, uint _fromBatch) public onlyAdmins {
        if(_option == 1){
            revealedBatch[_fromBatch] = _state;
            return;
        }
        if(_option == 2){
            rollInUse[_fromBatch] = _state;
            return;
        }
        if(_option == 3){
            mintInOrder[_fromBatch] = _state;
            return;
        }
        if(_option == 4){
            bindOnMintBatch[_fromBatch] = _state;
            return;
        }
        // if(_option == 5){
        //     presaleBatch[_fromBatch] = _state;
        //     return;
        // }
        if(_option == 6){
            rollSwapAllow[_fromBatch] = _state;
            return;
        }
    }

    /**
    @dev Allows an admin to set a start date for minting tokens for a specific batch.
    Tokens can only be minted after this date has passed.
    @param _batch The ID of the batch to set the mint date for.
    @param _unixDate The Unix timestamp for the start date of minting.
    @notice The Unix timestamp must be in the future, otherwise the function will revert.
    */
    function setMintDate(uint256 _batch, uint _unixDate) public onlyAdmins {
        require(_unixDate > block.timestamp, "Date Already Past");
        batchMintDateStart[_batch] = _unixDate;
    }

    /**
    @dev Sets the ID of the next token to be minted in a batch by an Admin.
    @param _id uint ID of the next token to be minted.
    @param _fromBatch uint Batch number of the batch in which the token will be minted.
    Requirements:
    Only accessible by admins.
    */
    function setTokenNextToMintInBatch(uint _id, uint _fromBatch) external onlyAdmins {
        tokenNextToMintInBatch[_fromBatch] = _id;
    }

    /**
    @dev Admin can set the new public or presale cost for a specific batch in WEI. The cost is denominated in wei,
    where 1 ETH = 10^18 WEI. To convert ETH to WEI and vice versa, use a tool such as https://etherscan.io/unitconverter.
    @param _isRollCost bool indicating if setting a roll or batch cost.
    @param _newCost uint256 indicating the new cost for the batch in WEI.
    @param _fromBatch uint indicating the ID of the batch to which the new cost applies.
    Note:
    This also sets the batchCostNext to the new cost so if a setCostNextOnTrigger was set it will need to be reset again.
    Requirements:
    Only accessible by admins.
    */
    function setCost(bool _isRollCost, uint256 _newCost, uint _fromBatch) public onlyAdmins {
        if (!_isRollCost) {
            batchCost[_fromBatch] = _newCost;
            batchCostNext[_fromBatch] = _newCost;
        } else {
            rollCost[_fromBatch] = _newCost;
        }
    }

    /**
    @dev Sets the cost for the next mint after a specific token is minted in a batch.
    Only accessible by admins.
    */
    function setCostNextOnTrigger(uint256 _nextCost, uint _triggerPointID, uint _fromBatch) public onlyAdmins {
        batchTriggerPoint[_fromBatch] = _triggerPointID;
        batchCostNext[_fromBatch] = _nextCost;
    }

    /**
    @dev Returns the cost for minting a token from the specified batch ID.
    If the caller is not an Admin, the function will return the presale cost if the batch is a presale batch,
    otherwise it will return the regular batch cost. If the caller is an Admin, the function will return 0.
    */
    function _cost(uint _batchID, bool _onTierList, uint8 _tID) public view returns(uint256){
        if (!checkIfAdmin()) {
            if(_onTierList){
                return tiers[_tID].tCost;
            }
            
            return batchCost[_batchID];
        }
        return 0;
    }

    function checkOut(uint _amount, uint _batchID, bytes32[] calldata proof) private {
        if (!checkIfAdmin()) {
            if (batchMintDateStart[_batchID] > 0) {
                require(block.timestamp >= batchMintDateStart[_batchID], "!D");
            }

            if(batchLimit[_batchID] != 0){
                require(walletMinted[msg.sender][_batchID] + _amount <= batchLimit[_batchID], "BLE");
                walletMinted[msg.sender][_batchID] += _amount;
            }

            (bool _onTierList, uint8 _tID) = isValidTier(proof, keccak256(abi.encodePacked(msg.sender)));
            if(_onTierList){
                if(tiers[_tID].tLimit == 0){
                    //use selected tier ID
                }
                else{
                    if(tierMinted[msg.sender][_tID] + _amount <= tiers[_tID].tLimit){
                        tierMinted[msg.sender][_tID] += _amount;
                    }
                    else{
                        //move to next tier if next one is available
                        if(_tID < tiers.length - 1){
                            _tID++;
                        }
                    }
                }
            }
            
            require(msg.value >= (_amount * _cost(_batchID, _onTierList, _tID)), "$?");
        }
    }

    function checkOutScan(uint _id, uint _fromBatch) private{
        if (!exists(_id)) {
            createdToken[_id] = true;
            if(mintInOrder[_fromBatch]){
                currentSupply[_id] = 1;
            }
        }

        if(rollInUse[_fromBatch]){
            roll[_id] = randomRoll(_fromBatch);
        }

        if(batchCost[_fromBatch] != batchCostNext[_fromBatch] && tokenNextToMintInBatch[_fromBatch] >= batchTriggerPoint[_fromBatch]){
            batchCost[_fromBatch] = batchCostNext[_fromBatch];
        }
        randomCounter++;
    }

    /**
    @dev Checks if a token with the given ID belongs to the specified batch.
    @param _id The ID of the token to check.
    @param _fromBatch The batch to check for token membership.
    @return bool indicating whether the token belongs to the specified batch.
    */
    function checkInBatch(uint _id, uint _fromBatch) public view returns(bool){
        require(_fromBatch < collectionBatchEndID.length, "!Batch");
        if(_fromBatch != 0 && _id <= collectionBatchEndID[_fromBatch] && _id > collectionBatchEndID[_fromBatch - 1]){
            return true;
        }
        if(_fromBatch <= 0 && _id <= collectionBatchEndID[_fromBatch]){
            return true;
        }
        return false;
    }

    /**
    @dev Allows Admins, Whitelisters, and Public to mint NFTs in order from a collection batch.
    Admins can call this function even while the contract is paused.
    @param _to The address to mint the NFTs to.
    @param _numberOfTokensToMint The number of tokens to mint from the batch in order.
    @param _fromBatch The batch to mint the NFTs from.
    @param proof An array of Merkle tree proofs to validate the mint.
    */
    function _mintInOrder(address _to, uint _numberOfTokensToMint, uint _fromBatch, bytes32[] calldata proof) public payable {
        require(mintInOrder[_fromBatch], "mintInOrder");
        require(!exists(collectionBatchEndID[_fromBatch]), "OOS");
        require(_fromBatch >= 0, "!Batch");
        require(_numberOfTokensToMint + tokenNextToMintInBatch[_fromBatch] - 1 <= collectionBatchEndID[_fromBatch], "Please Lower Amount");
        if(!checkIfAdmin()){
            require(!paused, "Paused");
            require(!pausedBatch[_fromBatch], "Paused Batch");

            checkOut(_numberOfTokensToMint, _fromBatch, proof);
        }
        
        _mintBatchTo(_to, _numberOfTokensToMint, _fromBatch);
    }

    function _mintBatchTo(address _to, uint _numberOfTokensToMint, uint _fromBatch)private {
        uint256[] memory _ids = new uint256[](_numberOfTokensToMint);
        uint256[] memory _amounts = new uint256[](_numberOfTokensToMint);
        for (uint256 i = 0; i < _numberOfTokensToMint; i++) {
            uint256 _id = tokenNextToMintInBatch[_fromBatch];
            require(canMintChecker(_id, 1, _fromBatch), "!MINT");
            
            checkOutScan(_id, _fromBatch);

            _ids[i] = tokenNextToMintInBatch[_fromBatch];
            _amounts[i] = 1;
            tokenNextToMintInBatch[_fromBatch]++;
        }
        
        _mintBatch(_to, _ids, _amounts, "");
    }

    /**
    @dev Allows Owner, Whitelisters, and Public to mint a single NFT with the given _id, _amount, and _fromBatch parameters for the specified _to address.
    @param _to The address to mint the NFT to.
    @param _id The ID of the NFT to mint.
    @param _amount The amount of NFTs to mint.
    @param _fromBatch The batch end ID that the NFT belongs to.
    @param proof The Merkle proof verifying the ownership of the tokens being minted.
    Requirements:
    - mintInOrder[_fromBatch] must be false.
    - _id must be within the batch specified by _fromBatch.
    - The total number of NFTs being minted across all batches cannot exceed maxBatchMintAmount.
    - If the caller is not an admin, the contract must not be paused and the batch being minted from must not be paused.
    - The caller must have a valid Merkle proof for the tokens being minted.
    - The amount of tokens being minted must satisfy the canMintChecker function.
    - The ID being minted must not have reached its max supply.
    */
    function mint(address _to, uint _id, uint _amount, uint _fromBatch, bytes32[] calldata proof) public payable {
        require(!mintInOrder[_fromBatch], "Requires !mintInOrder");
        require(checkInBatch(_id, _fromBatch), "!B");
        require(canMintChecker(_id, _amount, _fromBatch), "!MINT");
        if(!checkIfAdmin()){
            require(!paused, "Paused");
            require(!pausedBatch[_fromBatch], "Paused Batch");

            checkOut(_amount, _fromBatch, proof);
        }

        checkOutScan(_id, _fromBatch);
        currentSupply[_id] += _amount;
        
        _mint(_to, _id, _amount, "");
    }

    function canMintChecker(uint _id, uint _amount, uint _fromBatch) private view returns(bool){
        require(_amount > 0, "!A");
        require(_amount <= maxMintAmount, "MMA");
        require(_id <= collectionEndID, "!ID");

        // checks if the id exceeded it's max supply
        if (maxSupply[_id] != 0 && currentSupply[_id] + _amount > maxSupply[_id]) {
            // CANNOT MINT 
            return false;
        }

        // checks if the id exceeded it's max supply limit that each id in the batch is assigned
        if(maxSupplyForBatch[_fromBatch] != 0 && currentSupply[_id] + _amount > maxSupplyForBatch[_fromBatch]){
            // CANNOT MINT 
            return false;
        }
        
        // checks if the id needs requirement token(s)
        if(requirementTokens[_id].length > 0) {
            for (uint256 i = 0; i < requirementTokens[_id].length; i++) {
                uint256 _userTokenBalance = balanceOf(msg.sender, requirementTokens[_id][i]);
                if(_userTokenBalance < requirementTokenAmounts[_id][i]){
                    //CANNOT MINT: DOES NOT HAVE REQUIREMENT TOKEN(S) AMOUNTS
                    return false;
                }
            }
        }

        // checks if the batch (other than the original) that the id resides in needs requirement token(s)
        if(batchRequirementTokens[_fromBatch].length > 0){
            for (uint256 j = 0; j < batchRequirementTokens[_fromBatch].length; j++) {
                uint256 _userBatchTokenBalance = balanceOf(msg.sender, batchRequirementTokens[_fromBatch][j]);
                if(_userBatchTokenBalance < batchRequirementTokenAmounts[_fromBatch][j]){
                    //CANNOT MINT: DOES NOT HAVE REQUIREMENT TOKEN(S) AMOUNTS
                    return false;
                }
            }
        }

        // CAN MINT
        return true;
    }

    /**
    @dev Allows Owner, Whitelisters, and Public to mint multiple NFTs at once, given a list of token IDs, their corresponding amounts,
    and the batch from which they are being minted. Checks if the caller has the required permissions and if the maximum allowed mint
    amount and maximum allowed batch mint amount are not exceeded. Also verifies that the specified token IDs are in the given batch,
    and that the caller has passed a valid proof of a transaction to checkOut.
    */
    function mintBatch(address _to, uint[] memory _ids, uint[] memory _amounts, uint _fromBatch, bytes32[] calldata proof) public payable {
        require(!mintInOrder[_fromBatch], "Requires !mintInOrder");
        require(_ids.length <= maxMintAmount, "IDs>");
        require(_ids.length == _amounts.length, "IDs != Amounts");
        require(canMintBatchChecker(_ids, _amounts, _fromBatch), "!MINT");

        uint256 _totalBatchAmount;
        for (uint256 i = 0; i < _amounts.length; i++) {
            require(checkInBatch(_ids[i], _fromBatch), "!B");
            _totalBatchAmount += _amounts[i];
        }
        require(_totalBatchAmount <= maxBatchMintAmount, "LE");

        if(!checkIfAdmin()){
            require(!paused, "Paused");
            require(!pausedBatch[_fromBatch], "Paused Batch");
            checkOut(_totalBatchAmount, _fromBatch, proof);
        }

        for (uint256 k = 0; k < _ids.length; k++) {
            uint256 _id = _ids[k];
            checkOutScan(_id, _fromBatch);
            currentSupply[_ids[k]] += _amounts[k];
        }

        _mintBatch(_to, _ids, _amounts, "");
    }

    function canMintBatchChecker(uint[] memory _ids, uint[] memory _amounts, uint _fromBatch)private view returns(bool){
        for (uint256 i = 0; i < _ids.length; i++) {
            uint256 _id = _ids[i];
            uint256 _amount = _amounts[i];
            if(!canMintChecker(_id, _amount, _fromBatch)){
                // CANNOT MINT
                return false;
            }
        }

        return true;
    }

    /**
    @dev Allows User to DESTROY multiple tokens they own.
    */
    function burnBatch(uint[] memory _ids, uint[] memory _amounts) external {
        for (uint256 i = 0; i < _ids.length; ++i) {
            uint256 _id = _ids[i];
            currentSupply[_id] -= _amounts[i];
        }
        _burnBatch(msg.sender, _ids, _amounts);
    }

    /**
    @dev Allows the contract admin to set the requirement tokens and their corresponding amounts for a specific token ID or batch end ID.
    If `_isBatch` is true, the requirement tokens and amounts will be set for the entire batch. Otherwise, they will be set for a specific token ID.
    @param _id The ID of the token or batch end for which the requirement tokens and amounts will be set.
    @param _isBatch A boolean indicating whether the ID corresponds to a batch end or a specific token.
    @param _requiredIDS An array of token IDs that are required to be owned in order to own the specified token or batch.
    @param _amounts An array of amounts indicating how many of each token ID in `_requiredIDS` are required to be owned in order to own the specified token or batch.
    */
    function setRequirementTokens(uint _id, bool _isBatch, uint[] memory _requiredIDS, uint[] memory _amounts) external onlyAdmins {
        if(_isBatch){
            require(_id >= 0 && _id <= collectionBatchEndID[collectionBatchEndID.length - 1], "!B");
            // is confirmed a Batch, _id = batchID
            batchRequirementTokens[_id] = _requiredIDS;
            batchRequirementTokenAmounts[_id] = _amounts;
        }
        else{
            requirementTokens[_id] = _requiredIDS;
            requirementTokenAmounts[_id] = _amounts;
        }
    }

    /**
    @dev Sets the URI for a token or batch of tokens.
    @param _hidden Flag to determine if the URI should be set as the hidden URI.
    @param _tier Flag to determine if the URI should be set as the tier URI.
    @param _isBatch Flag to determine if a batch of tokens is being modified.
    @param _id ID of the token or batch of tokens being modified.
    @param _uri The new URI to be set.
    @param _isIpfsCID Flag to determine if the new URI is an IPFS CID.
    */
    function setURI(bool _hidden, bool _tier, bool _isBatch, uint _id, string calldata _uri, bool _isIpfsCID) external onlyAdmins {
        if (_hidden) {
            hiddenURI = _uri;
            return;
        }

        if (_tier) {
            tierURI = _uri;
            return;
        }

        if (!_isBatch) {
            if (_isIpfsCID) {
                string memory _uriIPFS = string(abi.encodePacked(
                    "ipfs://",
                    _uri,
                    "/",
                    Strings.toString(_id),
                    ".json"
                ));

                tokenToURI[_id] = _uriIPFS;
                emit URI(_uriIPFS, _id);
            }
            else {
                tokenToURI[_id] = _uri;
                emit URI(_uri, _id);
            }
        }
        else{
            if (_isIpfsCID) {
                //modify IPFS CID
                ipfsCIDBatch[_id] = _uri;
            }
            else{
                //modify URI
                uriBatch[_id] = _uri;
            }
        }
    }

    /**
    @dev Allows the contract Admin to create a new batch of tokens with a specified end ID, URI or CID, and cost in WEI.
    @param _endBatchID The ending token ID of the new batch. Must be greater than the previous batch end ID.
    @param _newCost The cost of each token in the new batch in WEI.
    @param _uri The base URI or CID for the new batch of tokens.
    @param _isIpfsCID Set to true if the URI is a CID only.
    @param _isMintInOrder Set to true if the new batch should be minted in order.
    Example URI structure if _endBatchID = 55 and _isIpfsCID = false and _uri = BASEURI.EXTENSION
    will output: BASEURI.EXTENSION/55.json for IDs 55 and below until it hits another batch end ID.
    Requirements:
    - The _endBatchID parameter must be greater than the previous batch end ID.
    */
    function createBatchAndSetURI(uint _endBatchID, uint256 _newCost, string memory _uri, bool _isIpfsCID, bool _isMintInOrder) external onlyAdmins {
        require(_endBatchID > collectionBatchEndID[collectionBatchEndID.length-1], "EID > PB?");
        
        tokenNextToMintInBatch.push(collectionBatchEndID[collectionBatchEndID.length-1] + 1); //set mint start ID for batch
                    
        collectionBatchEndID.push(_endBatchID);

        if (_isIpfsCID) {
            //set IPFS CID
            ipfsCIDBatch.push(_uri);
            uriBatch.push("");
        }
        else{
            //set URI
            uriBatch.push(_uri);
            ipfsCIDBatch.push("");
        }

        batchCost.push(_newCost);
        batchCostNext[collectionBatchEndID.length-1] = _newCost;
        if(_isMintInOrder){
            setStateOf(3, true, collectionBatchEndID.length-1);
        }
    }

    /**
    @dev Returns the URI for a given token ID. If the token is a collection,
    the URI may be batched. If the token batch has roll enabled, it will have
    a random roll id. If the token is not found, the URI defaults to a hidden URI.
    @param _id uint256 ID of the token to query the URI of
    @return string representing the URI for the given token ID
    */
    function uri(uint256 _id) override public view returns(string memory){
        bool _batched = true;
        uint256 _batchID;
        string memory _CIDorURI;

        if(createdToken[_id]){
            if (_id <= collectionEndID) {
                if(keccak256(abi.encodePacked((tokenToURI[_id]))) != keccak256(abi.encodePacked(("")))){
                    return tokenToURI[_id];
                }

                for (uint256 i = 0; i < collectionBatchEndID.length; ++i) {
                    if(_id <= collectionBatchEndID[i]){
                        if(keccak256(abi.encodePacked((ipfsCIDBatch[i]))) != keccak256(abi.encodePacked(("")))){
                            _CIDorURI = string(abi.encodePacked(
                                "ipfs://",
                                ipfsCIDBatch[i],
                                "/"
                            ));
                            _batchID = i;
                            break;
                        }
                        if(keccak256(abi.encodePacked((uriBatch[i]))) != keccak256(abi.encodePacked(("")))){
                            _CIDorURI = string(abi.encodePacked(
                                uriBatch[i],
                                "/"
                            ));
                            _batchID = i;
                            break;
                        }
                        continue;
                    }
                    else{
                        //_id was not found in a batch
                        continue;
                    }
                }

                if(_id > collectionBatchEndID[collectionBatchEndID.length - 1]){
                    _batched = false;
                }

                if(_batched && revealedBatch[_batchID]){
                    if(keccak256(abi.encodePacked((roll[_id]))) == keccak256(abi.encodePacked(("")))){
                        //no roll
                        return (
                        string(abi.encodePacked(
                            _CIDorURI,
                            Strings.toString(_id),
                            ".json"
                        )));
                    }
                    else{
                        //has roll
                        return (
                        string(abi.encodePacked(
                            _CIDorURI,
                            roll[_id],
                            "/",
                            Strings.toString(_id),
                            ".json"
                        )));
                    }
                }
            }
        }
        //not found default to hidden
        return hiddenURI;
    }

    /**
    @dev Returns a random number between rollLimitMin and rollLimitMax for a given batch _fromBatch.
    @param _fromBatch The ID of the batch to get the roll limit for.
    @return A string representing the randomly selected roll within the specified range.
    */
    function randomRoll(uint _fromBatch) internal view returns (string memory){
        uint random = uint(keccak256(abi.encodePacked(
            block.timestamp,
            block.prevrandao,
            msg.sender,
            randomCounter,
            roll[randomCounter - 1])
            )) % rollLimitMax[_fromBatch];
        //return random;
        if (_fromBatch == 0) {
            if (random + 1 == 2) {
                return "WitchDoctor";
            }
            else {
                return "VoodooQueens";
            }
        }
        if (random < rollLimitMin[_fromBatch]){
            return Strings.toString(rollLimitMax[_fromBatch] - (random + 1));
        }
        else{
            return Strings.toString(random + 1);
        }
    }

    /**
    @dev Returns a randomly selected roll within the range specified for a given batch _fromBatch.
    @param _fromBatch The ID of the batch to get the roll limit for.
    @return _roll string representing the randomly selected roll within the specified range.
    */
    // function randomPick(uint _fromBatch) public view returns (string memory _roll){
    //     return randomRoll(_fromBatch);
    // }

    /**
    @dev Sets the roll for a given token.
    @param _id The token ID.
    @param _roll The value of the roll.
    @param _fromBatch The ID of the batch to set the roll limit for.
    */
    function rollSet(uint256 _id, uint _roll, uint _fromBatch) public payable {
        if (!checkIfAdmin()) {
            require(rollSwapAllow[_fromBatch], "Reroll Not Allowed");
            require(_roll > rollLimitMin[_fromBatch] && _roll <= rollLimitMax[_fromBatch], "Invalid Roll");
            require(balanceOf(msg.sender, _id) > 0, "Not Owner Of Token ID");
            require(msg.value >= (rollCost[_fromBatch]), "$?");
        }
        roll[_id] = Strings.toString(_roll);
    }

    /**
    @dev Sets the minimum and maximum values for the roll limit for a given batch _fromBatch.
    @param _min The minimum value of the roll limit (excluded).
    @param _max The maximum value of the roll limit (included).
    @param _fromBatch The ID of the batch to set the roll limit for.
    */
    function rollLimitSet(uint _min, uint _max, uint _fromBatch) external onlyAdmins {
        require(_min <= _max, "MIN <= MAX?");
        rollLimitMin[_fromBatch] = _min;
        rollLimitMax[_fromBatch] = _max;
    }

    /**
    @dev Returns the total number of tokens with a given ID that have been minted.
    @param _id The ID of the token.
    @return total number of tokens with the given ID.
    */
    function totalSupplyOfID(uint256 _id) public view returns(uint256) {
        return currentSupply[_id];
    }

    /**
    @dev Returns the total number of tokens within the collection.
    */
    function totalSupply() public view returns(uint256) {
        return collectionEndID;
    }

    /**
    @dev Returns true if a token with the given ID exists, otherwise returns false.
    @param _id The ID of the token.
    @return bool indicating whether the token with the given ID exists.
    */
    function exists(uint256 _id) public view returns(bool) {
        return createdToken[_id];
    }

    /**
    @dev Returns the maximum supply of a token with the given ID.
    @param _id The ID of the token.
    @param _isBatch A boolean indicating whether the ID is a batch ID or not.
    @return maximum supply of the token with the given ID. If it is 0, the supply is limitless.
    */
    function checkMaxSupply(uint256 _id, bool _isBatch) public view returns(uint256) {        
        if(_isBatch){
            return maxSupplyForBatch[_id];
        }
        else{
            return maxSupply[_id];
        }
    }

    /**
    @dev Allows the admin to set the maximum supply of tokens.
    @param _ids An array of token IDs to set the maximum supply for.
    @param _supplies An array of maximum supplies for the tokens in the corresponding position in _ids.
    @param _isBatchAllSameSupply A boolean indicating whether all tokens in _ids should have the same maximum supply or not.
    Note: If the maximum supply is set to 0, the supply is limitless.
    */
    function setMaxSupplies(uint[] memory _ids, uint[] memory _supplies, bool _isBatchAllSameSupply) external onlyAdmins {
        if(_isBatchAllSameSupply){
            maxSupplyForBatch[_ids[0]] = _supplies[0];          
        }
        else{
            for (uint256 i = 0; i < _ids.length; i++) {
                uint256 _id = _ids[i];
                maxSupply[_id] = _supplies[i];
            }
        }
    }

    /**
    @dev Allows admin to update the collectionEndID which is used to determine the end of the initial collection of NFTs.
    @param _newcollectionEndID The new collectionEndID to set.
    */
    function updatecollectionEndID(uint _newcollectionEndID) external onlyAdmins {
        collectionEndID = _newcollectionEndID;
    }

    /**
    @dev Allows admin to set the maximum amount of NFTs a user can mint in a single session.
    @param _newmaxMintAmount The new maximum amount of NFTs a user can mint in a single session.
    */
    function setMaxMintAmount(uint256 _newmaxMintAmount) public onlyAdmins {
        maxMintAmount = _newmaxMintAmount;
    }

    /**
    @dev Allows admin to set the mint limit for a batch.
    @param _limit The new limit to set.
    @param _fromBatch The index of the batch to set the limit for.
    */
    function setMintLimit(uint256 _limit, uint256 _fromBatch) public onlyAdmins {
        batchLimit[_fromBatch] = _limit;
    }

    /**
    @dev Allows admin to set the payout address for the contract.
    @param _address The new payout address to set.
    Note: address can be a wallet or a payment splitter contract
    */
    function setPayoutAddress(address _address) external onlyOwner{
        payments = payable(_address);
    }

    /**
    @dev Admin can withdraw the contract's balance to the specified payout address.
    The `payments` address must be set before calling this function.
    The function will revert if `payments` address is not set or the transaction fails.
    */
    function withdraw() public onlyAdmins {
        require(payments != address(0), "Payout address not set");

        uint256 balance = address(this).balance;
        require(balance > 0, "No funds to withdraw");

        // Splitter
        (bool success, ) = payable(payments).call{ value: balance }("");
        require(success, "Withdrawal failed");
    }

    /**
    @dev Auto send funds to the payout address.
    Triggers only if funds were sent directly to this address.
    */
    receive() external payable {
        require(payments != address(0), "Payment address not set");
        uint256 payout = msg.value;
        payments.transfer(payout);
    }

    /**
    @dev Throws if called by any account other than the owner or admin.
    */
    modifier onlyAdmins() {
        _checkAdmins();
        _;
    }

    /**
    @dev Internal function to check if the sender is an admin.
    */
    function _checkAdmins() internal view virtual {
        require(checkIfAdmin(), "!A");
    }

    /**
    @dev Checks if the sender is an admin.
    @return bool indicating whether the sender is an admin or not.
    */
    function checkIfAdmin() public view returns(bool) {
        if (msg.sender == owner() || msg.sender == projectLeader){
            return true;
        }
        if(admins.length > 0){
            for (uint256 i = 0; i < admins.length; i++) {
                if(msg.sender == admins[i]){
                    return true;
                }
            }
        }
        // Not an Admin
        return false;
    }

    /**
    @dev Owner and Project Leader can set the addresses as approved Admins.
    Example: ["0xADDRESS1", "0xADDRESS2", "0xADDRESS3"]
    */
    function setAdmins(address[] calldata _users) public onlyAdmins {
        require(msg.sender == owner() || msg.sender == projectLeader, "NOoPL");
        delete admins;
        admins = _users;
    }

    /**
    @dev Owner or Project Leader can set the address as new Project Leader.
    */
    function setProjectLeader(address _user) external {
        require(msg.sender == owner() || msg.sender == projectLeader, "NOoPL");
        projectLeader = _user;
    }

    /**
    * @dev Validates what tier a user is on for the Tierlist.
    */
    function isValidTier(bytes32[] calldata proof, bytes32 leaf) public view returns (bool, uint8) {
        if(tiers.length != 0){
            for (uint8 i = 0; i < tiers.length; i++) {
                if(MerkleProof.verify(proof, tiers[i].tRoot, leaf)){
                    return (true, i);
                }
            }
        }
        
        return (false, 0);
    }

    /**
    @dev Sets a new tier with the provided parameters or updates an existing tier.
    @param _create If true, creates a new tier with the provided parameters. If false, updates an existing tier.
    @param _tID The ID of the tier to be updated. Only applicable if _create is false.
    @param _tLimit The mint limit of the new tier or updated tier.
    @param _tCost The cost of the new tier or updated tier.
    @param _tRoot The Merkle root of the new tier or updated tier.
    Requirements:
    - Only admin addresses can call this function.
    - If _create is false, the ID provided must correspond to an existing tier.
    */
    function setTier(bool _create, uint8 _tID, uint256 _tLimit, uint256 _tCost, bytes32 _tRoot) external onlyAdmins {
        // Define a new Tier struct with the provided cost and Merkle root.
        Tier memory newTier = Tier(
            _tLimit,
            _tCost,
            _tRoot
        );
        
        if(_create){
            // If _create is true, add the new tier to the end of the tiers array.
            tiers.push(newTier);
        }
        else{
            // If _create is false, update the existing tier at the specified ID.
            require(tiers.length > 0 && _tID < tiers.length, "Invalid Tier ID");
            tiers[_tID] = newTier;
        }
    }

    /**
    * @dev Owner or Project Leader can set the restricted state of an address.
    * Note: Restricted addresses are banned from moving tokens.
    */
    function restrictAddress(address _user, bool _state) external {
        require(msg.sender == owner() || msg.sender == projectLeader, "NOoPL");
        restricted[_user] = _state;
    }

    /**
    * @dev Owner or Project Leader can set the flag state of a token ID.
    * Note: Flagged tokens are locked and untransferable.
    */
    function flagID(uint256 _id, bool _state) external {
        require(msg.sender == owner() || msg.sender == projectLeader, "NOoPL");
        flagged[_id] = _state;
    }

    /**
    * @dev Check if an ID is in a bind on mint batch.
    */
    function bindOnMint(uint _id) public view returns(bool){
        uint256 _batchID;
        for (uint256 i = 0; i < collectionBatchEndID.length; i++) {
            if(i != 0 && _id <= collectionBatchEndID[i] && _id > collectionBatchEndID[i - 1]){
                _batchID = i;
                break;
            }
            if(i <= 0 && _id <= collectionBatchEndID[i]){
                _batchID = i;
                break;
            }
        }
        return bindOnMintBatch[_batchID];
    }

    /**
    * @dev Hook that is called for any token transfer. 
    * This includes minting and burning, as well as batched variants.
    */
    function _update(address from, address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data) internal virtual override {
        // ... before action here ...
        require(restricted[from] == false && restricted[to] == false, "Operator, From, or To Address is RESTRICTED"); //checks if the any address in use is restricted

        for (uint256 i = 0; i < ids.length; i++) {
            if(flagged[ids[i]]){
                revert("FID"); //reverts if a token has been flagged
            }
        }
        
        super._update(from, to, ids, amounts, data); // Call parent hook

        // ... after action here ...
        for (uint256 i = 0; i < ids.length; i++) {
            if(bindOnMint(ids[i])){
                flagged[ids[i]] = true;
            }
        }   
    }

    //OPENSEA ROYALTY REQUIREMENT CODE SNIPPET ************_START
    function safeTransferFrom(address from, address to, uint256 tokenId, uint256 amount, bytes memory data)
        public
        override
        onlyAllowedOperator()
    {
        super.safeTransferFrom(from, to, tokenId, amount, data);
    }

    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public virtual override onlyAllowedOperator() {
        super.safeBatchTransferFrom(from, to, ids, amounts, data);
    }
    //OPENSEA ROYALTY REQUIREMENT CODE SNIPPET ************_END
}