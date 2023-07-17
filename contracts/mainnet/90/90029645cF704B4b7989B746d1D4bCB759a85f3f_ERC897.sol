/**
 *Submitted for verification at polygonscan.com on 2023-07-17
*/

pragma solidity =0.8.6;



// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)
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


// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC721/IERC721.sol)
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
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;

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
    function safeTransferFrom(address from, address to, uint256 tokenId) external;

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
    function transferFrom(address from, address to, uint256 tokenId) external;

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
    function setApprovalForAll(address operator, bool approved) external;

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


// OpenZeppelin Contracts (last updated v4.9.0) (utils/math/Math.sol)
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
            require(denominator > prod1, "Math: mulDiv overflow");

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


// OpenZeppelin Contracts (last updated v4.8.0) (utils/math/SignedMath.sol)
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


// OpenZeppelin Contracts (last updated v4.9.0) (utils/Strings.sol)
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

    /**
     * @dev Returns true if the two strings are equal.
     */
    function equal(string memory a, string memory b) internal pure returns (bool) {
        return keccak256(bytes(a)) == keccak256(bytes(b));
    }
}


// OpenZeppelin Contracts (last updated v4.9.0) (utils/cryptography/ECDSA.sol)
/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
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
    function tryRecover(bytes32 hash, bytes32 r, bytes32 vs) internal pure returns (address, RecoverError) {
        bytes32 s = vs & bytes32(0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff);
        uint8 v = uint8((uint256(vs) >> 255) + 27);
        return tryRecover(hash, v, r, s);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `r and `vs` short-signature fields separately.
     *
     * _Available since v4.2._
     */
    function recover(bytes32 hash, bytes32 r, bytes32 vs) internal pure returns (address) {
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
    function tryRecover(bytes32 hash, uint8 v, bytes32 r, bytes32 s) internal pure returns (address, RecoverError) {
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
    function recover(bytes32 hash, uint8 v, bytes32 r, bytes32 s) internal pure returns (address) {
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
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32 message) {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0x00, "\x19Ethereum Signed Message:\n32")
            mstore(0x1c, hash)
            message := keccak256(0x00, 0x3c)
        }
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
    function toTypedDataHash(bytes32 domainSeparator, bytes32 structHash) internal pure returns (bytes32 data) {
        /// @solidity memory-safe-assembly
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, "\x19\x01")
            mstore(add(ptr, 0x02), domainSeparator)
            mstore(add(ptr, 0x22), structHash)
            data := keccak256(ptr, 0x42)
        }
    }

    /**
     * @dev Returns an Ethereum Signed Data with intended validator, created from a
     * `validator` and `data` according to the version 0 of EIP-191.
     *
     * See {recover}.
     */
    function toDataWithIntendedValidatorHash(address validator, bytes memory data) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x00", validator, data));
    }
}


// OpenZeppelin Contracts v4.4.1 (interfaces/IERC1271.sol)
/**
 * @dev Interface of the ERC1271 standard signature validation method for
 * contracts as defined in https://eips.ethereum.org/EIPS/eip-1271[ERC-1271].
 *
 * _Available since v4.1._
 */
interface IERC1271 {
    /**
     * @dev Should return whether the signature provided is valid for the provided data
     * @param hash      Hash of the data to be signed
     * @param signature Signature byte array associated with _data
     */
    function isValidSignature(bytes32 hash, bytes memory signature) external view returns (bytes4 magicValue);
}


// OpenZeppelin Contracts (last updated v4.9.0) (utils/cryptography/SignatureChecker.sol)
/**
 * @dev Signature verification helper that can be used instead of `ECDSA.recover` to seamlessly support both ECDSA
 * signatures from externally owned accounts (EOAs) as well as ERC1271 signatures from smart contract wallets like
 * Argent and Gnosis Safe.
 *
 * _Available since v4.1._
 */
library SignatureChecker {
    /**
     * @dev Checks if a signature is valid for a given signer and data hash. If the signer is a smart contract, the
     * signature is validated against that smart contract using ERC1271, otherwise it's validated using `ECDSA.recover`.
     *
     * NOTE: Unlike ECDSA signatures, contract signatures are revocable, and the outcome of this function can thus
     * change through time. It could return true at block N and false at block N+1 (or the opposite).
     */
    function isValidSignatureNow(address signer, bytes32 hash, bytes memory signature) internal view returns (bool) {
        (address recovered, ECDSA.RecoverError error) = ECDSA.tryRecover(hash, signature);
        return
            (error == ECDSA.RecoverError.NoError && recovered == signer) ||
            isValidERC1271SignatureNow(signer, hash, signature);
    }

    /**
     * @dev Checks if a signature is valid for a given signer and data hash. The signature is validated
     * against the signer smart contract using ERC1271.
     *
     * NOTE: Unlike ECDSA signatures, contract signatures are revocable, and the outcome of this function can thus
     * change through time. It could return true at block N and false at block N+1 (or the opposite).
     */
    function isValidERC1271SignatureNow(
        address signer,
        bytes32 hash,
        bytes memory signature
    ) internal view returns (bool) {
        (bool success, bytes memory result) = signer.staticcall(
            abi.encodeWithSelector(IERC1271.isValidSignature.selector, hash, signature)
        );
        return (success &&
            result.length >= 32 &&
            abi.decode(result, (bytes32)) == bytes32(IERC1271.isValidSignature.selector));
    }
}


library Util {
    function isValidSignature(
        address signer,
        bytes memory message,
        bytes memory signature
    ) internal view returns (bool) {
        bytes32 hash = ECDSA.toEthSignedMessageHash(message);
        return SignatureChecker.isValidSignatureNow(signer, hash, signature);
    }
}


interface IERC897 {
    event ImplementationChanged(address indexed oldImp, address indexed newImp);
    
    function proxyType() external view returns(uint256);
    
    function implementation() external view returns(address);
}


// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)
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


// OpenZeppelin Contracts (last updated v4.9.0) (access/Ownable.sol)
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


contract ERC897 is Ownable, IERC897 {
    address public override implementation;
    uint256 private _proxyType = 2;
    
    receive() external payable {
    }
    
    fallback(bytes calldata input) external payable returns(bytes memory) {
        (bool success, bytes memory output) = implementation.delegatecall(input);
        
        require(success, string(output));
        
        return output;
    }
    
    function proxyType() external override view returns(uint256) {
        return _proxyType;
    }
    
    function setImplementation(address imp) external onlyOwner {
        emit ImplementationChanged(implementation, imp);
        implementation = imp;
    }
    
	/*
    function callContract(address contractAddress, bytes calldata input)
        external payable onlyOwner {
        
        (bool success, bytes memory output) = contractAddress.call(input);
        
    	require(success, string(output));
    }
    
    function callContract(address contractAddress, bytes calldata input, uint256 value)
        external payable onlyOwner {
        
        (bool success, bytes memory output) = contractAddress.call
            {value: value} (input);
        
        require(success, string(output));
    }
	*/
}

// SPDX-License-Identifier: SimPL-2.0
contract Lend is ERC897 {
    struct ItemInfo {
        uint256 tokenId;
        uint256 balance;
        address borrower;
        uint40 startTime;
        uint16 settledDur;
        bool filled;
        bool picked;
        bool cleared;
    }

    struct PoolInfo {
        address owner;
        uint16 durMin;
        uint16 durMax;
        address nftAddr;
        bool closed;
        uint256 earnest;
        uint256 interest;
        ItemInfo[] items;
    }

    struct RecordInfo {
        uint16 op;
        uint64 poolId;
        uint40 timestamp;
        bytes data;
    }

    struct ItemIndexToken {
        uint256 index;
        uint256 tokenId;
    }

    struct ItemPoolIndex {
        uint256 poolId;
        uint256 index;
    }

    struct ItemIndexPick {
        uint256 index;
        uint256 pick;
    }

    struct LendParams {
        uint256 poolId;
        ItemIndexPick[] items;
    }

    struct PoolFill {
        uint256 poolId;
        address owner;
        address nftAddr;
        uint256 earnest;
        uint256 interest;
        uint256 durMin;
        uint256 durMax;
        ItemIndexToken[] items;
        bytes signature;
    }

    struct ItemFill {
        uint256 poolId;
        ItemIndexToken[] items;
        bytes signature;
    }

    uint256 private constant DENO = 1e18;

    uint256 private constant OP_CLOSE = 1;
    uint256 private constant OP_LEND = 2;
    uint256 private constant OP_PICK = 3;
    uint256 private constant OP_BACK = 4;
    uint256 private constant OP_CLEAR = 5;
    uint256 private constant OP_CLAIM = 6;

    address private signer;

    mapping(uint256 => PoolInfo) private poolInfos;

    RecordInfo[] private records;

    uint256 public platformInterestRatio;
    uint256 public platformBalance;

    function setSigner(address sg) external onlyOwner {
        signer = sg;
    }

    function setPlatformInterestRatio(uint256 ratio) external onlyOwner {
        platformInterestRatio = ratio;
    }

    function _receiveETH(uint256 value) private {
        if (msg.value < value) {
            revert("msg.value too little");
        } else if (msg.value > value) {
            unchecked {
                payable(msg.sender).transfer(msg.value - value);
            }
        }
    }

    function _sendETH(uint256 value) private {
        if (value > 0) {
            payable(msg.sender).transfer(value);
        }
    }

    function _addRecord(uint256 op, uint256 poolId, bytes memory data) private {
        RecordInfo storage record = records.push();

        record.op = uint16(op);
        record.poolId = uint64(poolId);
        record.timestamp = uint40(block.timestamp);
        record.data = data;
    }

    function _transferNFT(
        address nftAddr,
        address from,
        address to,
        uint256 tokenId
    ) private {
        IERC721(nftAddr).transferFrom(from, to, tokenId);
    }

    function getPoolInfos(
        uint256[] calldata poolIds
    ) external view returns (PoolInfo[] memory) {
        uint256 length = poolIds.length;
        PoolInfo[] memory result = new PoolInfo[](length);

        for (uint256 i = 0; i < length; ++i) {
            result[i] = poolInfos[poolIds[i]];
        }

        return result;
    }

    function closeWithSign(uint256 poolId, bytes memory signature) external {
        bytes memory message = abi.encodePacked(
            uint16(1),
            msg.sender,
            uint64(poolId)
        );
        require(
            Util.isValidSignature(signer, message, signature),
            "signature invalid"
        );

        _close(poolId);
    }

    function close(uint256 poolId) external {
        PoolInfo storage poolInfo = poolInfos[poolId];
        require(poolInfo.owner == msg.sender, "not owner");

        _close(poolId);
    }

    function _close(uint256 poolId) private {
        PoolInfo storage poolInfo = poolInfos[poolId];

        require(!poolInfo.closed, "closed");
        poolInfo.closed = true;

        uint256 length = poolInfo.items.length;
        uint256 value = 0;

        unchecked {
            for (uint256 i = 0; i < length; ++i) {
                ItemInfo storage pi = poolInfo.items[i];

                if (_settleInterest(poolInfo, pi)) {
                    _addRecordClear(poolId, i);
                }

                if (pi.balance > 0) {
                    uint256 temp = pi.balance;
                    delete pi.balance;

                    value += temp;
                    _addRecord(
                        OP_CLAIM,
                        poolId,
                        abi.encodePacked(uint16(i), temp)
                    );
                }
            }
        }

        _sendETH(value);

        _addRecord(OP_CLOSE, poolId, bytes(""));
    }

    function lendWithSign(
        LendParams[] calldata lps,
        PoolFill[] calldata pfs,
        ItemFill[] calldata ifs
    ) external payable {
        unchecked {
            address _signer = signer;
            uint256 fillLength = pfs.length;

            for (uint256 i = 0; i < fillLength; ++i) {
                PoolFill calldata pf = pfs[i];
                PoolInfo storage poolInfo = poolInfos[pf.poolId];

                if (poolInfo.owner != address(0)) {
                    continue;
                }

                bytes memory message = abi.encodePacked(
                    uint16(2),
                    uint64(pf.poolId),
                    pf.owner,
                    pf.nftAddr,
                    pf.earnest,
                    pf.interest,
                    uint16(pf.durMin),
                    uint16(pf.durMax)
                );

                uint256 length = pf.items.length;
                ItemInfo[] storage items = poolInfo.items;

                for (uint256 j = 0; j < length; ++j) {
                    ItemIndexToken calldata fi = pf.items[j];

                    message = abi.encodePacked(
                        message,
                        uint16(fi.index),
                        fi.tokenId
                    );

                    while (items.length <= fi.index) {
                        items.push();
                    }

                    ItemInfo storage pi = items[fi.index];
                    if (!pi.filled) {
                        pi.tokenId = fi.tokenId;
                        pi.filled = true;
                    }
                }

                require(
                    Util.isValidSignature(_signer, message, pf.signature),
                    "signature invalid"
                );

                poolInfo.owner = pf.owner;
                poolInfo.nftAddr = pf.nftAddr;
                poolInfo.earnest = pf.earnest;
                poolInfo.interest = pf.interest;
                poolInfo.durMin = uint16(pf.durMin);
                poolInfo.durMax = uint16(pf.durMax);
            }

            fillLength = ifs.length;

            for (uint256 i = 0; i < fillLength; ++i) {
                ItemFill calldata pf = ifs[i];
                PoolInfo storage poolInfo = poolInfos[pf.poolId];

                require(poolInfo.owner != address(0), "pool empty");

                bytes memory message = abi.encodePacked(
                    uint16(3),
                    uint64(pf.poolId)
                );

                uint256 length = pf.items.length;
                ItemInfo[] storage items = poolInfo.items;

                for (uint256 j = 0; j < length; ++j) {
                    ItemIndexToken calldata fi = pf.items[j];

                    message = abi.encodePacked(
                        message,
                        uint16(fi.index),
                        fi.tokenId
                    );

                    while (items.length <= fi.index) {
                        items.push();
                    }

                    ItemInfo storage pi = items[fi.index];
                    if (!pi.filled) {
                        pi.tokenId = fi.tokenId;
                        pi.filled = true;
                    }
                }

                require(
                    Util.isValidSignature(_signer, message, pf.signature),
                    "signature invalid"
                );
            }
        }

        lend(lps);
    }

    function lend(LendParams[] calldata params) public payable {
        uint256 paramsLength = params.length;

        unchecked {
            uint256 value = 0;

            for (uint256 i = 0; i < paramsLength; ++i) {
                LendParams calldata ps = params[i];
                PoolInfo storage poolInfo = poolInfos[ps.poolId];

                // require(poolInfo.owner != address(0), "pool empty");
                require(!poolInfo.closed, "closed");

                uint256 length = ps.items.length;
                require(length > 0, "length 0");

                bytes memory message = abi.encodePacked(msg.sender);

                for (uint256 j = 0; j < length; ++j) {
                    ItemIndexPick calldata li = ps.items[j];
                    ItemInfo storage pi = poolInfo.items[li.index];

                    require(pi.filled, "item empty");

                    if (pi.borrower != address(0)) {
                        if (_settleInterest(poolInfo, pi)) {
                            _addRecordClear(ps.poolId, li.index);
                        }
                        require(pi.borrower == address(0), "borrowed");
                    }

                    bool picked = li.pick != 0;
                    if (picked) {
                        value += poolInfo.earnest;
                        _transferNFT(
                            poolInfo.nftAddr,
                            poolInfo.owner,
                            msg.sender,
                            pi.tokenId
                        );
                    } else {
                        _transferNFT(
                            poolInfo.nftAddr,
                            poolInfo.owner,
                            address(this),
                            pi.tokenId
                        );
                    }

                    value += poolInfo.interest * poolInfo.durMax;

                    pi.borrower = msg.sender;
                    pi.startTime = uint40(block.timestamp - 1);
                    pi.picked = picked;

                    message = abi.encodePacked(
                        message,
                        uint16(li.index),
                        picked
                    );
                }

                _addRecord(OP_LEND, ps.poolId, message);
            }

            _receiveETH(value);
        }
    }

    function pick(uint256 poolId, uint256[] calldata indexes) external payable {
        PoolInfo storage poolInfo = poolInfos[poolId];

        uint256 length = indexes.length;
        require(length > 0, "length 0");

        bytes memory message = bytes("");

        unchecked {
            for (uint256 i = 0; i < length; ++i) {
                uint256 index = indexes[i];
                ItemInfo storage pi = poolInfo.items[index];

                // require(pi.filled, "item empty");
                require(pi.borrower == msg.sender, "not borrower");
                require(!pi.picked, "picked");

                _settleInterestNoCleared(poolInfo, pi, false);

                pi.picked = true;
                _transferNFT(
                    poolInfo.nftAddr,
                    address(this),
                    msg.sender,
                    pi.tokenId
                );

                message = abi.encodePacked(message, uint16(index));
            }

            _receiveETH(poolInfo.earnest * length);
        }

        _addRecord(OP_PICK, poolId, message);
    }

    function back(uint256 poolId, ItemIndexToken[] calldata items) external {
        PoolInfo storage poolInfo = poolInfos[poolId];

        uint256 length = items.length;
        require(length > 0, "length 0");

        uint256 value = 0;
        bytes memory message = bytes("");

        unchecked {
            for (uint256 i = 0; i < length; ++i) {
                ItemIndexToken calldata ti = items[i];
                ItemInfo storage pi = poolInfo.items[ti.index];

                // require(pi.filled, "item empty");
                require(pi.borrower == msg.sender, "not borrower");

                _settleInterestNoCleared(poolInfo, pi, true);

                value += poolInfo.interest * (poolInfo.durMax - pi.settledDur);

                if (pi.picked) {
                    value += poolInfo.earnest;

                    _transferNFT(
                        poolInfo.nftAddr,
                        msg.sender,
                        poolInfo.owner,
                        ti.tokenId
                    );
                    pi.tokenId = ti.tokenId;
                } else {
                    _transferNFT(
                        poolInfo.nftAddr,
                        address(this),
                        poolInfo.owner,
                        pi.tokenId
                    );
                }

                delete pi.borrower;
                delete pi.settledDur;

                message = abi.encodePacked(
                    message,
                    uint16(ti.index),
                    pi.tokenId
                );
            }
        }

        _sendETH(value);

        _addRecord(OP_BACK, poolId, message);
    }

    function getBalance(
        ItemPoolIndex[] calldata params
    ) external view returns (uint256[] memory) {
        uint256 length = params.length;
        uint256[] memory lefts = new uint256[](length);

        unchecked {
            for (uint256 i = 0; i < length; ++i) {
                ItemPoolIndex calldata ps = params[i];
                PoolInfo storage poolInfo = poolInfos[ps.poolId];

                if (ps.index >= poolInfo.items.length) {
                    continue;
                }

                ItemInfo storage pi = poolInfo.items[ps.index];

                uint256 interest = 0;
                uint256 earnest = 0;

                if (pi.borrower != address(0) && !pi.cleared) {
                    uint256 duration = _calcDuration(pi);
                    if (duration > poolInfo.durMax) {
                        duration = poolInfo.durMax;

                        if (pi.picked) {
                            earnest = poolInfo.earnest;
                        }
                    }

                    if (duration > pi.settledDur) {
                        interest =
                            poolInfo.interest *
                            (duration - pi.settledDur);
                        interest =
                            interest -
                            (interest * platformInterestRatio) /
                            DENO;
                    }
                }

                lefts[i] = pi.balance + interest + earnest;
            }
        }

        return lefts;
    }

    function claim(ItemPoolIndex[] calldata params) external {
        uint256 value = 0;
        uint256 length = params.length;

        unchecked {
            for (uint256 i = 0; i < length; ++i) {
                value += _claim(params[i]);
            }
        }

        _sendETH(value);
    }

    function claim(ItemPoolIndex calldata params) external {
        _sendETH(_claim(params));
    }

    function _claim(ItemPoolIndex calldata params) private returns (uint256) {
        PoolInfo storage poolInfo = poolInfos[params.poolId];
        require(poolInfo.owner == msg.sender, "not owner");

        ItemInfo storage pi = poolInfo.items[params.index];

        if (_settleInterest(poolInfo, pi)) {
            _addRecordClear(params.poolId, params.index);
        }

        uint256 value = pi.balance;
        delete pi.balance;

        _addRecord(
            OP_CLAIM,
            params.poolId,
            abi.encodePacked(uint16(params.index), value)
        );

        return value;
    }

    function _calcDuration(ItemInfo storage pi) private view returns (uint256) {
        uint256 unit = 1 days;
        unchecked {
            return (block.timestamp - pi.startTime + unit - 1) / unit;
        }
    }

    function _settleInterestNoCleared(
        PoolInfo storage poolInfo,
        ItemInfo storage item,
        bool checkMin
    ) private {
        require(!item.cleared, "cleared");

        uint256 duration = _calcDuration(item);

        if (checkMin && duration < poolInfo.durMin) {
            duration = poolInfo.durMin;
        }

        require(duration <= poolInfo.durMax, "duration too much");

        unchecked {
            if (duration > item.settledDur) {
                uint256 interest = poolInfo.interest *
                    (duration - item.settledDur);
                uint256 platform = (interest * platformInterestRatio) / DENO;
                platformBalance += platform;
                item.balance += interest - platform;
                item.settledDur = uint16(duration);
            }
        }
    }

    function _settleInterest(
        PoolInfo storage poolInfo,
        ItemInfo storage item
    ) private returns (bool) {
        if (item.borrower == address(0) || item.cleared) {
            return false;
        }

        uint256 duration = _calcDuration(item);
        if (duration > poolInfo.durMax) {
            duration = poolInfo.durMax;
            item.cleared = true;
        }

        unchecked {
            if (duration > item.settledDur) {
                uint256 interest = poolInfo.interest *
                    (duration - item.settledDur);
                uint256 platform = (interest * platformInterestRatio) / DENO;
                platformBalance += platform;
                item.balance += interest - platform;
                item.settledDur = uint16(duration);
            }

            if (item.cleared) {
                if (item.picked) {
                    item.balance += poolInfo.earnest;
                } else {
                    _transferNFT(
                        poolInfo.nftAddr,
                        address(this),
                        poolInfo.owner,
                        item.tokenId
                    );

                    delete item.borrower;
                    delete item.settledDur;
                    delete item.cleared;
                }

                return true;
            }
        }

        return false;
    }

    function _addRecordClear(uint256 poolId, uint256 index) private {
        _addRecord(OP_CLEAR, poolId, abi.encodePacked(uint16(index)));
    }

    function queryRecords(
        uint256 startIndex,
        uint256 maxLength
    ) external view returns (uint256, RecordInfo[] memory) {
        unchecked {
            uint256 length = Math.min(records.length - startIndex, maxLength);
            RecordInfo[] memory result = new RecordInfo[](length);

            for (uint256 i = 0; i < length; ++i) {
                result[i] = records[startIndex + i];
            }

            return (records.length, result);
        }
    }

    function withdraw(address to, uint256 amount) external onlyOwner {
        platformBalance -= amount;
        payable(to).transfer(amount);
    }
}