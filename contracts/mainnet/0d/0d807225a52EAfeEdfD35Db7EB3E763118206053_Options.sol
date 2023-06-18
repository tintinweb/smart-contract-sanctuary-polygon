// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

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

// SPDX-License-Identifier: MIT
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
pragma solidity ^0.8.0;

interface IGovernanceStaking {
    function stake(uint256 _amount, uint256 _duration) external;
    function unstake(uint256 _amount) external;
    function claim() external;
    function distribute(address _token, uint256 _amount) external;
    function whitelistReward(address _rewardToken) external;
    function pending(address _user, address _token) external view returns (uint256);
    function userStaked(address _user) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IPairsContract {

    struct Asset {
        string name;
        address chainlinkFeed;
        uint256 minLeverage;
        uint256 maxLeverage;
        uint256 feeMultiplier;
        uint256 baseFundingRate;
    }

    struct OpenInterest {
        uint256 longOi;
        uint256 shortOi;
        uint256 maxOi;
    }

    function allowedAsset(uint) external view returns (bool);
    function idToAsset(uint256 _asset) external view returns (Asset memory);
    function idToOi(uint256 _asset, address _tigAsset) external view returns (OpenInterest memory);
    function setAssetBaseFundingRate(uint256 _asset, uint256 _baseFundingRate) external;
    function modifyLongOi(uint256 _asset, address _tigAsset, bool _onOpen, uint256 _amount) external;
    function modifyShortOi(uint256 _asset, address _tigAsset, bool _onOpen, uint256 _amount) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IReferrals {
    function setReferred(address _referredTrader, address _referrer) external;
    function getReferred(address _trader) external view returns (address, uint);
    function addRefFees(address _trader, address _tigAsset, uint _fees) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IStableVault {
    function deposit(address, uint) external;
    function withdraw(address, uint) external returns (uint256);
    function allowed(address) external view returns (bool);
    function stable() external view returns (address);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

interface ITradeNFT {

    struct Trade {
        uint256 collateral;
        uint256 asset;
        bool direction;
        uint256 duration;
        uint256 openPrice;
        uint256 expires;
        uint256 orderType;
        address trader;
        uint256 id;
        address tigAsset;
        address receivedAsset;
        address stableVault;
    }

    struct MintTrade {
        address account;
        uint256 collateral;
        uint256 asset;
        bool direction;
        uint256 duration;
        uint256 price;
        uint256 orderType;
        address tigAsset;
        address receivedAsset;
        address stableVault;
    }

    function trades(uint256) external view returns (Trade memory);
    function executeLimitOrder(uint256 _id, uint256 _price, uint256 _newMargin) external;
    function assetOpenPositions(uint256 _asset) external view returns (uint256[] calldata);
    function assetOpenPositionsIndexes(uint256 _asset, uint256 _id) external view returns (uint256);
    function limitOrders(uint256 _asset) external view returns (uint256[] memory);
    function limitOrderIndexes(uint256 _asset, uint256 _id) external view returns (uint256);
    function assetOpenPositionsLength(uint256 _asset) external view returns (uint256);
    function limitOrdersLength(uint256 _asset) external view returns (uint256);
    function ownerOf(uint256 _id) external view returns (address);
    function mint(MintTrade memory _mintTrade) external;
    function burn(uint256 _id) external;
    function getCount() external view returns (uint);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../utils/MetaContext.sol";
import "../interfaces/ITradeNFT.sol";
import "../interfaces/IReferrals.sol";
import "../interfaces/IPairsContract.sol";
import "../interfaces/IStableVault.sol";
import "../interfaces/IGovernanceStaking.sol";

interface IStable is IERC20 {
    function burnFrom(address account, uint256 amount) external;
    function mintFor(address account, uint256 amount) external;
}

interface ExtendedIERC20 is IERC20 {
    function decimals() external view returns (uint);
}

interface ITrading {
    struct Proxy {
        address proxy;
        uint256 time;
    }
    function proxyApprovals(address _account) external view returns(Proxy memory);
}

interface ERC20Permit is IERC20 {
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;
}

interface IPrice {
    function latestRoundData() external view returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound);
    function decimals() external view returns (uint8);
}

contract Options is MetaContext {
    using ECDSA for bytes32;

    uint256 constant private DIVISION_CONSTANT = 1e10;
    uint256 constant private CHAINLINK_PRECISION = 2e8;

    struct ERC20PermitData {
        uint256 deadline;
        uint256 amount;
        uint8 v;
        bytes32 r;
        bytes32 s;
        bool usePermit;
    }

    struct PriceData {
        address provider;
        bool isClosed;
        uint256 asset;
        uint256 price;
        uint256 spread;
        uint256 timestamp;
    }

    struct TradeInfo {
        uint256 collateral;
        address collateralAsset;
        address stableVault;
        address receivedAsset;
        uint256 asset;
        bool direction;
        uint256 duration;
        address referrer;
    }

    struct TradedAsset {
        uint maxCollateral;
        uint minCollateral;
        uint maxDuration;
        uint minDuration;
        uint maxOpen;
        uint openInterest;
        uint assetId;
        uint winPercent;
        uint closeFee;
        uint botFee;
    }

    bool public chainlinkEnabled;
    uint public _validSignatureTimer;
    bool public useSpread;

    ITradeNFT public tradeNFT;
    IGovernanceStaking public staking;
    IReferrals public referrals;
    IPairsContract public pairsContract;
    ITrading public tradingContract;

    mapping(address => bool) public allowedVault;
    mapping(address => bool) public marginApproved;
    mapping(uint => TradedAsset) public tradedAssets;
    mapping(address => bool) public isNode;

    constructor(
        address _tradeNFT,
        address _staking,
        address _referrals,
        address _pairsContract,
        address _trading
    )
    {
        if (
            _tradeNFT == address(0) ||
            _staking == address(0) ||
            _referrals == address(0) ||
            _pairsContract == address(0) ||
            _trading == address(0)
        ) {
            revert("!constructor");
        }
        tradeNFT = ITradeNFT(_tradeNFT);
        staking = IGovernanceStaking(_staking);
        referrals = IReferrals(_referrals);
        pairsContract = IPairsContract(_pairsContract);
        tradingContract = ITrading(_trading);
    }

    // ===== END-USER FUNCTIONS =====

    /**
     * @param _tradeInfo Trade info
     * @param _priceData verifiable off-chain price data
     * @param _signature node signature
     * @param _permitData data and signature needed for token approval
     * @param _trader address the trade is initiated for
     */
    function openTrade(
        TradeInfo calldata _tradeInfo,
        PriceData calldata _priceData,
        bytes calldata _signature,
        ERC20PermitData calldata _permitData,
        address _trader
    )
        external
    {
        _validateProxy(_trader);
        TradedAsset storage asset = tradedAssets[_tradeInfo.asset];
        require(asset.openInterest + _tradeInfo.collateral <= asset.maxOpen, "!maxOpen");
        require(_tradeInfo.collateral <= asset.maxCollateral, "!max");
        require(_tradeInfo.collateral >= asset.minCollateral, "!min");
        require(_tradeInfo.duration <= asset.maxDuration, "!maxD");
        require(_tradeInfo.duration >= asset.minDuration, "!minD");
        
        address _tigAsset = _checkVault(_tradeInfo.stableVault, _tradeInfo.collateralAsset, _tradeInfo.receivedAsset);
        (uint256 _price, uint _spread) = getVerifiedPrice(_tradeInfo.asset, _priceData, _signature, _tradeInfo.direction ? 1 : 2, true);

        _handleDeposit(_tigAsset, _tradeInfo.collateralAsset, _tradeInfo.collateral, _tradeInfo.stableVault, _permitData, _trader);
        asset.openInterest += _tradeInfo.collateral;

        ITradeNFT.MintTrade memory _mintTrade = ITradeNFT.MintTrade(
            _trader,
            _tradeInfo.collateral,
            _tradeInfo.asset,
            _tradeInfo.direction,
            _tradeInfo.duration,
            _price,
            0,
            _tigAsset,
            _tradeInfo.receivedAsset,
            _tradeInfo.stableVault
        );
       
        tradeNFT.mint(_mintTrade);

        emit TradeOpened(_tradeInfo, _tradeInfo.duration + block.timestamp, 0, _price, tradeNFT.getCount()-1, _trader);  
    }

    /**
     * @param _tradeInfo Trade info
     * @param _orderType type of limit order used to open the position
     * @param _price limit price
     * @param _permitData data and signature needed for token approval
     * @param _trader address the trade is initiated for
     */
    function initiateLimitOrder(
        TradeInfo calldata _tradeInfo,
        uint256 _orderType, // 1 limit, 2 stop
        uint256 _price,
        ERC20PermitData calldata _permitData,
        address _trader
    )
        external
    {   
        TradedAsset storage asset = tradedAssets[_tradeInfo.asset];
        require(asset.openInterest + _tradeInfo.collateral <= asset.maxOpen, "!maxOpen");
        require(_tradeInfo.collateral <= asset.maxCollateral, "!max");
        require(_tradeInfo.collateral >= asset.minCollateral, "!min");
        require(_tradeInfo.duration <= asset.maxDuration, "!maxD");
        require(_tradeInfo.duration >= asset.minDuration, "!minD");

        _validateProxy(_trader);
        address _tigAsset = IStableVault(_tradeInfo.stableVault).stable();

        _checkVault(_tradeInfo.stableVault, _tradeInfo.collateralAsset, _tradeInfo.receivedAsset);

        if (_orderType == 0) revert("!limit");
        if (_price == 0) revert("!price");

        _handleDeposit(_tigAsset, _tradeInfo.collateralAsset, _tradeInfo.collateral, _tradeInfo.stableVault, _permitData, _trader);

        ITradeNFT.MintTrade memory _mintTrade = ITradeNFT.MintTrade(
            _trader,
            _tradeInfo.collateral,
            _tradeInfo.asset,
            _tradeInfo.direction,
            _tradeInfo.duration,
            _price,
            _orderType,
            _tigAsset,
            _tradeInfo.receivedAsset,
            _tradeInfo.stableVault
        );
        
        tradeNFT.mint(_mintTrade);

        emit TradeOpened(_tradeInfo, type(uint).max, _orderType, _price, tradeNFT.getCount()-1, _trader);
    }

    /**
     * @param _id position ID
     * @param _trader address the trade is initiated for
     */
    function cancelLimitOrder(
        uint256 _id,
        address _trader
    )
        external
    {
        _validateProxy(_trader);
        _checkOwner(_id, _trader);
        ITradeNFT.Trade memory _trade = tradeNFT.trades(_id);
        if (_trade.orderType == 0) revert("!limit");
        IStable(_trade.tigAsset).mintFor(_trader, _trade.collateral);
        tradeNFT.burn(_id);
        emit OptionsLimitCancelled(_id, _trader);
    }

    /**
     * @param _id position id
     * @param _priceData verifiable off-chain price data
     * @param _signature node signature
     */
    function executeLimitOrder(
        uint256 _id, 
        PriceData calldata _priceData,
        bytes calldata _signature
    ) 
        external
    {
        ITradeNFT.Trade memory trade = tradeNFT.trades(_id);
        TradedAsset storage asset = tradedAssets[trade.asset];
        require(asset.openInterest + trade.collateral <= asset.maxOpen, "!maxOpen");
        
        (uint256 _price, uint256 _spread) = getVerifiedPrice(trade.asset, _priceData, _signature, 0, true);

        if (trade.orderType == 0) revert("!limit");

        if (trade.direction && trade.orderType == 1) {
            if (trade.openPrice < _price) revert("!limitPrice");
        } else if (!trade.direction && trade.orderType == 1) {
            if (trade.openPrice > _price) revert("!limitPrice");
        } else if (!trade.direction && trade.orderType == 2) {
            if (trade.openPrice < _price) revert("!limitPrice");
            trade.openPrice = _price;
        } else {
            if (trade.openPrice > _price) revert("!limitPrice");
            trade.openPrice = _price;
        } 
        if (trade.direction && useSpread) {
            trade.openPrice += trade.openPrice * _spread / DIVISION_CONSTANT;
        } else {
            trade.openPrice -= trade.openPrice * _spread / DIVISION_CONSTANT;
        }

        asset.openInterest += trade.collateral;

        IStable(trade.tigAsset).mintFor(_msgSender(), trade.collateral * asset.botFee / 1e6);
        tradeNFT.executeLimitOrder(_id, trade.openPrice, trade.collateral);

        emit OptionsLimitOrderExecuted(trade.asset, trade.direction, trade.duration, trade.openPrice, trade.collateral, _id, trade.expires, trade.trader, _msgSender());
    }

    /**
     * @notice close trade
     * @param _id id of the tradeNFT
     * @param _priceData verifiable off-chain data
     * @param _signature node signature
     */
    function closeTrade(
        uint256 _id,
        PriceData calldata _priceData,
        bytes calldata _signature
    )
        external
    {
        ITradeNFT.Trade memory _trade = tradeNFT.trades(_id);
        require(_trade.trader != address(0), "!exists");

        TradedAsset memory _tradedAsset = tradedAssets[_trade.asset];
        address _tigAsset = _trade.tigAsset;

        if (_trade.orderType != 0) revert("!limit");

        (uint256 _price,) = getVerifiedPrice(_trade.asset, _priceData, _signature, 0, true);
        if (block.timestamp < _trade.expires) revert("!expired");

        bool isWin;
        if (_trade.direction && _price > _trade.openPrice) {
            isWin = true;
        } else if(!_trade.direction && _price <= _trade.openPrice) {
            isWin = true;
        }

        uint toSend;
        if(isWin) {
            toSend = _trade.collateral + _trade.collateral * _tradedAsset.winPercent / 1e6;
            if(_tigAsset == _trade.receivedAsset) {
                IStable(_tigAsset).mintFor(address(_trade.trader), toSend);
            } else {
                IStable(_tigAsset).mintFor(address(this), toSend);
                IStableVault(_trade.stableVault).withdraw(_trade.receivedAsset, toSend);
                IERC20(_trade.receivedAsset).transfer(_trade.trader, toSend);
            }
        }

        (address _referrer, uint _refFees) = getRef(_trade.trader);
        if(_referrer != address(0)) { 
            IStable(_tigAsset).mintFor(_referrer, _trade.collateral * _refFees / 1e6);
        }
        IStable(_tigAsset).mintFor(address(this), _trade.collateral * _tradedAsset.closeFee / 1e6);
        IStable(_tigAsset).mintFor(_msgSender(), _trade.collateral * _tradedAsset.botFee / 1e6);

        uint balance = IStable(_tigAsset).balanceOf(address(this));
        IStable(_tigAsset).approve(address(staking), balance);
        staking.distribute(_tigAsset, balance);
        emit OptionsFeesDistributed(_tigAsset, balance, _referrer == address(0) ? 0 : _trade.collateral * _refFees / 1e6, _trade.collateral * _tradedAsset.botFee / 1e6, _referrer);

        _tradedAsset.openInterest -= _trade.collateral;
        tradeNFT.burn(_id);
        emit TradeClosed(_id, _price, isWin ? _tradedAsset.winPercent : 0, toSend, _trade.trader, _msgSender());
    }

    /**
    * @notice verifies the signed price and returns it
    * @param _asset id of position asset
    * @param _priceData price data object came from the price oracle
    * @param _signature to verify the oracle
    * @param _withSpreadIsLong 0, 1, or 2 - to specify if we need the price returned to be after spread
    * @return _price price after verification and with spread if _withSpreadIsLong is 1 or 2
    * @return _spread spread after verification
    */
    function getVerifiedPrice(
        uint256 _asset,
        PriceData calldata _priceData,
        bytes calldata _signature,
        uint256 _withSpreadIsLong,
        bool _expirable
    ) 
        public view
        returns(uint256 _price, uint256 _spread) 
    {
        address _provider = (
            keccak256(abi.encode(_priceData))
        ).toEthSignedMessageHash().recover(_signature);

        require(_provider == _priceData.provider, "BadSig");
        require(isNode[_provider], "!Node");
        require(_asset == _priceData.asset, "!Asset");
        require(!_priceData.isClosed, "Closed");
        require(block.timestamp >= _priceData.timestamp, "FutSig");
        if(_expirable) require(block.timestamp <= _priceData.timestamp + _validSignatureTimer, "ExpSig");
        require(_priceData.price > 0, "NoPrice");
        address _chainlinkFeed = pairsContract.idToAsset(_asset).chainlinkFeed;

        if (chainlinkEnabled && _chainlinkFeed != address(0)) {
            (uint80 roundId, int256 assetChainlinkPriceInt, , uint256 updatedAt, uint80 answeredInRound) = IPrice(_chainlinkFeed).latestRoundData();
            if (answeredInRound >= roundId && updatedAt > 0 && assetChainlinkPriceInt != 0) {
                uint256 assetChainlinkPrice = uint256(assetChainlinkPriceInt) * 10**(18 - IPrice(_chainlinkFeed).decimals());
                require(
                    _priceData.price < assetChainlinkPrice+assetChainlinkPrice*CHAINLINK_PRECISION/DIVISION_CONSTANT , "!chainlinkPrice"
                );
                require(
                    _priceData.price > assetChainlinkPrice-assetChainlinkPrice*CHAINLINK_PRECISION/DIVISION_CONSTANT, "!chainlinkPrice"
                );
            }
        }

        _price = _priceData.price;
        _spread = _priceData.spread;

        if(_withSpreadIsLong == 1 && useSpread) 
            _price += _price * _spread / DIVISION_CONSTANT;
        else if(_withSpreadIsLong == 2 && useSpread) 
            _price -= _price * _spread / DIVISION_CONSTANT;
    }

    function getRef(
        address _trader
    ) public view returns(address, uint) {
        return referrals.getReferred(_trader);
    }

    /**
     * @dev handle stableVault deposits for different trading functions
     * @param _tigAsset tigAsset token address
     * @param _marginAsset token being deposited into stableVault
     * @param _margin amount being deposited
     * @param _stableVault StableVault address
     * @param _permitData Data for approval via permit
     * @param _trader Trader address to take tokens from
     */
    function _handleDeposit(address _tigAsset, address _marginAsset, uint256 _margin, address _stableVault, ERC20PermitData calldata _permitData, address _trader) internal {
        IStable tigAsset = IStable(_tigAsset);
        if (_tigAsset != _marginAsset) {
            if (_permitData.usePermit) {
                ERC20Permit(_marginAsset).permit(_trader, address(this), _permitData.amount, _permitData.deadline, _permitData.v, _permitData.r, _permitData.s);
            }
            uint256 _balBefore = tigAsset.balanceOf(address(this));
            uint256 _marginDecMultiplier = 10**(18-ExtendedIERC20(_marginAsset).decimals());
            IERC20(_marginAsset).transferFrom(_trader, address(this), _margin/_marginDecMultiplier);
            if (!marginApproved[_marginAsset]) {
                IERC20(_marginAsset).approve(_stableVault, type(uint).max);
                marginApproved[_marginAsset] = true;
            }
            IStableVault(_stableVault).deposit(_marginAsset, _margin/_marginDecMultiplier);
            if (tigAsset.balanceOf(address(this)) != _balBefore + _margin) revert("!deposit");
            tigAsset.burnFrom(address(this), tigAsset.balanceOf(address(this)));
        } else {
            tigAsset.burnFrom(_trader, _margin);
        }        
    }

    /**
     * @dev check that trader address owns the position
     * @param _id position id
     * @param _trader trader address
     */
    function _checkOwner(uint256 _id, address _trader) internal view {
        if (tradeNFT.ownerOf(_id) != _trader) revert("!owner");
    }

    /**
     * @dev Check that the stableVault input is whitelisted and the margin asset is whitelisted in the vault
     * @param _stableVault StableVault address
     * @param _token Margin asset token address
     * @param _token2 Received asset token address
     */
    function _checkVault(address _stableVault, address _token, address _token2) internal view returns(address _stable) {
        _stable = IStableVault(_stableVault).stable();
        if (!allowedVault[_stableVault]) revert("!vault");
        if (_token != _stable && !IStableVault(_stableVault).allowed(_token)) revert("!allowedToken");
        if (_token2 != _stable && !IStableVault(_stableVault).allowed(_token2)) revert("!allowedToken");
    }

    /**
     * @dev Check that the trader has approved the proxy address to trade for it
     * @param _trader Trader address
     */
    function _validateProxy(address _trader) internal view {
        if (_trader != _msgSender()) {
            ITrading.Proxy memory _proxy = tradingContract.proxyApprovals(_trader);
            if (_proxy.proxy != _msgSender() || _proxy.time < block.timestamp) revert("!proxy");
        }
    }

    /**
     * @dev Whitelists a margin address
     * @param _chainlink if chainlink is to be used
     * @param _timer valid gignature timer
     */
    function setSettings(
        bool _chainlink,
        uint _timer
    )
        external
        onlyOwner
    {
        chainlinkEnabled = _chainlink;
        _validSignatureTimer = _timer;
    }

    /**
     * @dev changes trading contract address
     * @param _new new contract address
     */
    function changeTradingContract(
        address _new
    )
        external
        onlyOwner
    {
        tradingContract = ITrading(_new);
    }

    /**
     * @dev changes use spread
     * @param _use bool for use spread
     */
    function setUseSpread(
        bool _use
    )
        external
        onlyOwner
    {
        useSpread = _use;
    }

    /**
     * @dev Whitelists a node address
     * @param _node node address
     * @param _bool true if allowed
     */
    function setNode(
        address _node,
        bool _bool
    )
        external
        onlyOwner
    {
        isNode[_node] = _bool;
    }

    /**
     * @dev Whitelists a stableVault contract address
     * @param _stableVault StableVault address
     * @param _bool true if allowed
     */
    function setAllowedVault(
        address _stableVault,
        bool _bool
    )
        external
        onlyOwner
    {
        allowedVault[_stableVault] = _bool;
    }

    function setTradedAsset(
        uint _id,
        uint _maxC,
        uint _minC,
        uint _maxD,
        uint _minD,
        uint _maxO,
        uint _winP,
        uint[] calldata _fees
    ) external onlyOwner {
        require(_maxD > 60, "!mD");
        require(_maxC >= _minC, "!C");
        require(_maxD >= _minD, "!D");

        TradedAsset storage _asset = tradedAssets[_id];

        _asset.maxCollateral = _maxC;
        _asset.minCollateral = _minC;
        _asset.maxDuration = _maxD;
        _asset.minDuration = _minD;
        _asset.maxOpen = _maxO;
        _asset.assetId = _id;
        _asset.winPercent = _winP;
        _asset.closeFee = _fees[0];
        _asset.botFee = _fees[1];
    }

    // ===== EVENTS =====
    event TradeOpened(
        TradeInfo tradeInfo,
        uint256 expires,
        uint256 orderType,
        uint256 price,
        uint256 id,
        address trader
    );

    event TradeClosed(
        uint256 id,
        uint256 closePrice,
        uint256 percent,
        uint256 payout,
        address trader,
        address executor
    );

    event OptionsLimitOrderExecuted(
        uint256 asset,
        bool direction,
        uint duration,
        uint256 openPrice,
        uint256 collateral,
        uint256 id,
        uint256 expires,
        address trader,
        address executor
    );

    event OptionsLimitCancelled(
        uint256 id,
        address trader
    );

    event OptionsFeesDistributed(
        address tigAsset,
        uint256 daoFees,
        uint256 refFees,
        uint256 botFees,
        address referrer
    );
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";

contract MetaContext is Ownable {
    mapping(address => bool) private _isTrustedForwarder;

    function setTrustedForwarder(address _forwarder, bool _bool) external onlyOwner {
        _isTrustedForwarder[_forwarder] = _bool;
    }

    function isTrustedForwarder(address _forwarder) external view returns (bool) {
        return _isTrustedForwarder[_forwarder];
    }

    function _msgSender() internal view virtual override returns (address sender) {
        if (_isTrustedForwarder[msg.sender]) {
            // The assembly code is more direct than the Solidity version using `abi.decode`.
            /// @solidity memory-safe-assembly
            assembly {
                sender := shr(96, calldataload(sub(calldatasize(), 20)))
            }
        } else {
            return super._msgSender();
        }
    }

    function _msgData() internal view virtual override returns (bytes calldata) {
        if (_isTrustedForwarder[msg.sender]) {
            return msg.data[:msg.data.length - 20];
        } else {
            return super._msgData();
        }
    }
}