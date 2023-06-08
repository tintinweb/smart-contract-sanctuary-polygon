// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        // On the first call to nonReentrant, _status will be _NOT_ENTERED
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

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
pragma solidity 0.8.17;

/// @title IMarketplaceNonCustodial
/// @author LYNC WORLD(https://lync.world)
/// @notice This is an Interface for the Non-Custodial Marketplace.
interface IMarketplaceNonCustodial {

    /// @notice NFTStandard is an enum that represents the NFT standard of the NFTs being listed.
    /// @notice E721 represents the ERC721 NFT standard.
    /// @notice E1155 represents the ERC1155 NFT standard.
    enum NFTStandard {
        E721,
        E1155
    }

    /// @notice Order is a struct that represents a listing of NFTs on the marketplace.
    /// @dev Order will be referred to as listing in some places. Both terms are used interchangeably.
    /// @param orderId is the unique identifier of the order.
    /// @param nftAddress is the address of the NFT contract.
    /// @param standard is the NFT standard of the NFTs being listed.
    /// @param tokenId is the ID of the NFT being listed.
    /// @param quantity is the quantity of NFTs being listed.
    /// @param pricePerItem is the price per NFT being listed.
    /// @param seller is the address of the seller.
    struct Order {
        uint256 orderId;
        address nftAddress;
        NFTStandard standard;
        uint256 tokenId;
        uint256 quantity;
        uint256 pricePerItem;
        address payable seller;
    }
    
    /// @notice Buyer is a struct that represents a buyer of NFTs on the marketplace.
    /// @param buyer is the address of the buyer.
    /// @param quantityBought is the quantity of NFTs bought.
    /// @param buyPricePerItem is the price per NFT bought.
    struct Buyer {
        address buyer;
        uint256 quantityBought;
        uint256 buyPricePerItem;
    }

    /// @notice InvalidNFTStandard is an error that is thrown if the NFT standard is invalid.
    error InvalidNFTStandard(address nftAddress);

    /// @notice ItemsNotApprovedForListing is an error that is thrown if the NFTs are not approved for listing.
    error ItemsNotApprovedForListing();

    /// @notice InvalidOrderIdInput is an error that is thrown if the order ID input is invalid.
    error InvalidOrderIdInput(uint256 orderId);

    /// @notice OrderClosed is an error that is thrown if the order is closed.
    error OrderClosed(uint256 orderId);

    /// @notice InvalidCaller is an error that is thrown if the function caller is invalid.
    error InvalidCaller(address expected, address caller);

    /// @notice InactiveOrder is an error that is thrown if the order is inactive.
    error InactiveOrder(uint256 orderId);

    /// @notice NotEnoughItemsOwnedByCaller is an error that is thrown if the caller does not own enough NFTs.
    error NotEnoughItemsOwnedByCaller(address nftAddress, uint256 tokenId);

    /// @notice ZeroPricePerItemInput is an error that is thrown if the price per NFT input is provided as zero.
    error ZeroPricePerItemInput(uint256 input);

    /// @notice InvalidQuantityInput is an error that is thrown if the quantity input is invalid.
    error InvalidQuantityInput(uint256 input);

    /// @notice ItemAlreadyOwned is an error that is thrown if the caller already owns the NFT.
    error ItemAlreadyOwned(address nftAddress, uint256 tokenId);

    /// @notice ModifyListingFailed is an error that is thrown if the modify listing function fails due to invalid inputs.
    error ModifyListingFailed(uint256 newPriceInput, uint256 qtyToAdd);

    /// @notice ItemsListed is an event that is emitted when NFTs are listed on the marketplace.
    /// @param orderIdAssigned is the unique identifier of the order.
    /// @param nftAddress is the address of the NFT contract.
    /// @param standard is the NFT standard of the NFTs being listed.
    /// @param tokenId is the ID of the NFT being listed.
    /// @param quantity is the quantity of NFTs being listed.
    /// @param pricePerItem is the price per NFT being listed.
    /// @param seller is the address of the seller.
    event ItemsListed(
        uint256 indexed orderIdAssigned,
        address indexed nftAddress,
        NFTStandard standard,
        uint256 indexed tokenId,
        uint256 quantity,
        uint256 pricePerItem,
        address seller
    );

    /// @notice ItemsBought is an event that is emitted when NFTs are bought on the marketplace.
    /// @param orderId is the unique identifier of the order/listing.
    /// @param nftAddress is the address of the NFT contract.
    /// @param standard is the NFT standard of the NFTs being bought.
    /// @param tokenId is the ID of the NFT being bought.
    /// @param buyQty is the quantity of NFTs being bought.
    /// @param soldFor is the total price of the NFTs bought.
    /// @param buyer is the address of the buyer.
    event ItemsBought(
        uint256 indexed orderId,
        address indexed nftAddress,
        NFTStandard standard,
        uint256 indexed tokenId,
        uint256 buyQty,
        uint256 soldFor,
        address buyer
    );

    /// @notice ItemsModified is an event that is emitted when a order/listing is modified.
    /// @param orderId is the unique identifier of the order/listing.
    /// @param nftAddress is the address of the NFT contract.
    /// @param standard is the NFT standard of the NFTs being modified.
    /// @param tokenId is the token ID of the NFT being modified.
    /// @param newPricePerItem is the new price per NFT.
    /// @param qtyToAdd is the quantity of NFTs being added to the listing.
    event ItemsModified(
        uint256 indexed orderId,
        address indexed nftAddress,
        NFTStandard standard,
        uint256 indexed tokenId,
        uint256 newPricePerItem,
        uint256 qtyToAdd
    );

    /// @notice ItemsCancel is an event that is emitted when a order/listing is cancelled.
    /// @param orderId is the unique identifier of the order/listing.
    /// @param nftAddress is the address of the NFT contract.
    /// @param standard is the NFT standard of the NFTs being cancelled.
    /// @param tokenId is the token ID of the NFT being cancelled.
    /// @param unlistedBy is the address of the seller.
    event ItemsCancel(
        uint256 indexed orderId,
        address indexed nftAddress,
        NFTStandard standard,
        uint256 indexed tokenId,
        address unlistedBy
    );

    /// @notice AdminFeesChanged is an event that is emitted when the admin fees percentage is changed.
    /// @param newPercentFees is the new admin fees percentage.
    event AdminFeesChanged(uint256 newPercentFees);

    /// @notice listItem is a function that lists NFTs on the marketplace.
    /// @notice The NFTs being listed must be approved for listing.
    /// @param _nftAddress is the address of the NFT contract.
    /// @param _standard is the NFT standard of the NFTs being listed.
    /// @param _tokenId is the ID of the NFT being listed.
    /// @param _quantity is the quantity of NFTs being listed.
    /// @param _pricePerItem is the price per NFT being listed.
    function listItem(
        address _nftAddress,
        NFTStandard _standard,
        uint256 _tokenId,
        uint256 _quantity,
        uint256 _pricePerItem
    ) external;

    /// @notice modifyListing is a function that modifies a listing on the marketplace.
    /// @notice This function can only be called by the seller.
    /// @param _orderId is the unique identifier of the order/listing.
    /// @param _newPricePerItem is the new price per NFT. Pass in zero to not modify this.
    /// @param _qtyToAdd is the quantity of NFTs being added to the listing. Pass in zero to not modify this.
    function modifyListing(
        uint256 _orderId,
        uint256 _newPricePerItem,
        uint256 _qtyToAdd
    ) external;

    /// @notice cancelListing is a function that cancels a listing on the marketplace.
    /// @notice This function can only be called by the seller.
    /// @param _orderId is the unique identifier of the order/listing.
    function cancelListing(uint256 _orderId) external;

    /// @notice buyItem is a function that can be used to buy NFTs on the marketplace.
    /// @param _orderId is the unique identifier of the order/listing.
    /// @param _qtyToBuy is the quantity of NFTs being bought.
    function buyItem(uint256 _orderId, uint256 _qtyToBuy) external payable;

    /// @notice isOrderActive is a function that returns whether an order is active or not.
    /// @param _orderId is the unique identifier of the order/listing.
    /// @return bool output is whether the order is active or not.
    function isOrderActive(uint256 _orderId) external view returns (bool);

    /// @notice isERC721 is a function that returns whether an NFT is ERC721 or not.
    /// @param nftAddress is the address of the NFT contract.
    /// @return bool output is whether the NFT is ERC721 or not.
    function isERC721(address nftAddress) external view returns (bool);

    /// @notice isERC1155 is a function that returns whether an NFT is ERC1155 or not.
    /// @param nftAddress is the address of the NFT contract.
    /// @return bool output is whether the NFT is ERC1155 or not.
    function isERC1155(address nftAddress) external view returns (bool);

    /// @notice isOrderClosed is a function that returns whether an order is closed or not.
    /// @param _orderId is the unique identifier of the order/listing.
    /// @return bool output is whether the order is closed or not.
    function isOrderClosed(uint256 _orderId) external view returns (bool);

    /// @notice setAdmin is a function that sets the admin of the marketplace.
    /// @notice This function can only be called by the current admin.
    /// @param _newAddress is the address of the new admin.
    function setAdmin(address _newAddress) external;

    /// @notice setFeesForAdmin is a function that sets the admin fees percentage.
    /// @notice This function can only be called by the current admin.
    /// @param _percentFees is the new admin fees percentage.
    function setFeesForAdmin(uint256 _percentFees) external;

    /// @notice withdrawFunds is a function that withdraws funds from the marketplace.
    /// @notice This function can only be called by the current admin.
    /// @param _to Address to withdraw funds to.
    function withdrawFunds(address _to) external;

}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "../marketplace/IMarketplaceNonCustodial.sol";
import "../RentAndLend/IRentLendMarketplace.sol";

/// @title ILyncMultiSig
/// @author LYNC WORLD (https://lync.world)
/// @notice This is the interface for LyncMultiSig contract
interface ILyncMultiSig{

    /// @notice This enum represents the contract type for which the transaction is being performed
    /// @notice MARKETPLACE: Marketplace contract
    /// @notice RENTLEND: RentLend contract
    enum ContractType{
        MARKETPLACE,
        RENTLEND
    }

    /// @notice This enum represents the transaction type being performed
    /// @notice CHANGE_ADMIN: Change admin of the contracts
    /// @notice CHANGE_ADMIN_FEE: Change admin fee percent of the contracts
    /// @notice WITHDRAW_FUNDS: Withdraw funds from the contracts
    /// @notice CHANGE_MIN_RENT_DUE: Change minimum rent duration for the RentLend contract
    /// @notice CHANGE_AUTOMATION: Change automation address of the RentLend contract
    enum AdminTxn{
        CHANGE_ADMIN,
        CHANGE_ADMIN_FEE,
        WITHDRAW_FUNDS,
        CHANGE_MIN_RENT_DUE,
        CHANGE_AUTOMATION
    }

    /// @notice This struct represents the transaction being performed
    /// @param contractType: Contract type for which the transaction is being performed
    /// @param txnType: Transaction type being performed
    /// @param addressInput: Address input for the transaction
    /// @param uintInput: uint256 input for the transaction
    struct Txn{
        ContractType contractType;
        AdminTxn txnType;
        address addressInput;
        uint256 uintInput;
    }

    /// @notice This event is emitted when a transaction is performed
    /// @param _contractType: Contract type for which the transaction is being performed
    /// @param _txnType: Transaction type being performed
    /// @param _addressInput: Address input for the transaction
    /// @param _uintInput: uint256 input for the transaction
    event AdminTxnPerformed(
        ContractType indexed _contractType,
        AdminTxn indexed _txnType,
        address _addressInput,
        uint256 _uintInput
    );

    /// @notice This event is emitted when funds are received in the contract
    /// @param _from: Address from which funds are received
    /// @param _amount: Amount of funds received
    event FundsReceived(address indexed _from, uint256 _amount);

    /// @notice This event is emitted when funds are withdrawn from the contract
    /// @param _to: Address to which funds are withdrawn
    event FundsWithdrawn(address indexed _to);

    /// @notice This function checks if the address is an owner of the contract
    /// @param _addr is the address to check
    /// @return isOwner is True if the address is an owner, false otherwise
    function isOwner(address _addr) external view returns (bool isOwner);

    /// @notice This function returns the owner of the contract at the given index
    /// @param _index is the index of the owners array
    /// @return owner is the address at the given index
    function owners(uint256 _index) external view returns (address owner);

    /// @notice This function returns the number of valid signatures required for a transaction
    /// @return required is the number of valid signatures required for a transaction
    function confirmationsRequired() external view returns (uint256 required);

    /// @notice This function returns the address of the marketplace contract
    function marketplace() external view returns (IMarketplaceNonCustodial marketplace);

    /// @notice This function returns the address of the RentLend contract
    function rentLend() external view returns (IRentLendMarketplace rentLend);

    /// @notice This function returns the current nonce
    /// @dev Nonce is incremented after every transaction
    /// @return nonce is the current nonce
    function nonce() external view returns (uint256 nonce);
    
    /// @notice Reference timestamp for calculating the hashTimestamp
    /// @dev This is used to calculate the hash that is signed by the owners
    /// @return referenceTimestamp is the reference timestamp
    function referenceTimestamp() external view returns (uint256 referenceTimestamp);

    /// @notice This function returns the current hashTimestamp
    /// @dev This is used to calculate the hash that is signed by the owners
    /// @return hashTimestamp is the hashTimestamp
    function getHashTimestamp() external view returns (uint256 hashTimestamp);

    /// @notice This function returns the hash for a transaction that is signed by the owners
    /// @param _tx is the transaction for which the hash is to be calculated
    /// @dev The hash will change after every transaction or after every 5 minutes
    /// @return hash is the hash for the transaction
    function getHash(Txn calldata _tx) external view returns (bytes32 hash);

    /// @notice This function returns the hash for a transaction that is signed by the owners
    /// @notice This hash is used for the transaction that withdraws funds from the contract
    /// @dev The hash will change after every transaction or after every 5 minutes
    /// @return hash is the hash for the transaction
    function getLocalTxnHash() external view returns (bytes32 hash);

    /// @notice This function returns the signer of the hash
    /// @param _hash is the hash for which the signer is to be found
    /// @param _sig is the signature
    /// @return signerAddress is the address of the signer
    function getSigner(
        bytes32 _hash,
        bytes calldata _sig
    ) external pure returns (address signerAddress);

    /// @notice This function performs the admin transactions for marketplace and RentLend contracts
    /// @notice This function can only be called by the owners of the contract
    /// @notice The required number of owners must sign the hash returned by getHash() to perform the transaction
    /// @notice This function takes an array of signatures as input to verify the owners
    /// @param _tx is the transaction to be performed
    /// @param sigs is the array of signatures
    function performAdminTxn(Txn calldata _tx, bytes[] calldata sigs) external;

    /// @notice This function withdraws funds from the contract
    /// @notice This function can only be called by the owners of the contract
    /// @notice The required number of owners must sign the local transaction hash returned by getLocalTxnHash() to withdraw funds
    /// @notice This function takes an array of signatures as input to verify the owners
    /// @param _to is the address to which funds are to be withdrawn
    /// @param sigs is the array of signatures
    function withdrawAnyFunds(address _to, bytes[] calldata sigs) external;
}

// SPDX-License-Identifier: None
pragma solidity 0.8.17;

import "./ILyncMultiSig.sol";
import "../marketplace/IMarketplaceNonCustodial.sol";
import "../RentAndLend/IRentLendMarketplace.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

/// @title LyncMultiSig contract
/// @author LYNC WORLD (https://lync.world)
/// @notice This contract is used to perform admin transactions on Marketplace and RentLend contracts
contract LyncMultiSig is ILyncMultiSig, ReentrancyGuard {

    using ECDSA for bytes32;

    /// @notice owners array contains the addresses of the owners of the contract
    address[] public owners;

    /// @notice confirmationsRequired represents the number of confirmations required for a transaction to be performed
    uint public confirmationsRequired;

    /// @notice marketplace represents the address of the Marketplace contract
    IMarketplaceNonCustodial public immutable marketplace;

    /// @notice rentLend represents the address of the RentLend contract
    IRentLendMarketplace public immutable rentLend;

    /// @notice chainId represents the chain id of the network on which the contract is deployed
    uint256 public immutable chainId;

    /// @notice nonce represents the current nonce of the contract
    uint256 public nonce;

    /// @notice Reference timestamp to calculate the hashTimestamp
    uint256 public referenceTimestamp;

    /// @notice isOwner mapping is used to check if an address is an owner of the contract
    /// @dev address => bool
    mapping(address => bool) public isOwner;

    /// @notice executed mapping is used to check if a hash has been used to perform a transaction
    /// @dev bytes32 => bool
    mapping(bytes32 => bool) private executed;

    /// @notice usedSigs mapping is used to check if a signature has been used to perform a transaction
    /// @dev bytes => bool
    mapping(bytes => bool) private usedSigs;

    /// @notice Constructor of the contract
    /// @dev Initializes the owners array, confirmationsRequired, marketplace, rentLend, chainId, nonce and referenceTimestamp
    /// @param _owners Array of addresses of the owners of the contract
    /// @param _required Number of signatures of owners required to perform a transaction
    /// @param _marketplace Address of the Marketplace contract
    /// @param _rentLend Address of the RentLend contract
    constructor(
        address[] memory _owners,
        uint256 _required,
        address _marketplace,
        address _rentLend
    ) {
        require(_owners.length > 1, "Invalid no. of owners!");
        require(_required <= _owners.length, "Invalid confirmations required!");

        for (uint i = 0; i < _owners.length; i++) {
            address owner = _owners[i];

            require(owner != address(0), "Invalid owner!");
            require(!isOwner[owner], "Owner not unique!");

            isOwner[owner] = true;
            owners.push(owner);
        }
        require(_marketplace != address(0), "Marketplace can't be null!");
        require(_rentLend != address(0), "RentLend can't be null!");
        uint256 id;
        assembly {
            id := chainid()
        }
        chainId = id;
        nonce = 0;
        referenceTimestamp = block.timestamp;
        confirmationsRequired = _required;
        marketplace = IMarketplaceNonCustodial(_marketplace);
        rentLend = IRentLendMarketplace(_rentLend);
    }

    /// @notice Modifier to check if the caller is an owner of the contract
    modifier onlyOwner() {
        require(isOwner[msg.sender], "Caller not an owner!");
        _;
    }

    /// @notice Modifier to check if the transaction input is valid
    /// @param _tx Transaction input to be checked
    /// @dev Checks if the transaction type is valid and if the inputs are valid
    /// @dev Txn struct is defined in ILyncMultiSig interface
    modifier validTxnInput(Txn calldata _tx) {
        if (_tx.contractType == ContractType.MARKETPLACE) {
            if (
                _tx.txnType == AdminTxn.CHANGE_MIN_RENT_DUE ||
                _tx.txnType == AdminTxn.CHANGE_AUTOMATION
            ) revert("Invalid txn type!");
        }
        if (_tx.txnType == AdminTxn.CHANGE_ADMIN)
            require(
                _tx.addressInput != address(0),
                "Address input can't be null!"
            );
        else if (_tx.txnType == AdminTxn.CHANGE_ADMIN_FEE)
            require(
                _tx.uintInput > 0 && _tx.uintInput < 100,
                "Invalid uint input!"
            );
        else if (_tx.txnType == AdminTxn.WITHDRAW_FUNDS)
            require(
                _tx.addressInput != address(0),
                "Address input can't be null!"
            );
        else if (_tx.txnType == AdminTxn.CHANGE_AUTOMATION) {
            require(
                _tx.addressInput != address(0),
                "Address input can't be null!"
            );
        }
        _;
    }

    /// @notice Function to get the hash timestamp
    /// @dev This hash will change every 5 minutes
    /// @return hashTimestamp for the current hash
    function getHashTimestamp() public view returns (uint256 hashTimestamp) {
        uint256 difference = (block.timestamp - referenceTimestamp);
        uint256 lapses = (difference / 5 minutes); // floor division
        hashTimestamp = (lapses * 5 minutes) + referenceTimestamp;
    }

    /// @notice Function to get the current hash for admin transactions on Marketplace and RentLend contracts
    /// @dev Hash is calculated using the address of the contract, chainId, nonce and hashTimestamp and the transaction input
    /// @dev This hash will change every 5 minutes and will be signed by the owners of the contract
    /// @dev Hash will change because of the hashTimestamp changing every 5 minutes
    /// @return hash to be signed by the owners of the contract
    function getHash(Txn calldata _tx) public view returns (bytes32 hash) {
        hash = keccak256(
            abi.encodePacked(
                address(this),
                chainId,
                nonce,
                _tx.contractType,
                _tx.txnType,
                _tx.addressInput,
                _tx.uintInput,
                getHashTimestamp()
            )
        );
    }

    /// @notice Function to get the current hash the local transactions in this contract
    /// @dev Hash is calculated using the address of the contract, chainId, nonce and hashTimestamp
    /// @dev This hash will change every 5 minutes and will be signed by the owners of the contract
    /// @dev Hash will change because of the hashTimestamp changing every 5 minutes
    /// @return hash to be signed by the owners of the contract
    function getLocalTxnHash() public view returns (bytes32 hash) {
        hash = keccak256(
            abi.encodePacked(address(this), chainId, nonce, getHashTimestamp())
        );
    }

    /// @notice Function to get the signer of a hash
    /// @dev This function uses the hash and the signature to get the signer of the hash
    /// @param _hash Hash for which the signer is to be found
    /// @param _sig Signature of the hash
    /// @return signerAddress Address of the signer of the hash
    function getSigner(
        bytes32 _hash,
        bytes memory _sig
    ) public pure returns (address signerAddress) {
        bytes32 ethSignedHash = _hash.toEthSignedMessageHash();
        signerAddress = ethSignedHash.recover(_sig);
    }

    /// @notice Function to perform admin transactions on Marketplace and RentLend contracts
    /// @dev This function can only be called by the owners of the contract
    /// @dev The transaction input is checked for validity using the validTxnInput modifier
    /// @dev Txn struct is defined in ILyncMultiSig interface
    /// @param _tx Transaction input to be performed
    /// @param _sigs Signatures from signed hash by the owners of the contract
    function performAdminTxn(
        Txn calldata _tx,
        bytes[] calldata _sigs
    ) external onlyOwner validTxnInput(_tx) nonReentrant {
        bytes32 hash = getHash(_tx);
        _verifySignatures(hash, _sigs);
        if (_tx.txnType == AdminTxn.CHANGE_ADMIN) {
            _setAdmin(_tx.contractType, _tx.addressInput);
        } else if (_tx.txnType == AdminTxn.CHANGE_ADMIN_FEE) {
            _setFeesForAdmin(_tx.contractType, _tx.uintInput);
        } else if (_tx.txnType == AdminTxn.WITHDRAW_FUNDS) {
            _withdrawFunds(_tx.contractType, _tx.addressInput);
        } else if (_tx.txnType == AdminTxn.CHANGE_MIN_RENT_DUE) {
            _setMinRentDueSeconds(_tx.uintInput);
        } else if (_tx.txnType == AdminTxn.CHANGE_MIN_RENT_DUE) {
            _setAutomationAddress(_tx.addressInput);
        }
        executed[hash] = true;
        nonce += 1;
        referenceTimestamp = getHashTimestamp(); // update to last hashTimestamp
        emit AdminTxnPerformed(
            _tx.contractType,
            _tx.txnType,
            _tx.addressInput,
            _tx.uintInput
        );
    }

    /// @notice Internal function to verify the signatures of the owners of the contract
    /// @dev This function will revert if any condition is not met
    /// @dev This function is called by performAdminTxn function
    /// @dev This function checks for duplicate signatures and verifies the signatures of the owners of the contract
    /// @dev This function also checks if the number of signatures is greater than or equal to the required signatures
    /// @param hash Hash for which the signatures are to be verified
    /// @param _sigs Signatures generated by the owners of the contract by signing the hash from getHash function
    function _verifySignatures(bytes32 hash, bytes[] calldata _sigs) internal {
        require(!executed[hash], "Hash invalid or expired!");
        uint256 totalSigs = _sigs.length;
        require(
            totalSigs >= confirmationsRequired && totalSigs <= owners.length,
            "Invalid no of signatures!"
        );
        uint256 count = 0;
        for (uint256 i = 0; i < totalSigs; i++) {
            bytes memory sig = _sigs[i];
            require(!usedSigs[sig], "Duplicate signature!");
            usedSigs[sig] = true;
            address signerAddress = getSigner(hash, sig);
            if (isOwner[signerAddress]) count += 1;
        }
        require(
            count >= confirmationsRequired,
            "Signatures verification failed!"
        );
    }

    /// @notice Internal function to set the admin address for Marketplace and RentLend contracts
    /// @dev This function is called by performAdminTxn function
    /// @dev ContractType is an enum defined in ILyncMultiSig interface
    /// @param _contract Contract for which the admin address is to be changed
    /// @param _newAddress New admin address
    function _setAdmin(ContractType _contract, address _newAddress) internal {
        if (_contract == ContractType.MARKETPLACE) {
            marketplace.setAdmin(_newAddress);
        } else {
            rentLend.setAdmin(_newAddress);
        }
    }

    /// @notice Internal function to set the fees percent for admin for Marketplace and RentLend contracts
    /// @dev This function is called by performAdminTxn function
    /// @dev ContractType is an enum defined in ILyncMultiSig interface
    /// @param _contract Contract for which the fees percent for admin is to be changed
    /// @param _percentFees New fees percent for admin
    function _setFeesForAdmin(
        ContractType _contract,
        uint256 _percentFees
    ) internal {
        if (_contract == ContractType.MARKETPLACE) {
            marketplace.setFeesForAdmin(_percentFees);
        } else {
            rentLend.setFeesForAdmin(_percentFees);
        }
    }

    /// @notice Internal function to withdraw funds from Marketplace and RentLend contracts
    /// @dev This function is called by performAdminTxn function
    /// @dev ContractType is an enum defined in ILyncMultiSig interface
    /// @param _contract Contract from which the funds are to be withdrawn
    /// @param _to Address to which the funds are to be withdrawn
    function _withdrawFunds(ContractType _contract, address _to) internal {
        if (_contract == ContractType.MARKETPLACE) {
            marketplace.withdrawFunds(_to);
        } else {
            rentLend.withdrawFunds(_to);
        }
    }

    /// @notice Internal function to set the minimum rent due seconds for RentLend contract
    /// @dev This function is called by performAdminTxn function
    /// @param _minDuration New minimum rent due seconds
    function _setMinRentDueSeconds(uint256 _minDuration) internal {
        rentLend.setMinRentDueSeconds(_minDuration);
    }

    /// @notice Internal function to set the automation address for RentLend contract
    /// @dev This function is called by performAdminTxn function
    /// @param _newAddress New automation address
    function _setAutomationAddress(address _newAddress) internal {
        rentLend.setAutomationAddress(_newAddress);
    }

    /// @notice Function to withdraw any funds from this contract
    /// @dev This function can only be called by the owners of the contract
    /// @dev The owners of the contract should sign the hash from getLocalTxnHash function and pass the signatures as an argument
    /// @param _to Address to which the funds are to be withdrawn
    /// @param _sigs Signatures generated by the owners of the contract by signing the hash from getLocalTxnHash function
    function withdrawAnyFunds(
        address _to,
        bytes[] calldata _sigs
    ) external onlyOwner nonReentrant {
        bytes32 hash = getLocalTxnHash();
        _verifySignatures(hash, _sigs);
        (bool success, ) = payable(_to).call{value: (address(this).balance)}(
            ""
        );
        require(success, "Failed to withdraw funds!");
        emit FundsWithdrawn(_to);
        executed[hash] = true;
        nonce += 1;
        referenceTimestamp = getHashTimestamp(); // update to last hashTimestamp
    }

    /// @notice React to receiving ether
    receive() external payable {
        emit FundsReceived(msg.sender, msg.value);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

/// @title IRentLendMarketplace
/// @author LYNC WORLD (https://lync.world)
/// @notice This is the interface for the RentLendMarketplace contract
interface IRentLendMarketplace {

    /// @notice NFTStandard is an enum that represents the NFT standard of the NFTs being listed.
    /// @notice E721 represents the ERC721 NFT standard.
    /// @notice E1155 represents the ERC1155 NFT standard.
    enum NFTStandard {
        E721,
        E1155
    }

    /// @notice LendStatus is an enum that represents the status of the lending order.
    /// @notice LISTED represents the lending order is listed.
    /// @notice DELISTED represents the lending order is delisted.
    enum LendStatus {
        LISTED,
        DELISTED
    }

    /// @notice RentStatus is an enum that represents the status of the renting order.
    /// @notice RENTED represents the renting order is rented.
    /// @notice RETURNED represents the renting order is returned.
    enum RentStatus {
        RENTED,
        RETURNED
    } 

    /// @notice Lending is a struct that represents the lending order.
    /// @param lendingId is the unique id of the lending order.
    /// @param nftStandard is the NFT standard of the NFTs being listed.
    /// @param nftAddress is the address of the NFT contract.
    /// @param tokenId is the id of the NFT.
    /// @param lenderAddress is the address of the lender.
    /// @param tokenQuantity is the quantity of the NFTs being listed.
    /// @param pricePerDay is the price per day of the NFTs being listed.
    /// @param maxRentDuration is the maximum rent duration of the NFTs being listed.
    /// @param tokenQuantityAlreadyRented is the quantity of the NFTs already rented.
    /// @param renterKeyArray is the array of the renter keys.
    /// @param lendStatus is the status of the lending order.
    /// @param chain is the chain of the NFTs being listed.
    struct Lending {
        uint256 lendingId;
        NFTStandard nftStandard;
        address nftAddress;
        uint256 tokenId;
        address payable lenderAddress;
        uint256 tokenQuantity;
        uint256 pricePerDay;
        uint256 maxRentDuration;
        uint256 tokenQuantityAlreadyRented;
        uint256[] renterKeyArray;
        LendStatus lendStatus;
        string chain;
    }

    /// @notice Renting is a struct that represents the renting order.
    /// @param rentingId is the unique id of the renting order.
    /// @param lendingId is the id of the lending order.
    /// @param renterAddress is the address of the renter.
    /// @param tokenQuantityRented is the quantity of the NFTs rented.
    /// @param startTimeStamp is the start timestamp of the renting order.
    /// @param rentedDuration is the rented duration of the renting order.
    /// @param rentedPricePerDay is the rented price per day of the renting order.
    /// @param refundRequired is the boolean value that represents if a refund is required during the settlement or not.
    /// @dev Refund might be required if the lender does not hold its part of the deal throughout the renting period.
    /// @param refundEndTimeStamp is the timestamp upto which the order was valid. Ideally, it should be zero.
    /// @param rentStatus is the status of the renting order.
    struct Renting {
        uint256 rentingId;
        uint256 lendingId;
        address renterAddress;
        uint256 tokenQuantityRented;
        uint256 startTimeStamp;
        uint256 rentedDuration;
        uint256 rentedPricePerDay;
        bool refundRequired;
        uint256 refundEndTimeStamp;
        RentStatus rentStatus;
    }

    /// @notice PriceNotMet is an error that is emitted when the price is not met.
    error PriceNotMet(uint256 lendingId, uint256 price);

    /// @notice PriceMustBeAboveZero is an error that is emitted when the price is provided as zero in some function.
    error PriceMustBeAboveZero();

    /// @notice RentDurationNotAcceptable is an error that is emitted when the rent duration is not acceptable.
    error RentDurationNotAcceptable(uint256 maxRentDuration);

    /// @notice InvalidOrderIdInput is an error that is emitted when the order id of lending or renting order is invalid.
    error InvalidOrderIdInput(uint256 orderId);

    /// @notice InvalidCaller is an error that is emitted when the caller of the function is invalid.
    error InvalidCaller(address expectedAddress, address callerAddress);

    /// @notice InvalidNFTStandard is an error that is emitted when the NFT standard is invalid.
    error InvalidNFTStandard(address nftAddress);

    /// @notice InvalidInputs is an error that is emitted when the inputs are invalid.
    error InvalidInputs(
        uint256 _tokenQtyToAdd,
        uint256 _newPrice,
        uint256 _newMaxRentDuration
    );

    /// @notice Lent is an event that is emitted when a lending order is listed.
    /// @param lendingId is the unique id of the lending order.
    /// @param nftStandard is the NFT standard of the NFTs being listed.
    /// @param nftAddress is the address of the NFT contract.
    /// @param tokenId is the token id of the NFT.
    /// @param lenderAddress is the address of the lender.
    /// @param tokenQuantity is the quantity of the NFTs being listed.
    /// @param pricePerDay is the price per day of the NFTs being listed.
    /// @param maxRentDuration is the maximum rent duration of the NFTs being listed.
    /// @param lendStatus is the status of the lending order.
    event Lent(
        uint256 indexed lendingId,
        NFTStandard nftStandard,
        address nftAddress,
        uint256 tokenId,
        address indexed lenderAddress,
        uint256 tokenQuantity,
        uint256 pricePerDay,
        uint256 maxRentDuration,
        LendStatus lendStatus
    );

    /// @notice LendingUpdated is an event that is emitted when a lending order is updated.
    /// @param lendingId is the unique id of the lending order.
    /// @param tokenQuantity is the quantity of the NFTs being listed.
    /// @param pricePerDay is the price per day of the NFTs being listed.
    /// @param maxRentDuration is the maximum rent duration of the NFTs being listed.
    event LendingUpdated(
        uint256 indexed lendingId,
        uint256 tokenQuantity,
        uint256 pricePerDay,
        uint256 maxRentDuration
    );

    /// @notice Rented is an event that is emitted when a renting order is created.
    /// @param rentingId is the unique id of the renting order.
    /// @param lendingId is the id of the lending order.
    /// @param renterAddress is the address of the renter.
    /// @param tokenQuantityRented is the quantity of the NFTs rented.
    /// @param rentedDuration is the rented duration of the renting order.
    /// @param rentStatus is the status of the renting order.
    event Rented(
        uint256 indexed rentingId,
        uint256 indexed lendingId,
        address indexed renterAddress,
        uint256 tokenQuantityRented,
        uint256 rentedDuration,
        RentStatus rentStatus
    );

    /// @notice Returned is an event that is emitted when a renting order is returned.
    /// @param rentingId is the unique id of the renting order.
    /// @param lendingId is the lending id of the associated lending order.
    /// @param renterAddress is the address of the renter.
    /// @param tokenQuantityReturned is the quantity of the NFTs returned.
    /// @param rentStatus is the status of the renting order.
    event Returned(
        uint256 indexed rentingId,
        uint256 indexed lendingId,
        address indexed renterAddress,
        uint256 tokenQuantityReturned,
        RentStatus rentStatus
    );

    /// @notice Refunded is an event that is emitted when a renting order is refunded due to the 
    /// lender not holding its end of the deal throughout the renting period.
    /// @param rentingId is the unique id of the renting order.
    /// @param lendingId is the lending id of the associated lending order.
    /// @param renterAddress is the address of the renter.
    /// @param refundAmount is the amount of refund.
    /// @param refundTokenQuantity is the quantity of the NFTs refunded.
    /// @param rentStatus is the status of the renting order.
    event Refunded(
        uint256 indexed rentingId,
        uint256 indexed lendingId,
        address indexed renterAddress,
        uint256 refundAmount,
        uint256 refundTokenQuantity,
        RentStatus rentStatus
    );

    /// @notice DeListed is an event that is emitted when a lending order is de-listed.
    /// @param lendingId is the unique id of the lending order.
    /// @param lendStatus is the status of the lending order.
    event DeListed(uint256 indexed lendingId, LendStatus lendStatus);

    /// @notice lend is a function that is used to list a lending order.
    /// @notice The caller of this function must be the owner of the NFTs being lent.
    /// @param _nftStandard is the NFT standard of the NFTs being lent.
    /// @param _nftAddress is the address of the NFT contract.
    /// @param _tokenId is the token id of the NFT.
    /// @param _tokenQuantity is the quantity of the NFTs being lent.
    /// @param _price is the price per day of the NFTs being lent.
    /// @param _maxRentDuration is the maximum rent duration of the NFTs being lent.
    function lend(
        NFTStandard _nftStandard,
        address _nftAddress,
        uint256 _tokenId,
        uint256 _tokenQuantity,
        uint256 _price,
        uint256 _maxRentDuration
    ) external;

    /// @notice modifyLending is a function that is used to modify a lending order.
    /// @notice The caller of this function must be the lister of the lending order.
    /// @param _lendingId is the unique id of the lending order.
    /// @param _tokenQtyToAdd is the quantity of the NFTs being added. Pass in zero to not modify this.
    /// @param _newPrice is the new price per day of the NFTs being listed. Pass in zero to not modify this.
    /// @param _newMaxRentDuration is the new maximum rent duration of the NFTs being listed. Pass in zero to not modify this.
    function modifyLending(
        uint256 _lendingId,
        uint256 _tokenQtyToAdd,
        uint256 _newPrice,
        uint256 _newMaxRentDuration
    ) external;
    
    /// @notice cancelLending is a function that is used to cancel a lending order.
    /// @notice The caller of this function must be the lister of the lending order.
    /// @param _lendingId is the unique id of the lending order.
    function cancelLending(uint256 _lendingId) external; 

    /// @notice rent is a function that is used to rent a lending order.
    /// @notice Anyone can call this function.
    /// @notice The caller of this function must send in the exact amount of ETH required to rent the NFTs.
    /// @param _lendingId is the unique id of the lending order.
    /// @param _tokenQuantity is the quantity of the NFTs being rented.
    /// @param _duration is the duration of the renting order.
    function rent(
        uint256 _lendingId,
        uint256 _tokenQuantity,
        uint256 _duration
    ) external payable;

    /// @notice calculateCost is a function that is used to calculate the cost of renting NFTs.
    /// @param _pricePerDay is the price per day of the NFTs being rented.
    /// @param _duration is the duration for which the NFTs are being rented.
    /// @param qty is the quantity of the NFTs being rented.
    /// @return cost is the total cost for renting the NFTs.
    function calculateCost(
        uint256 _pricePerDay,
        uint256 _duration,
        uint256 qty
    ) external pure returns (uint256 cost);

    /// @notice returnRented is a function that is used to return a renting order.
    /// @notice The caller of this function must be the renter of the renting order.
    /// @param _rentingID is the unique id of the renting order.
    /// @param _tokenQuantity is the quantity of the NFTs being returned.
    function returnRented(uint256 _rentingID, uint256 _tokenQuantity) external;

    /// @notice getLendingData is a function that is used to get the data of a lending order.
    /// @param _lendingId is the unique id of the lending order.
    /// @return All the data of the lending order.
    function getLendingData(
        uint256 _lendingId
    ) external view returns (Lending memory);

    /// @notice setAdmin is a function that is used to set the admin address.
    /// @notice The caller of this function must be the current admin.
    /// @param _newAddress is the address of the new admin.
    function setAdmin(address _newAddress) external;

    /// @notice setFeesForAdmin is a function that is used to set the fees percentage for the admin.
    /// @notice The caller of this function must be the current admin.
    /// @param _percentFees is the new fees percentage for the admin.
    function setFeesForAdmin(uint256 _percentFees) external;

    /// @notice setMinRentDueSeconds is a function that is used to set the minimum rent duration.
    /// @notice The caller of this function must be the current admin.
    /// @param _minDuration is the new minimum rent duration.
    function setMinRentDueSeconds(uint256 _minDuration) external;

    /// @notice withdrawableAmount is a function that is used to get the amount of ETH that can be withdrawn by the admin.
    /// @return The amount of ETH that can be withdrawn by the admin.
    function withdrawableAmount() external view returns (uint256);

    /// @notice withdrawFunds is a function that is used to withdraw the fees earned by the admin.
    /// @notice The caller of this function must be the current admin.
    /// @param _to Address to withdraw funds to.
    function withdrawFunds(address _to) external;

    /// @notice setAutomationAddress is a function that is used to set the address of the chainlink automation contract.
    /// @notice The caller of this function must be the current admin.
    /// @param _automation is the address of the chainlink automation contract.
    function setAutomationAddress(address _automation) external;

    /// @notice isERC721 is a function that returns whether an NFT is ERC721 or not.
    /// @param nftAddress is the address of the NFT contract.
    /// @return bool output is whether the NFT is ERC721 or not.
    function isERC721(address nftAddress) external view returns (bool);

    /// @notice isERC1155 is a function that returns whether an NFT is ERC1155 or not.
    /// @param nftAddress is the address of the NFT contract.
    /// @return bool output is whether the NFT is ERC1155 or not.
    function isERC1155(address nftAddress) external view returns (bool);

    /// @notice automationAddress is a function that is used to get the address of the chainlink automation contract.
    function automationAddress() external view returns (address);

    /// @notice checkReturnRefundAutomation is a function that is used to check, return and refund NFTs.
    /// @notice This function is called by the chainlink automation contract.
    function checkReturnRefundAutomation() external;

    /// @notice getExpiredRentings is a function that is used to get the expired renting orders.
    /// @return The ids of the expired renting orders and the number of expired renting orders.
    /// @dev This function will be used by the chainlink automation contract.
    function getExpiredRentings() external view returns (uint256[] memory, uint256);

    /// @notice getRefundRentings is a function that is used to get the refund required renting orders.
    /// @return The ids of the refund required renting orders and the number of refund required renting orders.
    /// @dev This function will be used by the chainlink automation contract.
    function getRefundRentings() external view returns (uint256[] memory, uint256);
}