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
// OpenZeppelin Contracts (last updated v4.8.0) (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    enum Rounding {
        Down, // Toward negative infinity
        Up, // Toward infinity
        Zero // Toward zero
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
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 result) {
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
                return prod0 / denominator;
            }

            // Make sure the result is less than 2^256. Also prevents denominator == 0.
            require(denominator > prod1);

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
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator,
        Rounding rounding
    ) internal pure returns (uint256) {
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
            if (value >= 10**64) {
                value /= 10**64;
                result += 64;
            }
            if (value >= 10**32) {
                value /= 10**32;
                result += 32;
            }
            if (value >= 10**16) {
                value /= 10**16;
                result += 16;
            }
            if (value >= 10**8) {
                value /= 10**8;
                result += 8;
            }
            if (value >= 10**4) {
                value /= 10**4;
                result += 4;
            }
            if (value >= 10**2) {
                value /= 10**2;
                result += 2;
            }
            if (value >= 10**1) {
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
            return result + (rounding == Rounding.Up && 10**result < value ? 1 : 0);
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
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log256(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log256(value);
            return result + (rounding == Rounding.Up && 1 << (result * 8) < value ? 1 : 0);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

import "./math/Math.sol";

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

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
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/structs/EnumerableSet.sol)
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
 * ```
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

// developer: Lucas Iwai
//

//         .__       .__     __                            __.__
//   _____ |__| ____ |  |___/  |_  ____   _____   ____    |__|__|
//  /     \|  |/ ___\|  |  \   __\/ __ \ /     \ /  _ \   |  |  |
// |  Y Y  \  / /_/  >   Y  \  | \  ___/|  Y Y  (  <_> )  |  |  |
// |__|_|  /__\___  /|___|  /__|  \___  >__|_|  /\____/\__|  |__|
//       \/  /_____/      \/          \/      \/      \______|

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IContract {
    function mint(
        address,
        string memory,
        uint256
    ) external;

    function getTotalSupply() external view returns (uint256);
}

// developer: Lucas Iwai
//

//         .__       .__     __                            __.__
//   _____ |__| ____ |  |___/  |_  ____   _____   ____    |__|__|
//  /     \|  |/ ___\|  |  \   __\/ __ \ /     \ /  _ \   |  |  |
// |  Y Y  \  / /_/  >   Y  \  | \  ___/|  Y Y  (  <_> )  |  |  |
// |__|_|  /__\___  /|___|  /__|  \___  >__|_|  /\____/\__|  |__|
//       \/  /_____/      \/          \/      \/      \______|

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "./IContract.sol";

contract MightEmojiNFTController {
    using EnumerableSet for EnumerableSet.AddressSet;

    enum NFTRarityType {
        Common,
        Uncommon,
        Rare,
        Legendary
    }

    struct NFTInfo {
        string baseURI;
        uint256 whitelistPrice;
        uint256 reservationPrice;
        uint256 publicPrice;
        uint16 maxSupply;
        uint16 currentSupply;
        uint16 reserved;
        uint16 whitelistMaxSupply;
        uint16 publicMaxSupply;
        uint16 teamMaxSupply;
        uint16 teamCurrentSupply;
        uint16 reservationLimitByWallet;
    }

    struct ReservationLinkInfo {
        uint256 index;
        NFTRarityType rarityType;
        string link;
        address marketer;
        uint256 reserved;
        uint256 minted;
    }

    struct UserInfo {
        NFTRarityType rarityType;
        address referralMarketer;
        string link;
        uint256 reserved;
        uint256 reserveMinted;
        uint256 minted;
    }

    struct MarketerPhotoInfo {
        address marketer;
        string photo;
        string name;
    }

    struct MarketerTotalInfo {
        MarketerPhotoInfo photoInfo;
        ReservationLinkInfo common;
        ReservationLinkInfo uncommon;
        ReservationLinkInfo rare;
        ReservationLinkInfo legendary;
    }

    address public nftContract;

    mapping(NFTRarityType => NFTInfo) public nftInfos;

    // admin
    mapping(address => bool) public isAdmin;
    // dev
    mapping(address => bool) public isDev;

    // marketer
    EnumerableSet.AddressSet marketerAddresses;
    mapping(address => mapping(NFTRarityType => ReservationLinkInfo))
        public marketerReservationInfos;
    mapping(address => MarketerPhotoInfo) public marketerPhotoInfos;

    // user
    mapping(address => mapping(NFTRarityType => UserInfo)) public userInfos;

    // team
    EnumerableSet.AddressSet teamAddresses;

    // reservation links
    uint256 public reservationLinksCount;
    mapping(string => ReservationLinkInfo) public reservationLinks;

    // rarity type
    mapping(uint256 => NFTRarityType) rarityByTokenId;

    uint256 public whitelistMintStartTimestamp;
    uint256 public reservationMintStartTimestamp;
    uint256 public publicMintStartTimestamp;

    // merkle root
    bytes32 public whitelistMerkleRoot;

    // fee
    address public devWallet;
    uint8 public devFee = 10;
    uint8 public marketerFee = 50;
    uint8 public totalPercent = 100;

    event MarketerAdded(address marketer, string url, string name);
    event MarketerRemoved(address marketer);
    event TeamMemberAdded(address teamMember);
    event TeamMemberRemoved(address teamMember);
    event ReservationLinkInfoAdded(
        uint256 index,
        NFTRarityType rarityType,
        string link,
        address marketer
    );
    event NFTReserved(
        address user,
        NFTRarityType rarityType,
        uint256 reservedAmount
    );

    modifier onlyAdmin() {
        require(isAdmin[msg.sender], "You are not admin.");
        _;
    }

    constructor(
        uint256 _whitelistMintStartTimestamp,
        uint256 _reservationMintStartTimestamp,
        uint256 _publicMintStartTimestamp
    ) {
        isAdmin[msg.sender] = true;
        isDev[msg.sender] = true;
        devWallet = msg.sender;
        whitelistMintStartTimestamp = _whitelistMintStartTimestamp;
        reservationMintStartTimestamp = _reservationMintStartTimestamp;
        publicMintStartTimestamp = _publicMintStartTimestamp;
    }

    function addAdmin(address _admin) external onlyAdmin {
        isAdmin[_admin] = true;
    }

    function updateDevWallet(address _devWallet) external {
        require(isDev[msg.sender] == true, "You are not dev");

        isDev[devWallet] = false;
        devWallet = _devWallet;
        isDev[_devWallet] = true;
    }

    function setNftContract(address _nftContract) external onlyAdmin {
        nftContract = _nftContract;
    }

    function addMarketer(
        address _marketer,
        string memory _url,
        string memory _name
    ) external onlyAdmin {
        require(
            !marketerAddresses.contains(_marketer),
            "This marketer is registered already"
        );
        marketerAddresses.add(_marketer);

        MarketerPhotoInfo memory marketerPhoto = MarketerPhotoInfo(
            _marketer,
            _url,
            _name
        );
        marketerPhotoInfos[_marketer] = marketerPhoto;

        emit MarketerAdded(_marketer, _url, _name);
    }

    function removeMarketer(address _marketer) external onlyAdmin {
        require(
            marketerAddresses.contains(_marketer),
            "This address is not marketer"
        );
        marketerAddresses.remove(_marketer);

        emit MarketerRemoved(_marketer);
    }

    function addTeamMember(address _teamMember) external onlyAdmin {
        require(
            !teamAddresses.contains(_teamMember),
            "This team member is registered already"
        );
        teamAddresses.add(_teamMember);

        emit TeamMemberAdded(_teamMember);
    }

    function removeTeamMember(address _teamMember) external onlyAdmin {
        require(
            teamAddresses.contains(_teamMember),
            "This address is not team member"
        );
        teamAddresses.remove(_teamMember);

        emit TeamMemberRemoved(_teamMember);
    }

    function addReservationLinkInfo(
        string memory _link,
        NFTRarityType _rarityType,
        address _marketer
    ) external onlyAdmin {
        require(
            marketerAddresses.contains(_marketer),
            "This address is not marketer"
        );
        require(
            compareStrings(
                marketerReservationInfos[_marketer][_rarityType].link,
                ""
            ),
            "This marketer's current rarity reservation link is already registered"
        );

        reservationLinksCount++;
        reservationLinks[_link] = ReservationLinkInfo(
            reservationLinksCount,
            _rarityType,
            _link,
            _marketer,
            0,
            0
        );
        marketerReservationInfos[_marketer][_rarityType] = ReservationLinkInfo(
            reservationLinksCount,
            _rarityType,
            _link,
            _marketer,
            0,
            0
        );

        emit ReservationLinkInfoAdded(
            reservationLinksCount,
            _rarityType,
            _link,
            _marketer
        );
    }

    function compareStrings(string memory _a, string memory _b)
        public
        pure
        returns (bool)
    {
        return (keccak256(abi.encodePacked((_a))) ==
            keccak256(abi.encodePacked((_b))));
    }

    function setNFTInfo(
        NFTRarityType _rarityType,
        string memory _baseUri,
        uint256 _whitelistPrice,
        uint256 _reservationPrice,
        uint256 _publicPrice,
        uint16 _maxSupply,
        uint16 _whitelistMaxSupply,
        uint16 _publicMaxSupply,
        uint16 _teamMaxSupply,
        uint16 _reservationLimitByWallet
    ) external onlyAdmin {
        nftInfos[_rarityType] = NFTInfo(
            _baseUri,
            _whitelistPrice,
            _reservationPrice,
            _publicPrice,
            _maxSupply,
            0,
            0,
            _whitelistMaxSupply,
            // 0,
            _publicMaxSupply,
            // 0,
            _teamMaxSupply,
            0,
            _reservationLimitByWallet
        );
    }

    function updateBaseUri(NFTRarityType _rarityType, string memory _baseUri)
        external
        onlyAdmin
    {
        nftInfos[_rarityType].baseURI = _baseUri;
    }

    function updateWhitelistPrice(
        NFTRarityType _rarityType,
        uint256 _whitelistPrice
    ) external onlyAdmin {
        nftInfos[_rarityType].whitelistPrice = _whitelistPrice;
    }

    function updateReservationPrice(
        NFTRarityType _rarityType,
        uint256 _reservationPrice
    ) external onlyAdmin {
        nftInfos[_rarityType].reservationPrice = _reservationPrice;
    }

    function updatePublicPrice(NFTRarityType _rarityType, uint256 _publicPrice)
        external
        onlyAdmin
    {
        nftInfos[_rarityType].publicPrice = _publicPrice;
    }

    function reserveNFTsByUser(
        uint16 _quantity,
        NFTRarityType _rarityType,
        string memory _reservationLink
    ) external {
        ReservationLinkInfo memory reservationLink = reservationLinks[
            _reservationLink
        ];
        UserInfo memory userInfo = userInfos[msg.sender][_rarityType];
        NFTInfo memory nftInfo = nftInfos[_rarityType];

        // reservation link is valid
        require(
            compareStrings(reservationLink.link, _reservationLink),
            "This reservation link is not valid"
        );
        // reservation time is valid
        require(
            block.timestamp < publicMintStartTimestamp,
            "Reservation time is not valid"
        );
        // nft rarity type is valid
        require(
            reservationLink.rarityType == _rarityType,
            "Rarity type is not valid"
        );
        // quantity is valid
        require(_quantity > 0, "Quantity should be more than 0");
        require(
            _quantity + userInfo.reserved <= nftInfo.reservationLimitByWallet,
            "Maximum reserve amount in wallet exceeded"
        );
        require(
            _quantity + nftInfo.reserved <= nftInfo.publicMaxSupply,
            "Maximum reserve amount in this rarity exceeded"
        );
        // referral marketer is the same
        require(
            userInfo.reserved == 0 ||
                (userInfo.reserved > 0 &&
                    compareStrings(
                        userInfos[msg.sender][_rarityType].link,
                        _reservationLink
                    )),
            "Referral marketer is not the same"
        );
        if (userInfo.reserved == 0) {
            // new user
            userInfos[msg.sender][_rarityType] = UserInfo(
                _rarityType,
                reservationLink.marketer,
                _reservationLink,
                0,
                0,
                0
            );
        }

        userInfos[msg.sender][_rarityType].reserved += _quantity;
        reservationLinks[_reservationLink].reserved += _quantity;
        nftInfos[_rarityType].reserved += _quantity;
        marketerReservationInfos[reservationLink.marketer][_rarityType]
            .reserved += _quantity;

        emit NFTReserved(msg.sender, _rarityType, _quantity);
    }

    function whitelistMint(
        NFTRarityType _rarityType,
        uint16 _quantity,
        bytes32[] calldata _merkleProof
    ) external payable {
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        require(
            MerkleProof.verify(_merkleProof, whitelistMerkleRoot, leaf),
            "Invalid Merkle Proof"
        );
        require(_quantity > 0, "Quantity cannot be zero");
        NFTInfo memory nftInfo = nftInfos[_rarityType];
        require(
            block.timestamp >= whitelistMintStartTimestamp &&
                block.timestamp < reservationMintStartTimestamp,
            "Whitelist mint is not active"
        );
        require(
            nftInfo.currentSupply + _quantity <= nftInfo.whitelistMaxSupply,
            "Max whitelist mint reached"
        );
        require(
            nftInfo.whitelistPrice * _quantity <= msg.value,
            "Insufficient funds sent"
        );

        mintNFT(nftInfo, _rarityType, _quantity);
        payable(devWallet).transfer((msg.value * devFee) / totalPercent);
    }

    function reservationMint(NFTRarityType _rarityType, uint16 _quantity)
        external
        payable
    {
        require(_quantity > 0, "Quantity cannot be zero");
        UserInfo memory userInfo = userInfos[msg.sender][_rarityType];
        NFTInfo memory nftInfo = nftInfos[_rarityType];
        require(
            block.timestamp >= reservationMintStartTimestamp &&
                block.timestamp < publicMintStartTimestamp,
            "Reservation mint is not active"
        );
        require(
            userInfo.minted + _quantity <= userInfo.reserved,
            "Reservation mint amount in the wallet reached"
        );
        require(
            nftInfo.reservationPrice * _quantity <= msg.value,
            "Insufficient funds sent"
        );

        mintNFT(nftInfo, _rarityType, _quantity);
        reservationLinks[userInfo.link].minted += _quantity;
        userInfos[msg.sender][_rarityType].reserveMinted += _quantity;
        marketerReservationInfos[userInfo.referralMarketer][_rarityType]
            .minted += _quantity;

        payable(userInfo.referralMarketer).transfer(
            (msg.value * marketerFee) / totalPercent
        );
        payable(devWallet).transfer((msg.value * devFee) / totalPercent);
    }

    function publicMint(NFTRarityType _rarityType, uint16 _quantity)
        external
        payable
    {
        require(_quantity > 0, "Quantity cannot be zero");
        NFTInfo memory nftInfo = nftInfos[_rarityType];
        require(
            block.timestamp >= publicMintStartTimestamp,
            "Public mint is not active"
        );
        require(
            nftInfo.currentSupply + _quantity <= nftInfo.maxSupply,
            "Public mint amount in the rarity type reached"
        );
        require(
            nftInfo.publicPrice * _quantity <= msg.value,
            "Insufficient funds sent"
        );

        mintNFT(nftInfo, _rarityType, _quantity);
        payable(devWallet).transfer((msg.value * devFee) / totalPercent);
    }

    function teamMint(NFTRarityType _rarityType, uint16 _quantity)
        external
        payable
    {
        require(_quantity > 0, "Quantity cannot be zero");
        require(teamAddresses.contains(msg.sender), "Not team member");
        NFTInfo memory nftInfo = nftInfos[_rarityType];
        require(
            block.timestamp >= publicMintStartTimestamp,
            "Team mint is not active"
        );
        require(
            nftInfo.currentSupply + _quantity <= nftInfo.maxSupply,
            "Team mint amount in the rarity type reached"
        );

        mintNFT(nftInfo, _rarityType, _quantity);
    }

    function withdraw() external onlyAdmin {
        payable(msg.sender).transfer(address(this).balance);
    }

    function setWhitelistMerkleRoot(bytes32 _whitelistMerkleRoot)
        external
        onlyAdmin
    {
        whitelistMerkleRoot = _whitelistMerkleRoot;
    }

    function getMarketers() public view returns (MarketerTotalInfo[] memory) {
        uint256 numberOfMarketers = marketerAddresses.length();

        address[] memory _marketerAddresses = new address[](numberOfMarketers);
        MarketerTotalInfo[] memory marketers = new MarketerTotalInfo[](
            numberOfMarketers
        );

        for (uint i = 0; i < numberOfMarketers; i++) {
            _marketerAddresses[i] = marketerAddresses.at(i);
        }

        for (uint i = 0; i < numberOfMarketers; i++) {
            marketers[i].photoInfo = marketerPhotoInfos[_marketerAddresses[i]];
            marketers[i].common = marketerReservationInfos[
                _marketerAddresses[i]
            ][NFTRarityType.Common];
            marketers[i].uncommon = marketerReservationInfos[
                _marketerAddresses[i]
            ][NFTRarityType.Uncommon];
            marketers[i].rare = marketerReservationInfos[_marketerAddresses[i]][
                NFTRarityType.Rare
            ];
            marketers[i].legendary = marketerReservationInfos[
                _marketerAddresses[i]
            ][NFTRarityType.Legendary];
        }

        return marketers;
    }

    function getNFTInfos() public view returns (NFTInfo[] memory) {
        NFTInfo[] memory nftInfoData = new NFTInfo[](4);
        nftInfoData[0] = nftInfos[NFTRarityType.Common];
        nftInfoData[1] = nftInfos[NFTRarityType.Uncommon];
        nftInfoData[2] = nftInfos[NFTRarityType.Rare];
        nftInfoData[3] = nftInfos[NFTRarityType.Legendary];

        return nftInfoData;
    }

    function getTeamAddresses() public view returns (address[] memory) {
        uint256 numberOfTeamMembers = teamAddresses.length();
        address[] memory _teamAddresses = new address[](numberOfTeamMembers);

        for (uint i = 0; i < numberOfTeamMembers; i++) {
            _teamAddresses[i] = teamAddresses.at(i);
        }

        return _teamAddresses;
    }

    function getMarketerAddresses() public view returns (address[] memory) {
        uint256 numberOfMarketerMembers = marketerAddresses.length();
        address[] memory _marketerAddresses = new address[](
            numberOfMarketerMembers
        );

        for (uint i = 0; i < numberOfMarketerMembers; i++) {
            _marketerAddresses[i] = marketerAddresses.at(i);
        }

        return _marketerAddresses;
    }

    function mintNFT(
        NFTInfo memory nftInfo,
        NFTRarityType _rarityType,
        uint16 _quantity
    ) internal {
        uint256 totalMinted = IContract(nftContract).getTotalSupply();

        for (uint i; i < _quantity; i++) {
            string memory uri = string(
                abi.encodePacked(
                    nftInfo.baseURI,
                    "/",
                    Strings.toString(nftInfo.currentSupply + i + 1),
                    ".json"
                )
            );
            IContract(nftContract).mint(msg.sender, uri, totalMinted + i + 1);
            rarityByTokenId[totalMinted + i + 1] = _rarityType;
        }
        nftInfos[_rarityType].currentSupply += _quantity;
        userInfos[msg.sender][_rarityType].minted += _quantity;
    }
}