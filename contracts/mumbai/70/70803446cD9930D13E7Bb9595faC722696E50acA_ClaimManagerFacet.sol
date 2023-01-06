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
    bytes32 public constant SUPER_MANAGER_LEVEL =
        keccak256("SUPER_MANAGER_LEVEL");

    bytes32 public constant GENERAL_MANAGER_LEVEL =
        keccak256("GENERAL_MANAGER_LEVEL");

    bytes32 public constant GOVERANACE_BOARD_LEVEL =
        keccak256("GOVERANACE_BOARD_LEVEL");

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

import {InsuranceBaseStorage} from "./base/InsuranceBaseStorage.sol";
import {IInsuranceBaseStorage} from "./interfaces/IInsuranceBaseStorage.sol";
import {ClaimManagerInternalFacet} from "./internal/ClaimManagerInternalFacet.sol";
import {IClaimManager} from "./interfaces/IClaimManager.sol";
import {AccessControlInternal} from "@solidstate/contracts/access/access_control/AccessControl.sol";
import {ECDSAUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/cryptography/ECDSAUpgradeable.sol";

contract ClaimManagerFacet is
    ClaimManagerInternalFacet,
    AccessControlInternal,
    IClaimManager
{
    using InsuranceBaseStorage for InsuranceBaseStorage.Layout;

    function requestClaim(ClaimRequestParams memory _claimData_)
        public
        returns (bool)
    {
        _requestClaim(_claimData_);
        return true;
    }

    function submitAssessment(
        uint256 _claimId_,
        uint256 _claimApprovedAmount_,
        bool _isAccepted_
    ) public returns (bool) {
        _submitAssessment(_claimId_, _claimApprovedAmount_, _isAccepted_);
        _checkVoteAssessmentConsensus(_claimId_, _isAccepted_);
        return true;
    }

    function voteAssessment(uint256 _claimId_, bool _isAccepted_)
        public
        returns (bool)
    {
        _voteAssessment(_claimId_, _isAccepted_);
        _increaseVoterReward(_claimId_);
        _checkVoteAssessmentConsensus(_claimId_, _isAccepted_);
        return true;
    }

    function finalizedAssessment(uint256 _claimId_, bool _isAccepted_)
        public
        onlyRole(InsuranceBaseStorage.GOVERANACE_BOARD_LEVEL)
        returns (bool)
    {
        _finalizedAssessment(_claimId_, _isAccepted_);
        return true;
    }

    function cancelClaim(uint256 _claimId_) public returns (bool) {
        _cancelClaim(_claimId_);
        return true;
    }

    function setClaimRules(IInsuranceBaseStorage.ClaimRules memory _cr_)
        public
        onlyRole(InsuranceBaseStorage.SUPER_MANAGER_LEVEL)
    {
        _setClaimRules(_cr_);
    }

    function getClaimStatus(uint256 _claimId_)
        public
        view
        returns (IInsuranceBaseStorage.ClaimStatus status)
    {
        return _getClaimStatus(_claimId_);
    }

    function getClaimData(uint256 _claimId_)
        public
        view
        returns (IInsuranceBaseStorage.ClaimData memory)
    {
        return _getClaimData(_claimId_);
    }

    function getClaimRules()
        public
        view
        returns (IInsuranceBaseStorage.ClaimRules memory)
    {
        return _getClaimRules();
    }

    function isIPFSClaimExist(string memory _ipfsHash_)
        public
        view
        returns (bool)
    {
        return _isIPFSClaimExist(_ipfsHash_);
    }
}

// SPDX-License-Identifier: CovestFinance.V1.0.0
pragma solidity 0.8.17;

import {IInsuranceBaseStorage} from "./IInsuranceBaseStorage.sol";
import {IClaimManagerInternal} from "./IClaimManagerInternal.sol";

interface IClaimManager is IClaimManagerInternal {
    function cancelClaim(uint256 _claimId_) external returns (bool);

    function finalizedAssessment(uint256 _claimId_, bool _isAccepted_)
        external
        returns (bool);

    function getClaimRules()
        external
        view
        returns (IInsuranceBaseStorage.ClaimRules memory);

    function getClaimData(uint256 _claimId_)
        external
        view
        returns (IInsuranceBaseStorage.ClaimData memory);

    function getClaimStatus(uint256 _claimId_)
        external
        view
        returns (IInsuranceBaseStorage.ClaimStatus status);

    function isIPFSClaimExist(string memory _ipfsHash_)
        external
        view
        returns (bool);

    function requestClaim(
        IClaimManagerInternal.ClaimRequestParams memory _claimData_
    ) external returns (bool);

    function setClaimRules(IInsuranceBaseStorage.ClaimRules memory _cr_)
        external;

    function submitAssessment(
        uint256 _claimId_,
        uint256 _claimApprovedAmount_,
        bool _isAccepted_
    ) external returns (bool);

    function voteAssessment(uint256 _claimId_, bool _isAccepted_)
        external
        returns (bool);
}

// SPDX-License-Identifier: CovestFinance.V1.0.0
pragma solidity 0.8.17;

import {IInsuranceBaseStorage} from "./IInsuranceBaseStorage.sol";

interface IClaimManagerInternal {
    event ClaimRulesChanged(IInsuranceBaseStorage.ClaimRules claimRules);

    event ClaimRequested(
        string indexed policyId,
        uint256 indexed claimId,
        address indexed validator,
        string ipfsHash,
        uint256 claimAmount
    );

    event ClaimAssessmentSubmitted(
        uint256 indexed claimId,
        address indexed validator,
        uint256 claimApprovedAmount,
        bool isAccepted
    );

    event ClaimAssessmentVoted(
        uint256 indexed claimId,
        address indexed voter,
        bool isAccepted
    );

    event ClaimAssessmentConsensusReached(
        uint256 indexed claimId,
        IInsuranceBaseStorage.ClaimStatus status
    );

    event ClaimAssessmentPointIncreased(
        uint256 indexed claimId,
        address indexed validator,
        uint256 point
    );

    event ClaimAssessmentRewardIncreased(
        uint256 indexed claimId,
        address indexed validator,
        uint256 reward
    );

    struct ClaimRequestParams {
        string policyId;
        string ipfsHash;
        uint256 claimAmount; // the value decimals is 18 //
        uint256 signatureValidUntil; // signature valid until //
        uint8 v;
        bytes32 r;
        bytes32 s;
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

import {InsuranceBaseStorage} from "../base/InsuranceBaseStorage.sol";
import {IInsuranceBaseStorage} from "../interfaces/IInsuranceBaseStorage.sol";
import {IClaimManagerInternal} from "../interfaces/IClaimManagerInternal.sol";
import {IRiskCarrierManager} from "../../interfaces/IRiskCarrierManager.sol";
import {IValidatorManager} from "../../interfaces/IValidatorManager.sol";
import {IValidatorBaseStorage} from "../../interfaces/IValidatorBaseStorage.sol";
import {ECDSAUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/cryptography/ECDSAUpgradeable.sol";
import {IERC20MetadataUpgradeable} from "@openzeppelin/contracts-upgradeable/interfaces/IERC20MetadataUpgradeable.sol";

abstract contract ClaimManagerInternalFacet is IClaimManagerInternal {
    using InsuranceBaseStorage for InsuranceBaseStorage.Layout;

    function _requestClaim(ClaimRequestParams memory _claimData_) internal {
        InsuranceBaseStorage.Layout storage _ibs_ = InsuranceBaseStorage
            .layout();

        require(
            _getPolicyStatus(_claimData_.policyId) ==
                IInsuranceBaseStorage.PolicyStatus.Active,
            "PINA"
        );

        IInsuranceBaseStorage.PolicyData memory _pd_ = _ibs_.policies[
            _claimData_.policyId
        ];

        require(_pd_.policyholder == msg.sender, "NAU");

        require(_pd_.claimRequestUntil > block.timestamp, "CRE");

        require(_pd_.accumulatedClaimReserveAmount == 0, "ACRAIN0");

        require(
            _pd_.sumInsured >=
                _claimData_.claimAmount + _pd_.accumulatedClaimPaidAmount,
            "MAXCLAIM"
        );

        IValidatorManager _vm_ = IValidatorManager(_ibs_.validatorManager);

        address _claimValidator_ = _vm_.selectValidator(
            _claimData_.claimAmount
        );

        require(_claimValidator_ != address(0), "NAVF");

        uint256 _claimId_ = _ibs_.claimList.length;

        IInsuranceBaseStorage.ClaimData memory _cd_ = IInsuranceBaseStorage
            .ClaimData(
                _claimData_.policyId,
                _claimData_.ipfsHash,
                uint40(block.timestamp),
                uint40(block.timestamp) +
                    (_ibs_.claimRules.claimAssessmentPeriod * 1 days),
                _claimId_, //* claimId *//
                _claimData_.claimAmount,
                0,
                _pd_.currency,
                _claimValidator_,
                IInsuranceBaseStorage.ClaimStatus.Submitted
            );

        _ibs_.claimList.push(_cd_);
        _ibs_
            .policies[_claimData_.policyId]
            .accumulatedClaimReserveAmount = _claimData_.claimAmount;
        _ibs_.claimIdsByPolicyId[_claimData_.policyId].push(_claimId_);

        require(_vm_.createVotingVoucher(_claimId_) == true, "ECVV");

        require(
            _vm_.increaseValidatorOnHoldAmount(
                _claimId_,
                _claimValidator_,
                _claimData_.claimAmount /
                    _ibs_.claimRules.claimAmountPerOnHoldStaking
            ),
            "CSVOHA"
        );

        emit ClaimRequested(
            _claimData_.policyId,
            _ibs_.claimList.length - 1,
            _claimValidator_,
            _claimData_.ipfsHash,
            _claimData_.claimAmount
        );
    }

    function _cancelClaim(uint256 _claimId_) internal {
        InsuranceBaseStorage.Layout storage _ibs_ = InsuranceBaseStorage
            .layout();

        IInsuranceBaseStorage.ClaimData memory _cd_ = _ibs_.claimList[
            _claimId_
        ];

        IInsuranceBaseStorage.PolicyData memory _pd_ = _ibs_.policies[
            _cd_.policyId
        ];

        require(
            _cd_.status == IInsuranceBaseStorage.ClaimStatus.Submitted,
            "CS"
        );

        require(_pd_.policyholder == msg.sender, "NV");

        require(_cd_.claimExpiresAt > block.timestamp, "CAE");

        IValidatorManager _vm_ = IValidatorManager(_ibs_.validatorManager);

        _ibs_.claimList[_claimId_].status = IInsuranceBaseStorage
            .ClaimStatus
            .Cancelled;

        require(
            _vm_.decreaseValidatorOnHoldAmount(_claimId_, _cd_.claimValidator),
            "EDVOHA"
        );

        _ibs_.policies[_cd_.policyId].accumulatedClaimReserveAmount = 0;

        emit ClaimAssessmentConsensusReached(_claimId_, _cd_.status);
    }

    function _submitAssessment(
        uint256 _claimId_,
        uint256 _claimApprovedAmount_,
        bool _isAccepted_
    ) internal {
        InsuranceBaseStorage.Layout storage _ibs_ = InsuranceBaseStorage
            .layout();

        IInsuranceBaseStorage.ClaimData memory _cd_ = _ibs_.claimList[
            _claimId_
        ];

        IValidatorManager _vm_ = IValidatorManager(_ibs_.validatorManager);

        require(
            _cd_.status == IInsuranceBaseStorage.ClaimStatus.Submitted,
            "CSINS"
        );

        require(_cd_.claimValidator == msg.sender, "NV");

        require(_cd_.claimExpiresAt > block.timestamp, "CAE");

        IValidatorBaseStorage.ClaimValidatorVote memory _cvv_ = _vm_
            .getValidatorVote(_claimId_, msg.sender);

        require(_cvv_.isVoter == true, "NVoter");

        require(_cvv_.isVoted == false, "Voted");

        if (_isAccepted_ == false) {
            require(_claimApprovedAmount_ == 0, "CAA0");
        }

        _ibs_.claimList[_claimId_].status = IInsuranceBaseStorage
            .ClaimStatus
            .Voting;

        _ibs_.claimList[_claimId_].claimApprovedAmount = _claimApprovedAmount_;

        _ibs_
            .policies[_cd_.policyId]
            .accumulatedClaimReserveAmount = _claimApprovedAmount_;

        require(_vm_.voteVoucher(_claimId_, msg.sender, _isAccepted_), "EVV");

        emit ClaimAssessmentSubmitted(
            _claimId_,
            msg.sender,
            _claimApprovedAmount_,
            _isAccepted_
        );
    }

    function _voteAssessment(uint256 _claimId_, bool _isAccepted_) internal {
        InsuranceBaseStorage.Layout storage _ibs_ = InsuranceBaseStorage
            .layout();

        IInsuranceBaseStorage.ClaimData memory _cd_ = _ibs_.claimList[
            _claimId_
        ];

        IValidatorManager _vm_ = IValidatorManager(_ibs_.validatorManager);

        require(
            _cd_.status == IInsuranceBaseStorage.ClaimStatus.Voting,
            "CSINV"
        );

        require(_cd_.claimExpiresAt > block.timestamp, "CAE");

        IValidatorBaseStorage.ClaimValidatorVote memory _cvv_ = _vm_
            .getValidatorVote(_claimId_, msg.sender);

        require(_cvv_.isVoter == true, "NVoter");

        require(_cvv_.isVoted == false, "Voted");

        require(_vm_.voteVoucher(_claimId_, msg.sender, _isAccepted_), "EVV");

        emit ClaimAssessmentVoted(_claimId_, msg.sender, _isAccepted_);
    }

    function _checkVoteAssessmentConsensus(uint256 _claimId_, bool _isAccepted_)
        internal
    {
        InsuranceBaseStorage.Layout storage _ibs_ = InsuranceBaseStorage
            .layout();

        IInsuranceBaseStorage.ClaimData memory _cd_ = _ibs_.claimList[
            _claimId_
        ];

        IValidatorManager _vm_ = IValidatorManager(_ibs_.validatorManager);

        IValidatorBaseStorage.VotingVoucher memory _vv_ = _vm_.getVotingVoucher(
            _claimId_
        );

        require(
            _cd_.status == IInsuranceBaseStorage.ClaimStatus.Voting,
            "CSINV"
        );

        require(_cd_.claimExpiresAt > block.timestamp, "CAE");

        string memory _policyId_ = _ibs_.claimList[_claimId_].policyId;

        if (_isAccepted_ == true) {
            if (
                _vv_.totalAcceptedPower >
                ((_vv_.totalPower * _ibs_.claimRules.claimConsensusRatio) / 100)
            ) {
                _ibs_.claimList[_claimId_].status = IInsuranceBaseStorage
                    .ClaimStatus
                    .Accepted;

                _ibs_.policies[_policyId_].accumulatedClaimReserveAmount = 0;

                _ibs_.policies[_policyId_].accumulatedClaimPaidAmount += _ibs_
                    .claimList[_claimId_]
                    .claimApprovedAmount;

                require(
                    IRiskCarrierManager(_ibs_.riskCarrierManager)
                        .claimRiskCarrierPolicy(
                            _ibs_.poolId,
                            _policyId_,
                            _ibs_.claimList[_claimId_].claimApprovedAmount
                        ),
                    "CVAC:ECCRCP"
                );

                IERC20MetadataUpgradeable _ERC20_ = IERC20MetadataUpgradeable(
                    _ibs_.policies[_policyId_].currency
                );

                uint8 _decimalsForConvert_ = 18 - _ERC20_.decimals();

                uint256 _claimApprovedAmountByCurrencyDecimals_ = _ibs_
                    .claimList[_claimId_]
                    .claimApprovedAmount / 10**_decimalsForConvert_;

                require(
                    _ERC20_.balanceOf(address(this)) >=
                        _claimApprovedAmountByCurrencyDecimals_,
                    "CVAC:IB"
                );

                require(
                    _ERC20_.transfer(
                        msg.sender,
                        _claimApprovedAmountByCurrencyDecimals_
                    ),
                    "CVAC:CTTU"
                );

                emit ClaimAssessmentConsensusReached(
                    _claimId_,
                    _ibs_.claimList[_claimId_].status
                );

                _increaseValidatorPoint(_claimId_);
            }
        } else {
            if (
                _vv_.totalRejectedPower >=
                ((_vv_.totalPower *
                    (100 - _ibs_.claimRules.claimConsensusRatio)) / 100)
            ) {
                _ibs_.claimList[_claimId_].status = IInsuranceBaseStorage
                    .ClaimStatus
                    .Rejected;

                _ibs_.policies[_policyId_].accumulatedClaimReserveAmount = 0;

                emit ClaimAssessmentConsensusReached(
                    _claimId_,
                    _ibs_.claimList[_claimId_].status
                );

                _increaseValidatorPoint(_claimId_);
            }
        }
    }

    function _increaseValidatorPoint(uint256 _claimId_) internal {
        InsuranceBaseStorage.Layout storage _ibs_ = InsuranceBaseStorage
            .layout();

        IInsuranceBaseStorage.ClaimData memory _cd_ = _ibs_.claimList[
            _claimId_
        ];

        IValidatorManager _vm_ = IValidatorManager(_ibs_.validatorManager);

        require(
            _vm_.increasePoint(
                _cd_.claimValidator,
                _ibs_.claimRules.pointPerClaimAssessment
            ),
            "EIPCV"
        );

        emit ClaimAssessmentPointIncreased(
            _claimId_,
            _cd_.claimValidator,
            _ibs_.claimRules.pointPerClaimAssessment
        );
    }

    function _increaseValidatorReward(uint256 _claimId_) internal {
        InsuranceBaseStorage.Layout storage _ibs_ = InsuranceBaseStorage
            .layout();

        IInsuranceBaseStorage.ClaimData memory _cd_ = _ibs_.claimList[
            _claimId_
        ];

        IValidatorManager _vm_ = IValidatorManager(_ibs_.validatorManager);

        require(
            _vm_.increaseReward(
                _cd_.claimValidator,
                _cd_.currency,
                (_ibs_.claimRules.rewardPerClaimAssessment *
                    _ibs_.claimRules.validatorRewardRatio) / 100
            ),
            "EIRCV"
        );

        emit ClaimAssessmentRewardIncreased(
            _claimId_,
            _cd_.claimValidator,
            _ibs_.claimRules.rewardPerClaimAssessment
        );
    }

    function _increaseVoterReward(uint256 _claimId_) internal {
        InsuranceBaseStorage.Layout storage _ibs_ = InsuranceBaseStorage
            .layout();

        IInsuranceBaseStorage.ClaimData memory _cd_ = _ibs_.claimList[
            _claimId_
        ];

        IValidatorManager _vm_ = IValidatorManager(_ibs_.validatorManager);

        IValidatorBaseStorage.VotingVoucher memory _vv_ = _vm_.getVotingVoucher(
            _claimId_
        );

        uint256 rewarded = (
            (_ibs_.claimRules.rewardPerClaimAssessment *
                _ibs_.claimRules.voterRewardRatio)
        ) / (100 * (_vv_.totalCount - 1));

        require(
            _vm_.increaseReward(msg.sender, _cd_.currency, rewarded),
            "EIRV"
        );

        emit ClaimAssessmentRewardIncreased(_claimId_, msg.sender, rewarded);
    }

    function _finalizedAssessment(uint256 _claimId_, bool _isAccepted_)
        internal
    {
        InsuranceBaseStorage.Layout storage _ibs_ = InsuranceBaseStorage
            .layout();

        IInsuranceBaseStorage.ClaimData memory _cd_ = _ibs_.claimList[
            _claimId_
        ];

        IValidatorManager _vm_ = IValidatorManager(_ibs_.validatorManager);

        IValidatorBaseStorage.VotingVoucher memory _vv_ = _vm_.getVotingVoucher(
            _claimId_
        );

        require(
            _cd_.status == IInsuranceBaseStorage.ClaimStatus.Voting,
            "CSINV"
        );

        require(block.timestamp > _cd_.claimExpiresAt, "NE");

        require(
            _vv_.totalAcceptedPower <=
                ((_vv_.totalPower * _ibs_.claimRules.claimConsensusRatio) /
                    100),
            "RC"
        );

        string memory _policyId_ = _ibs_.claimList[_claimId_].policyId;

        if (_isAccepted_ == true) {
            _ibs_.claimList[_claimId_].status = IInsuranceBaseStorage
                .ClaimStatus
                .Accepted;

            require(
                IRiskCarrierManager(_ibs_.riskCarrierManager)
                    .claimRiskCarrierPolicy(
                        _ibs_.poolId,
                        _policyId_,
                        _ibs_.claimList[_claimId_].claimApprovedAmount
                    ),
                "CVAC:ECCRCP"
            );

            IERC20MetadataUpgradeable _ERC20_ = IERC20MetadataUpgradeable(
                _ibs_.policies[_policyId_].currency
            );

            uint8 _decimalsForConvert_ = 18 - _ERC20_.decimals();

            uint256 _claimApprovedAmountByCurrencyDecimals_ = _ibs_
                .claimList[_claimId_]
                .claimApprovedAmount / 10**_decimalsForConvert_;

            require(
                _ERC20_.balanceOf(address(this)) >=
                    _claimApprovedAmountByCurrencyDecimals_,
                "CVAC:IB"
            );

            require(
                _ERC20_.transfer(
                    msg.sender,
                    _claimApprovedAmountByCurrencyDecimals_
                ),
                "CVAC:CTTU"
            );

            _ibs_.policies[_policyId_].accumulatedClaimReserveAmount = 0;

            _ibs_.policies[_policyId_].accumulatedClaimPaidAmount += _ibs_
                .claimList[_claimId_]
                .claimApprovedAmount;

            require(
                _vm_.decreaseValidatorOnHoldAmount(
                    _claimId_,
                    _cd_.claimValidator
                ),
                "EDVOHA"
            );
        } else {
            _ibs_.claimList[_claimId_].status = IInsuranceBaseStorage
                .ClaimStatus
                .Rejected;

            _ibs_.policies[_policyId_].accumulatedClaimReserveAmount = 0;
        }

        emit ClaimAssessmentConsensusReached(
            _claimId_,
            _ibs_.claimList[_claimId_].status
        );

        _increaseValidatorPoint(_claimId_);
    }

    function _setClaimRules(IInsuranceBaseStorage.ClaimRules memory _cr_)
        internal
    {
        require(_cr_.claimConsensusRatio <= 100, "ICCR");
        require(
            _cr_.validatorRewardRatio + _cr_.voterRewardRatio <= 100,
            "IVRRPVRR"
        );

        InsuranceBaseStorage.layout().claimRules = _cr_;

        emit ClaimRulesChanged(_cr_);
    }

    function _getClaimRules()
        internal
        view
        returns (IInsuranceBaseStorage.ClaimRules memory)
    {
        return InsuranceBaseStorage.layout().claimRules;
    }

    function _getClaimData(uint256 _claimId_)
        internal
        view
        returns (IInsuranceBaseStorage.ClaimData memory)
    {
        return InsuranceBaseStorage.layout().claimList[_claimId_];
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

    function _getClaimStatus(uint256 _claimId_)
        internal
        view
        returns (IInsuranceBaseStorage.ClaimStatus status)
    {
        return (InsuranceBaseStorage.layout().claimList[_claimId_].status);
    }

    function _isIPFSClaimExist(string memory _ipfsHash_)
        internal
        view
        returns (bool)
    {
        return InsuranceBaseStorage.layout().isIPFSClaimExist[_ipfsHash_];
    }
}

// SPDX-License-Identifier: CovestFinance.V1.0.0
pragma solidity 0.8.17;

import {IRiskCarrierManager} from "../riskCarrier/interfaces/IRiskCarrierManager.sol";

// SPDX-License-Identifier: CovestFinance.V1.0.0
pragma solidity 0.8.17;

import {IValidatorBaseStorage} from "../validator/interfaces/IValidatorBaseStorage.sol";

// SPDX-License-Identifier: CovestFinance.V1.0.0
pragma solidity 0.8.17;

import {IValidatorManager} from "../validator/interfaces/IValidatorManager.sol";

// SPDX-License-Identifier: CovestFinance.V1.0.0
pragma solidity 0.8.17;

interface IRiskCarrierBaseStorage {
    struct RiskCarrierController {
        address addr;
        string name;
        uint8 riskTransferRatio; // 100 * percentage / 100 //
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
            IRiskCarrierBaseStorage.RiskCarrierController[]
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
            IRiskCarrierBaseStorage.RiskCarrierController[]
                memory riskCarrierControllerList,
            uint256 newPage
        );

    function registerRiskCarrierController(
        string memory _poolId_,
        string memory _name_,
        address _addr_,
        uint8 _riskTransferRatio_
    ) external;

    function setRiskTransferRatio(
        string memory _poolId_,
        address _addr_,
        uint8 _riskTransferRatio_
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
        address indexed addr,
        uint8 riskTransferRatio
    );
    event SetRiskTransferRatio(
        string indexed poolId,
        address addr,
        uint8 riskTransferRatio
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

import {IValidatorBaseStorage} from "./IValidatorBaseStorage.sol";
import {IValidatorAggregatorInternal} from "./IValidatorAggregatorInternal.sol";

interface IValidatorAggregator is IValidatorAggregatorInternal {
    function createVotingVoucher(uint256 _claimId_) external returns (bool);

    function getTotalPenaltyPoint() external view returns (uint256);

    function getTotalPoint() external view returns (uint256);

    function getValidatorCalculationRules()
        external
        view
        returns (IValidatorBaseStorage.ValidatorCalculationRules memory);

    function getValidatorCount() external view returns (uint256);

    function getValidatorPoint(address _validator_)
        external
        view
        returns (IValidatorBaseStorage.ValidatorPoint memory);

    function getValidatorVote(uint256 _claimId_, address _validator_)
        external
        view
        returns (IValidatorBaseStorage.ClaimValidatorVote memory);

    function getValidatorVoteList(
        uint256 _claimId_,
        uint256 _page_,
        uint256 _size_
    )
        external
        view
        returns (
            IValidatorBaseStorage.ClaimValidatorVote[] memory _votes_,
            uint256 newPage
        );

    function getValidators(uint256 _page_, uint256 _size_)
        external
        view
        returns (address[] memory _validators_, uint256 newPage);

    function getVotingVoucher(uint256 _claimId_)
        external
        view
        returns (IValidatorBaseStorage.VotingVoucher memory);

    function increasePoint(address _validator_, uint256 _point_)
        external
        returns (bool);

    function increaseReward(
        address _validator_,
        address _currency_,
        uint256 _reward_
    ) external returns (bool);

    function payoutValidatorReward(address _currency_, uint256 _reward_)
        external
        returns (bool);

    function selectValidator(uint256 _claimAmount_)
        external
        view
        returns (address);

    function setUpfrontManager(address _addr_) external;

    function setValidatorCalculationRules(
        IValidatorBaseStorage.ValidatorCalculationRules memory _vcr_
    ) external;

    function setValidatorRules(IValidatorBaseStorage.ValidatorRules memory _vr_)
        external;

    function slash(
        address _validator_,
        IValidatorBaseStorage.SlashVoucher memory _vsv_
    ) external returns (bool);

    function validatorPauseWork(bool _isPause_) external;

    function voteVoucher(
        uint256 _claimId_,
        address _validator_,
        bool _isAccepted_
    ) external returns (bool);

    function workStatus(address _validator_) external view returns (bool);
}

// SPDX-License-Identifier: CovestFinance.V1.0.0
pragma solidity 0.8.17;

import {IValidatorBaseStorage} from "./IValidatorBaseStorage.sol";

interface IValidatorAggregatorInternal {
    event Slashed(
        address indexed validator,
        IValidatorBaseStorage.SlashVoucher slashVoucher
    );

    event ValidatorPausedWork(address indexed validator, bool isPause);

    event ValidatorCalcuationRulesChanged(
        IValidatorBaseStorage.ValidatorCalculationRules validatorCalculationRules
    );

    event ValidatorRulesChanged(
        IValidatorBaseStorage.ValidatorRules validatorRules
    );

    event PointChanged(address indexed validator, uint256 amount);

    event RewardChanged(
        address indexed validator,
        address indexed currency,
        uint256 amount
    );

    event VotingVoucherCreated(
        uint256 indexed claimId,
        uint256 totalPower,
        uint256 totalValidatorCount
    );

    event VotingVoucherUpdated(
        uint256 indexed claimId,
        address indexed validator,
        bool isAccepted
    );

    event ValidatorRewardPaid(
        address indexed validator,
        address indexed currency,
        uint256 reward,
        uint256 rewardByCurrency
    );

    event UpfrontManagerChanged(address indexed upfrontManager);
}

// SPDX-License-Identifier: CovestFinance.V1.0.0
pragma solidity 0.8.17;

interface IValidatorBaseStorage {
    struct ValidatorPoint {
        uint256 point;
        uint256 penalty; // penalty of the point that will calculate to select the validator for the claim //
    }

    struct ValidatorSelection {
        address validator;
        uint256 score;
    }

    struct ValidatorRules {
        uint256 initialPoint;
    }

    struct ValidatorCalculationRules {
        uint8 weightCapacity;
        uint8 weightReputation;
        uint8 weightRandomness;
    }

    struct StakingRules {
        uint256 minStake;
        uint256 maxStake;
    }

    struct StakingBalance {
        uint256 staked; // amount //
        uint256 onHold; // amount //
        uint256 penalty; // amount //
        uint40 lastUpdate;
    }

    struct ClaimValidatorVote {
        bool isVoted;
        bool isAccepted;
        bool isVoter;
        uint256 power;
    }

    struct VotingVoucher {
        uint256 totalPower;
        uint256 totalCount;
        uint256 validatorOnHold;
        uint256 totalAcceptedPower;
        uint256 totalAcceptedCount;
        uint256 totalRejectedPower;
        uint256 totalRejectedCount;
        address[] validators;
    }

    struct SlashVoucher {
        uint256 penaltyStake;
        uint256 penaltyPoint;
        string reason;
        string validatedData;
    }

    function GENERAL_MANAGER_LEVEL() external view returns (bytes32);

    function INSURANCE_MANAGER_LEVEL() external view returns (bytes32);

    function SUPER_MANAGER_LEVEL() external view returns (bytes32);

    function VALIDATOR_MANAGER_LEVEL() external view returns (bytes32);
}

// SPDX-License-Identifier: CovestFinance.V1.0.0
pragma solidity 0.8.17;

import {IValidatorAggregator} from "./IValidatorAggregator.sol";
import {IValidatorStaking} from "./IValidatorStaking.sol";

interface IValidatorManager is IValidatorAggregator, IValidatorStaking {}

// SPDX-License-Identifier: CovestFinance.V1.0.0
pragma solidity 0.8.17;

import {IValidatorBaseStorage} from "./IValidatorBaseStorage.sol";
import {IValidatorStakingInternal} from "./IValidatorStakingInternal.sol";

interface IValidatorStaking is IValidatorStakingInternal {
    function decreaseValidatorOnHoldAmount(
        uint256 _claimId_,
        address _validator_
    ) external returns (bool);

    function getLastUpdateByValidator(address _validator_)
        external
        view
        returns (uint256);

    function getOnHoldAmountByValidator(address _validator_)
        external
        view
        returns (uint256);

    function getPenaltyAmountByValidator(address _validator_)
        external
        view
        returns (uint256);

    function getStakedAmountByValidator(address _validator_)
        external
        view
        returns (uint256);

    function getStakingRules()
        external
        view
        returns (IValidatorBaseStorage.StakingRules memory);

    function getTotalNetStakeAmount() external view returns (uint256);

    function getTotalOnHoldAmount() external view returns (uint256);

    function getTotalPenaltyStake() external view returns (uint256);

    function getTotalStakedAmount() external view returns (uint256);

    function getValidatorNetStakeAmount(address _validator_)
        external
        view
        returns (uint256);

    function getValidatorStake(address _validator_)
        external
        view
        returns (IValidatorBaseStorage.StakingBalance memory);

    function increaseValidatorOnHoldAmount(
        uint256 _claimId_,
        address _validator_,
        uint256 _amount_
    ) external returns (bool);

    function isValidatorWhitelisted(address _addr_)
        external
        view
        returns (bool);

    function miToken() external view returns (address);

    function payPenalty(uint256 _amount_) external returns (bool);

    function removeValidator(address _validator_) external returns (bool);

    function setMIToken(address _addr_) external;

    function setStakingRules(IValidatorBaseStorage.StakingRules memory _sr_)
        external;

    function setValidatorWhitelist(address _addr_, bool _status_) external;

    function stake(uint256 _amount_) external returns (bool);

    function unstake(uint256 _amount_) external returns (bool);
}

// SPDX-License-Identifier: CovestFinance.V1.0.0
pragma solidity 0.8.17;

import {IValidatorBaseStorage} from "./IValidatorBaseStorage.sol";

interface IValidatorStakingInternal {
    event MITokenChanged(address indexed miToken);
    event ValidatorWhitelistChanged(address indexed validator, bool status);
    event ValidatorChanged(address indexed validator, bool status);
    event StakingRulesChanged(IValidatorBaseStorage.StakingRules stakingRules);
    event ValidatorOnHoldAmountChanged(
        uint256 indexed claimId,
        address indexed validator,
        uint256 amount
    );
    event initializedPoint(address indexed validator, uint256 amount);
    event Staked(address indexed validator, uint256 amount);
    event Unstaked(address indexed validator, uint256 amount);
    event PenaltyPaid(address indexed validator, uint256 amount);
}