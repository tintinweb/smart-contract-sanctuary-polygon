// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (utils/cryptography/ECDSA.sol)

pragma solidity ^0.8.0;

import "../Strings.sol";

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (utils/math/Math.sol)

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/math/SignedMath.sol)

pragma solidity ^0.8.0;

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

import "./math/Math.sol";
import "./math/SignedMath.sol";

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

// SPDX-License-Identifier: AGPL-3.0-or-later

pragma solidity ^0.8.9;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.9;

import "./IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
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
pragma solidity ^0.8.9;

import "./interfaces/IERC20.sol";
import "./interfaces/IERC20Metadata.sol";
import "./utils/Ownable.sol";
import "./utils/ReentrancyGuard.sol";
import "./utils/SignatureUtils.sol";

/**
 * - APY
 * - rewardToken
 * - user -> depositToken -> pool -> {
 *      record -> { balance, claimedAmount, depositTime }
 *      recordCount
 *      accumulatedBalance
 *   }
 * - poolCount
 * - depositToken -> pool -> { min, max, accumalatedAmount, lockingPeriod }
 *
 * amt * (APY/365) * d1 + amt * (APY/365) * d2 = amt * (APY/365) * (d1+d2)
 */

contract LendingPool is Ownable, ReentrancyGuard {
    struct RecordInfo {
        uint256 poolId;
        uint256 balance;
        uint256 depositTime;
        uint256 claimedAmount;
    }

    struct RecordMap {
        mapping(uint256 => RecordInfo) recordMap; // recordId => RecordInfo
        uint256 count;
    }

    struct PoolInfo {
        IERC20 depositToken;
        IERC20 rewardToken;
        uint256 APY;
        uint256 minDeposit;
        uint256 maxTvl;
        uint256 lockingPeriod;
        uint256 endDate;
        uint256 totalAmount;
        bool isDailyPool;
        bool isActive;
    }

    uint256 constant ONE_YEAR_IN_SECONDS = 31536000;
    uint256 constant ONE_DAY_IN_SECONDS = 86400;

    uint256 public poolCount;
    mapping(uint256 => PoolInfo) public pools; // poolId => PoolInfo
    // mapping(address => mapping(uint256 => RecordMap)) public userRecords; // userAddr => poolId => RecordMap
    mapping(address => RecordMap) public userRecords; // userAddr => RecordMap => recordId => RecordInfo
    mapping(address => mapping(uint256 => uint256)) public userBalancePerPool; // userAddr => poolId => lendingAmount

    // Todo: store total deposit and reward for calculation
    mapping(IERC20 => uint256) public totalDepositAmount;
    mapping(IERC20 => uint256) public totalRewardAmount;

    mapping(bytes => bool) invalidSignatureId; // _id => isValid
    address public signer;

    // temporaily used for testing
    uint256 public dailyPayoutDuration;
    uint256 public yearlyPayoutDuration;

    event PoolCreated(
        uint256 poolId,
        address depositToken,
        address rewardToken,
        uint256 APY,
        uint256 minDeposit,
        uint256 maxTvl,
        uint256 lockingPeriod,
        uint256 endDate,
        bool isDailyPool
    );

    event TokenDeposited(
        uint256 poolId,
        uint256 poolTotalAmount,
        address user,
        uint256 recordId,
        uint256 depositAmount,
        uint256 depositTime
    );

    event TokenWithdrawed(
        bytes _id,
        uint256 poolId,
        uint256 poolTotalAmount,
        address user,
        uint256 recordId,
        uint256 principalAmount,
        uint256 interestAmount,
        uint256 claimTime,
        uint256 totalClaimAmount
    );

    event PoolStatusUpdated(uint256 poolId, bool isActive);

    constructor() {}

    modifier poolExist(uint256 poolId) {
        require(
            pools[poolId].rewardToken != IERC20(address(0)),
            "Lending-pool: pool doesn't exist"
        );
        _;
    }

    modifier poolActive(uint256 poolId) {
        require(pools[poolId].isActive, "Lending-pool: pool is inactive");
        _;
    }

    // temporarily used for testing
    function setDailyPayoutDuration(uint256 durationInSeconds) public {
        require(
            durationInSeconds > 0,
            "Lending-pool: payout Duration must be greater than 0"
        );
        dailyPayoutDuration = durationInSeconds;
    }

    // temporarily used for testing
    function setYearlyPayoutDuration(uint256 durationInSeconds) public {
        require(
            durationInSeconds > 0,
            "Lending-pool: payout Duration must be greater than 0"
        );
        yearlyPayoutDuration = durationInSeconds;
    }

    function setSigner(address _signer) public onlyOwner {
        require(
            _signer != signer && _signer != address(0),
            "Lending-pool: invalid address"
        );
        signer = _signer;
    }

    function setPoolSatus(
        uint256 poolId,
        bool _isActive
    ) public poolExist(poolId) onlyOwner {
        require(
            pools[poolId].isActive != _isActive,
            "Lending-pool: invalid pool status"
        );
        pools[poolId].isActive = _isActive;
        emit PoolStatusUpdated(poolId, _isActive);
    }

    function createPool(
        IERC20 depositToken,
        IERC20 rewardToken,
        uint256 APY,
        uint256 minDeposit,
        uint256 maxTvl,
        uint256 lockingPeriod,
        uint256 endDate,
        bool isDailyPool
    ) public onlyOwner {
        require(
            address(depositToken) != address(0),
            "Lending-pool: depositToken is the zero address"
        );
        require(
            address(rewardToken) != address(0),
            "Lending-pool: rewardToken is the zero address"
        );
        require(
            APY > 0 && APY < 100,
            "Lending-Pool: APY must be between 0 and 100 percent"
        );
        require(
            minDeposit < maxTvl || minDeposit == 0 || maxTvl == 0,
            "Lending-pool: minDeposit must be lower than max token locked value"
        );
        require(
            lockingPeriod > 0,
            "Lending-pool: lockingPeriod must be greater than 0"
        );
        require(
            endDate > block.timestamp + lockingPeriod,
            "Lending-pool: endDate must be greater than block timestamp + lockingPeriod"
        );
        require(
            // isDailyPool || lockingPeriod >= ONE_YEAR_IN_SECONDS,
            isDailyPool || lockingPeriod >= yearlyPayoutDuration * 365, // temporarily used for testing
            "Locking-pool: invalid lockingPeriod for yearly reward pool"
        );

        PoolInfo memory _poolInfo = PoolInfo(
            depositToken,
            rewardToken,
            APY,
            minDeposit,
            maxTvl,
            lockingPeriod,
            endDate,
            0,
            isDailyPool,
            true
        );
        pools[poolCount] = _poolInfo;
        emit PoolCreated(
            poolCount,
            address(depositToken),
            address(rewardToken),
            APY,
            minDeposit,
            maxTvl,
            lockingPeriod,
            endDate,
            isDailyPool
        );
        poolCount += 1;
    }

    function deposit(
        uint256 poolId,
        uint256 depositAmount
    ) public poolExist(poolId) poolActive(poolId) nonReentrant {
        require(
            depositAmount > 0,
            "Lending-pool: depositAmount must be greater than 0"
        );
        PoolInfo memory _poolInfo = pools[poolId];
        require(
            _poolInfo.endDate > block.timestamp + _poolInfo.lockingPeriod,
            "Lending-pool: pool has ended"
        );
        require(
            depositAmount >= _poolInfo.minDeposit || _poolInfo.minDeposit == 0,
            "Lending-pool: depositAmount must be greater than minDeposit"
        );
        require(
            depositAmount + _poolInfo.totalAmount <= _poolInfo.maxTvl ||
                _poolInfo.maxTvl == 0,
            "Lending-pool: maxTvl has been reached"
        );

        _poolInfo.depositToken.transferFrom(
            msg.sender,
            address(this),
            depositAmount
        );
        pools[poolId].totalAmount += depositAmount;

        RecordInfo memory _recordInfo = RecordInfo(
            poolId,
            depositAmount,
            block.timestamp,
            0
        );
        uint256 _count = userRecords[msg.sender].count;
        userRecords[msg.sender].recordMap[_count] = _recordInfo;
        userRecords[msg.sender].count += 1;
        userBalancePerPool[msg.sender][poolId] += depositAmount;
        emit TokenDeposited(
            poolId,
            pools[poolId].totalAmount,
            msg.sender,
            _count,
            depositAmount,
            block.timestamp
        );
    }

    function claim(
        uint256 poolId,
        uint256 recordId,
        PriceFeed memory priceFeed,
        bytes calldata signature
    ) public poolExist(poolId) nonReentrant {
        RecordInfo memory _recordInfo = userRecords[msg.sender].recordMap[
            recordId
        ];
        PoolInfo memory _poolInfo = pools[poolId];
        require(
            _poolInfo.isDailyPool ||
                block.timestamp >
                _recordInfo.depositTime + _poolInfo.lockingPeriod,
            "Lending-pool: yearly pool withdraw period hasn't reached"
        );
        uint256 withdrawableAmount = _claimInterest(
            recordId,
            _recordInfo,
            _poolInfo,
            priceFeed,
            signature
        );
        emit TokenWithdrawed(
            priceFeed._id,
            poolId,
            pools[poolId].totalAmount,
            msg.sender,
            recordId,
            0,
            withdrawableAmount,
            block.timestamp,
            _recordInfo.claimedAmount + withdrawableAmount
        );
    }

    function withdraw(
        uint256 poolId,
        uint256 recordId,
        PriceFeed memory priceFeed,
        bytes calldata signature
    ) public poolExist(poolId) nonReentrant {
        RecordInfo memory _recordInfo = userRecords[msg.sender].recordMap[
            recordId
        ];
        PoolInfo memory _poolInfo = pools[poolId];
        require(
            block.timestamp > _recordInfo.depositTime + _poolInfo.lockingPeriod,
            "Lending-pool: locking period hasn't ended"
        );
        uint256 withdrawableAmount = _claimInterest(
            recordId,
            _recordInfo,
            _poolInfo,
            priceFeed,
            signature
        );

        _poolInfo.depositToken.transfer(msg.sender, _recordInfo.balance);
        pools[poolId].totalAmount -= _recordInfo.balance;
        userRecords[msg.sender].recordMap[recordId].balance = 0;
        userBalancePerPool[msg.sender][poolId] -= _recordInfo.balance;
        emit TokenWithdrawed(
            priceFeed._id,
            poolId,
            pools[poolId].totalAmount,
            msg.sender,
            recordId,
            _recordInfo.balance,
            withdrawableAmount,
            block.timestamp,
            _recordInfo.claimedAmount + withdrawableAmount
        );
    }

    function _claimInterest(
        uint256 recordId,
        RecordInfo memory _recordInfo,
        PoolInfo memory _poolInfo,
        PriceFeed memory priceFeed,
        bytes calldata signature
    ) private returns (uint256) {
        require(_recordInfo.balance > 0, "Lending-pool: No balance to claim");
        _checkPriceFeedSignature(
            priceFeed,
            signature,
            _poolInfo.depositToken,
            _poolInfo.rewardToken,
            recordId
        );

        uint256 withdrawableAmount = _getWithdrawableAmount(
            _poolInfo.depositToken,
            _poolInfo.rewardToken,
            _recordInfo.balance,
            _recordInfo.depositTime,
            _poolInfo.APY,
            _recordInfo.claimedAmount,
            priceFeed.rateSum,
            priceFeed.dayNum,
            _poolInfo.isDailyPool // temporarily used for testing
        );
        require(
            withdrawableAmount > 0,
            "Lending-pool: no reward left to claim"
        );
        _poolInfo.rewardToken.transfer(msg.sender, withdrawableAmount);
        userRecords[msg.sender]
            .recordMap[recordId]
            .claimedAmount += withdrawableAmount;
        return withdrawableAmount;
    }

    // temporarily used for testing
    function _getWithdrawableAmount(
        IERC20 depositToken,
        IERC20 rewardToken,
        uint256 depositAmount,
        uint256 depositTime,
        uint256 APY,
        uint256 claimedAmount,
        uint256 rateSum,
        uint256 payoutDayNum,
        bool isDailyPool
    ) private view returns (uint256) {
        uint256 dayNum = (block.timestamp - depositTime) /
            (isDailyPool ? dailyPayoutDuration : yearlyPayoutDuration);
        if (depositToken == rewardToken) {
            return ((depositAmount * APY * dayNum) / 36500) - claimedAmount;
        }
        require(
            payoutDayNum == dayNum,
            "Lending-pool: invalid number of payout days from price feed"
        );
        return
            ((depositAmount * APY * rateSum) /
                (10 ** IERC20Metadata(address(rewardToken)).decimals() *
                    36500)) - claimedAmount;
    }

    // function _getWithdrawableAmount(
    //     IERC20 depositToken,
    //     IERC20 rewardToken,
    //     uint256 depositAmount,
    //     uint256 depositTime,
    //     uint256 APY,
    //     uint256 claimedAmount,
    //     uint256 rateSum,
    //     uint256 payoutDayNum
    // ) private view returns (uint256) {
    //     uint256 dayNum = (block.timestamp - depositTime) / ONE_DAY_IN_SECONDS;
    //     if (depositToken == rewardToken) {
    //         return ((depositAmount * APY * dayNum) / 36500) - claimedAmount;
    //     }
    //     require(
    //         payoutDayNum == dayNum,
    //         "Lending-pool: invalid number of payout days from price feed"
    //     );
    //     return ((depositAmount * APY * rateSum) / 36500) - claimedAmount;
    // }

    function _checkPriceFeedSignature(
        PriceFeed memory priceFeed,
        bytes calldata signature,
        IERC20 depositToken,
        IERC20 rewardToken,
        uint256 recordId
    ) private {
        if (depositToken == rewardToken) {
            return;
        }
        require(
            !invalidSignatureId[priceFeed._id],
            "Lending-pool: signature transaction id is used already"
        );
        bytes32 hashed = SignatureUtils.hashPriceFeed(priceFeed, recordId);
        (, bool _isValid) = SignatureUtils.isValid(hashed, signer, signature);
        require(_isValid, "Lending-pool: invalid signature");
        invalidSignatureId[priceFeed._id] = true;
    }

    function emergencyWithdraw(
        IERC20 tokenAddr,
        uint256 amount
    ) public onlyOwner {
        tokenAddr.transfer(msg.sender, amount);
    }

    function getPools(
        uint256 offset,
        uint256 limit
    ) public view returns (PoolInfo[] memory) {
        if (offset > poolCount) {
            return new PoolInfo[](0);
        }
        uint256 _length = offset + limit > poolCount
            ? poolCount - offset
            : limit;
        uint256 _iterLimit = offset + limit > poolCount
            ? poolCount
            : offset + limit;
        PoolInfo[] memory _pools = new PoolInfo[](_length);
        for (uint256 i = offset; i < _iterLimit; i++) {
            _pools[i - offset] = pools[i];
        }
        return _pools;
    }

    function testGetUserRecords(
        address userAddr,
        uint256 offset,
        uint256 limit
    ) public view returns (RecordInfo[] memory records) {
        uint256 _recordCount = userRecords[userAddr].count;
        if (offset > _recordCount) {
            return new RecordInfo[](0);
        }
        uint256 _length = offset + limit > _recordCount
            ? _recordCount - offset
            : limit;
        uint256 _iterLimit = offset + limit > _recordCount
            ? _recordCount
            : offset + limit;
        RecordInfo[] memory _records = new RecordInfo[](_length);
        for (uint256 i = offset; i < _iterLimit; i++) {
            RecordInfo memory _recordInfo = userRecords[userAddr].recordMap[i];
            _records[i - offset] = _recordInfo;
        }
        return _records;
    }

    function getUserRecords(
        address userAddr,
        uint256 offset,
        uint256 limit,
        uint256[] memory rateSumList
    )
        public
        view
        returns (
            RecordInfo[] memory records,
            uint256[] memory withdrawableAmount
        )
    {
        uint256 _recordCount = userRecords[userAddr].count;
        if (offset > _recordCount) {
            return (new RecordInfo[](0), new uint256[](0));
        }
        uint256 _length = offset + limit > _recordCount
            ? _recordCount - offset
            : limit;
        uint256 _iterLimit = offset + limit > _recordCount
            ? _recordCount
            : offset + limit;
        RecordInfo[] memory _records = new RecordInfo[](_length);
        uint256[] memory _withdrawableAmount = new uint256[](_length);
        for (uint256 i = offset; i < _iterLimit; i++) {
            RecordInfo memory _recordInfo = userRecords[userAddr].recordMap[i];
            _records[i - offset] = _recordInfo;
            PoolInfo memory _poolInfo = pools[_recordInfo.poolId];
            uint256 _rateSum = rateSumList[i - offset];
            _withdrawableAmount[i - offset] = _getWithdrawableAmountRaw(
                _poolInfo.depositToken,
                _poolInfo.rewardToken,
                _recordInfo.balance,
                _recordInfo.depositTime,
                _poolInfo.APY,
                _recordInfo.claimedAmount,
                _rateSum,
                _poolInfo.isDailyPool // temporarily used for testing
            );
        }
        return (_records, _withdrawableAmount);
    }

    // temporarily used for testing
    function _getWithdrawableAmountRaw(
        IERC20 depositToken,
        IERC20 rewardToken,
        uint256 depositAmount,
        uint256 depositTime,
        uint256 APY,
        uint256 claimedAmount,
        uint256 rateSum,
        bool isDailyPool
    ) private view returns (uint256) {
        if (depositAmount == 0) {
            return 0;
        }
        uint256 dayNum = (block.timestamp - depositTime) /
            (isDailyPool ? dailyPayoutDuration : yearlyPayoutDuration);
        if (depositToken == rewardToken) {
            return ((depositAmount * APY * dayNum) / 36500) - claimedAmount;
        }
        return
            ((depositAmount * APY * rateSum) /
                (10 ** IERC20Metadata(address(rewardToken)).decimals() *
                    36500)) - claimedAmount;
    }

    // function _getWithdrawableAmountRaw(
    //     IERC20 depositToken,
    //     IERC20 rewardToken,
    //     uint256 depositAmount,
    //     uint256 depositTime,
    //     uint256 APY,
    //     uint256 claimedAmount,
    //     uint256 rateSum
    // ) private view returns (uint256) {
    //     uint256 dayNum = (block.timestamp - depositTime) / ONE_DAY_IN_SECONDS;
    //     if (depositToken == rewardToken) {
    //         return ((depositAmount * APY * dayNum) / 36500) - claimedAmount;
    //     }
    //     return ((depositAmount * APY * rateSum) / 36500) - claimedAmount;
    // }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.9;

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
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.9;

import "./Context.sol";

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
pragma solidity ^0.8.9;

abstract contract ReentrancyGuard {
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

struct PriceFeed {
    bytes _id;
    uint256 rateSum;
    uint256 dayNum;
}

library SignatureUtils {
    function hashPriceFeed(
        PriceFeed memory priceFeed,
        uint256 recordId
    ) internal pure returns (bytes32 digest) {
        return
            keccak256(
                abi.encodePacked(
                    priceFeed._id,
                    priceFeed.rateSum,
                    priceFeed.dayNum,
                    recordId
                )
            );
    }

    function isValid(
        bytes32 hashed,
        address signer,
        bytes calldata signature
    ) internal pure returns (address, bool) {
        bytes32 digest = ECDSA.toEthSignedMessageHash(hashed);

        address recoverAddr = ECDSA.recover(digest, signature);
        return (recoverAddr, recoverAddr == signer);
    }
}