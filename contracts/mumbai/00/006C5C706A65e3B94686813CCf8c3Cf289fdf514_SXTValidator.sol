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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

/// @title Admin related functionalities
/// @dev This conntract is abstract. It is inherited in SXTApi and SXTValidator to set and handle admin only functions

abstract contract Admin {
    /// @dev Address of admin set by inheriting contracts
    address public admin;

    /// @notice Modifier for checking if Admin address has called the function
    modifier onlyAdmin() {
        require(msg.sender == getAdmin(), "admin only function");
        _;
    }

    /**
     * @notice Get the address of Admin wallet
     * @return adminAddress Address of Admin wallet set in the contract
     */
    function getAdmin() public view returns (address adminAddress) {
        return admin;
    }

    /**
     * @notice Set the address of Admin wallet
     * @param  adminAddress Address of Admin wallet to be set in the contract
     */
    function setAdmin(address adminAddress) public onlyAdmin {
        admin = adminAddress;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface ISXTValidator {

    // Structure for storing request data
    struct SXTRequest {
        bytes32 requestId;
        uint128 createdAt;
        uint128 expiredAt;
        bytes4 callbackFunctionSignature;
        address callbackAddress;
    }

    // Structure for storing signer data
    struct Signer {
        bool active;
        // Index of oracle in signersList/transmittersList
        uint8 index;
    }

    // Structure for storing config arguments of SXTValidator Contract
    struct ValidatorConfigArgs {
        address[] signers;
        uint8 f;
        bytes onchainConfig;
        uint64 offchainConfigVersion;
        bytes offchainConfig;
    }
    /**
     * Function for registering a new request in SXTValidator
     * @param callbackAddress Address of user smart contract which sent the request
     * @param callbackFunctionSignature Signature of the callback function from user contract, which SXTValiddator should call for returning response
     */    
    function registerSXTRequest(
        address callbackAddress,
        bytes4 callbackFunctionSignature
    ) external returns (SXTRequest memory, bytes memory);

    /**
     * Set maximum number of oracles to allow
     * @param count New maximum number of oracles to allow
     * @param oracleMask New Oracle mask to check the signature duplication
     */
    function setMaxOracleCount(uint64 count, uint256 oracleMask ) external;

    /**
     * Event emitted when new SXTApi Contract is updated in contract
     * @param sxtApi Address of new SXTApi contract
     */    
     event SXTApiRegistered(address indexed sxtApi);

    /**
     * Event emitted when new request expiry duration is updated in contract
     * @param expireTime Duration of seconds in which a request should expire
     */
    event SXTRequestExpireTimeRegistered(uint256 expireTime);
    
    /**
     * Event emitted when Maximum number of possible oracles is updated in contract
     * @param count New maximum number of oracles to allow
     */
    event SXTMaximumOracleCountRegistered(uint64 count);

    /**
     * Event emitted when the response is received by SXTValidator contract, for a request
     * @param requestId Request ID for which response received
     * @param data Response received in encoded format
     */
    event SXTResponseRegistered(bytes32 indexed requestId, bytes data);

    /**
     * Event emitted when config arguments are updated in the contract
     * @param prevConfigBlockNumber block numberi which previous config was set
     * @param configCount Number of times the contract config is updated till now
     * @param signers Array of list of valid signers for a response
     * @param onchainConfig Encoded version of config args stored onchain
     * @param offchainConfigVersion Version of latest config
     * @param offchainConfig Encoded version of config args stored offchain
     */
    event SXTConfigRegistered(
        uint32 prevConfigBlockNumber,
        uint64 configCount,
        address[] signers,
        bytes onchainConfig,
        uint64 offchainConfigVersion,
        bytes offchainConfig
    );
}

/**
 ________  ________  ________  ________  _______   ________  ________   ________  _________  ___  _____ ______   _______      
|\   ____\|\   __  \|\   __  \|\   ____\|\  ___ \ |\   __  \|\   ___  \|\   ___ \|\___   ___\\  \|\   _ \  _   \|\  ___ \     
\ \  \___|\ \  \|\  \ \  \|\  \ \  \___|\ \   __/|\ \  \|\  \ \  \\ \  \ \  \_|\ \|___ \  \_\ \  \ \  \\\__\ \  \ \   __/|    
 \ \_____  \ \   ____\ \   __  \ \  \    \ \  \_|/_\ \   __  \ \  \\ \  \ \  \ \\ \   \ \  \ \ \  \ \  \\|__| \  \ \  \_|/__  
  \|____|\  \ \  \___|\ \  \ \  \ \  \____\ \  \_|\ \ \  \ \  \ \  \\ \  \ \  \_\\ \   \ \  \ \ \  \ \  \    \ \  \ \  \_|\ \ 
    ____\_\  \ \__\    \ \__\ \__\ \_______\ \_______\ \__\ \__\ \__\\ \__\ \_______\   \ \__\ \ \__\ \__\    \ \__\ \_______\
   |\_________\|__|     \|__|\|__|\|_______|\|_______|\|__|\|__|\|__| \|__|\|_______|    \|__|  \|__|\|__|     \|__|\|_______|
   \|_________|         
 */

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./abstract/Admin.sol";

import "./interfaces/ISXTValidator.sol";

import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";


/// @title SXTValidator registers request and enables request fulfillment
/// @dev This conntract will be deployed by SXT team, used fulfill the request by Oracle SXT Node

contract SXTValidator is Admin, ISXTValidator {
    using ECDSA for bytes32;

    // SXTValidator contract version
    uint64 private constant VERSION = 1;

    // Todo should be immutable
    uint128 private constant chainId = 5;

    // For Checking Duplication of signatures
    uint256 public sxt_oracleMask = 0x0001010101010101010101010101010101010101010101010101010101010101;

    // Maximum number of oracles the offchain reporting protocol is designed for
    uint64 public sxt_maxNumOracles = 31;

    // Request Expire time
    uint256 private sxt_requestExpireTime = 5 minutes;

    /// @dev SXTValidator contract nonce
    uint256 private nonce;

    // incremented each time a new config is posted. This count is incorporated
    // into the config digest to prevent replay attacks.
    uint32 private sxt_configCount;

    // makes it easier for offchain systems to extract config from logs
    uint32 private sxt_latestConfigBlockNumber;

    /// @dev SXTApi contract address
    address public sxtApi;

    /// @dev signersList contains the signing address of each oracle
    address[] private sxt_signersList;

    /// @dev SXT oracle signer addresses
    mapping(address => Signer) public sxt_signers;

    ValidatorConfigArgs public sxt_configArgs;

    /// @dev SXTRequest data
    mapping(bytes32 => bytes) public requests;

    /**
     * @dev Constructor function
     * @param api SXTApi contract address
     */
    constructor(address api) {
        admin = msg.sender;
        sxtApi = api;    
    }

    /**
     * Set SXTApi contract address
     * @param api SXTApi contract address
     */
    function setSXTApi(address api) external onlyAdmin {
        sxtApi = api;
        emit SXTApiRegistered(api);
    }

    /**
     * @notice Set expire time for requests
     * @param expireTime New expire time duration to set for requests
     */
    function setSXTRequestExpireTime(uint256 expireTime) external onlyAdmin {
        require( expireTime > 0 && expireTime != sxt_requestExpireTime, "SXTValidator: Invalid Expire Time");

        sxt_requestExpireTime = expireTime;
        emit SXTRequestExpireTimeRegistered( expireTime );
    }

    /**
     * @notice Set maximum number of oracles to allow signing the response
     * @param count New  maximum number of oracles to allow signing the response
     * @param oracleMask New Oracle mask to check the signature duplication
     */
    function setMaxOracleCount(uint64 count, uint256 oracleMask ) external onlyAdmin {
        require( count > 0 && count != sxt_maxNumOracles, "SXTValidator: Invalid Count");
        sxt_maxNumOracles = count;
        sxt_oracleMask = oracleMask;
        emit SXTMaximumOracleCountRegistered( count );
    }

    /**
     * @notice Set Oracle signers configuration
     * @param signers Valid signers for a response
     * @param f Number of faulty oracles
     * @param offchainConfigVersion Version of latest config
     * @param offchainConfig Encoded version of config args stored offchain
     */
    function setConfig(
        address[] calldata signers,
        uint8 f,
        uint64 offchainConfigVersion,
        bytes calldata offchainConfig
    ) external onlyAdmin {
        require(
            signers.length <= sxt_maxNumOracles,
            "SXTValidator: Too many oracles"
        );
        require(3 * f < signers.length, "faulty-oracle f too high");

        ValidatorConfigArgs memory args = ValidatorConfigArgs({
            signers: signers,
            f: f,
            onchainConfig: abi.encodePacked(
                VERSION,
                offchainConfigVersion,
                offchainConfig
            ),
            offchainConfigVersion: offchainConfigVersion,
            offchainConfig: offchainConfig
        });

        // Remove old signers/transmitters addresses
        uint256 oldLength = sxt_signersList.length;
        for (uint256 i = 0; i < oldLength; i++) {
            address signer = sxt_signersList[i];
            delete sxt_signers[signer];
        }
        delete sxt_signersList;

        // Add new signers addresses
        for (uint256 i = 0; i < args.signers.length; i++) {
            require(
                !sxt_signers[args.signers[i]].active,
                "repeated signer address"
            );
            sxt_signers[args.signers[i]] = Signer({
                active: true,
                index: uint8(i)
            });
        }
        sxt_signersList = args.signers;

        uint32 prevConfigBlockNumber = sxt_latestConfigBlockNumber;
        sxt_latestConfigBlockNumber = uint32(block.number);
        sxt_configCount++;
        sxt_configArgs = args;

        emit SXTConfigRegistered(
            prevConfigBlockNumber,
            sxt_configCount,
            args.signers,
            args.onchainConfig,
            args.offchainConfigVersion,
            args.offchainConfig
        );
    }

    /**
     * Register SXT Request
     * @dev Only SXTApi contract will be able to call this function
     * @param callbackAddress callback contract address
     * @param callbackFunctionSignature callback function signature
     */
    function registerSXTRequest(
        address callbackAddress,
        bytes4 callbackFunctionSignature
    )
        external
        override
        onlySXTApi
        returns (SXTRequest memory request, bytes memory paramHash)
    {
        require(
            callbackAddress != address(0),
            "SXTValidator: callback address is invalid"
        );
        require(
            callbackFunctionSignature != bytes32(0),
            "SXTValidator: callback function is invalid"
        );

        nonce++;
        bytes32 requestId = keccak256(abi.encodePacked(address(this), nonce));

        request = SXTRequest({
            requestId: requestId,
            createdAt: uint128(block.timestamp),
            expiredAt: uint128(block.timestamp + sxt_requestExpireTime),
            callbackFunctionSignature: callbackFunctionSignature,
            callbackAddress: callbackAddress
        });
        paramHash = _buildParamHash(request);
        requests[requestId] = paramHash;
    }

    /**
     * @notice Send Api call response to UserClient contract
     * @param requestId ID of request to send response for
     * @param signatures Array of signatures of all oracle nodes
     * @param response encoded response
     */
    function fulfill(
        bytes32 requestId,
        bytes[] memory signatures,
        bytes memory response
    ) external {

        bytes32 request = requestId;
        bytes memory report = response;

        require(
            sxt_signersList.length <= sxt_maxNumOracles,
            "SXTValidator: too many oracles"
        );

        ValidatorConfigArgs memory args = sxt_configArgs;
        uint256 length = args.f + 1;
        require(signatures.length == length, "wrong number of signatures");

        // i-th byte counts number of sigs made by i-th signer
        uint256 signedCount = 0;

        Signer memory signer;
        bytes memory signature;
        for (uint256 i = 0; i < length; i++) {
            signature = signatures[i];
            address signerAddress = _getSigner(
                request,
                report,
                signature
            );
            signer = sxt_signers[signerAddress];
            require(signer.active, "signature error");
            unchecked {
                signedCount += 1 << (8 * signer.index);
            }

            // Validate the signer duplication
            require(
                signedCount & sxt_oracleMask == signedCount,
                    // for 31 oracles
                    // 0x0001010101010101010101010101010101010101010101010101010101010101 == 
                    // for 1 oracle
                    // 0x0001 ==                                         
                "SXTValidator: duplicate signer"
            );
        }

        _fulfill(request, report);
    }

    /// @dev internal function to fulfill a request
    function _fulfill(bytes32 requestId, bytes memory response)
        internal
        returns (bool)
    {
        bytes memory req = requests[requestId];
        require(req.length != 0, "SXTValidator: Invalid requestId");

        SXTRequest memory request = _decodeParamHash(req);
        require(
            request.expiredAt >= block.timestamp,
            "SXTValidator: request was expired"
        );

        // decode bytes response to string[][]
        string[][] memory decodedData = abi.decode(response, (string[][]));

        (bool success, ) = request.callbackAddress.call(
            abi.encodeWithSelector(
                request.callbackFunctionSignature,
                requestId,
                decodedData
            )
        );
        require(success, "SXTValidator: fulfilling is failed");
        emit SXTResponseRegistered(requestId, response);
        delete requests[requestId];
        return success;
    }

    /**
     * @notice Builds hash of all request parameters
     * @param request struct instange of a request
     */
    function _buildParamHash(SXTRequest memory request)
        internal
        pure
        returns (bytes memory)
    {
        return
            abi.encode(
                request.requestId,
                request.createdAt,
                request.expiredAt,
                request.callbackFunctionSignature,
                request.callbackAddress
            );
    }

    /**
     * @dev internal function to decode the parameters hash
     * @param request struct instange of a request
     * @return request structure instance
     */
    function _decodeParamHash(bytes memory paramHash)
        internal
        pure
        returns (SXTRequest memory request)
    {
        (
            bytes32 requestId,
            uint128 createdAt,
            uint128 expiredAt,
            bytes4 callbackSignature,
            address callbackAddress
        ) = abi.decode(paramHash, (bytes32, uint128, uint128, bytes4, address));
        request = SXTRequest({
            requestId: requestId,
            createdAt: createdAt,
            expiredAt: expiredAt,
            callbackFunctionSignature: callbackSignature,
            callbackAddress: callbackAddress
        });
    }

    /**
     * Verify signature
     */
    function _getSigner(
        bytes32 requestId,
        bytes memory response,
        bytes memory signature
    ) public pure returns (address) {
        bytes32 signedHash = keccak256(
            abi.encodePacked(requestId, response)
        );
        bytes32 messageHash = signedHash.toEthSignedMessageHash();
        return messageHash.recover(signature);
    }

    /// @notice get the list of valid signers set
    function getSigners() external view returns (address[] memory) {
        return sxt_signersList;
    }

    /// @notice modifier for checking if caller is SXTApi contract
    modifier onlySXTApi() {
        require(msg.sender == sxtApi, "SXTValidator: only SXTApi can call");
        _;
    }
}