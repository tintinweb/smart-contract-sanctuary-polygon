/**
 *Submitted for verification at polygonscan.com on 2023-04-19
*/

// File: contracts/web3cert/libs/Web3CertTypeUtils.sol


pragma solidity ^0.8.17;

library Web3CertTypeUtils {

    function remove(uint256[] storage _keys, uint256 _key, bool _strict) internal {
        // Move the last element into the place to delete
        if (_keys.length > 0) {
            uint256 index = _keys.length - 1;
            // if found, then index >0 else 1st element is a target
            for (uint256 i = 0; i < _keys.length - 1; i++) {
                if (_keys[i] == _key) {
                    index = i;
                    break;
                }
            }
            for (uint256 i = index; i < _keys.length - 1; i++) {
                _keys[i] = _keys[i + 1];
            }
            _keys.pop();
        } else {
            // no elements
            if (_strict)  revert("Can't remove from empty array");
        }
    }

    function remove(bytes32[] storage _keys, bytes32 _key, bool _strict) internal {
        // Move the last element into the place to delete
        if (_keys.length > 0) {
            uint256 index = _keys.length - 1;
            // if found, then index >0 else 1st element is a target
            for (uint256 i = 0; i < _keys.length - 1; i++) {
                if (_keys[i] == _key) {
                    index = i;
                    break;
                }
            }
            for (uint256 i = index; i < _keys.length - 1; i++) {
                _keys[i] = _keys[i + 1];
            }
            _keys.pop();
        } else {
            // no elements
            if (_strict)  revert("Can't remove from empty array");
        }
    }

    function to_bytes32(string memory source) internal pure returns (bytes32 result) {
        bytes memory b = bytes(source);
        return bytes32(b);
    }

    function to_string(bytes32 _bytes32) internal pure returns (string memory) {
        uint8 i = 0;
        while (i < 32 && _bytes32[i] != 0) {
            i++;
        }
        bytes memory bytesArray = new bytes(i);
        for (i = 0; i < 32 && _bytes32[i] != 0; i++) {
            bytesArray[i] = _bytes32[i];
        }
        return string(bytesArray);
    }

    function recoverSigner(bytes32 _messageHash, bytes memory _signature) internal pure returns (address) {
        // reject if signature is invalid
        require(_signature.length == 65, "invalid signature length!");
        // append prefix, because on the backend libary appends it to generate a signature
        bytes32 ethSignedMessageHash = keccak256(
            abi.encodePacked("\x19Ethereum Signed Message:\n32", _messageHash)
        );
        // split signature
        bytes32 r;
        bytes32 s;
        uint8 v;
        assembly {
            r := mload(add(_signature, 32))
            s := mload(add(_signature, 64))
            v := byte(0, mload(add(_signature, 96)))
        }

        return ecrecover(ethSignedMessageHash, v, r, s);
    }
}

// File: contracts/web3cert/types/Web3CertTypes.sol


pragma solidity ^0.8.17;


contract Web3CertTypes {

    struct CertRef {
        uint256 _id;
        uint256 _version;
    }

    struct Artifact {
        address issuer;
        bytes32 hash;
        uint256 category;
        uint256 date;
        uint256 dateTo;   
        // url
        string url;
        // artifact imprint
        bytes32 imprint;
        bytes signature;
    }

    struct Resource {
        bytes32 hash;
        // bytes32 representation
        bytes32 locale;
        uint256 category;
        // any custom key
        bytes32 key;
        string url;
        bytes32 imprint;
        uint256 date;
        bytes signature;
        uint256 signatureDate;
    }


}

// File: contracts/web3cert/interfaces/IWeb3CertResourceRegistry.sol


pragma solidity ^0.8.17;


interface IWeb3CertResourceRegistry {
    event ResourceRegistered(uint256 indexed certId, uint256 indexed version, bytes32 indexed hash, string locale, string key, string uri);
    event ResourceSigned(bytes32 indexed hash);
    event ResourceRemoved(bytes32 indexed hash);

    // add localized data
    function addResource(uint256 _certId, uint256 _version, string calldata _locale, uint256 _category,
        string calldata _key, string calldata _url, bytes32 _imprint) external;

    // add signature for the localized text resoure
    function registerSignature(bytes32 _resourceHash, bytes calldata _signature) external;

    function removeResource(bytes32 _key) external;

    // get certificate reference for the given resource 
    function getCertRefByResource(bytes32 _key) external view returns (Web3CertTypes.CertRef memory);

    // get resource by given id
    function getResource(bytes32 _key) external view returns (Web3CertTypes.Resource memory);

    // get all resources by locale
    function getResourcesByLocale(uint256 _certId, uint256 _version, string calldata _locale) external view returns (Web3CertTypes.Resource[] memory);

    // get all resources by category
    function getResourcesByCategory(uint256 _certId, uint256 _version, uint256 _category) external view returns (Web3CertTypes.Resource[] memory);

    // get all registered locales
    function getLocales(uint256 _certId, uint256 _version) external view returns (string[] memory);

    // get all registered categories
    function getCategories(uint256 _certId, uint256 _version) external view returns (uint256[] memory);

    // resolve signer if resource is signed
    function resolveSigner(bytes32 _hash) external view returns (address);

    // is signed
    function isSigned(bytes32 _hash) external view returns (bool);

}

// File: @openzeppelin/contracts/utils/math/Math.sol


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

// File: @openzeppelin/contracts/utils/Strings.sol


// OpenZeppelin Contracts (last updated v4.8.0) (utils/Strings.sol)

pragma solidity ^0.8.0;


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

// File: @openzeppelin/contracts/utils/cryptography/ECDSA.sol


// OpenZeppelin Contracts (last updated v4.8.0) (utils/cryptography/ECDSA.sol)

pragma solidity ^0.8.0;


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

// File: @openzeppelin/contracts/utils/cryptography/EIP712.sol


// OpenZeppelin Contracts (last updated v4.8.0) (utils/cryptography/EIP712.sol)

pragma solidity ^0.8.0;


/**
 * @dev https://eips.ethereum.org/EIPS/eip-712[EIP 712] is a standard for hashing and signing of typed structured data.
 *
 * The encoding specified in the EIP is very generic, and such a generic implementation in Solidity is not feasible,
 * thus this contract does not implement the encoding itself. Protocols need to implement the type-specific encoding
 * they need in their contracts using a combination of `abi.encode` and `keccak256`.
 *
 * This contract implements the EIP 712 domain separator ({_domainSeparatorV4}) that is used as part of the encoding
 * scheme, and the final step of the encoding to obtain the message digest that is then signed via ECDSA
 * ({_hashTypedDataV4}).
 *
 * The implementation of the domain separator was designed to be as efficient as possible while still properly updating
 * the chain id to protect against replay attacks on an eventual fork of the chain.
 *
 * NOTE: This contract implements the version of the encoding known as "v4", as implemented by the JSON RPC method
 * https://docs.metamask.io/guide/signing-data.html[`eth_signTypedDataV4` in MetaMask].
 *
 * _Available since v3.4._
 */
abstract contract EIP712 {
    /* solhint-disable var-name-mixedcase */
    // Cache the domain separator as an immutable value, but also store the chain id that it corresponds to, in order to
    // invalidate the cached domain separator if the chain id changes.
    bytes32 private immutable _CACHED_DOMAIN_SEPARATOR;
    uint256 private immutable _CACHED_CHAIN_ID;
    address private immutable _CACHED_THIS;

    bytes32 private immutable _HASHED_NAME;
    bytes32 private immutable _HASHED_VERSION;
    bytes32 private immutable _TYPE_HASH;

    /* solhint-enable var-name-mixedcase */

    /**
     * @dev Initializes the domain separator and parameter caches.
     *
     * The meaning of `name` and `version` is specified in
     * https://eips.ethereum.org/EIPS/eip-712#definition-of-domainseparator[EIP 712]:
     *
     * - `name`: the user readable name of the signing domain, i.e. the name of the DApp or the protocol.
     * - `version`: the current major version of the signing domain.
     *
     * NOTE: These parameters cannot be changed except through a xref:learn::upgrading-smart-contracts.adoc[smart
     * contract upgrade].
     */
    constructor(string memory name, string memory version) {
        bytes32 hashedName = keccak256(bytes(name));
        bytes32 hashedVersion = keccak256(bytes(version));
        bytes32 typeHash = keccak256(
            "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
        );
        _HASHED_NAME = hashedName;
        _HASHED_VERSION = hashedVersion;
        _CACHED_CHAIN_ID = block.chainid;
        _CACHED_DOMAIN_SEPARATOR = _buildDomainSeparator(typeHash, hashedName, hashedVersion);
        _CACHED_THIS = address(this);
        _TYPE_HASH = typeHash;
    }

    /**
     * @dev Returns the domain separator for the current chain.
     */
    function _domainSeparatorV4() internal view returns (bytes32) {
        if (address(this) == _CACHED_THIS && block.chainid == _CACHED_CHAIN_ID) {
            return _CACHED_DOMAIN_SEPARATOR;
        } else {
            return _buildDomainSeparator(_TYPE_HASH, _HASHED_NAME, _HASHED_VERSION);
        }
    }

    function _buildDomainSeparator(
        bytes32 typeHash,
        bytes32 nameHash,
        bytes32 versionHash
    ) private view returns (bytes32) {
        return keccak256(abi.encode(typeHash, nameHash, versionHash, block.chainid, address(this)));
    }

    /**
     * @dev Given an already https://eips.ethereum.org/EIPS/eip-712#definition-of-hashstruct[hashed struct], this
     * function returns the hash of the fully encoded EIP712 message for this domain.
     *
     * This hash can be used together with {ECDSA-recover} to obtain the signer of a message. For example:
     *
     * ```solidity
     * bytes32 digest = _hashTypedDataV4(keccak256(abi.encode(
     *     keccak256("Mail(address to,string contents)"),
     *     mailTo,
     *     keccak256(bytes(mailContents))
     * )));
     * address signer = ECDSA.recover(digest, signature);
     * ```
     */
    function _hashTypedDataV4(bytes32 structHash) internal view virtual returns (bytes32) {
        return ECDSA.toTypedDataHash(_domainSeparatorV4(), structHash);
    }
}

// File: @openzeppelin/contracts/utils/introspection/IERC165.sol


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

// File: @openzeppelin/contracts/utils/introspection/ERC165.sol


// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;


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
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// File: contracts/web3cert/Web3Service.sol


pragma solidity ^0.8.7;



abstract contract Web3Service {
    // owner
    address private _owner;
    // service
    address private _service;

    constructor() {
        _owner = msg.sender;
    }

    modifier onlyOwner() {
        require(owner() == msg.sender, "not the owner");
        _;
    }

    modifier onlyService() {
        require(service() == msg.sender, "not authorized");
        _;
    }

    function setOwner(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "zero address");
        _owner = newOwner;
    }

    function setService(address newService) public virtual onlyOwner {
        require(newService != address(0), "zero address");
        _service = newService;
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    function service() public view virtual returns (address) {
        return _service;
    }


    function _versionedHash(uint256 _tokenId, uint256 _version) internal virtual pure returns (bytes32) {
        return keccak256(abi.encodePacked(_tokenId, _version));
    }



}

// File: contracts/web3cert/Web3CertResourceRegistry.sol


pragma solidity ^0.8.7;







/**
 * @title Contract to store all resources related to web3 content certificate
 */
contract Web3CertResourceRegistry is ERC165, IWeb3CertResourceRegistry, EIP712, Web3Service
{
    using Web3CertTypeUtils for bytes32[];
    using Web3CertTypeUtils for bytes32;
    using Web3CertTypeUtils for uint256[];


    bytes32 private immutable _RESOURCE_TYPEHASH =
        keccak256("Resource(uint256 w3certId,uint256 version,string locale,string url)"
    );     

    // key = {CERTID}{VERSION} to resourceID or mediaResource
    mapping(bytes32 => bytes32[]) private certResources;

    // key = {resourceKey} to CertEntry
    mapping (bytes32 => Web3CertTypes.CertRef) resourcesToCert;

    // key = {resourceID} to resource
    mapping(bytes32 => Web3CertTypes.Resource) private resources;

    // key = {CERTID}{VERSION} / key = locale
    mapping(bytes32 => mapping(bytes32 => bytes32[])) private resourcesPerLocale;

    // key = {CERTID}{VERSION} / key = category
    mapping(bytes32 => mapping(uint256 => bytes32[])) private resourcesPerCategory;    

    // key = {CERTID}{VERSION}, value = locales
    mapping(bytes32 => bytes32[]) private certLocales;

    // key = {CERTID}{VERSION}, value = uint256
    mapping(bytes32 => uint256[]) private certCategories;    


    constructor() EIP712("W3MPRES", "1")   { 
    }    

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165) returns (bool) {
        return
            interfaceId == type(IWeb3CertResourceRegistry).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    function addResource(uint256 _certId, uint256 _version, string calldata _locale, 
            uint256 _category, string calldata _key, string calldata _url, bytes32 _imprint) external override onlyService {
        require(bytes(_url).length > 0, "empty url");
        // key = {CERTID}{VERSION}
        bytes32 subject = _versionedHash(_certId, _version);
        // resource Identifier
        bytes32 localeKey = Web3CertTypeUtils.to_bytes32(_locale);
        bytes32 resourceHash = keccak256(abi.encodePacked(_certId, _version, _locale, _url));

        require(resources[resourceHash].date == 0, "already registered");

        // resource details
        resources[resourceHash].hash = resourceHash;
        resources[resourceHash].locale = localeKey;
        resources[resourceHash].url = _url;
        resources[resourceHash].imprint = _imprint;
        resources[resourceHash].date = block.timestamp;
        resources[resourceHash].category = _category;
        resources[resourceHash].key = Web3CertTypeUtils.to_bytes32(_key);
        // global mapping
        certResources[subject].push(resourceHash);

        //index
        resourcesToCert[resourceHash]._id = _certId;
        resourcesToCert[resourceHash]._version = _version;

        // not used locale before
        if (resourcesPerLocale[subject][localeKey].length == 0){
             // used language
            certLocales[subject].push(localeKey);
        }

        // not used cateory before
        if (resourcesPerCategory[subject][_category].length == 0){
             // used language
            certCategories[subject].push(_category);
        }

        resourcesPerLocale[subject][localeKey].push(resourceHash);
        resourcesPerCategory[subject][_category].push(resourceHash);

         emit ResourceRegistered(_certId, _version, resourceHash, _locale, _key, _url);      
    }

    function registerSignature(bytes32 _resourceHash, bytes calldata _signature) external override onlyService {
        require(bytes(_signature).length > 0, "empty signature");
        require(resources[_resourceHash].date > 0, "resource not found");
        require(resources[_resourceHash].signatureDate == 0, "already signed");
        //register signature
        resources[_resourceHash].signature = _signature;
        resources[_resourceHash].signatureDate = block.timestamp;

        emit ResourceSigned(_resourceHash);
    }

    function removeResource(bytes32 _hash) external override onlyService {
        require(resources[_hash].date > 0,"resource not found");
        require(resources[_hash].signatureDate == 0, "resource is signed");
        bytes32 subject = _versionedHash(resourcesToCert[_hash]._id, resourcesToCert[_hash]._version);
        // if no key -> revert
        certResources[subject].remove(_hash, true);
        // remove from locale-based index
        resourcesPerLocale[subject][resources[_hash].locale].remove(_hash, false);
        // remove from category-based index
        resourcesPerCategory[subject][resources[_hash].category].remove(_hash, false);

        // references to locale
        uint256 localeCount = resourcesPerLocale[subject][resources[_hash].locale].length;
        if (localeCount == 0) {
            // remove from used
            certLocales[subject].remove(resources[_hash].locale, false);
        }

        // references to category
        uint256 categoryCount = resourcesPerCategory[subject][resources[_hash].category].length;
        if (categoryCount == 0) {
            // remove from used
            certCategories[subject].remove(resources[_hash].category, false);
        }

        // remove resource
        delete resources[_hash];
        delete resourcesToCert[_hash];

        emit ResourceRemoved(_hash);
    }

    function getCertRefByResource(bytes32 _key) external override view returns (Web3CertTypes.CertRef memory) {
        require(resources[_key].date > 0,"resource not found");
        return resourcesToCert[_key];
    }

    function resolveSigner(bytes32 _hash) external override view returns (address) {
        require(resources[_hash].date > 0,"resource not found");
        require(resources[_hash].signatureDate > 0, "not signed");
        return _resolveSigner(resourcesToCert[_hash]._id, resourcesToCert[_hash]._version, Web3CertTypeUtils.to_string(resources[_hash].locale), resources[_hash].url, resources[_hash].signature);
    }

    function _resolveSigner(uint256 _w3certId, uint256 _version, string memory _locale, string memory _url, bytes memory _signature) private view returns (address) {
        bytes32 structHash = keccak256(abi.encode(_RESOURCE_TYPEHASH, _w3certId, _version, _locale, _url));
        (address recoveredSigner, ) = ECDSA.tryRecover( _hashTypedDataV4(structHash), _signature);
        return recoveredSigner;
    }
    
    function isSigned(bytes32 _hash) external override view returns (bool) {
        require(resources[_hash].date > 0,"resource not found");
        return  resources[_hash].signatureDate >0;     
    }
 
    function getResource(bytes32 _key) external view override returns (Web3CertTypes.Resource memory) {
        return resources[_key];
    }

    function getResourcesByLocale(uint256 _certId, uint256 _version, string calldata _locale) external view override returns (Web3CertTypes.Resource[] memory) {
        bytes32 subject = _versionedHash(_certId, _version);
        bytes32 key = Web3CertTypeUtils.to_bytes32(_locale);
        uint256 resCount = resourcesPerLocale[subject][key].length;
        Web3CertTypes.Resource[] memory res = new Web3CertTypes.Resource[](resCount);
        for (uint256 i = 0; i < resCount; i++) {
            res[i] = resources[resourcesPerLocale[subject][key][i]];
        }
        return res;
    }

    function getResourcesByCategory(uint256 _certId, uint256 _version, uint256 _category) external view override returns (Web3CertTypes.Resource[] memory) {
        bytes32 subject = _versionedHash(_certId, _version);
        uint256 resCount = resourcesPerCategory[subject][_category].length;
        Web3CertTypes.Resource[] memory res = new Web3CertTypes.Resource[](resCount);
        for (uint256 i = 0; i < resCount; i++) {
            res[i] = resources[resourcesPerCategory[subject][_category][i]];
        }
        return res;
    }

    function getLocales(uint256 _certId, uint256 _version) external view override returns (string[] memory) {
        bytes32 subject = _versionedHash(_certId, _version);
        string[] memory res = new string[](certLocales[subject].length);
        for (uint256 i = 0; i < certLocales[subject].length; i++) {
            res[i] = Web3CertTypeUtils.to_string(certLocales[subject][i]);
        }
        return res;
    }

    function getCategories(uint256 _certId, uint256 _version) external view override returns (uint256[] memory) {
        return certCategories[_versionedHash(_certId, _version)];
    }

    function domainSeparatorV4() public view returns (bytes32) {
        return _domainSeparatorV4();
    }     
 
}