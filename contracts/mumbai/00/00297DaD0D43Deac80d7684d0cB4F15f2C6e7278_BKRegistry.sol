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

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

/**  This contract records license agreements and values for BKEmbedClients;
 * Agreements metadata is recorded in an an AgreementStruct, and stored in a AgreementStruct[] array.
 * Indexes are maintained to the position of each Agreement struct by the contracts addres, tokenId, and sequential positional index (starting with )
*/

/* The BKRegistry smart contract stores metadata about BKEmbedClient license agreements and makes it possible to store legal agreements 
    directly on the Blockchain.  The metadata is stored in a struct called Agreement, which is stored in an array of Agreement structs.  The Agreement struct contains the following fields:
    agreementId - a unique identifier for the agreement.  This is a hash of the sourceContract, assetId, and assetIdIndex.
    sourceContract - the address of the contract which created the agreement.
    assetId - the token or other asset for which the agreement is being created.  Usually a sequential uint256 tokenID.
    assetIdIndex - this is a sequential index of agreements for a particular asset, starting with index 0. 
    makerAddress - the address of the maker of the agreement.
    takerAddress - the address of the taker of the agreement.
    agreementHash - hash of the full rendered text of the agreement and the schedule, not including the signatures.
    signatureStatus - an enum which records the status of the signatures.  The enum is defined as follows:
        enum SignatureStatus {
            Unsigned,     //changes c an only happen prior to MakerSignature
            MakerSigned,  //maker signed always precedes taker signed.
            FullySigned,
            Terminated
        }
    The agreementValues mapping is keyed by the agreementId, and contains an array of DictionaryEntry structs.  The DictionaryEntry struct contains the following fields:
        key - the value inside the tag
        value - the value which is to replace that tag.

    Thus once an agreement is recorded and signed, it can be reconstructed by reading the agreement values and replacing the tags with the values written
    to the agreementValues mapping.

    Note that the initial lookup values derived for each agreement tag are done before the contract is registered with BKRegistry.  Likewise, the fully rendered template's hash
    is calculated before the contract is registered.  This is because the contract text may be too long to be passed as a paremtner and calculated
    as part of the smart contract..

*/
import "./Utils.sol";

enum SignatureStatus {
    Unsigned,     //changes c an only happen prior to MakerSignature
    MakerSigned,  //maker signed always precedes taker signed.
    FullySigned,
    Terminated
}
 

/* This struct records data to be insrted into the agreement template */
struct Agreement {
    bytes32 agreementId;
    address sourceContract;
    uint256 assetId;  
    uint256 assetIdIndex;  //this is a sequential index of agreements for a particular asset, starting with index 0. 
    address makerAddress;
    address takerAddress;
    bytes32 agreementHash; //hash of the full rendered text of the agreement and the schedule, not including the signatures.
    SignatureStatus signatureStatus;
}

contract BKRegistry {
    Agreement[] public agreements;
    mapping(address=>string[]) private templatePages;
    mapping(address => uint[]) private agreementBySourceContract; //contract address=> array of all index vals in 'agreements' to all Agreements for the contract
    mapping(bytes32 => uint) private agreementCountByAssetId; //hash(sourceAddress + tokenID) => last sequential index entry for     tokenId.
    mapping(bytes32 => uint) private agreementByHashKey; //hash(sourceAddress + tokenID + index) => agreementId
    mapping(bytes32 => DictionaryEntry[]) private agreementValues; //hash(sourceAddress + tokenID + index) => Values for contract in dictionEntry array
    address public owner;

    constructor() {
        owner = msg.sender;
    }
 
    function changeOwnership(address newOwner) public {
        require(msg.sender == owner, "Only owner can change ownership");
        owner = newOwner;
    }

    /**
     * This function prepares to write a new agreement to the registry.  It adds the agreement to the array of agreement structs, and add several index entires to assist in locating the agreement.
     * @param sourceContract - the contract for which the agreement is being created.
     * @param agreementHash = the hash of the agreement and schedule text which will be recorded.
     * @param assetId the token or other asset for whi
     * ch the agreement is being created.  Usually a sequential uint256 tokenID.
     */
    function writeNew(  address sourceContract, 
                        bytes32 agreementHash, 
                        uint256 assetId, 
                        address makerAddress, 
                        address takerAddress,  
                        DictionaryEntry[] memory entries) public {
                            
        require(msg.sender == owner, "only BKopyProto ownercan create new Agreement");
        require(getOwnerOf(sourceContract, assetId) != address(0), "Asset Id not exist");
        require(templatePages[sourceContract].length > 0, "No template pages defined for contract");

        uint nextIndex = countByAssetId(sourceContract, assetId);
        bytes32 hashKey = keccak256(abi.encodePacked(sourceContract, assetId, nextIndex));
        require(agreementByHashKey[hashKey] == 0, "Agreement already exists");
        
        Agreement memory newAgreement = Agreement(hashKey, sourceContract, assetId, nextIndex,  makerAddress, takerAddress,  agreementHash, SignatureStatus.Unsigned);
        uint agreementSlot = agreements.length;  //the index into which the agreement struct will be written.
        agreements.push(newAgreement);
        bytes32 tokenIdHash = keccak256(abi.encodePacked(sourceContract, assetId));  //a hash key which can be used to find the location of the agreement in the agreements array.
        agreementCountByAssetId[tokenIdHash] = nextIndex +1; //records teh number of agreement which exist for each assetID/contract pair.
        agreementByHashKey[hashKey] = agreementSlot;  //write the new position of the agreement into the agreementByHashkey  map.
        agreements.push(newAgreement);  //pushes the agreement on the to the end of agreements array. 
        //record basic information about the the transaction related values in the agreementValues map so they can be inserted in the text as
        //necessary.
        // agreementValues[hashKey].push(DictionaryEntry("Maker", Utils.addressToString(makerAddress)));
        // agreementValues[hashKey].push(DictionaryEntry("Taker", Utils.addressToString(takerAddress)));
        // agreementValues[hashKey].push(DictionaryEntry("ContractAddress", Utils.addressToString(sourceContract)));
        // agreementValues[hashKey].push(DictionaryEntry("AssetId", Utils.uintToString(assetId)));
        // agreementValues[hashKey].push(DictionaryEntry("AgreementHash", Utils.bytes32ToString(agreementHash)));
        //push the entires for the values calculated from the smart contract supplied by the caller.
        for (uint i = 0; i < entries.length; i++ ) {
            agreementValues[hashKey].push(entries[i]);
        }
    }

    

    function writeTemplatePage(address sourceContract, string memory page) public {
        require(msg.sender == owner, "{MMCI28} only BKopyProto owner can write template pages");
        //template pages can't be written after first agreement is created for source contract.
        require(agreementBySourceContract[sourceContract].length == 0, "{VI2I3X} template pages are readonly after 1st agmt");
        require(bytes(page).length > 0, "{V2I3X} page content must be non-zero length");
        require(bytes(page).length < 3100, "{VDE2C} page content should be less than 3000 characters.");  //we leave 3100 for 100char margin of error
        templatePages[sourceContract].push(page);
    }
    function readTemplatePage(address sourceContract, uint page) public view returns(string memory) {
        require(page < templatePages[sourceContract].length, "{V2I3X} page index out of range");
        return templatePages[sourceContract][page];
    }

    // function writeTemplateValues(bytes32 hashKey,  address maker, address taker, DictionaryEntry[] memory entries) private {       
    //     uint agreementSlot = agreementByHashKey[hashKey];
    //     Agreement storage agreement = agreements[agreementSlot];

    //     //Make sure the agreement has been recorded.
    //     require(agreement.agreementId != 0, "Agreement not found");
    //     //Make sure the msg.sender is owner
    //     require(msg.sender == getOwner(agreement.sourceContract), "only contract owner can write values");
    //     //make sure the agreement is not already signed.
    //     require(agreement.signatureStatus == SignatureStatus.Unsigned, "Agreement already signed");
        
    //     agreement.makerAddress = maker;
    //     agreement.takerAddress = taker;
    //     for (uint i = 0; i < entries.length; i++ ) {
    //         agreementValues[hashKey].push(entries[i]);
    //     }
    //  }
 
     function readTemplateValues(bytes32 hashKey) public view returns(DictionaryEntry[] memory) {
         return agreementValues[hashKey];
     }

    function getLastAgreementForAssetId(address sourceContract, uint256 assetId) public view returns (Agreement memory) {
        uint agreementSlot = agreementByHashKey[keccak256(abi.encodePacked(sourceContract, assetId, countByAssetId(sourceContract, assetId) -1))];
            
        Agreement storage agreement = agreements[agreementSlot];
        if (agreement.agreementId == 0) {
            revert("Agreement not found");
        }
        return agreement;
    }

    function getAgreement(address sourceContract, uint tokenId, uint index) public view returns(Agreement memory) {
        bytes32 hashKey = keccak256(abi.encodePacked(sourceContract, tokenId, index));
        uint agreementSlot = agreementByHashKey[hashKey];
        Agreement storage agreement = agreements[agreementSlot];
        if (agreement.agreementId == 0) {
            revert("Agreement not found");
        }
        return agreement;
    }
    /**
     * Reads template values for a particular agreement
     * @param hashKey - a Hash of contract address, tokenId and sequence # for token Id.
     */
    function readValues(bytes32 hashKey) public view returns(DictionaryEntry[] memory) {
        return agreementValues[hashKey];
    }


 /**Returns the number of agreements produced for a given tokenId/contract pair.
  * @param sourceContract - the smart contract address
  * @param assetId  - the tokenId being quieried.
  * @return the number of agreements produced for a given tokenId/contract pair or 0 if non produced.
  */
    function countByAssetId(address sourceContract, uint256 assetId) public view returns (uint) {
        return agreementCountByAssetId[keccak256(abi.encodePacked(sourceContract, assetId))];
    }
    
    
    function getOwner(address source) public view returns (address) {
        // ABI encode the function signature to get its bytes representation
        bytes memory callSig = abi.encodeWithSignature("owner()");
        (bool success, bytes memory data) = address(source).staticcall(callSig);
        if (!success) {
            return address(0);
        }
        return abi.decode(data, (address));
    }

    function getOwnerOf(address source, uint256 assetId) public view returns (address) {
        // ABI encode the function signature to get its bytes representation
        bytes memory callSig = abi.encodeWithSignature("ownerOf(uint256)", assetId);
        (bool success, bytes memory data) = address(source).staticcall(callSig);
        if (!success) {
            return address(0);
        }
        return abi.decode(data, (address));
    }
    
    function recordSignature(bytes32 hashkey, bytes memory signature, bool isMaker) public {
        require(msg.sender == owner, "only BKopy can record signatures");
        uint agreementSlot = agreementByHashKey[hashkey];
        Agreement storage agreement = agreements[agreementSlot];
        require(agreement.agreementId != 0, "Agreement not found");
        address signerAddress;
        string memory valueKey; //either "makerSignature" or "takerSignature"
        if (isMaker) {
            require(agreement.makerAddress != address(0), "Maker address not set");
            require(agreement.signatureStatus == SignatureStatus.Unsigned, "Agreement already signed by Maker");
            signerAddress = agreement.makerAddress;
            valueKey = "makerSignature";
        } else {
            require(agreement.takerAddress != address(0), "Taker address not set");
            require(agreement.signatureStatus != SignatureStatus.FullySigned, "Agreement already fully signed");
            require(agreement.signatureStatus == SignatureStatus.MakerSigned, "Agreement must be sigend by Maker first.");
 
            signerAddress = agreement.takerAddress;
            valueKey="takerSignature";
        }
        bytes32  agmtHash = agreement.agreementHash;
        bool isValidSig = Utils.isValidSignature(agmtHash, signerAddress, signature);
        require(isValidSig, "{JVJ2JC} Invalid signature");
        if(isMaker) {
            agreement.signatureStatus = SignatureStatus.MakerSigned;
        } else {
            agreement.signatureStatus = SignatureStatus.FullySigned;
        }
        
        agreementValues[hashkey].push(DictionaryEntry(valueKey, Utils.bytesToString(signature)));
    }

    function parsePage(address sourceContract, uint256 assetId, uint index, uint page) public view returns (string memory) {
        string memory pageContent = readTemplatePage(sourceContract, page);
        DictionaryEntry[] memory entries = readValues(keccak256(abi.encodePacked(sourceContract, assetId, index)));
        string memory parsed = Utils.parsePage(pageContent, entries);
        return parsed;
    }

    function parseSigBlock(address sourceContract, uint256 assetId, uint index) public view returns (string memory) {
        string memory sigPage = sigBlock;
        DictionaryEntry[] memory entries = readValues(keccak256(abi.encodePacked(sourceContract, assetId, index)));
        return Utils.parsePage(sigPage, entries);

    }
}

//SPDX-License-Identifier: UNLICENSEDd
pragma solidity ^0.8.17;

 
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

struct DictionaryEntry {
    string key;
    string value;
}

string constant sigBlock = "<p>The parties have executed this agreement by application of their respective digital ignatures of their Blockchain Wallet to the Keccak256 hash of the text of this document, which Keccak256 hash is #{AgreementHash}</p><br>Agreed to: #{MakerEntity}<br>Address: #{Maker}<br><br>Agreed to: #{TakerEntity}<br>Address #{Taker}<br>";

library Utils {
      using ECDSA for bytes32;
      /**
       * Converts an address to its string representation and returns to caller.0
       * @param _address - the address to convert
       */
      function addressToString(address _address) public pure returns(string memory) {
         bytes20 _addr = bytes20(_address);
        bytes memory alphabet = "0123456789abcdef";
        bytes memory str = new bytes(40);

     for(uint i = 0; i < 20; i++) {
        str[i*2] = alphabet[uint8(_addr[i] >> 4)];
        str[1 + i*2] = alphabet[uint8(_addr[i] & 0x0f)];
     }
        return string(str);
      }

      function uintToString(uint uint_) public pure returns(string memory) {
        return Strings.toString(uint_);
      }

     function bytes32ToString(bytes32 _bytes32) public pure returns (string memory) {
        bytes memory alphabet = "0123456789abcdef";

        bytes memory str = new bytes(64);
        for (uint i = 0; i < 32; i++) {
            str[i*2] = alphabet[uint8(_bytes32[i] >> 4)];
            str[1 + i*2] = alphabet[uint8(_bytes32[i] & 0x0f)];
        }
        return string(str);
    }  

    function bytesToString(bytes memory _bytes) public pure returns (string memory) {
       bytes memory alphabet = "0123456789abcdef";

        bytes memory str = new bytes(2 * _bytes.length);
        for(uint i = 0; i < _bytes.length; i++) {
            str[i*2] = alphabet[uint8(_bytes[i] >> 4)];
            str[1 + i*2] = alphabet[uint8(_bytes[i] & 0x0f)];
        }
        return string(str);
    }

    function parsePage(string memory _page, DictionaryEntry[] memory tags) public pure returns(string memory) {
        string memory result = _page;
        if (!hasTags(_page)) {
            return _page;
        }
        for(uint i = 0; i < tags.length; i++) {
            result = string_search_replace(result, tagify(tags[i].key), tags[i].value);
            if (!hasTags(result))  {
                return result;
            }
        }
        return result;
    }
    
    function tagify(string memory tag) private pure returns(string memory) {
        return string(abi.encodePacked("#{", tag, "}" ));
    }

    function isValidSignature(bytes32 message, address mysigner, bytes memory signature) public pure returns(bool)  {
        address signer = message.toEthSignedMessageHash().recover(signature);        
        return mysigner == signer;
    }  
   function string_search_replace(string memory _base, string memory _pattern, string memory _replacement) public pure returns (string memory) {
        bytes memory _baseBytes = bytes(_base);
        bytes memory _patternBytes = bytes(_pattern);
        bytes memory _replacementBytes = bytes(_replacement);

        string memory _tmp = _base;

        if(_patternBytes.length == 0) {
            return _base;
        }

        for(uint i=0; i <= _baseBytes.length - _patternBytes.length; i++) {
            bool found = true;
            for(uint j=0; j<_patternBytes.length; j++) {
                if(_baseBytes[i+j] != _patternBytes[j]) {
                    found = false;
                    break;
                }
            }

            if(found) {
                _tmp = "";

                string memory _pre = new string(i);
                bytes memory _preBytes = bytes(_pre);
                for(uint k=0; k<i; k++) {
                    _preBytes[k] = _baseBytes[k];
                }
                
                _tmp = string(abi.encodePacked(_preBytes, _replacementBytes));

                string memory _post = new string(_baseBytes.length - (_patternBytes.length + i));
                bytes memory _postBytes = bytes(_post);
                for(uint k=0; k<_baseBytes.length - (_patternBytes.length + i); k++) {
                    _postBytes[k] = _baseBytes[k + _patternBytes.length + i];
                }

                _tmp = string(abi.encodePacked(_tmp, _postBytes));
                _baseBytes = bytes(_tmp);
                i = i + _patternBytes.length - 1;
            }
        }

        return _tmp;
    }

function contains(string memory _string, string memory _substring) public pure returns(bool) {
        bytes memory stringBytes = bytes(_string);
        bytes memory substringBytes = bytes(_substring);

        if(substringBytes.length > stringBytes.length) {
            return false;
        }

        bool found;
        for(uint i = 0; i <= stringBytes.length - substringBytes.length; i++) {
            found = true;
            for(uint j = 0; j < substringBytes.length; j++) {
                if(stringBytes[i + j] != substringBytes[j]) {
                    found = false;
                    break;
                }
            }

            if(found) {
                return true;
            }
        }

        return false;
    }

    function hasTags(string memory _base )  private pure returns (bool) {
        bytes memory _baseBytes = bytes(_base);
        bytes memory _substringBytes = bytes("#{");
        if(_baseBytes.length < _substringBytes.length) {
            return false;
        }
        for(uint i = 0; i <= _baseBytes.length - _substringBytes.length; i++) {
            bool found = true;
            for(uint j = 0; j < _substringBytes.length; j++) {
                if(_baseBytes[i+j] != _substringBytes[j]) {
                    found = false;
                    break;
                }
            }
            if(found) {
                return found;
            }
        }
        return false;
    }
 
 

}