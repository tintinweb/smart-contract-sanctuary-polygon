// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../token/ERC20/extensions/IERC20MetadataUpgradeable.sol";

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20Upgradeable.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20MetadataUpgradeable is IERC20Upgradeable {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
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
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/cryptography/ECDSA.sol)

pragma solidity ^0.8.0;

import "../StringsUpgradeable.sol";

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSAUpgradeable {
    enum RecoverError {
        NoError,
        InvalidSignature,
        InvalidSignatureLength,
        InvalidSignatureS,
        InvalidSignatureV // Deprecated in v4.8
    }

    function _throwError(RecoverError error) private pure {
        if (error == RecoverError.NoError) {
            return; // no error: do nothing
        } else if (error == RecoverError.InvalidSignature) {
            revert("ECDSA: invalid signature");
        } else if (error == RecoverError.InvalidSignatureLength) {
            revert("ECDSA: invalid signature length");
        } else if (error == RecoverError.InvalidSignatureS) {
            revert("ECDSA: invalid signature 's' value");
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature` or error string. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     *
     * Documentation for signature generation:
     * - with https://web3js.readthedocs.io/en/v1.3.4/web3-eth-accounts.html#sign[Web3.js]
     * - with https://docs.ethers.io/v5/api/signer/#Signer-signMessage[ethers]
     *
     * _Available since v4.3._
     */
    function tryRecover(bytes32 hash, bytes memory signature) internal pure returns (address, RecoverError) {
        if (signature.length == 65) {
            bytes32 r;
            bytes32 s;
            uint8 v;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            /// @solidity memory-safe-assembly
            assembly {
                r := mload(add(signature, 0x20))
                s := mload(add(signature, 0x40))
                v := byte(0, mload(add(signature, 0x60)))
            }
            return tryRecover(hash, v, r, s);
        } else {
            return (address(0), RecoverError.InvalidSignatureLength);
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature`. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     */
    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, signature);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `r` and `vs` short-signature fields separately.
     *
     * See https://eips.ethereum.org/EIPS/eip-2098[EIP-2098 short signatures]
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address, RecoverError) {
        bytes32 s = vs & bytes32(0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff);
        uint8 v = uint8((uint256(vs) >> 255) + 27);
        return tryRecover(hash, v, r, s);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `r and `vs` short-signature fields separately.
     *
     * _Available since v4.2._
     */
    function recover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, r, vs);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `v`,
     * `r` and `s` signature fields separately.
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address, RecoverError) {
        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (301): 0 < s < secp256k1n ÷ 2 + 1, and for v in (302): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) {
            return (address(0), RecoverError.InvalidSignatureS);
        }

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        if (signer == address(0)) {
            return (address(0), RecoverError.InvalidSignature);
        }

        return (signer, RecoverError.NoError);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `v`,
     * `r` and `s` signature fields separately.
     */
    function recover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, v, r, s);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from a `hash`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from `s`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes memory s) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n", StringsUpgradeable.toString(s.length), s));
    }

    /**
     * @dev Returns an Ethereum Signed Typed Data, created from a
     * `domainSeparator` and a `structHash`. This produces hash corresponding
     * to the one signed with the
     * https://eips.ethereum.org/EIPS/eip-712[`eth_signTypedData`]
     * JSON-RPC method as part of EIP-712.
     *
     * See {recover}.
     */
    function toTypedDataHash(bytes32 domainSeparator, bytes32 structHash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
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
library MerkleProofUpgradeable {
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
library MathUpgradeable {
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

import "./math/MathUpgradeable.sol";

/**
 * @dev String operations.
 */
library StringsUpgradeable {
    bytes16 private constant _SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        unchecked {
            uint256 length = MathUpgradeable.log10(value) + 1;
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
            return toHexString(value, MathUpgradeable.log256(value) + 1);
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

pragma solidity ^0.8.0;

import { IAccessControl } from './IAccessControl.sol';
import { AccessControlInternal } from './AccessControlInternal.sol';

/**
 * @title Role-based access control system
 * @dev derived from https://github.com/OpenZeppelin/openzeppelin-contracts (MIT license)
 */
abstract contract AccessControl is IAccessControl, AccessControlInternal {
    /**
     * @inheritdoc IAccessControl
     */
    function grantRole(bytes32 role, address account)
        external
        onlyRole(_getRoleAdmin(role))
    {
        _grantRole(role, account);
    }

    /**
     * @inheritdoc IAccessControl
     */
    function hasRole(bytes32 role, address account)
        external
        view
        returns (bool)
    {
        return _hasRole(role, account);
    }

    /**
     * @inheritdoc IAccessControl
     */
    function getRoleAdmin(bytes32 role) external view returns (bytes32) {
        return _getRoleAdmin(role);
    }

    /**
     * @inheritdoc IAccessControl
     */
    function revokeRole(bytes32 role, address account)
        external
        onlyRole(_getRoleAdmin(role))
    {
        _revokeRole(role, account);
    }

    /**
     * @inheritdoc IAccessControl
     */
    function renounceRole(bytes32 role) external {
        _renounceRole(role);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { EnumerableSet } from '../../data/EnumerableSet.sol';
import { AddressUtils } from '../../utils/AddressUtils.sol';
import { UintUtils } from '../../utils/UintUtils.sol';
import { IAccessControlInternal } from './IAccessControlInternal.sol';
import { AccessControlStorage } from './AccessControlStorage.sol';

/**
 * @title Role-based access control system
 * @dev derived from https://github.com/OpenZeppelin/openzeppelin-contracts (MIT license)
 */
abstract contract AccessControlInternal is IAccessControlInternal {
    using AddressUtils for address;
    using EnumerableSet for EnumerableSet.AddressSet;
    using UintUtils for uint256;

    modifier onlyRole(bytes32 role) {
        _checkRole(role);
        _;
    }

    /*
     * @notice query whether role is assigned to account
     * @param role role to query
     * @param account account to query
     * @return whether role is assigned to account
     */
    function _hasRole(bytes32 role, address account)
        internal
        view
        virtual
        returns (bool)
    {
        return
            AccessControlStorage.layout().roles[role].members.contains(account);
    }

    /**
     * @notice revert if sender does not have given role
     * @param role role to query
     */
    function _checkRole(bytes32 role) internal view virtual {
        _checkRole(role, msg.sender);
    }

    /**
     * @notice revert if given account does not have given role
     * @param role role to query
     * @param account to query
     */
    function _checkRole(bytes32 role, address account) internal view virtual {
        if (!_hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        'AccessControl: account ',
                        account.toString(),
                        ' is missing role ',
                        uint256(role).toHexString(32)
                    )
                )
            );
        }
    }

    /*
     * @notice query admin role for given role
     * @param role role to query
     * @return admin role
     */
    function _getRoleAdmin(bytes32 role)
        internal
        view
        virtual
        returns (bytes32)
    {
        return AccessControlStorage.layout().roles[role].adminRole;
    }

    /**
     * @notice set role as admin role
     * @param role role to set
     * @param adminRole admin role to set
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        bytes32 previousAdminRole = _getRoleAdmin(role);
        AccessControlStorage.layout().roles[role].adminRole = adminRole;
        emit RoleAdminChanged(role, previousAdminRole, adminRole);
    }

    /*
     * @notice assign role to given account
     * @param role role to assign
     * @param account recipient of role assignment
     */
    function _grantRole(bytes32 role, address account) internal virtual {
        AccessControlStorage.layout().roles[role].members.add(account);
        emit RoleGranted(role, account, msg.sender);
    }

    /*
     * @notice unassign role from given account
     * @param role role to unassign
     * @parm account
     */
    function _revokeRole(bytes32 role, address account) internal virtual {
        AccessControlStorage.layout().roles[role].members.remove(account);
        emit RoleRevoked(role, account, msg.sender);
    }

    /**
     * @notice relinquish role
     * @param role role to relinquish
     */
    function _renounceRole(bytes32 role) internal virtual {
        _revokeRole(role, msg.sender);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { EnumerableSet } from '../../data/EnumerableSet.sol';

library AccessControlStorage {
    struct RoleData {
        EnumerableSet.AddressSet members;
        bytes32 adminRole;
    }

    struct Layout {
        mapping(bytes32 => RoleData) roles;
    }

    bytes32 internal constant DEFAULT_ADMIN_ROLE = 0x00;

    bytes32 internal constant STORAGE_SLOT =
        keccak256('solidstate.contracts.storage.AccessControl');

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { IAccessControlInternal } from './IAccessControlInternal.sol';

/**
 * @title AccessControl interface
 */
interface IAccessControl is IAccessControlInternal {
    /*
     * @notice query whether role is assigned to account
     * @param role role to query
     * @param account account to query
     * @return whether role is assigned to account
     */
    function hasRole(bytes32 role, address account)
        external
        view
        returns (bool);

    /*
     * @notice query admin role for given role
     * @param role role to query
     * @return admin role
     */
    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    /*
     * @notice assign role to given account
     * @param role role to assign
     * @param account recipient of role assignment
     */
    function grantRole(bytes32 role, address account) external;

    /*
     * @notice unassign role from given account
     * @param role role to unassign
     * @parm account
     */
    function revokeRole(bytes32 role, address account) external;

    /**
     * @notice relinquish role
     * @param role role to relinquish
     */
    function renounceRole(bytes32 role) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @title Partial AccessControl interface needed by internal functions
 */
interface IAccessControlInternal {
    event RoleAdminChanged(
        bytes32 indexed role,
        bytes32 indexed previousAdminRole,
        bytes32 indexed newAdminRole
    );

    event RoleGranted(
        bytes32 indexed role,
        address indexed account,
        address indexed sender
    );

    event RoleRevoked(
        bytes32 indexed role,
        address indexed account,
        address indexed sender
    );
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

/**
 * @title Set implementation with enumeration functions
 * @dev derived from https://github.com/OpenZeppelin/openzeppelin-contracts (MIT license)
 */
library EnumerableSet {
    error EnumerableSet__IndexOutOfBounds();

    struct Set {
        bytes32[] _values;
        // 1-indexed to allow 0 to signify nonexistence
        mapping(bytes32 => uint256) _indexes;
    }

    struct Bytes32Set {
        Set _inner;
    }

    struct AddressSet {
        Set _inner;
    }

    struct UintSet {
        Set _inner;
    }

    function at(Bytes32Set storage set, uint256 index)
        internal
        view
        returns (bytes32)
    {
        return _at(set._inner, index);
    }

    function at(AddressSet storage set, uint256 index)
        internal
        view
        returns (address)
    {
        return address(uint160(uint256(_at(set._inner, index))));
    }

    function at(UintSet storage set, uint256 index)
        internal
        view
        returns (uint256)
    {
        return uint256(_at(set._inner, index));
    }

    function contains(Bytes32Set storage set, bytes32 value)
        internal
        view
        returns (bool)
    {
        return _contains(set._inner, value);
    }

    function contains(AddressSet storage set, address value)
        internal
        view
        returns (bool)
    {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    function contains(UintSet storage set, uint256 value)
        internal
        view
        returns (bool)
    {
        return _contains(set._inner, bytes32(value));
    }

    function indexOf(Bytes32Set storage set, bytes32 value)
        internal
        view
        returns (uint256)
    {
        return _indexOf(set._inner, value);
    }

    function indexOf(AddressSet storage set, address value)
        internal
        view
        returns (uint256)
    {
        return _indexOf(set._inner, bytes32(uint256(uint160(value))));
    }

    function indexOf(UintSet storage set, uint256 value)
        internal
        view
        returns (uint256)
    {
        return _indexOf(set._inner, bytes32(value));
    }

    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    function add(Bytes32Set storage set, bytes32 value)
        internal
        returns (bool)
    {
        return _add(set._inner, value);
    }

    function add(AddressSet storage set, address value)
        internal
        returns (bool)
    {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    function remove(Bytes32Set storage set, bytes32 value)
        internal
        returns (bool)
    {
        return _remove(set._inner, value);
    }

    function remove(AddressSet storage set, address value)
        internal
        returns (bool)
    {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    function remove(UintSet storage set, uint256 value)
        internal
        returns (bool)
    {
        return _remove(set._inner, bytes32(value));
    }

    function toArray(Bytes32Set storage set)
        internal
        view
        returns (bytes32[] memory)
    {
        uint256 len = _length(set._inner);
        bytes32[] memory arr = new bytes32[](len);

        unchecked {
            for (uint256 index; index < len; ++index) {
                arr[index] = at(set, index);
            }
        }

        return arr;
    }

    function toArray(AddressSet storage set)
        internal
        view
        returns (address[] memory)
    {
        uint256 len = _length(set._inner);
        address[] memory arr = new address[](len);

        unchecked {
            for (uint256 index; index < len; ++index) {
                arr[index] = at(set, index);
            }
        }

        return arr;
    }

    function toArray(UintSet storage set)
        internal
        view
        returns (uint256[] memory)
    {
        uint256 len = _length(set._inner);
        uint256[] memory arr = new uint256[](len);

        unchecked {
            for (uint256 index; index < len; ++index) {
                arr[index] = at(set, index);
            }
        }

        return arr;
    }

    function _at(Set storage set, uint256 index)
        private
        view
        returns (bytes32)
    {
        if (index >= set._values.length)
            revert EnumerableSet__IndexOutOfBounds();
        return set._values[index];
    }

    function _contains(Set storage set, bytes32 value)
        private
        view
        returns (bool)
    {
        return set._indexes[value] != 0;
    }

    function _indexOf(Set storage set, bytes32 value)
        private
        view
        returns (uint256)
    {
        unchecked {
            return set._indexes[value] - 1;
        }
    }

    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    function _remove(Set storage set, bytes32 value) private returns (bool) {
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) {
            unchecked {
                bytes32 last = set._values[set._values.length - 1];

                // move last value to now-vacant index

                set._values[valueIndex - 1] = last;
                set._indexes[last] = valueIndex;
            }
            // clear last index

            set._values.pop();
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import { PausableStorage } from './PausableStorage.sol';

/**
 * @title Internal functions for Pausable security control module.
 */
abstract contract PausableInternal {
    using PausableStorage for PausableStorage.Layout;

    error Pausable__Paused();
    error Pausable__NotPaused();

    event Paused(address account);
    event Unpaused(address account);

    modifier whenNotPaused() {
        if (_paused()) revert Pausable__Paused();
        _;
    }

    modifier whenPaused() {
        if (!_paused()) revert Pausable__NotPaused();
        _;
    }

    /**
     * @notice query the contracts paused state.
     * @return true if paused, false if unpaused.
     */
    function _paused() internal view virtual returns (bool) {
        return PausableStorage.layout().paused;
    }

    /**
     * @notice Triggers paused state, when contract is unpaused.
     */
    function _pause() internal virtual whenNotPaused {
        PausableStorage.layout().paused = true;
        emit Paused(msg.sender);
    }

    /**
     * @notice Triggers unpaused state, when contract is paused.
     */
    function _unpause() internal virtual whenPaused {
        PausableStorage.layout().paused = false;
        emit Unpaused(msg.sender);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

library PausableStorage {
    struct Layout {
        bool paused;
    }

    bytes32 internal constant STORAGE_SLOT =
        keccak256('solidstate.contracts.storage.Pausable');

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import { UintUtils } from './UintUtils.sol';

library AddressUtils {
    using UintUtils for uint256;

    error AddressUtils__InsufficientBalance();
    error AddressUtils__NotContract();
    error AddressUtils__SendValueFailed();

    function toString(address account) internal pure returns (string memory) {
        return uint256(uint160(account)).toHexString(20);
    }

    function isContract(address account) internal view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    function sendValue(address payable account, uint256 amount) internal {
        (bool success, ) = account.call{ value: amount }('');
        if (!success) revert AddressUtils__SendValueFailed();
    }

    function functionCall(address target, bytes memory data)
        internal
        returns (bytes memory)
    {
        return
            functionCall(target, data, 'AddressUtils: failed low-level call');
    }

    function functionCall(
        address target,
        bytes memory data,
        string memory error
    ) internal returns (bytes memory) {
        return _functionCallWithValue(target, data, 0, error);
    }

    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return
            functionCallWithValue(
                target,
                data,
                value,
                'AddressUtils: failed low-level call with value'
            );
    }

    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory error
    ) internal returns (bytes memory) {
        if (value > address(this).balance)
            revert AddressUtils__InsufficientBalance();
        return _functionCallWithValue(target, data, value, error);
    }

    function _functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory error
    ) private returns (bytes memory) {
        if (!isContract(target)) revert AddressUtils__NotContract();

        (bool success, bytes memory returnData) = target.call{ value: value }(
            data
        );

        if (success) {
            return returnData;
        } else if (returnData.length > 0) {
            assembly {
                let returnData_size := mload(returnData)
                revert(add(32, returnData), returnData_size)
            }
        } else {
            revert(error);
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import { ReentrancyGuardStorage } from './ReentrancyGuardStorage.sol';

/**
 * @title Utility contract for preventing reentrancy attacks
 */
abstract contract ReentrancyGuard {
    error ReentrancyGuard__ReentrantCall();

    modifier nonReentrant() {
        ReentrancyGuardStorage.Layout storage l = ReentrancyGuardStorage
            .layout();
        if (l.status == 2) revert ReentrancyGuard__ReentrantCall();
        l.status = 2;
        _;
        l.status = 1;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

library ReentrancyGuardStorage {
    struct Layout {
        uint256 status;
    }

    bytes32 internal constant STORAGE_SLOT =
        keccak256('solidstate.contracts.storage.ReentrancyGuard');

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

/**
 * @title utility functions for uint256 operations
 * @dev derived from https://github.com/OpenZeppelin/openzeppelin-contracts/ (MIT license)
 */
library UintUtils {
    error UintUtils__InsufficientHexLength();

    bytes16 private constant HEX_SYMBOLS = '0123456789abcdef';

    function add(uint256 a, int256 b) internal pure returns (uint256) {
        return b < 0 ? sub(a, -b) : a + uint256(b);
    }

    function sub(uint256 a, int256 b) internal pure returns (uint256) {
        return b < 0 ? add(a, -b) : a - uint256(b);
    }

    function toString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return '0';
        }

        uint256 temp = value;
        uint256 digits;

        while (temp != 0) {
            digits++;
            temp /= 10;
        }

        bytes memory buffer = new bytes(digits);

        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }

        return string(buffer);
    }

    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return '0x00';
        }

        uint256 length = 0;

        for (uint256 temp = value; temp != 0; temp >>= 8) {
            unchecked {
                length++;
            }
        }

        return toHexString(value, length);
    }

    function toHexString(uint256 value, uint256 length)
        internal
        pure
        returns (string memory)
    {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = '0';
        buffer[1] = 'x';

        unchecked {
            for (uint256 i = 2 * length + 1; i > 1; --i) {
                buffer[i] = HEX_SYMBOLS[value & 0xf];
                value >>= 4;
            }
        }

        if (value != 0) revert UintUtils__InsufficientHexLength();

        return string(buffer);
    }
}

// SPDX-License-Identifier: CovestFinance.V1.0.0

pragma solidity 0.8.17;

import {IInsuranceBaseStorage} from "../interfaces/IInsuranceBaseStorage.sol";

library InsuranceBaseStorage {
    struct Layout {
        address provider;
        address currency;
        address upfrontManager;
        address validatorManager;
        address riskCarrierManager;
        string poolName;
        string poolId;
        string[] policyList;
        uint256 policyCount;
        bytes32 pricingMerkleRoot;
        IInsuranceBaseStorage.ClaimData[] claimList;
        IInsuranceBaseStorage.ClaimRules claimRules;
        /* policyId => policyData of the policyId */
        mapping(string => IInsuranceBaseStorage.PolicyData) policies;
        /* policyId => claimId array of the policyId */
        mapping(string => uint256[]) claimIdsByPolicyId;
        /* policyId => isPolicyExist(true or false) */
        mapping(string => bool) isPolicyExist;
        mapping(string => bool) isIPFSClaimExist;
    }

    bytes32 internal constant SUPER_MANAGER_LEVEL =
        keccak256("SUPER_MANAGER_LEVEL");

    bytes32 internal constant GENERAL_MANAGER_LEVEL =
        keccak256("GENERAL_MANAGER_LEVEL");

    bytes32 internal constant GOVERANACE_BOARD_LEVEL =
        keccak256("GOVERANACE_BOARD_LEVEL");

    bytes32 internal constant STORAGE_SLOT =
        keccak256("covest.contracts.insurance.storage");

    function layout() internal pure returns (Layout storage l) {
        bytes32 position = STORAGE_SLOT;
        assembly {
            l.slot := position
        }
    }
}

// SPDX-License-Identifier: CovestFinance.V1.0.0
pragma solidity 0.8.17;

interface IInsuranceBaseStorage {
    enum PolicyStatus {
        NotInsured,
        Active,
        Cancelled, /* Redeemed */
        Expired
    }

    enum ClaimStatus {
        Submitted,
        Evaluated,
        Voting,
        Cancelled,
        Accepted,
        Rejected
    }

    struct PolicyData {
        address policyholder;
        address currency;
        string policyId;
        uint40 coverageStart;
        uint40 coverageEnd;
        uint40 claimRequestUntil;
        uint256 premium; // decimals 18 //
        uint256 sumInsured; // decimals 18 //
        uint256 accumulatedClaimReserveAmount; // decimals 18 //
        uint256 accumulatedClaimPaidAmount; // decimals 18 //
        uint256 redeemAmount; // decimals 18 //
        bool cancelled;
        PolicyStatus status;
    }

    struct ClaimRules {
        uint8 claimAssessmentPeriod; // 1 = 1 days, 10 = 10 days , => block.timestamp + (1 days * claimAssessmentPeriod)//
        uint8 claimConsensusRatio; /// 100 = 100% //
        uint256 rewardPerClaimAssessment;
        uint8 validatorRewardRatio;
        uint8 voterRewardRatio;
        uint256 claimAmountPerOnHoldStaking;
        uint256 pointPerClaimAssessment;
    }

    struct ClaimData {
        string policyId;
        string ipfsHash;
        uint40 claimSubmittedAt;
        uint40 claimExpiresAt;
        uint256 claimId;
        uint256 claimRequestedAmount;
        uint256 claimApprovedAmount;
        address currency;
        address claimValidator;
        ClaimStatus status;
    }
}

// SPDX-License-Identifier: CovestFinance.V1.0.0
pragma solidity 0.8.17;

import {IPolicyManagerInternal} from "./IPolicyManagerInternal.sol";
import {IRiskCarrierBaseStorage} from "../../interfaces/IRiskCarrierBaseStorage.sol";

interface IPolicyManager is IPolicyManagerInternal {
    struct BuyPolicyParams {
        string policyId;
        string policyType;
        uint40 coverageStart;
        uint40 coverageEnd;
        uint40 claimRequestUntil;
        uint256 premium; // 10**18 //
        uint256 sumInsured; // 10**18 //
        uint8 premiumRate; // 1000000 = 100%, 100000 = 10%, 10000 = 1% , 1000 = 0.1% //
        uint8 riskCarrierRatio;
        uint40 signatureValidUntil;
        uint8 v;
        bytes32 r;
        bytes32 s;
        bytes32[] proof;
    }

    function buyPolicy(
        BuyPolicyParams memory _bp_,
        IRiskCarrierBaseStorage.RiskTransferParams[] memory _rt_
    ) external returns (bool);

    function decimals() external pure returns (uint8);

    function getHashBuyPolicy(HashBuyPolicyParams memory _data_)
        external
        view
        returns (bytes32);

    function getHashRedeemPolicy(HashRedeemPolicyParams memory _data_)
        external
        view
        returns (bytes32);

    function redeemPolicy(RedeemPolicyParams memory _redeemData_)
        external
        returns (bool);
}

// SPDX-License-Identifier: CovestFinance.V1.0.0
pragma solidity 0.8.17;

interface IPolicyManagerInternal {
    event PolicyIssued(
        address indexed user,
        string indexed policyId,
        uint40 coverageStart,
        uint40 coverageEnd,
        uint40 claimExpiresAt,
        uint256 sumInsured
    );

    event PolicyRedeemed(
        address indexed user,
        string indexed policyId,
        uint256 redeemAmount,
        uint8 redeemRate,
        uint8 riskCarrierRatio
    );

    struct IssuePolicyParams {
        string policyId;
        uint40 coverageStart;
        uint40 coverageEnd;
        uint40 claimExpiresAt;
        uint256 premium; // decimals 18 //
        uint256 sumInsured; // maxCoveraged decimals 18 //
        uint40 signatureValidUntil;
        uint8 v;
        bytes32 r;
        bytes32 s;
    }

    struct HashBuyPolicyParams {
        address user;
        string policyId;
        uint40 coverageStart;
        uint40 coverageEnd;
        uint40 claimRequestUntil;
        uint256 premium;
        uint256 sumInsured;
        uint40 signatureValidUntil;
    }

    struct RedeemPolicyParams {
        string policyId;
        uint8 redeemRate;
        uint8 riskCarrierRatio;
        uint40 signatureValidUntil;
        uint8 v;
        bytes32 r;
        bytes32 s;
    }

    struct HashRedeemPolicyParams {
        address user;
        string policyId;
        uint8 redeemRate;
        uint8 riskCarrierRatio;
        uint40 signatureValidUntil;
    }
}

// SPDX-License-Identifier: CovestFinance.V1.0.0
pragma solidity 0.8.17;

import {InsuranceBaseStorage} from "../base/InsuranceBaseStorage.sol";
import {IInsuranceBaseStorage} from "../interfaces/IInsuranceBaseStorage.sol";
import {IPolicyManagerInternal} from "../interfaces/IPolicyManagerInternal.sol";
import {ECDSAUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/cryptography/ECDSAUpgradeable.sol";
import {MerkleProofUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/cryptography/MerkleProofUpgradeable.sol";

abstract contract PolicyManagerInternalFacet is IPolicyManagerInternal {
    using InsuranceBaseStorage for InsuranceBaseStorage.Layout;

    function _issuePolicy(IssuePolicyParams memory _issueData_) internal {
        InsuranceBaseStorage.Layout storage _ibs_ = InsuranceBaseStorage
            .layout();

        require(
            _ibs_.isPolicyExist[_issueData_.policyId] == false,
            "Policy already exist"
        );

        require(
            _issueData_.coverageStart > block.timestamp,
            "Coverage start must be in the future"
        );

        require(
            _issueData_.coverageEnd > _issueData_.coverageStart,
            "Coverage end must be after coverage start"
        );

        require(
            _issueData_.claimExpiresAt > _issueData_.coverageEnd,
            "Claim expires at must be after coverage end"
        );

        _ibs_.isPolicyExist[_issueData_.policyId] = true;
        _ibs_.policies[_issueData_.policyId] = IInsuranceBaseStorage.PolicyData(
            msg.sender,
            _ibs_.currency,
            _issueData_.policyId,
            _issueData_.coverageStart,
            _issueData_.coverageEnd,
            _issueData_.claimExpiresAt,
            _issueData_.premium,
            _issueData_.sumInsured,
            0,
            0,
            0,
            false,
            IInsuranceBaseStorage.PolicyStatus.Active
        );

        _ibs_.policyList.push(_issueData_.policyId);

        emit PolicyIssued(
            msg.sender,
            _issueData_.policyId,
            _issueData_.coverageStart,
            _issueData_.coverageEnd,
            _issueData_.claimExpiresAt,
            _issueData_.sumInsured
        );
    }

    function _redeemPolicy(RedeemPolicyParams memory _redeemData_) internal {
        InsuranceBaseStorage.Layout storage _ibs_ = InsuranceBaseStorage
            .layout();

        require(_ibs_.isPolicyExist[_redeemData_.policyId] == true, "PINE");

        require(
            _getPolicyStatus(_redeemData_.policyId) ==
                IInsuranceBaseStorage.PolicyStatus.Active,
            "PINA"
        );

        require(_redeemData_.redeemRate <= 100, "RPINLTE100");

        require(
            _redeemData_.riskCarrierRatio <= _redeemData_.redeemRate,
            "RCRLTRR"
        );

        _ibs_.policies[_redeemData_.policyId].status = IInsuranceBaseStorage
            .PolicyStatus
            .Cancelled;

        _ibs_.policies[_redeemData_.policyId].redeemAmount =
            (_ibs_.policies[_redeemData_.policyId].premium *
                _redeemData_.redeemRate) /
            100;

        emit PolicyRedeemed(
            msg.sender,
            _redeemData_.policyId,
            _ibs_.policies[_redeemData_.policyId].redeemAmount,
            _redeemData_.redeemRate,
            _redeemData_.riskCarrierRatio
        );
    }

    function _verifyMerkleProof(
        bytes32[] memory _proof_,
        string memory _policyType_, // cargo => general_01 || ไปรษณีญ์ => จังหวัด_อำเภอ_ตำบล_รหัสปณ, value //
        uint256 _premiumRate_
    ) internal view returns (bool) {
        require(_premiumRate_ <= 1 * 10**6 && _premiumRate_ > 0, "IPR");
        return
            MerkleProofUpgradeable.verify(
                _proof_,
                InsuranceBaseStorage.layout().pricingMerkleRoot,
                keccak256(abi.encodePacked(_policyType_, _premiumRate_))
            );
    }

    function _getHashBuyPolicy(HashBuyPolicyParams memory _data_)
        internal
        view
        returns (bytes32)
    {
        return
            keccak256(
                abi.encodePacked(
                    _data_.user,
                    _data_.policyId,
                    _data_.coverageStart,
                    _data_.coverageEnd,
                    _data_.claimRequestUntil,
                    _data_.premium,
                    _data_.sumInsured,
                    _data_.signatureValidUntil,
                    address(this),
                    block.chainid
                )
            );
    }

    function _verifyBuyPolicy(IssuePolicyParams memory _issueData_)
        internal
        view
        returns (bool)
    {
        bytes32 hashMessage = _getHashBuyPolicy(
            HashBuyPolicyParams(
                msg.sender,
                _issueData_.policyId,
                _issueData_.coverageStart,
                _issueData_.coverageEnd,
                _issueData_.claimExpiresAt,
                _issueData_.premium,
                _issueData_.sumInsured,
                _issueData_.signatureValidUntil
            )
        );

        return
            ECDSAUpgradeable.recover(
                hashMessage,
                _issueData_.v,
                _issueData_.r,
                _issueData_.s
            ) == InsuranceBaseStorage.layout().provider;
    }

    function _getHashRedeemPolicy(HashRedeemPolicyParams memory _data_)
        internal
        view
        returns (bytes32)
    {
        return
            keccak256(
                abi.encodePacked(
                    _data_.user,
                    _data_.policyId,
                    _data_.redeemRate,
                    _data_.riskCarrierRatio,
                    _data_.signatureValidUntil,
                    address(this),
                    block.chainid
                )
            );
    }

    function _verifyRedeemPolicy(RedeemPolicyParams memory _redeemData_)
        internal
        view
        returns (bool)
    {
        bytes32 hashMessage = _getHashRedeemPolicy(
            HashRedeemPolicyParams(
                msg.sender,
                _redeemData_.policyId,
                _redeemData_.redeemRate,
                _redeemData_.riskCarrierRatio,
                _redeemData_.signatureValidUntil
            )
        );

        return
            ECDSAUpgradeable.recover(
                hashMessage,
                _redeemData_.v,
                _redeemData_.r,
                _redeemData_.s
            ) == InsuranceBaseStorage.layout().provider;
    }

    function _isPolicyExist(string memory _policyId_)
        internal
        view
        returns (bool)
    {
        return InsuranceBaseStorage.layout().isPolicyExist[_policyId_];
    }

    function _getPolicyStatus(string memory _policyId_)
        internal
        view
        returns (IInsuranceBaseStorage.PolicyStatus status)
    {
        InsuranceBaseStorage.Layout storage _ibs_ = InsuranceBaseStorage
            .layout();

        if (_ibs_.isPolicyExist[_policyId_] == false) {
            return IInsuranceBaseStorage.PolicyStatus.NotInsured;
        } else if (_ibs_.policies[_policyId_].cancelled == true) {
            status = IInsuranceBaseStorage.PolicyStatus.Cancelled;
        } else if (block.timestamp > _ibs_.policies[_policyId_].coverageEnd) {
            status = IInsuranceBaseStorage.PolicyStatus.Expired;
        } else {
            status = IInsuranceBaseStorage.PolicyStatus.Active;
        }

        return status;
    }

    function _getPoliciesStatus(string[] memory _policies_)
        internal
        view
        returns (IInsuranceBaseStorage.PolicyStatus[] memory policiesStatus)
    {
        policiesStatus = new IInsuranceBaseStorage.PolicyStatus[](
            _policies_.length
        );
        for (uint256 i = 0; i < _policies_.length; i++) {
            policiesStatus[i] = _getPolicyStatus(_policies_[i]);
        }

        return policiesStatus;
    }

    function _getPoliciesInfo(uint256 _page_, uint256 _size_)
        internal
        view
        returns (
            IInsuranceBaseStorage.PolicyData[] memory policiesData,
            IInsuranceBaseStorage.PolicyStatus[] memory policiesStatus,
            uint256 newPage
        )
    {
        InsuranceBaseStorage.Layout storage _ibs_ = InsuranceBaseStorage
            .layout();

        uint256 length = _size_;
        if (length > _ibs_.policyList.length - _page_) {
            length = _ibs_.policyList.length - _page_;
        }

        policiesData = new IInsuranceBaseStorage.PolicyData[](length);
        policiesStatus = new IInsuranceBaseStorage.PolicyStatus[](length);

        for (uint256 i = 0; i < length; i++) {
            policiesData[i] = _ibs_.policies[_ibs_.policyList[_page_ + i]];
            policiesStatus[i] = _getPolicyStatus(_ibs_.policyList[_page_ + i]);
        }

        return (policiesData, policiesStatus, _page_ + length);
    }
}

// SPDX-License-Identifier: CovestFinance.V1.0.0
pragma solidity 0.8.17;

import {InsuranceBaseStorage} from "./base/InsuranceBaseStorage.sol";
import {IInsuranceBaseStorage} from "./interfaces/IInsuranceBaseStorage.sol";
import {PolicyManagerInternalFacet} from "./internal/PolicyManagerInternalFacet.sol";
import {IPolicyManager} from "./interfaces/IPolicyManager.sol";
import {IUpfrontManager} from "../interfaces/IUpfrontManager.sol";
import {IRiskCarrierBaseStorage} from "../interfaces/IRiskCarrierBaseStorage.sol";
import {IRiskCarrierManager} from "../interfaces/IRiskCarrierManager.sol";
import {ReentrancyGuard} from "@solidstate/contracts/utils/ReentrancyGuard.sol";
import {PausableInternal} from "@solidstate/contracts/security/PausableInternal.sol";
import {AccessControlInternal} from "@solidstate/contracts/access/access_control/AccessControl.sol";
import {IERC20MetadataUpgradeable} from "@openzeppelin/contracts-upgradeable/interfaces/IERC20MetadataUpgradeable.sol";

contract PolicyManagerFacet is
    PolicyManagerInternalFacet,
    PausableInternal,
    ReentrancyGuard,
    IPolicyManager
{
    using InsuranceBaseStorage for InsuranceBaseStorage.Layout;

    function buyPolicy(
        BuyPolicyParams memory _bp_,
        IRiskCarrierBaseStorage.RiskTransferParams[] memory _rt_
    ) public nonReentrant whenNotPaused returns (bool) {
        InsuranceBaseStorage.Layout storage _ibs_ = InsuranceBaseStorage
            .layout();

        IssuePolicyParams memory _issueData_ = IssuePolicyParams(
            _bp_.policyId,
            _bp_.coverageStart,
            _bp_.coverageEnd,
            _bp_.claimRequestUntil,
            _bp_.premium,
            _bp_.sumInsured,
            _bp_.signatureValidUntil,
            _bp_.v,
            _bp_.r,
            _bp_.s
        );

        require(
            _verifyMerkleProof(_bp_.proof, _bp_.policyType, _bp_.premiumRate),
            "IP"
        );

        require(_bp_.sumInsured * _bp_.premiumRate == _bp_.premium, "ISI");

        require(
            _issueData_.signatureValidUntil > block.timestamp,
            "Signature must be valid"
        );
        require(_verifyBuyPolicy(_issueData_), "IPD");

        IERC20MetadataUpgradeable _ERC20_ = IERC20MetadataUpgradeable(
            _ibs_.currency
        );

        uint8 _decimalsForConvert = decimals() - _ERC20_.decimals();
        uint256 _premium_ = _bp_.premium / 10**_decimalsForConvert;

        require(
            _ERC20_.allowance(msg.sender, address(this)) >= _premium_,
            "IAP"
        );
        require(_ERC20_.balanceOf(msg.sender) >= _premium_, "IB");
        require(_bp_.riskCarrierRatio <= 100, "IRTR");

        {
            uint256 _riskCarrierAmount_ = ((_premium_ * _bp_.riskCarrierRatio) /
                100);

            require(
                _ERC20_.transferFrom(
                    msg.sender,
                    _ibs_.riskCarrierManager,
                    _riskCarrierAmount_
                ),
                "ECTFTRR"
            );

            require(
                IRiskCarrierManager(_ibs_.riskCarrierManager)
                    .issueRiskCarrierPolicy(_ibs_.poolId, _bp_.policyId, _rt_),
                "CIRP"
            );

            require(
                _ERC20_.transferFrom(
                    msg.sender,
                    _ibs_.upfrontManager,
                    _premium_ - _riskCarrierAmount_
                ),
                "ECTFTUF"
            );

            require(
                IUpfrontManager(_ibs_.upfrontManager).updateBalance(
                    _premium_ - _riskCarrierAmount_
                ),
                "ECUBUM"
            );
        }

        _issuePolicy(_issueData_);

        return true;
    }

    function redeemPolicy(RedeemPolicyParams memory _redeemData_)
        public
        nonReentrant
        whenNotPaused
        returns (bool)
    {
        InsuranceBaseStorage.Layout storage _ibs_ = InsuranceBaseStorage
            .layout();

        require(_verifyRedeemPolicy(_redeemData_), "IRP");

        _redeemPolicy(_redeemData_);

        IERC20MetadataUpgradeable _ERC20_ = IERC20MetadataUpgradeable(
            _ibs_.policies[_redeemData_.policyId].currency
        );

        uint8 _decimalsForConvert_ = decimals() - _ERC20_.decimals();

        uint256 _redeemAmount_ = _ibs_
            .policies[_redeemData_.policyId]
            .redeemAmount; //? decimals 18 ?//

        require(
            IRiskCarrierManager(_ibs_.riskCarrierManager)
                .redeemRiskCarrierPolicy(
                    _ibs_.poolId,
                    _redeemData_.policyId,
                    (_redeemAmount_ * _redeemData_.riskCarrierRatio) / 100 //? decimals 18 ?//
                ),
            "RRCP"
        );

        uint256 _redeemAmountByCurrencyDecimals_ = _redeemAmount_ /
            10**_decimalsForConvert_;

        require(
            _ERC20_.balanceOf(address(this)) >=
                _redeemAmountByCurrencyDecimals_,
            "IB"
        );

        require(
            _ERC20_.transfer(msg.sender, _redeemAmountByCurrencyDecimals_),
            "CTTU"
        );

        return true;
    }

    function getHashBuyPolicy(HashBuyPolicyParams memory _data_)
        public
        view
        returns (bytes32)
    {
        return _getHashBuyPolicy(_data_);
    }

    function getHashRedeemPolicy(HashRedeemPolicyParams memory _data_)
        public
        view
        returns (bytes32)
    {
        return _getHashRedeemPolicy(_data_);
    }

    function isPolicyExist(string memory _policyId_)
        internal
        view
        returns (bool)
    {
        return _isPolicyExist(_policyId_);
    }

    function getPolicyStatus(string memory _policyId_)
        internal
        view
        returns (IInsuranceBaseStorage.PolicyStatus status)
    {
        return _getPolicyStatus(_policyId_);
    }

    function getPoliciesStatus(string[] memory _policies_)
        internal
        view
        returns (IInsuranceBaseStorage.PolicyStatus[] memory policiesStatus)
    {
        return _getPoliciesStatus(_policies_);
    }

    function getPoliciesInfo(uint256 _page_, uint256 _size_)
        internal
        view
        returns (
            IInsuranceBaseStorage.PolicyData[] memory policiesData,
            IInsuranceBaseStorage.PolicyStatus[] memory policiesStatus,
            uint256 newPage
        )
    {
        return _getPoliciesInfo(_page_, _size_);
    }

    function decimals() public pure returns (uint8) {
        return 18;
    }
}

// SPDX-License-Identifier: CovestFinance.V1.0.0
pragma solidity 0.8.17;

import {IRiskCarrierBaseStorage} from "../riskCarrier/interfaces/IRiskCarrierBaseStorage.sol";

// SPDX-License-Identifier: CovestFinance.V1.0.0
pragma solidity 0.8.17;

import {IRiskCarrierManager} from "../riskCarrier/interfaces/IRiskCarrierManager.sol";

// SPDX-License-Identifier: CovestFinance.V1.0.0
pragma solidity 0.8.17;

import {IUpfrontManager} from "../upfront/interfaces/IUpfrontManager.sol";

// SPDX-License-Identifier: CovestFinance.V1.0.0
pragma solidity 0.8.17;

interface IRiskCarrierBaseStorage {
    struct RiskCarrierController {
        address addr;
        string name;
    }

    struct RiskCarrierControllerWithRiskTransferRatio {
        address addr;
        string name;
        uint8 riskTransferRatio;
    }

    struct RiskTransferParams {
        string name;
        bytes params;
    }

    struct RiskCarrierControllerListForMultiGroup {
        RiskCarrierController[] riskCarrierControllerList;
    }

    function GENERAL_MANAGER_LEVEL() external view returns (bytes32);

    function SUPER_MANAGER_LEVEL() external view returns (bytes32);
}

// SPDX-License-Identifier: CovestFinance.V1.0.0
pragma solidity 0.8.17;

import {IRiskCarrierRegistry} from "./IRiskCarrierRegistry.sol";
import {IRiskCarrierRouter} from "./IRiskCarrierRouter.sol";
import {IRiskCarrierTrustedCaller} from "./IRiskCarrierTrustedCaller.sol";

interface IRiskCarrierManager is
    IRiskCarrierRegistry,
    IRiskCarrierRouter,
    IRiskCarrierTrustedCaller
{}

// SPDX-License-Identifier: CovestFinance.V1.0.0
pragma solidity 0.8.17;

import {IRiskCarrierBaseStorage} from "./IRiskCarrierBaseStorage.sol";
import {IRiskCarrierRegistryInternal} from "./IRiskCarrierRegistryInternal.sol";

interface IRiskCarrierRegistry is IRiskCarrierRegistryInternal {
    function delistRiskCarrierController(string memory _poolId_, address _addr_)
        external;

    function getRiskCarrierControllerListByPolicy(
        string memory _poolId_,
        string memory _policyId_,
        uint256 _page_,
        uint256 _size_
    )
        external
        view
        returns (
            IRiskCarrierBaseStorage.RiskCarrierControllerWithRiskTransferRatio[]
                memory riskCarrierControllerList,
            uint256 newPage
        );

    function getRiskCarrierControllerListByPool(
        string memory _poolId_,
        uint256 _page_,
        uint256 _size_
    )
        external
        view
        returns (
            IRiskCarrierBaseStorage.RiskCarrierControllerWithRiskTransferRatio[]
                memory riskCarrierControllerList,
            uint256 newPage
        );

    function registerRiskCarrierController(
        string memory _poolId_,
        string memory _name_,
        address _addr_
    ) external;
}

// SPDX-License-Identifier: CovestFinance.V1.0.0
pragma solidity 0.8.17;

interface IRiskCarrierRegistryInternal {
    event DelistRiskCarrierController(
        string indexed poolId,
        address indexed addr
    );
    event RegisterRiskCarrierController(
        string indexed poolId,
        string indexed name,
        address indexed addr
    );
}

// SPDX-License-Identifier: CovestFinance.V1.0.0
pragma solidity 0.8.17;

import {IRiskCarrierBaseStorage} from "./IRiskCarrierBaseStorage.sol";
import {IRiskCarrierRouterInternal} from "./IRiskCarrierRouterInternal.sol";

interface IRiskCarrierRouter is IRiskCarrierRouterInternal {
    function claimRiskCarrierPolicy(
        string memory _poolId_,
        string memory _policyId_,
        uint256 _claimAmount_
    ) external returns (bool);

    function decimals() external pure returns (uint8);

    function issueRiskCarrierPolicy(
        string memory _poolId_,
        string memory _policyId_,
        IRiskCarrierBaseStorage.RiskTransferParams[] memory _params_
    ) external returns (bool);

    function redeemRiskCarrierPolicy(
        string memory _poolId_,
        string memory _policyId_,
        uint256 _redeemAmount_
    ) external returns (bool);
}

// SPDX-License-Identifier: CovestFinance.V1.0.0
pragma solidity 0.8.17;

interface IRiskCarrierRouterInternal {
    event ClaimRiskCarrierPolicy(
        string indexed poolId,
        string indexed policyId,
        uint256 claimAmount
    );
    event IssueRiskCarrierPolicy(
        string indexed poolId,
        string indexed policyId
    );
    event RedeemRiskCarrierPolicy(
        string indexed poolId,
        string indexed policyId,
        uint256 redeemAmount
    );
}

// SPDX-License-Identifier: CovestFinance.V1.0.0
pragma solidity 0.8.17;

import {IRiskCarrierTrustedCallerInternal} from "./IRiskCarrierTrustedCallerInternal.sol";

interface IRiskCarrierTrustedCaller is IRiskCarrierTrustedCallerInternal {
    function isTrustedCaller(string memory _poolId_, address _addr_)
        external
        view
        returns (bool);

    function setTrustedCaller(
        string memory _poolId_,
        address _addr_,
        bool _isTrusted_
    ) external;
}

// SPDX-License-Identifier: CovestFinance.V1.0.0
pragma solidity 0.8.17;

interface IRiskCarrierTrustedCallerInternal {
    event SetTrustedCaller(
        string indexed poolId,
        address indexed addr,
        bool isTrusted
    );
}

// SPDX-License-Identifier: CovestFinance.V1.0.0
pragma solidity 0.8.17;

import {IUpfrontBaseStorage} from "./IUpfrontBaseStorage.sol";
import {IUpfrontAssetAllocatorInternal} from "./IUpfrontAssetAllocatorInternal.sol";

interface IUpfrontAssetAllocator is IUpfrontAssetAllocatorInternal {
    function getAllocationWeight(IUpfrontBaseStorage.RoleTitle _role_)
        external
        view
        returns (uint8);

    function getRole(address _user_)
        external
        view
        returns (IUpfrontBaseStorage.RoleTitle);

    function getRoleHistory(address _user_)
        external
        view
        returns (IUpfrontBaseStorage.RoleHistory memory);

    function getRoleTitle(uint256 _index_)
        external
        pure
        returns (IUpfrontBaseStorage.RoleTitle);

    function getRolesBalance(IUpfrontBaseStorage.RoleTitle _role_)
        external
        view
        returns (uint256);

    function getRolesCount(IUpfrontBaseStorage.RoleTitle _role_)
        external
        view
        returns (uint256);

    function getSumAllocationWeight() external view returns (uint8);

    function payoutClaimAssessor(
        address _validator_,
        address _currency_,
        uint256 _amount_
    ) external returns (bool, uint256 amountByCurrency);

    function setAllocationWeight(
        IUpfrontBaseStorage.RoleTitle _role_,
        uint8 _allocationWeight_
    ) external;

    function setBatchAllocationWeight(
        IUpfrontBaseStorage.RoleTitle[] memory _role_,
        uint8[] memory _allocationWeight_
    ) external;

    function setRole(address _user_, IUpfrontBaseStorage.RoleTitle _role_)
        external;

    function updateBalance(uint256 _receivedBalance_) external returns (bool);
}

// SPDX-License-Identifier: CovestFinance.V1.0.0
pragma solidity 0.8.17;

import {IUpfrontBaseStorage} from "./IUpfrontBaseStorage.sol";

interface IUpfrontAssetAllocatorInternal {
    event AllocationWeightChanged(
        IUpfrontBaseStorage.RoleTitle role,
        uint8 allocationWeight
    );
    event BalanceChanged(
        uint256 receivedBalance,
        uint256 withdrawnBalance,
        uint256 distributorBalance,
        uint256 riskAssessorBalance,
        uint256 claimAssessorBalance,
        uint256 governanceBoardBalance
    );
    event RoleChanged(
        address user,
        IUpfrontBaseStorage.RoleTitle previousRole,
        IUpfrontBaseStorage.RoleTitle currentRole
    );
}

// SPDX-License-Identifier: CovestFinance.V1.0.0
pragma solidity 0.8.17;

interface IUpfrontBaseStorage {
    enum RoleTitle {
        None,
        Distributor,
        RiskAssessor,
        ClaimAssessor,
        GovernanceBoard
    }

    struct RoleHistory {
        RoleTitle currentRole;
        RoleTitle previousRole;
    }

    function GENERAL_MANAGER_LEVEL() external view returns (bytes32);

    function INSURANCE_MANAGER_LEVEL() external view returns (bytes32);

    function SUPER_MANAGER_LEVEL() external view returns (bytes32);

    function VALIDATOR_MANAGER_LEVEL() external view returns (bytes32);
}

// SPDX-License-Identifier: CovestFinance.V1.0.0
pragma solidity 0.8.17;

import {IUpfrontAssetAllocator} from "./IUpfrontAssetAllocator.sol";

interface IUpfrontManager is IUpfrontAssetAllocator {}