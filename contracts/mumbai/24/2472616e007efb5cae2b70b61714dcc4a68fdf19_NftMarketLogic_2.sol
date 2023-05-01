/**
 *Submitted for verification at polygonscan.com on 2023-04-29
*/

pragma solidity ^0.8.0;


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

interface IMyERC721 is IERC721 {
    function approve_with_sig(address spender, uint256 tokenId, bytes memory signature, address signer, uint expireTime) external;
}

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

library ECDSA {
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
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n", Strings.toString(s.length), s));
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

contract NftMarketLogic_2 {
    mapping(address => mapping(uint => uint)) public nftPrice;

    mapping(bytes => bool) public usedSignatures;

    mapping(address => uint) public userBalance;

    bool public marketState;
    address public owner;
    uint public fee = 5;

    event MarketStateChange(bool indexed state);

    event EthDeposit(address indexed operator, address indexed to, uint256 amount);
    event EthWithdraw(address indexed operator, address indexed from, address indexed to, uint256 amount);

    event NftTransferViaMarket(address indexed from, address indexed to, address indexed nftAddr, uint256 tokenId);
    event NftOnSale(address indexed owner, address indexed nftAddr, uint256 indexed tokenId,uint price);
    event NftOffSale(address indexed owner, address indexed nftAddr, uint256 indexed tokenId);
    event NftPriceChange(address indexed nftAddr, uint256 indexed tokenId, uint256 indexed price);

    constructor(){
        owner = msg.sender;
    }
    modifier onlyOwner() {
        require(msg.sender == owner,'not owner');
        _;
    }

    modifier onlyMarketOpen() {
        require(marketState, 'market stopped');
        _;
    }

    function set_market_state(bool state) public onlyOwner {
        marketState = state;
        emit MarketStateChange(state);
    }

    function set_fee(uint _fee) public onlyOwner {
        fee = _fee;
    }

    function deposit_eth(address to) public payable {
        userBalance[to] += msg.value;
        emit EthDeposit(msg.sender, to, msg.value);
    }

    function withdraw_eth(uint amount, address payable to) public {
        uint balance = userBalance[msg.sender];
        require(balance >= amount, 'not enough funds');
        userBalance[msg.sender] -= amount;
        to.transfer(amount);
        emit EthWithdraw(msg.sender, msg.sender, to, amount);
    }

    function sell_eth_with_sig(bytes memory signature, address signer, uint256 amount, uint timestamp) public onlyOwner {
     
        string memory message = string(abi.encodePacked('sell eth\nAddress:', Strings.toHexString(signer), '\nAmount:', Strings.toString(amount), '\nTimestamp:', Strings.toString(timestamp)));
        Utils.verify_signer(signature, signer, message);
        require(!usedSignatures[signature], 'duplicate signature caused by used timestamp');

  
        uint balance = userBalance[signer];
        require(balance >= amount, 'balance not enough');

        userBalance[signer] -= amount;
        payable(owner).transfer(amount);
        usedSignatures[signature]=true;
        emit EthWithdraw(msg.sender, signer, owner, amount);

    }

    function get_nft_sale_state(address nftAddr, uint tokenId) public view returns (bool){
        IERC721 nft = IERC721(nftAddr);
        if (nft.getApproved(tokenId) == address(this) && nftPrice[nftAddr][tokenId] > 0) {return true;}
        return false;
    }

    function put_nft_on_sale_with_sig(bytes memory approveSignature, bytes memory priceSignature, address signer, uint price, address nftAddress, uint tokenId, uint timestamp) public onlyOwner {
 
        string memory message_approve = string(abi.encodePacked('approve_nft\nSignerAddress:', Strings.toHexString(signer), '\nSpenderAddress:', Strings.toHexString(address(this)), '\nNftAddress:', Strings.toHexString(nftAddress), '\nId:', Strings.toString(tokenId), '\nTimestamp:', Strings.toString(timestamp)));
        Utils.verify_signer(approveSignature, signer, message_approve);

        string memory message_price = string(abi.encodePacked('set_nft_price\nSignerAddress:', Strings.toHexString(signer), '\nNftAddress:', Strings.toHexString(nftAddress), '\nId:', Strings.toString(tokenId), '\nPrice:', Strings.toString(price), '\nTimestamp:', Strings.toString(timestamp)));
        Utils.verify_signer(priceSignature, signer, message_price);
        require(!usedSignatures[priceSignature], 'duplicate signature caused by used timestamp');

        require(price > 0, 'invalid price');
        IMyERC721 nft = IMyERC721(nftAddress);
        require(signer == nft.ownerOf(tokenId), 'signer is not owner');
        if (nft.getApproved(tokenId) != address(this)) {
            nft.approve_with_sig(address(this), tokenId, approveSignature, signer, timestamp);
        }
        if (price != nftPrice[nftAddress][tokenId]) {
            nftPrice[nftAddress][tokenId] = price;
            emit NftPriceChange(nftAddress, tokenId, price);
        }
        usedSignatures[priceSignature]=true;
        emit NftOnSale(signer, nftAddress, tokenId,price);
    }

    function put_nft_off_sale_with_sig(bytes memory signature, address signer, address nftAddress, uint tokenId, uint timestamp) public onlyOwner {
        string memory message_approve = string(abi.encodePacked('approve_nft\nSignerAddress:', Strings.toHexString(signer), '\nSpenderAddress:', Strings.toHexString(address(0)), '\nNftAddress:', Strings.toHexString(nftAddress), '\nId:', Strings.toString(tokenId), '\nTimestamp:', Strings.toString(timestamp)));
        Utils.verify_signer(signature, signer, message_approve);
        require(!usedSignatures[signature], 'duplicate signature caused by used timestamp');

        bool nftSaleState = get_nft_sale_state(nftAddress, tokenId);
        require(nftSaleState, 'nft already off sale');

        IMyERC721 nft = IMyERC721(nftAddress);
        require(signer == nft.ownerOf(tokenId), 'signer is not owner');
        if (nft.getApproved(tokenId) == address(this)) {
  
            nft.approve_with_sig(address(0), tokenId, signature, signer, timestamp);
        }
        delete nftPrice[nftAddress][tokenId];
        usedSignatures[signature]=true;
        emit NftPriceChange(nftAddress, tokenId, 0);
        emit NftOffSale(signer, nftAddress, tokenId);

    }

    function set_nft_price(address nftAddress, uint tokenId, uint price) public {
        require(price > 0, 'invalid price');
        IERC721 nft = IERC721(nftAddress);
        require(nft.getApproved(tokenId) != address(this), 'nft not approved');
        require(msg.sender == nft.ownerOf(tokenId), 'not owner');
        if (price != nftPrice[nftAddress][tokenId]) {
            nftPrice[nftAddress][tokenId] = price;
            emit NftPriceChange( nftAddress, tokenId, price);
        }
        emit NftOnSale(msg.sender, nftAddress, tokenId,price);
    }

    function set_nft_price_to_zero_with_sig(bytes memory signature, address signer, address nftAddress, uint tokenId, uint timestamp) public onlyOwner {
        string memory message = string(abi.encodePacked('set_nft_price_to_zero\nSignerAddress:', Strings.toHexString(signer), '\nNftAddress:', Strings.toHexString(nftAddress), '\nId:', Strings.toString(tokenId), '\nTimestamp:', Strings.toString(timestamp)));
        Utils.verify_signer(signature, signer, message);
        require(!usedSignatures[signature], 'duplicate signature caused by used timestamp');

        IERC721 nft = IERC721(nftAddress);
        require(signer == nft.ownerOf(tokenId), 'not owner');

        bool nftSaleState = get_nft_sale_state(nftAddress, tokenId);

        if (nftPrice[nftAddress][tokenId] != 0) {
            nftPrice[nftAddress][tokenId] = 0;
            emit NftPriceChange(nftAddress, tokenId, 0);
        }
        usedSignatures[signature]=true;
        if (nftSaleState) {
            emit NftOffSale(signer, nftAddress, tokenId);
        }

    }

    function set_nft_price_with_sig(bytes memory signature, address signer, address nftAddress, uint tokenId, uint price, uint timestamp) public onlyOwner {
        string memory message = string(abi.encodePacked('set_nft_price\nSignerAddress:', Strings.toHexString(signer), '\nNftAddress:', Strings.toHexString(nftAddress), '\nId:', Strings.toString(tokenId), '\nPrice:', Strings.toString(price), '\nTimestamp:', Strings.toString(timestamp)));
        Utils.verify_signer(signature, signer, message);
        require(!usedSignatures[signature], 'duplicate signature caused by used timestamp');

        require(price > 0, 'invalid price');

        IERC721 nft = IERC721(nftAddress);
        require(nft.getApproved(tokenId) == address(this), 'nft not approved');
        require(signer == nft.ownerOf(tokenId), 'not owner');

        if (price != nftPrice[nftAddress][tokenId]) {
            nftPrice[nftAddress][tokenId] = price;
            emit NftPriceChange(nftAddress, tokenId, price);
        }

        usedSignatures[signature]=true;
        emit NftOnSale(signer, nftAddress, tokenId,price);
    }


    function buy_nft(address nftAddress, uint tokenId) public {
        IERC721 nft = IERC721(nftAddress);
        address nftOwner = nft.ownerOf(tokenId);
        require(msg.sender != nftOwner, 'the same buyer and nft owner');

        bool nftSaleState = get_nft_sale_state(nftAddress, tokenId);
        require(nftSaleState, 'nft not on sale');

        uint price = nftPrice[nftAddress][tokenId];

        require(userBalance[msg.sender] >= price, 'buyer not enough balance');
        userBalance[msg.sender] -= price;
        emit EthWithdraw(msg.sender, msg.sender, nftOwner, price);

        uint tradeFee = price * fee / 100;
        payable(owner).transfer(tradeFee);
        uint amountSendToNftOwner = price - tradeFee;
        userBalance[nftOwner] += amountSendToNftOwner;
        emit EthDeposit(msg.sender, nftOwner, amountSendToNftOwner);
        nft.transferFrom(nftOwner, msg.sender, tokenId);
        emit NftTransferViaMarket(nftOwner, msg.sender, nftAddress, tokenId);
    }

    function buy_nft_with_sig(bytes memory buyerSignature, address buyerAddress, address nftAddress, uint tokenId, uint timestamp) public onlyOwner {
        string memory message = string(abi.encodePacked('but_nft\nSignerAddress:', Strings.toHexString(buyerAddress), '\nNftAddress:', Strings.toHexString(nftAddress), '\nId:', Strings.toString(tokenId), '\nTimestamp:', Strings.toString(timestamp)));

        Utils.verify_signer(buyerSignature, buyerAddress, message);
        require(!usedSignatures[buyerSignature], 'duplicate signature caused by used timestamp');

        IERC721 nft = IERC721(nftAddress);
        address nftOwner = nft.ownerOf(tokenId);
        require(buyerAddress != nftOwner, 'the same buyer and nft owner');

        bool nftSaleState = get_nft_sale_state(nftAddress, tokenId);
        require(nftSaleState, 'nft not on sale');

        uint price = nftPrice[nftAddress][tokenId];

        require(userBalance[buyerAddress] >= price, 'buyer not enough balance');
        userBalance[buyerAddress] -= price;
        emit EthWithdraw(msg.sender, buyerAddress, nftOwner, price);

        uint tradeFee = price * fee / 100;
        payable(owner).transfer(tradeFee);
        uint amountSendToNftOwner = price - tradeFee;
        userBalance[nftOwner] += amountSendToNftOwner;
        emit EthDeposit(msg.sender, nftOwner, amountSendToNftOwner);
        nft.transferFrom(nftOwner, buyerAddress, tokenId);
        usedSignatures[buyerSignature]=true;
        emit NftTransferViaMarket(nftOwner, buyerAddress, nftAddress, tokenId);
    }
}

library Utils {

    function verify_signer(bytes memory signature, address signer, string memory message) internal {
        bytes32 ethSignedMessagedHash = ECDSA.toEthSignedMessageHash(bytes(message));
        address recover_addr = ECDSA.recover(ethSignedMessagedHash, signature);
        require(recover_addr == signer, 'address not match');

    }

}