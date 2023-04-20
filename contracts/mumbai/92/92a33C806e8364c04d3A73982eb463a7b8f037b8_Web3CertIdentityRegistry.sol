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

// File: contracts/web3cert/interfaces/IWeb3CertIdentityRegistry.sol


pragma solidity ^0.8.17;

interface IWeb3CertIdentityRegistry  {

    event IdentityRegistered(bytes32 indexed identity, string name, string url);
    event IdentityUpdated(bytes32 indexed identity, string name, string url);
    event IdentityApproved(bytes32 indexed identity);
    event IdentityCompromised(bytes32 indexed identity);
    event KeyRegistered(bytes32 indexed identity, bytes32 key, uint256 level);
    event KeyRemoved(bytes32 indexed identity, bytes32 key);
    event KeyVoided(bytes32 indexed identity, bytes32 key);    

    struct Key {
        address account;
        uint256 level;
        uint256 validFrom;
        uint256 validTo;
        uint256 revoked;
    }

    struct Identity {
        string name;
        string url;
        uint256 date;
        uint256 approved;
        uint256 compromised;
    }
    function registerIdentity(string calldata _name, string calldata _url) external;
    function registerIdentity(address _user, string calldata _name, string calldata _url, bytes calldata _permit) external;
    function registerIdentityAndManagementKey(address _user, string calldata _name, string calldata _url, address _management, bytes calldata _permit) external;
    function updateIdentity(string calldata _name, string calldata _url) external;
    function updateIdentity(address _user, string calldata _name, string calldata _url, bytes calldata _permit) external;
    function registerKey(address _target, uint256 _level, uint256 _validTo) external;
    function registerKey(address _user, address _target, uint256 _level, uint256 _validTo, bytes calldata _permit) external;
    function removeKey(address _target) external;
    function voidKey(address _target) external;
    function voidKey(address _user, address _target, bytes calldata _permit) external;
    function getKeyData(bytes32 _identity, bytes32 _key) external view returns (Key memory);
    function getKeys(bytes32 _identity) external view returns (bytes32[] memory);
    function getIdentityData(bytes32 _identity) external view returns (Identity memory);
    function getIdentityDataByAddress(address _address) external view returns (Identity memory);
    function hasValidAccountIdentity(address _address) external view returns (bool);
    function hasValidIdentityKey(bytes32 _identity, bytes32 _key, uint256 _level) external view returns (bool);
    function hasValidIdentityKey(bytes32 _identity, address _account, uint256 _level) external view returns (bool); 
    function hasValidAccountManagementKey(address _Account, address _key) external view returns (bool);
    function approveIdentity(bytes32 _identity) external;
    function compromiseIdentity(bytes32 _identity) external;
   
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

// File: @openzeppelin/contracts/utils/Context.sol


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

// File: @openzeppelin/contracts/access/IAccessControl.sol


// OpenZeppelin Contracts v4.4.1 (access/IAccessControl.sol)

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControl {
    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {AccessControl-_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) external view returns (bool);

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {AccessControl-_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) external;
}

// File: @openzeppelin/contracts/access/AccessControl.sol


// OpenZeppelin Contracts (last updated v4.8.0) (access/AccessControl.sol)

pragma solidity ^0.8.0;





/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms. This is a lightweight version that doesn't allow enumerating role
 * members except through off-chain means by accessing the contract event logs. Some
 * applications may benefit from on-chain enumerability, for those cases see
 * {AccessControlEnumerable}.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it.
 */
abstract contract AccessControl is Context, IAccessControl, ERC165 {
    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
    }

    mapping(bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with a standardized message including the required role.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     *
     * _Available since v4.1._
     */
    modifier onlyRole(bytes32 role) {
        _checkRole(role);
        _;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControl).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view virtual override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `_msgSender()` is missing `role`.
     * Overriding this function changes the behavior of the {onlyRole} modifier.
     *
     * Format of the revert message is described in {_checkRole}.
     *
     * _Available since v4.6._
     */
    function _checkRole(bytes32 role) internal view virtual {
        _checkRole(role, _msgSender());
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function _checkRole(bytes32 role, address account) internal view virtual {
        if (!hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        Strings.toHexString(account),
                        " is missing role ",
                        Strings.toHexString(uint256(role), 32)
                    )
                )
            );
        }
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view virtual override returns (bytes32) {
        return _roles[role].adminRole;
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     *
     * May emit a {RoleGranted} event.
     */
    function grantRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     *
     * May emit a {RoleRevoked} event.
     */
    function revokeRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been revoked `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     *
     * May emit a {RoleRevoked} event.
     */
    function renounceRole(bytes32 role, address account) public virtual override {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * May emit a {RoleGranted} event.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     *
     * NOTE: This function is deprecated in favor of {_grantRole}.
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        bytes32 previousAdminRole = getRoleAdmin(role);
        _roles[role].adminRole = adminRole;
        emit RoleAdminChanged(role, previousAdminRole, adminRole);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * Internal function without access restriction.
     *
     * May emit a {RoleGranted} event.
     */
    function _grantRole(bytes32 role, address account) internal virtual {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * Internal function without access restriction.
     *
     * May emit a {RoleRevoked} event.
     */
    function _revokeRole(bytes32 role, address account) internal virtual {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }
}

// File: contracts/web3cert/Web3CertIdentityRegistry.sol


pragma solidity ^0.8.17;




/**
 * @title Contract to store identities web3 content certificate
 */
contract Web3CertIdentityRegistry is IWeb3CertIdentityRegistry, AccessControl {
    uint256 public constant ADMIN = 1;
    uint256 public constant MANAGER = 2;

    mapping(address => uint256) private _nonces;

    using Web3CertTypeUtils for bytes32[];
    using Web3CertTypeUtils for bytes32;

    bytes32 public constant VERIFIER_ROLE = keccak256("VERIFIER_ROLE");
    bytes32 public constant BOUNCER_ROLE = keccak256("BOUNCER_ROLE");

    // key = hash(address)
    mapping(bytes32 => Identity) private identities;

    // permissions between keys :  key = hash(address)
    mapping(bytes32 => mapping(bytes32 => Key)) private identityKeys;

    mapping(bytes32 => bytes32[]) private identityKeyItems;

    // true if identity autautoApproveomatically approved
    bool public autoApprove;

    
    constructor() {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(VERIFIER_ROLE, msg.sender);
        _grantRole(BOUNCER_ROLE, msg.sender);
    }

    /**
     * @notice  Register current user as identity. This user is an admin for his identity
     */
    function registerIdentity(string calldata _name, string calldata _url) external override {
        _registerIdentity(msg.sender, _name, _url);
        _nonces[msg.sender] +=1;
    }

    /**
     * @notice  Register the specified user an identity. 
     Signature should contains the none,user,name,url and signed by the authorized record. 
     */
    function registerIdentity(address _user, string calldata _name, string calldata _url, bytes calldata _permit) external override {
        require(_user!=address(0), "zero address");
        // verify signature
        address recoveredSigner = keccak256(abi.encodePacked(_user, _name, _url)).recoverSigner(_permit);
        // recovered signer should be the user
        require(recoveredSigner == _user, "invalid signature");
        // register the user
        _registerIdentity(_user, _name, _url);
        _nonces[_user] +=1;

    }
    /**
     * @notice Register `approved` identity and assign a management key. Allowed only for the user with verifier role
     */
    function registerIdentityAndManagementKey(address _user, string calldata _name, string calldata _url, address _management, bytes calldata _permit) external override {
        require(_user!=address(0), "zero address");
        // verify signature
        address recoveredSigner = keccak256(abi.encodePacked(_user, _management, _name, _url)).recoverSigner(_permit);
        // recovered signer should be the user
        require(recoveredSigner == _user, "invalid signature");
        // register the user
        bytes32 identityKey = _registerIdentity(_user, _name, _url);
        // add management key
        _registerKey(identityKey, _management, MANAGER, 0);

        _nonces[_user] +=1;
    }

    /**
     * @notice  Update name and url for  the existing identity that belongs to the caller
     */
    function updateIdentity(string calldata _name, string calldata _url) external override {
        _updateIdentity(keccak256(abi.encodePacked(msg.sender)), _name, _url);
        // increment nonce for the user identity
        _nonces[msg.sender] +=1;
    }

    function updateIdentity(address _user, string calldata _name, string calldata _url, bytes calldata _permit) external override {
        // verify signature
        address recoveredSigner = keccak256(abi.encodePacked(_nonces[_user], _user, _name, _url)).recoverSigner(_permit);
        // recovered signer should be the user
        require(recoveredSigner == _user, "invalid signature");
        _updateIdentity(keccak256(abi.encodePacked(msg.sender)), _name, _url);
        // increment nonce for the user identity
        _nonces[msg.sender] +=1;
    }


    /**
     * @notice Register a new key under the exising identity.
     */
    function registerKey(address _target, uint256 _level, uint256 _validTo) external override {
        // no access controlfor the current identity
        bytes32 uKey = keccak256(abi.encodePacked(msg.sender));
        _registerKey(uKey, _target, _level, _validTo);
        // increment nonce for the user identity
        _nonces[msg.sender] +=1;
    }
    /**
     * @notice Register a new key for the specified user. 
        Signature should contains the nonce,user,target,level,validTo and signed by the authorized record. 
     */
    function registerKey(address _user, address _target, uint256 _level, uint256 _validTo, bytes calldata _permit) external override {
        // verify signature
        address recoveredSigner = keccak256(abi.encodePacked(_nonces[_user], _user, _target, _level, _validTo)).recoverSigner(_permit);
        // recovered signer should be the user
        require(recoveredSigner == _user, "invalid signature");
        bytes32 uKey = keccak256(abi.encodePacked(_user));
        _registerKey(uKey, _target, _level, _validTo);
        // increment nonce for the user identity
        _nonces[_user] +=1;
    }

    /**
     * @notice Remove a key from the current user
     */
    function removeKey(address _target) external override {
        bytes32 uKey = keccak256(abi.encodePacked(msg.sender));
        bytes32 tKey = keccak256(abi.encodePacked(_target));
       _removeKey(uKey, tKey);
        // increment nonce for the user identity
       _nonces[msg.sender] +=1;
    }

    /**
     * @notice Revoke a key from the current user
     */
    function voidKey(address _target) external override {
        bytes32 uKey = keccak256(abi.encodePacked(msg.sender));
        bytes32 tKey = keccak256(abi.encodePacked(_target));
       _voidKey(uKey, tKey);
        // increment nonce for the user identity
       _nonces[msg.sender] +=1;
    }

    /**
     * @notice Revoke a key from the current user.
      Signature should contains the nonce,user,target and signed by the authorized record.       
     */
    function voidKey(address _user, address _target, bytes calldata _permit) external override {
        address recoveredSigner = keccak256(abi.encodePacked(_nonces[_user], _user, _target)).recoverSigner(_permit);
        require(recoveredSigner == _user, "invalid signature");
        bytes32 uKey = keccak256(abi.encodePacked(_user));
        bytes32 tKey = keccak256(abi.encodePacked(_target));
       _voidKey(uKey, tKey);
        // increment nonce for the user identity
       _nonces[msg.sender] +=1;
    }    

    function getKeyData(bytes32 _identity, bytes32 _key) external override view returns (Key memory) {
        return identityKeys[_identity][_key];
    }

    function getKeys(bytes32 _identity) external override view returns (bytes32[] memory) {
        return identityKeyItems[_identity];
    }

    function getIdentityData(bytes32 _identity) external override view returns (Identity memory) {
        return identities[_identity];
    }

    function getIdentityDataByAddress(address _address) external override view returns (Identity memory) {
        return identities[keccak256(abi.encodePacked(_address))];
    }    
    /**
     * @notice  Check if address has an identity that is approved and not compromised
     */
    function hasValidAccountIdentity(address _address) external override view returns (bool) {
        bytes32 _key = keccak256(abi.encodePacked(_address));
        return identities[_key].date > 0 && identities[_key].approved > 0 && identities[_key].compromised == 0;
    }    

    /**
     * @notice Check if specified identity is approved and not compromised and it has a valid specified key (not revoked, not expired)
     */
    function hasValidIdentityKey(bytes32 _identity, bytes32 _key, uint256 _level) external override view returns (bool) {
        if (identities[_identity].date > 0 && identities[_identity].approved > 0 && identities[_identity].compromised == 0) {
            Key memory k = identityKeys[_identity][_key];
            // registered, not expired, not revoked and level is equal
             return (k.validFrom > 0 && k.validTo < block.timestamp && k.revoked == 0 && k.level == _level);
        } else return false;
    }

    /**
     * @notice Check if specified identity is approved and not compromised and it has a valid specified key (not revoked, not expired)
     */
    function hasValidIdentityKey(bytes32 _identity, address _account, uint256 _level) external override view returns (bool) {
        if (identities[_identity].date > 0 && identities[_identity].approved > 0 && identities[_identity].compromised == 0) {
            bytes32 _key = keccak256(abi.encodePacked(_account));
            Key memory k = identityKeys[_identity][_key];
            // registered, not expired, not revoked and level is equal
            return (k.validFrom > 0 && k.validTo < block.timestamp && k.revoked == 0 && k.level == _level);
        } else return false;
    }    

    /**
     * @notice Check if specified identity is approved and not compromised and it has a valid specified key (not revoked, not expired)
     */
    function hasValidAccountManagementKey(address _identity, address _key) external override view returns (bool) {
        bytes32 uKey = keccak256(abi.encodePacked(_identity));
        if (identities[uKey].date > 0 && identities[uKey].approved > 0 && identities[uKey].compromised == 0) {
            bytes32 tKey = keccak256(abi.encodePacked(_key));
            Key memory k = identityKeys[uKey][tKey];
            // registered, not expired, not revoked and level is equal
            return (k.validFrom > 0 && k.validTo < block.timestamp && k.revoked == 0 && (k.level == ADMIN || k.level == MANAGER));
        } else return false;
    } 

    /**
     * @notice Approve the identity
     */
    function approveIdentity(bytes32 _identity) external override onlyRole(VERIFIER_ROLE) {
        _approveIdentity(_identity);
    }

    /**
     * @notice Compromise the identity
     */
    function compromiseIdentity(bytes32 _identity) external override onlyRole(BOUNCER_ROLE) {
        require(identities[_identity].date > 0, "identity not registered");
        require(identities[_identity].compromised == 0, "already compromised");
        identities[_identity].compromised = block.timestamp;
        emit IdentityCompromised(_identity);
    } 


    /**
     * @notice Apply autoApprove value
     */
    function applyAutoApprove(bool _autoApprove) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require (autoApprove !=_autoApprove, "already set");
        autoApprove = _autoApprove;
    }

    function _approveIdentity(bytes32 _identity) private {
        require(identities[_identity].date > 0, "identity not registered");
        require(identities[_identity].approved == 0, "already approved");
        identities[_identity].approved = block.timestamp;
        emit IdentityApproved(_identity);

    }

    function _removeKey(bytes32 _ukey, bytes32 _tkey) private {
        require(identities[_ukey].date > 0, "identity not registered");
        require(identityKeys[_ukey][_tkey].level == 0, "key not registered");

        identityKeyItems[_ukey].remove(_tkey, true);
        delete identityKeys[_ukey][_tkey];

        emit KeyRemoved(_ukey, _tkey);
    } 

    function _voidKey(bytes32 _ukey, bytes32 _tkey) private {
        require(identities[_ukey].date > 0, "identity not registered");
        require(identityKeys[_ukey][_tkey].level == 0, "key not registered");
        require(identityKeys[_ukey][_tkey].revoked > 0, "key already revoked");
        identityKeys[_ukey][_tkey].revoked = block.timestamp;

        emit KeyVoided(_ukey, _tkey); 
    }     

    function _registerIdentity(address _user, string calldata _name, string calldata _url) private returns (bytes32){
        bytes32 key = keccak256(abi.encodePacked(_user));
        require(identities[key].date == 0, "identity already registered");
        //metdata
        identities[key].name = _name;
        identities[key].url = _url;
        identities[key].date = block.timestamp;
        // root entity is an admin
        identityKeys[key][key].validFrom = block.timestamp;
        identityKeys[key][key].level = ADMIN;
        identityKeys[key][key].account = _user;
        identityKeyItems[key].push(key);

        emit IdentityRegistered(key, _name, _url);
        emit KeyRegistered(key, key, ADMIN);

        if (autoApprove) {
            // automatically approve identity
            _approveIdentity(key);
        }
        return key;
    }

    function _updateIdentity(bytes32 _key, string calldata _name, string calldata _url) private {
        require(identities[_key].date > 0, "identity not registered");
        identities[_key].name = _name;
        identities[_key].url = _url;
        emit IdentityUpdated(_key, _name, _url);
    }

    function _registerKey(bytes32 _ukey, address _account, uint256 _level, uint256 _validTo) private {
        require(_level > 0, "level is not specified");
        require(identities[_ukey].date > 0, "identity not registered");
        bytes32 _tkey = keccak256(abi.encodePacked(_account));
        require(identityKeys[_ukey][_tkey].validFrom == 0, "key already registered");
        identityKeys[_ukey][_tkey].account = _account;
        identityKeys[_ukey][_tkey].validFrom = block.timestamp;
        identityKeys[_ukey][_tkey].validTo = _validTo;
        identityKeys[_ukey][_tkey].level = _level;
        identityKeyItems[_ukey].push(_tkey);

        emit KeyRegistered(_ukey, _tkey, _level);
    } 

    function nonces(address user) public view virtual returns (uint256) {
        return _nonces[user];
    }

}