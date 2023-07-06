/**
 *Submitted for verification at polygonscan.com on 2023-07-06
*/

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

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
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
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

// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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

// OpenZeppelin Contracts (last updated v4.8.0) (utils/cryptography/EIP712.sol)

// OpenZeppelin Contracts (last updated v4.8.0) (utils/cryptography/ECDSA.sol)

// OpenZeppelin Contracts (last updated v4.8.0) (utils/Strings.sol)

// OpenZeppelin Contracts (last updated v4.8.0) (utils/math/Math.sol)

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

contract DAO is Ownable, EIP712 {
    /**
     * @dev The name of the domain.
     */
    string public domainName;

    /**
     * @dev The version of the domain.
     */
    string public domainVersion;

    /**
     * @dev The ID of the event.
     */
    uint256 public eventId;

    /**
     * @dev The ID of the event type.
     */
    uint256 public eventTypeId;

    /**
     * @dev The limit of options that can be voted on.
     */
    uint256 public optionLimit;

    /**
     * @dev The limit of senators that can participate in the event.
     */
    uint256 public senatorLimit;

    /**
     * @dev The ID of the distribution.
     */
    uint256 public distributionId;

    /**
     * @dev The address of the project.
     */
    address public projectAddress;

    /**
     * @dev The instance of the ERC20 token used.
     */
    IERC20 public ERC20Instance;

    /**
     * @dev Enum of possible event types.
     */
    enum EventType {
        Excalibur,
        Knights
    }

    /**
     * @dev A struct that represents the winnings of an event.
     * @param index The index of the winnings.
     * @param share The share of winnings.
     * @param initiated A boolean flag to indicate if winnings have been initiated.
     */
    struct Winnings {
        uint256 index;
        uint256 share;
        bool initiated;
    }

    /**
     * @dev A struct that represents the distribution of winnings for an event.
     * @param winner Percent to transfer to the winner of the event.
     * @param votedUsers Percent to transfer to the voted users of the event.
     * @param senators Percent to transfer to the senators of the event.
     * @param project Percent to transfer to the project.
     * @param editor Percent to transfer to the editor of the event.
     * @param enabled A flag to indicate if the distribution is enabled or not.
     */
    struct Distribution {
        uint32 winner;
        uint32 votedUsers;
        uint32 senators;
        uint32 project;
        uint32 editor;
        uint8 enabled;
    }

    /**
     * @dev A struct that represents the properties of an event.
     * @param eventType The type of the event.
     * @param editor The address of the editor who created the event.
     * @param endTime The end time of the event.
     * @param distributionPath The path to the distribution of the event.
     * @param description The description of the event.
     * @param options An array of addresses representing the event options.
     * @param senators An array of addresses representing the event senators.
     */
    struct Events {
        EventType eventType;
        address editor;
        uint256 endTime;
        uint256 distributionPath;
        string description;
        address[] options;
        address[] senators;
    }

    // ["0","0xA6c00FB83e02a2a96a95223761b4Bc7B5fa2b302","1690621375","0","MRLN",["0xA6c00FB83e02a2a96a95223761b4Bc7B5fa2b302"],["0xA6c00FB83e02a2a96a95223761b4Bc7B5fa2b302","0xA6c00FB83e02a2a96a95223761b4Bc7B5fa2b302"]]

    /**
     * @dev Private constant representing the type hash of the 'Events' struct.
     * It is calculated using the keccak256 hash function with the packed representation of the struct's members.
     * The struct includes the following members:
     * - EventType eventType: Type of event
     * - address editor: Address of the editor
     * - uint128 endTime: End time of the event
     * - string description: Description of the event
     * - address[] options: Array of options for the event
     * - address[] senators: Array of senators for the event
     * This constant is used for encoding and decoding of struct data in function arguments.
     */
    bytes32 private constant _EVENTS_TYPEHASH =
        keccak256(
            "Events(uint8 eventType,address editor,uint256 endTime,uint256 distributionPath,string description,address[] options,address[] senators)"
        );

    /**
     * @notice Mapping to keep track of signers.
     */
    mapping(address => bool) public signer;

    /**
     * @notice Mapping to store events by eventId.
     */
    mapping(uint256 => Events) public events;

    /**
     * @notice Mapping to store option shares for events.
     */
    mapping(uint256 => mapping(uint256 => uint256)) public optionShare;

    /**
     * @notice Mapping to store user option shares for events.
     */
    mapping(address => mapping(uint256 => mapping(uint256 => uint256)))
        public userOptionShare;

    /**
     * @notice Mapping to store event share amounts.
     */
    mapping(uint256 => uint256) public eventShare;

    /**
     * @notice Mapping to store winnings for events.
     */
    mapping(uint256 => Winnings) public winnings;

    /**
     * @notice Mapping to keep track of claimed winnings by users.
     */
    mapping(address => mapping(uint256 => bool)) public claimed;

    /**
     * @notice Mapping to store distribution details for events.
     */
    mapping(uint256 => Distribution) public distribution;

    mapping(bytes => bool) public used;

    mapping(uint256 => mapping(uint256 => uint256)) totalVotes;
    /**
     * @dev Emitted when a signer is updated.
     * @param _signer The address of the updated signer.
     * @param value The new value of the signer.
     * @param timestamp The timestamp of the update.
     */
    event SignerUpdated(address indexed _signer, bool value, uint256 timestamp);

    /**
     * @dev Emitted when a distribution path is added.
     * @param _distributionId The ID of the distribution.
     * @param _distribution The new distribution.
     * @param timestamp The timestamp of the update.
     */
    event DistributionPathAdded(
        uint256 _distributionId,
        Distribution _distribution,
        uint256 timestamp
    );

    /**
     * @dev Emitted when a distribution path is disabled.
     * @param _distributionId The ID of the distribution.
     * @param _distribution The disabled distribution.
     * @param timestamp The timestamp of the update.
     */
    event DistributionPathDisabled(
        uint256 _distributionId,
        Distribution _distribution,
        uint256 timestamp
    );

    /**
     * @dev Emitted when the senator limit is updated.
     * @param value The new senator limit.
     * @param timestamp The timestamp of the update.
     */
    event SenatorLimitUpdated(uint256 value, uint256 timestamp);

    /**
     * @dev Emitted when the option limit is updated.
     * @param value The new option limit.
     * @param timestamp The timestamp of the update.
     */
    event OptionLimitUpdated(uint256 value, uint256 timestamp);

    /**
     * @dev Emitted when a new event is added.
     * @param _eventId The ID of the new event.
     * @param _event The new event.
     * @param timestamp The timestamp of the add.
     */
    event EventAdded(
        uint256 indexed _eventId,
        Events _event,
        uint256 timestamp
    );

    /**
     * @dev Emitted when a user votes.
     * @param _user The address of the user who voted.
     * @param _eventId The ID of the event being voted on.
     * @param _optionId The ID of the option being voted for.
     * @param amount The amount of tokens being staked in the vote.
     * @param timestamp The timestamp of the vote.
     */
    event Voted(
        address indexed _user,
        uint256 indexed _eventId,
        uint256 indexed _optionId,
        uint256 amount,
        uint256 timestamp
    );

    /**
     * @dev Emitted when an event is distributed.
     * @param _eventId The ID of the event being distributed.
     * @param winner The address of the winner of the event.
     * @param voterRewards The amount of tokens being rewarded to voters.
     * @param timestamp The timestamp of the distribution.
     */
    event Distributed(
        uint256 indexed _eventId,
        address indexed winner,
        uint256 voterRewards,
        uint256 timestamp
    );

    /**
     * @dev Emitted when a user claims their reward for an event.
     * @param _eventId The ID of the event the user is claiming a reward for.
     * @param _option The ID of the option the user is claiming a reward for.
     * @param _amount The amount of tokens being claimed.
     * @param timestamp The timestamp of the claim.
     */
    event Claimed(
        uint256 indexed _eventId,
        uint256 indexed _option,
        uint256 _amount,
        uint256 timestamp
    );

    /**
     * @notice Initializes a new instance of the contract.
     * @param _signer The address of the signer who will sign the distributions.
     * @param _token The address of the ERC20 token used for distributions.
     * @param _projectAddress The address of the project which owns this contract.
     * @param _domainName The name of the EIP712 domain for signing distributions.
     * @param _domainVersion The version of the EIP712 domain for signing distributions.
     * @param _distributions An array of Distribution structs for setting up the distributions.
     * @param _senatorLimit The limit on senators to be added to each event
     * @param _optionLimit The limit on options to be added to each event
     * @dev The constructor requires non-zero values for `_signer`, `_token` and `_projectAddress`.
     *      The ERC20 instance is initialized with `_token`.
     *      The `_signer` address is added to the `signer` mapping.
     *      The `addDistributionPaths` function is called to add the distribution paths to the EIP712 domain separator.
     */
    constructor(
        address _signer,
        address _token,
        address _projectAddress,
        string memory _domainName,
        string memory _domainVersion,
        Distribution[] memory _distributions,
        uint256 _senatorLimit,
        uint256 _optionLimit
    ) EIP712(_domainName, _domainVersion) {
        require(_token != address(0), "Zero token address");
        require(_projectAddress != address(0), "Zero project address");
        require(_signer != address(0), "Zero address cannot be signer");
        projectAddress = _projectAddress;
        ERC20Instance = IERC20(_token);
        signer[_signer] = true;
        addDistributionPaths(_distributions);
        setSenatorLimit(_senatorLimit);
        setOptionLimit(_optionLimit);
    }

    /**
     * @notice Updates the `signer` mapping with the specified signers and their boolean value.
     * @param _signers An array of addresses to be updated in the `signer` mapping.
     * @param value The boolean value to set for the specified signers.
     * @dev Only the contract owner is authorized to call this function.
     *      The `_signers` array must have at least one address.
     *      The `value` parameter sets the boolean value for all the specified signers.
     *      This function updates the `signer` mapping for all the specified signers.
     */
    function updateSigners(
        address[] memory _signers,
        bool value
    ) external onlyOwner {
        require(_signers.length > 0, "Zero signers");
        for (uint i; i < _signers.length; ) {
            signer[_signers[i]] = value;
            emit SignerUpdated(_signers[i], value, block.timestamp);
            unchecked {
                ++i;
            }
        }
    }

    /**
     * @notice Adds distribution paths to the contract for distributing rewards.
     * @param _distributions An array of Distribution structs representing the distribution paths.
     * @dev Only the contract owner is authorized to call this function.
     *      The `_distributions` array must have at least one Distribution struct.
     *      Each Distribution struct in the `_distributions` array must have percentages that sum up to 10000.
     *      Each Distribution struct must have a valid `enabled` value of either 0 or 1.
     *      The Distribution structs are added to the `distribution` mapping with `distributionId` as the key.
     *      The `distributionId` is incremented for each Distribution struct added.
     */
    function addDistributionPaths(
        Distribution[] memory _distributions
    ) public onlyOwner {
        require(_distributions.length > 0, "Zero distribution paths");
        for (uint i; i < _distributions.length; ) {
            require(
                _distributions[i].winner +
                    _distributions[i].votedUsers +
                    _distributions[i].senators +
                    _distributions[i].project +
                    _distributions[i].editor ==
                    10000,
                "Invalid percentages"
            );
            require(
                _distributions[i].enabled == 1 ||
                    _distributions[i].enabled == 0,
                "Invalid enable response"
            );
            distribution[distributionId] = _distributions[i];
            emit DistributionPathAdded(
                distributionId,
                _distributions[i],
                block.timestamp
            );
            unchecked {
                ++distributionId;
                ++i;
            }
        }
    }

    /**
     * @notice Disables the specified distribution paths by setting their `enabled` value to 0.
     * @param _distributionIds An array of distribution IDs to be disabled.
     * @dev Only the contract owner is authorized to call this function.
     *      The `_distributionIds` array must have at least one distribution ID.
     *      Each distribution ID must be a valid and existing ID in the `distribution` mapping.
     *      This function sets the `enabled` value of each specified distribution to 0, effectively disabling them.
     */
    function disableDistributionPaths(
        uint256[] memory _distributionIds
    ) external onlyOwner {
        require(_distributionIds.length > 0, "Zero distribution Ids");
        for (uint i; i < _distributionIds.length; ) {
            require(
                _distributionIds[i] > 0 && _distributionIds[i] < distributionId,
                "Invalid distribution Id"
            );
            distribution[_distributionIds[i]].enabled = 0;
            emit DistributionPathDisabled(
                _distributionIds[i],
                distribution[_distributionIds[i]],
                block.timestamp
            );
            unchecked {
                ++i;
            }
        }
    }

    /**
     * @notice Sets the maximum number of senators allowed for a proposal.
     * @param _limit The new senator limit to be set.
     * @dev Only the contract owner is authorized to call this function.
     *      The `_limit` parameter must be greater than 0 and less than or equal to 20.
     *      This function sets the `senatorLimit` variable to the specified `_limit`.
     */
    function setSenatorLimit(uint256 _limit) public onlyOwner {
        require(_limit > 0 && _limit <= 20, "Invalid senator limit");
        senatorLimit = _limit;
        emit SenatorLimitUpdated(_limit, block.timestamp);
    }

    /**
     * @notice Sets the maximum number of options allowed for a proposal.
     * @param _limit The new option limit to be set.
     * @dev Only the contract owner is authorized to call this function.
     *      The `_limit` parameter must be greater than 0.
     *      This function sets the `optionLimit` variable to the specified `_limit`.
     */
    function setOptionLimit(uint256 _limit) public onlyOwner {
        require(_limit > 0, "Zero option limit");
        optionLimit = _limit;
        emit OptionLimitUpdated(_limit, block.timestamp);
    }

    /**
     * @notice Adds a new event to the contract.
     * @param _event The details of the event to be added, including editor, endTime, distributionPath, senators, and options.
     * @param signature The signature for the event to be verified.
     * @return bool A boolean indicating if the event was added successfully.
     * @dev This function verifies various conditions before adding the event.
     *      The `_event` parameter must contain a non-zero editor address, an end time greater than the current block timestamp,
     *      a valid and enabled distribution path, a valid number of senators within the limit defined by `senatorLimit`,
     *      and a valid number of options within the limit defined by `optionLimit`.
     *      The `_signer` is retrieved using `getSigner` function and must be a valid signer defined in the `signer` mapping.
     *      If all conditions are met, the event is added to the `events` mapping and the event ID is incremented.
     */
    function addEvent(
        Events calldata _event,
        bytes calldata signature
    ) external returns (bool) {
        require(_event.editor != address(0), "Zero editor address");
        require(_event.endTime > block.timestamp, "End time in past");
        require(
            distribution[_event.distributionPath].enabled == 1,
            "Invalid distribution path"
        );
        require(
            _event.senators.length <= senatorLimit,
            "Invalid senators length"
        );
        require(
            _event.options.length > 0 && _event.options.length <= optionLimit,
            "Invalid options length"
        );
        require(!used[signature], "Signature already used");
        address _signer = getSigner(_event, signature);
        require(_signer != address(0) && signer[_signer], "Invalid signer");
        used[signature] = true;
        events[eventId] = _event;
        emit EventAdded(eventId, _event, block.timestamp);
        ++eventId;
        return true;
    }

    /**
     * @notice Allows a user to vote for an option in a specific event.
     * @param _eventId The ID of the event to vote in.
     * @param _option The option to vote for.
     * @param _amount The amount to vote with.
     * @return bool A boolean indicating if the vote was successful.
     * @dev This function verifies various conditions before allowing a user to vote.
     *      The `_eventId` parameter must be a valid event ID that is less than the current `eventId`.
     *      The `_amount` parameter must be greater than zero.
     *      The `_event` is retrieved from the `events` mapping using the `_eventId` parameter.
     *      The current block timestamp must be less than or equal to the end time of the event.
     *      The `_option` parameter must be a valid option index within the options of the event.
     *      If all conditions are met, the vote is recorded by updating the relevant vote share mappings,
     *      and the user's account is charged with the vote amount using the `pay` function.
     */
    function vote(
        uint256 _eventId,
        uint256 _option,
        uint256 _amount
    ) external returns (bool) {
        require(_eventId < eventId, "Invalid event ID");
        require(_amount > 0, "Zero vote amount");
        Events memory _event = events[_eventId];
        require(_event.endTime >= block.timestamp, "Voting period ended");
        require(_option < _event.options.length, "Invalid option");

        optionShare[_eventId][_option] += _amount;
        eventShare[_eventId] += _amount;
        userOptionShare[msg.sender][_eventId][_option] += _amount;

        // Increment the total number of voters for the given event and option
        totalVotes[_eventId][_option]++;

        emit Voted(msg.sender, _eventId, _option, _amount, block.timestamp);
        pay(msg.sender, address(this), _amount);
        return true;
    }

    /**
     * @dev Returns the winner and its details for a given event.
     * @param _eventId The ID of the event.
     * @return The index of the winner option, its share, the total share of the event and the address of the winner option.
     */

    function getWinner(
        uint256 _eventId
    ) public view returns (uint256, uint256, uint256, address) {
        require(_eventId < eventId, "Invalid event ID");
        require(eventShare[_eventId] > 0, "No locks done yet");

        Events memory _event = events[_eventId];
        uint256 maxShare = optionShare[_eventId][0];
        uint256 winner = 0;

        for (uint i = 1; i < _event.options.length; ) {
            if (maxShare < optionShare[_eventId][i]) {
                maxShare = optionShare[_eventId][i];
                winner = i;
            }
            unchecked {
                ++i;
            }
        }

        return (winner, maxShare, eventShare[_eventId], _event.options[winner]);
    }

    /**
     * @notice Distribute the winnings of an event among the editor, project, senators, and winner.
     * @dev The event's voting period must have ended, and the winnings must not have been distributed before.
     * @param _eventId The ID of the event to distribute the winnings for.
     * @return A boolean indicating whether the winnings were successfully distributed.
     */
    function distribute(uint256 _eventId) external returns (bool) {
        Events memory _event = events[_eventId];
        require(_event.endTime <= block.timestamp, "Voting period not ended");
        (
            uint256 _index,
            uint256 maxShare,
            uint256 totalShare,
            address _winner
        ) = getWinner(_eventId);

        Winnings memory _winnings = winnings[_eventId];
        require(!_winnings.initiated, "Already distributed");

        //transfers
        Distribution memory path = distribution[_event.distributionPath];

        uint256 winningAmount = eventShare[_eventId];

        uint256 editorShare = (winningAmount * path.editor) / 10000;
        uint256 projectShare = (winningAmount * path.project) / 10000;

        pay(_event.editor, editorShare);
        pay(projectAddress, projectShare);

        uint256 remaining = 0;

        if (_event.eventType == (EventType.Excalibur)) {
            uint256 senatorShare = 0;
            if (_event.senators.length > 0) {
                senatorShare = (winningAmount * path.senators) / 10000;
                uint256 length = _event.senators.length;
                uint256 individualShare = senatorShare / length;
                for (uint i; i < length; ) {
                    pay(_event.senators[i], individualShare);
                    unchecked {
                        ++i;
                    }
                }
            }

            uint256 winnerShare = (winningAmount * path.winner) / 10000;
            pay(_winner, winnerShare);

            remaining =
                winningAmount -
                (editorShare + projectShare + senatorShare + winnerShare);
        } else {
            uint256 winnerPercent = ((maxShare * 20000) / totalShare) < 7500
                ? ((maxShare * 20000) / totalShare)
                : 7500;

            uint256 winnerShare = (winningAmount * winnerPercent) / 10000;
            pay(_winner, winnerShare);

            remaining =
                winningAmount -
                (editorShare + projectShare + winnerShare);
        }
        winnings[_eventId] = Winnings(_index, remaining, true);
        emit Distributed(_eventId, _winner, remaining, block.timestamp);
        return true;
    }

    /**
     * @notice Claim the winnings of a specific event for the caller.
     * @dev The winnings must have been distributed and the caller must have unclaimed winnings.
     * @param _eventId The ID of the event to claim winnings for.
     * @return A boolean indicating whether the winnings were successfully claimed.
     */
    function claimWinnings(uint256 _eventId) external returns (bool) {
        Winnings memory _winnings = winnings[_eventId];
        require(_winnings.initiated, "Distribution not done");
        require(_winnings.share > 0, "Zero winnings");
        require(!claimed[msg.sender][_eventId], "Already claimed");
        claimed[msg.sender][_eventId] = true;
        uint256 userShare = userOptionShare[msg.sender][_eventId][
            _winnings.index
        ];
        require(userShare > 0, "No shares found");
        userShare =
            (userShare * 10000) /
            optionShare[_eventId][_winnings.index];

        uint256 userAmount = (_winnings.share * userShare) / 10000;
        emit Claimed(_eventId, _winnings.index, userAmount, block.timestamp);
        pay(msg.sender, userAmount);
        return true;
    }

    /**
     * @notice Internal function to transfer ERC20 tokens to a specified user.
     * @dev The amount must be greater than zero.
     * @param user The address of the user to transfer tokens to.
     * @param amount The amount of tokens to transfer.
     */

    function pay(address user, uint256 amount) internal {
        ERC20Instance.transfer(user, amount);
    }

    /**
     * @notice Internal function to transfer ERC20 tokens from one address to another.
     * @param from The address to transfer tokens from.
     * @param to The address to transfer tokens to.
     * @param amount The amount of tokens to transfer.
     */

    function pay(address from, address to, uint256 amount) internal {
        ERC20Instance.transferFrom(from, to, amount);
    }

    /**
     * @notice Recovers the signer of the message by using the provided signature and the information about the event.
     * @param _event The event to get the signer for.
     * @param signature The signature to recover the signer from.
     * @return _signer The address of the signer of the message.
     */
    function getSigner(
        Events calldata _event,
        bytes calldata signature
    ) public view returns (address _signer) {
        bytes32 digest = _hashTypedDataV4(
            keccak256(
                abi.encode(
                    _EVENTS_TYPEHASH,
                    uint8(_event.eventType),
                    _event.editor,
                    _event.endTime,
                    _event.distributionPath,
                    keccak256(abi.encodePacked(_event.description)),
                    keccak256(abi.encodePacked(_event.options)),
                    keccak256(abi.encodePacked(_event.senators))
                )
            )
        );

        _signer = ECDSA.recover(digest, signature);
    }

    function DOMAIN_SEPERATOR() external view returns (bytes32) {
        return _domainSeparatorV4();
    }

    function eventData(
        uint256 _eventId
    )
        external
        view
        returns (
            uint8,
            address,
            uint256,
            uint256,
            string memory,
            address[] memory,
            address[] memory
        )
    {
        require(_eventId < eventId, "Invalid event ID");
        Events memory _event = events[_eventId];
        return (
            uint8(_event.eventType),
            _event.editor,
            _event.endTime,
            _event.distributionPath,
            _event.description,
            _event.options,
            _event.senators
        );
    }
}