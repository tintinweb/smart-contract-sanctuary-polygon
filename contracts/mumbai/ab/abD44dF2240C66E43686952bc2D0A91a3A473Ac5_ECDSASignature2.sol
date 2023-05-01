// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/cryptography/ECDSA.sol)

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

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.18;

import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "./Interfaces/IECDSASignature2.sol";
import "./ECDSAssembly/Assembly.sol";

contract ECDSASignature2 is Assembly, IECDSASignature2 {
    constructor(address[] memory _signers) {
        require(
            _signers.length >= 2,
            "A minimum of 2 signatories are required"
        );

        _addSigner(msg.sender);

        for (uint i = 0; i < _signers.length; i++) {
            _addSigner(_signers[i]);
        }
    }

    function verifyMessage(
        bytes32 messageHash,
        uint256 nonce,
        uint256 timestamp,
        bytes[] memory signatures
    ) external {
        _verifyMessage(messageHash, nonce, timestamp, signatures);
    }

    function makeHashToSign(
        bytes32 hashMessage,
        uint256 externalRandom
    ) external view returns (HashToSign memory) {
        return _makeHashToSign(hashMessage, externalRandom);
    }

    function signatureStatus(
        bytes32 messageHash,
        uint256 nonce,
        uint256 timestamp,
        bytes[] memory signatures
    ) external view returns (uint8) {
        return _signatureStatus(messageHash, nonce, timestamp, signatures);
    }

    function setSignatureLifetime(uint256 time) internal {
        _setSignatureLifetime(time);
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.18;

import "./Revocator.sol";
import "./Authorizer.sol";

abstract contract Assembly is Revocator, Authorizer {

    function authorizeNewSigner(
        address newSigner,
        uint256 nonce,
        uint256 timestamp,
        bytes[] memory signatures
    ) external {
        _authorizeNewSigner(newSigner, nonce, timestamp, signatures);
    }

    function revokeSigner(
        address signer,
        uint256 nonce,
        uint256 timestamp,
        bytes[] memory signatures
    ) external {
        _revokeSigner(signer, nonce, timestamp, signatures);
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.18;

import "./Verifier.sol";

abstract contract Authorizer is Verifier {
    function _authorizeNewSigner(
        address newSigner,
        uint256 nonce,
        uint256 timestamp,
        bytes[] memory signatures        
    ) internal toForce() {
        bytes32 hash = keccak256(abi.encodePacked(newSigner, msg.sender));
        _verifyMessage(hash, nonce, timestamp, signatures);
        _addSigner(newSigner);
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.18;

abstract contract Config {
    uint256 private _timePeriodInSeconds = 10 minutes;

    function getTimePeriod() internal view returns (uint256) {
        return _timePeriodInSeconds;
    }

    function _setSignatureLifetime(uint256 time) internal {
        _timePeriodInSeconds = time;
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.18;

import "./Config.sol";
import "./NonceVault.sol";

abstract contract Encoder is Config, NonceVault {
    
    struct HashToSign {
        bytes32 hashMessage;
        bytes32 markedHash;
        uint256 timestamp;
        uint256 nonce;
    }

    function watermark(
        bytes32 message,
        uint256 timestamp,
        uint256 nonce
    ) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(message, timestamp, nonce));
    }

    function timeStamp() internal view returns (uint256) {
        uint256 timePeriod = block.timestamp + getTimePeriod();
        return timePeriod;
    }

    /// @dev create a hash with timestamp and nonce with the claim data.
    /// @notice This function is called by the signature servers to generate the hash that will be applied to the signature with the private key.
    /// @param hashMessage hash to sign.
    /// @param externalRandom this is a number randomly generated by the server.
    function _makeHashToSign(
        bytes32 hashMessage,
        uint256 externalRandom
    ) internal view returns (HashToSign memory) {
        uint256 timestamp = timeStamp();
        uint256 nonce = uint256(
            keccak256(
                abi.encodePacked(
                    block.timestamp,
                    block.prevrandao,
                    externalRandom,
                    hashMessage
                )
            )
        );
        require(_checkNonce(nonce) == false, "nonce was already used");
        bytes32 markedHash = watermark(hashMessage, timestamp, nonce);
        return HashToSign(hashMessage, markedHash, timestamp, nonce);
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.18;

abstract contract NonceVault {
    mapping(uint256 => bool) private nonceUsed;

    function _checkNonce(uint256 nonce) internal view returns (bool) {
        return nonceUsed[nonce];
    }

    function _useNonce(uint256 nonce) internal {
        nonceUsed[nonce] = true;
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.18;

import "./Verifier.sol";

abstract contract Revocator is Verifier {
    function _revokeSigner(
        address signer,
        uint256 nonce,
        uint256 timestamp,
        bytes[] memory signatures
    ) internal toForce() {
        bytes32 hash = keccak256(abi.encodePacked(signer, msg.sender));
        _removeSigner(signer);
        _verifyMessage(hash, nonce, timestamp, signatures);
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.18;

abstract contract Signers {
    address[] private signers;
    mapping(address => bool) private index;
    bool private isForce;

    function _addSigner(address signer) internal {
        require(index[signer] == false, "The signatory is already authorized");
        signers.push(signer);
        index[signer] = true;
    }

    function _removeSigner(address signer) internal {
        require(signers.length > 3, "There cannot be less than 3 signatories");
        require(
            isPrime(signers.length - 1) == false || isForce,
            "The number of signatories cannot be even"
        );
        require(index[signer], "The signatory is not registered");

        for (uint i = 0; i < signers.length; i++) {
            if (signers[i] == signer) {
                swap(i);
                return;
            }
        }
    }

    function swap(uint id) private {
        signers[id] = signers[signers.length - 1];
        signers.pop();
    }

    function isPrime(uint n) private pure returns (bool) {
        return n % 2 == 0;
    }

    function check() internal view {
        require(
            isPrime(signers.length) == false || isForce,
            "The number of signatories cannot be even"
        );
    }

    function signersLength() internal view returns (uint) {
        return signers.length;
    }

    function getSigner(uint id) internal view returns (address) {
        return signers[id];
    }

    modifier toForce() {
        isForce = true;
        _;
        isForce = false;
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.18;

import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

import "./Signers.sol";
import "./Encoder.sol";

abstract contract Verifier is Signers, Encoder {
    using ECDSA for bytes32;

    mapping(uint256 => bool) private nonceUsed;

    event SignatureClaimed(
        bytes32 indexed claimHash,
        bytes32 indexed markedHash,
        uint256 nonce,
        uint256 timestamp,
        uint256 blockTimestamp,
        bytes[] indexed signatures
    );

    function _verify(
        bytes32 data,
        bytes memory signature,
        address account
    ) private pure returns (bool) {
        return data.toEthSignedMessageHash().recover(signature) == account;
    }

    /// @dev Verify that the amount of bars to receive by the player is correct
    /// @param signatures Signatures created by each of the signatories
    function _verifyMessage(
        bytes32 messageHash,
        uint256 nonce,
        uint256 timestamp,
        bytes[] memory signatures
    ) internal {
        require(_checkNonce(nonce) == false, "nonce was already used");
        require(
            block.timestamp <= timestamp,
            "this signature is not valid, its lifetime has expired"
        );

        bytes32 markedHash = watermark(messageHash, timestamp, nonce);

        bool result = _verifyByTheSigners(markedHash, signatures);
        require(result, "hash or signature is invalid");

        _useNonce(nonce);

        emit SignatureClaimed(
            messageHash,
            markedHash,
            nonce,
            timestamp,
            block.timestamp,
            signatures
        );
    }

    function _verifyByTheSigners(
        bytes32 markedHash,
        bytes[] memory signatures
    ) private view returns (bool) {
        check();
        uint sLength = signersLength();
        if (signatures.length > sLength) revert("Too many signatures");

        uint validSignatures = 0;
        uint validSigners = sLength * 1e4;

        address[] memory verifiedSigners = new address[](sLength);
        uint verifiedCount = 0;

        for (uint j = 0; j < signatures.length; j++) {
            bytes memory signature = signatures[j];

            for (uint i = 0; i < sLength; i++) {
                address signer = getSigner(i);

                // Si el signatario ya ha sido verificado, saltar al siguiente
                if (_isVerifiedSigner(verifiedSigners, verifiedCount, signer))
                    continue;

                bool result = _verify(markedHash, signature, signer);
                if (result) {
                    validSignatures += (1 * 1e4);
                    verifiedSigners[verifiedCount++] = signer; // Marcar el signatario como verificado
                    if (validSignatures >= (validSigners / 2)) return true;
                    break; // Salir del bucle interno
                }
            }
        }

        return false;
    }

    function _isVerifiedSigner(
        address[] memory verifiedSigners,
        uint count,
        address signer
    ) private pure returns (bool) {
        for (uint i = 0; i < count; i++) {
            if (verifiedSigners[i] == signer) {
                return true;
            }
        }
        return false;
    }

    /// @dev Check the status of a claim signature
    /// @param messageHash hash
    /// @param signatures Signatures created by each of the signatories
    /// @return uint8: 1 = hash or signature is invalid, 2 = nonce was already used, 3 = lifetime has expired, 0 = Ok - Success
    function _signatureStatus(
        bytes32 messageHash,
        uint256 nonce,
        uint256 timestamp,
        bytes[] memory signatures
    ) internal view returns (uint8) {
        bool result = _verifyByTheSigners(
            watermark(messageHash, timestamp, nonce),
            signatures
        );
        if (!result) return 1;
        if (nonceUsed[nonce]) return 2;
        if (block.timestamp > timestamp) return 3;
        return 0;
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.18;

interface IECDSASignature2 {
    function verifyMessage(bytes32 messageHash, uint256 nonce, uint256 timestamp, bytes[] memory signatures) external;
    function signatureStatus(bytes32 messageHash, uint256 nonce, uint256 timestamp, bytes[] memory signatures) external view returns(uint8);
}