/**
 *Submitted for verification at polygonscan.com on 2023-04-04
 */

// SPDX-License-Identifier: MIT
// File: @openzeppelin/contracts/utils/math/SafeMath.sol

// OpenZeppelin Contracts (last updated v4.6.0) (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(
        uint256 a,
        uint256 b
    ) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(
        uint256 a,
        uint256 b
    ) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(
        uint256 a,
        uint256 b
    ) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(
        uint256 a,
        uint256 b
    ) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(
        uint256 a,
        uint256 b
    ) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

pragma solidity ^0.8.0;

/**
 * @dev Provides a set of functions to operate with Base64 strings.
 *
 * _Available since v4.5._
 */
library Base64 {
    /**
     * @dev Base64 Encoding/Decoding Table
     */
    string internal constant _TABLE =
        "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

    /**
     * @dev Converts a `bytes` to its Bytes64 `string` representation.
     */
    function encode(bytes memory data) internal pure returns (string memory) {
        /**
         * Inspired by Brecht Devos (Brechtpd) implementation - MIT licence
         * https://github.com/Brechtpd/base64/blob/e78d9fd951e7b0977ddca77d92dc85183770daf4/base64.sol
         */
        if (data.length == 0) return "";

        // Loads the table into memory
        string memory table = _TABLE;

        // Encoding takes 3 bytes chunks of binary data from `bytes` data parameter
        // and split into 4 numbers of 6 bits.
        // The final Base64 length should be `bytes` data length multiplied by 4/3 rounded up
        // - `data.length + 2`  -> Round up
        // - `/ 3`              -> Number of 3-bytes chunks
        // - `4 *`              -> 4 characters for each chunk
        string memory result = new string(4 * ((data.length + 2) / 3));

        /// @solidity memory-safe-assembly
        assembly {
            // Prepare the lookup table (skip the first "length" byte)
            let tablePtr := add(table, 1)

            // Prepare result pointer, jump over length
            let resultPtr := add(result, 32)

            // Run over the input, 3 bytes at a time
            for {
                let dataPtr := data
                let endPtr := add(data, mload(data))
            } lt(dataPtr, endPtr) {

            } {
                // Advance 3 bytes
                dataPtr := add(dataPtr, 3)
                let input := mload(dataPtr)

                // To write each character, shift the 3 bytes (18 bits) chunk
                // 4 times in blocks of 6 bits for each character (18, 12, 6, 0)
                // and apply logical AND with 0x3F which is the number of
                // the previous character in the ASCII table prior to the Base64 Table
                // The result is then added to the table to get the character to write,
                // and finally write it in the result pointer but with a left shift
                // of 256 (1 byte) - 8 (1 ASCII char) = 248 bits

                mstore8(
                    resultPtr,
                    mload(add(tablePtr, and(shr(18, input), 0x3F)))
                )
                resultPtr := add(resultPtr, 1) // Advance

                mstore8(
                    resultPtr,
                    mload(add(tablePtr, and(shr(12, input), 0x3F)))
                )
                resultPtr := add(resultPtr, 1) // Advance

                mstore8(
                    resultPtr,
                    mload(add(tablePtr, and(shr(6, input), 0x3F)))
                )
                resultPtr := add(resultPtr, 1) // Advance

                mstore8(resultPtr, mload(add(tablePtr, and(input, 0x3F))))
                resultPtr := add(resultPtr, 1) // Advance
            }

            // When data `bytes` is not exactly 3 bytes long
            // it is padded with `=` characters at the end
            switch mod(mload(data), 3)
            case 1 {
                mstore8(sub(resultPtr, 1), 0x3d)
                mstore8(sub(resultPtr, 2), 0x3d)
            }
            case 2 {
                mstore8(sub(resultPtr, 1), 0x3d)
            }
        }

        return result;
    }
}
// File: @openzeppelin/contracts/token/ERC20/extensions/draft-IERC20Permit.sol

// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/draft-IERC20Permit.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
interface IERC20Permit {
    /**
     * @dev Sets `value` as the allowance of `spender` over ``owner``'s tokens,
     * given ``owner``'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `deadline` must be a timestamp in the future.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments.
     * - the signature must use ``owner``'s current nonce (see {nonces}).
     *
     * For more information on the signature format, see the
     * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
     * section].
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @dev Returns the current nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases ``owner``'s nonce by one. This
     * prevents a signature from being used multiple times.
     */
    function nonces(address owner) external view returns (uint256);

    /**
     * @dev Returns the domain separator used in the encoding of the signature for {permit}, as defined by {EIP712}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);
}

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol

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
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );

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
    function allowance(
        address owner,
        address spender
    ) external view returns (uint256);

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

// File: @openzeppelin/contracts/utils/Counters.sol

// OpenZeppelin Contracts v4.4.1 (utils/Counters.sol)

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
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
    function sqrt(
        uint256 a,
        Rounding rounding
    ) internal pure returns (uint256) {
        unchecked {
            uint256 result = sqrt(a);
            return
                result +
                (rounding == Rounding.Up && result * result < a ? 1 : 0);
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
    function log2(
        uint256 value,
        Rounding rounding
    ) internal pure returns (uint256) {
        unchecked {
            uint256 result = log2(value);
            return
                result +
                (rounding == Rounding.Up && 1 << result < value ? 1 : 0);
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
    function log10(
        uint256 value,
        Rounding rounding
    ) internal pure returns (uint256) {
        unchecked {
            uint256 result = log10(value);
            return
                result +
                (rounding == Rounding.Up && 10 ** result < value ? 1 : 0);
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
    function log256(
        uint256 value,
        Rounding rounding
    ) internal pure returns (uint256) {
        unchecked {
            uint256 result = log256(value);
            return
                result +
                (rounding == Rounding.Up && 1 << (result * 8) < value ? 1 : 0);
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
    function toHexString(
        uint256 value,
        uint256 length
    ) internal pure returns (string memory) {
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

// File: @openzeppelin/contracts/access/Ownable.sol

// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

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

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

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
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
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

// File: @openzeppelin/contracts/utils/Address.sol

// OpenZeppelin Contracts (last updated v4.8.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(
            address(this).balance >= amount,
            "Address: insufficient balance"
        );

        (bool success, ) = recipient.call{value: amount}("");
        require(
            success,
            "Address: unable to send value, recipient may have reverted"
        );
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data
    ) internal returns (bytes memory) {
        return
            functionCallWithValue(
                target,
                data,
                0,
                "Address: low-level call failed"
            );
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
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
                "Address: low-level call with value failed"
            );
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(
            address(this).balance >= value,
            "Address: insufficient balance for call"
        );
        (bool success, bytes memory returndata) = target.call{value: value}(
            data
        );
        return
            verifyCallResultFromTarget(
                target,
                success,
                returndata,
                errorMessage
            );
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data
    ) internal view returns (bytes memory) {
        return
            functionStaticCall(
                target,
                data,
                "Address: low-level static call failed"
            );
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        (bool success, bytes memory returndata) = target.staticcall(data);
        return
            verifyCallResultFromTarget(
                target,
                success,
                returndata,
                errorMessage
            );
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data
    ) internal returns (bytes memory) {
        return
            functionDelegateCall(
                target,
                data,
                "Address: low-level delegate call failed"
            );
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return
            verifyCallResultFromTarget(
                target,
                success,
                returndata,
                errorMessage
            );
    }

    /**
     * @dev Tool to verify that a low level call to smart-contract was successful, and revert (either by bubbling
     * the revert reason or using the provided one) in case of unsuccessful call or if target was not a contract.
     *
     * _Available since v4.8._
     */
    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        if (success) {
            if (returndata.length == 0) {
                // only check isContract if the call was successful and the return data is empty
                // otherwise we already know that it was a contract
                require(isContract(target), "Address: call to non-contract");
            }
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    /**
     * @dev Tool to verify that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason or using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    function _revert(
        bytes memory returndata,
        string memory errorMessage
    ) private pure {
        // Look for revert reason and bubble it up if present
        if (returndata.length > 0) {
            // The easiest way to bubble the revert reason is using memory via assembly
            /// @solidity memory-safe-assembly
            assembly {
                let returndata_size := mload(returndata)
                revert(add(32, returndata), returndata_size)
            }
        } else {
            revert(errorMessage);
        }
    }
}

// File: @openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol

// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.transfer.selector, to, value)
        );
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.transferFrom.selector, from, to, value)
        );
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.approve.selector, spender, value)
        );
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(
                token.approve.selector,
                spender,
                newAllowance
            )
        );
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(
                oldAllowance >= value,
                "SafeERC20: decreased allowance below zero"
            );
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(
                token,
                abi.encodeWithSelector(
                    token.approve.selector,
                    spender,
                    newAllowance
                )
            );
        }
    }

    function safePermit(
        IERC20Permit token,
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal {
        uint256 nonceBefore = token.nonces(owner);
        token.permit(owner, spender, value, deadline, v, r, s);
        uint256 nonceAfter = token.nonces(owner);
        require(
            nonceAfter == nonceBefore + 1,
            "SafeERC20: permit did not succeed"
        );
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address-functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(
            data,
            "SafeERC20: low-level call failed"
        );
        if (returndata.length > 0) {
            // Return data is optional
            require(
                abi.decode(returndata, (bool)),
                "SafeERC20: ERC20 operation did not succeed"
            );
        }
    }
}

// File: @openzeppelin/contracts/token/ERC721/IERC721Receiver.sol

// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
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
    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// File: @openzeppelin/contracts/token/ERC721/IERC721.sol

// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(
        address indexed from,
        address indexed to,
        uint256 indexed tokenId
    );

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(
        address indexed owner,
        address indexed approved,
        uint256 indexed tokenId
    );

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(
        address indexed owner,
        address indexed operator,
        bool approved
    );

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external payable;

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external payable;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Note that the caller is responsible to confirm that the recipient is capable of receiving ERC721
     * or else they may be permanently lost. Usage of {safeTransferFrom} prevents loss, though the caller must
     * understand this adds an external call which potentially creates a reentrancy vulnerability.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external payable;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(
        uint256 tokenId
    ) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(
        address owner,
        address operator
    ) external view returns (bool);
}

// File: @openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol

// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Metadata.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Metadata is IERC721 {
    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

// File: @openzeppelin/contracts/token/ERC721/ERC721.sol

// OpenZeppelin Contracts (last updated v4.8.2) (token/ERC721/ERC721.sol)

pragma solidity ^0.8.0;

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension, but not including the Enumerable extension, which is available separately as
 * {ERC721Enumerable}.
 */
contract ERC721 is Context, ERC165, IERC721, IERC721Metadata {
    using Address for address;
    using Strings for uint256;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Mapping from token ID to owner address
    mapping(uint256 => address) private _owners;

    // Mapping owner address to token count
    mapping(address => uint256) private _balances;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(
        address owner
    ) public view virtual override returns (uint256) {
        require(
            owner != address(0),
            "ERC721: address zero is not a valid owner"
        );
        return _balances[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(
        uint256 tokenId
    ) public view virtual override returns (address) {
        address owner = _ownerOf(tokenId);
        require(owner != address(0), "ERC721: invalid token ID");
        return owner;
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(
        uint256 tokenId
    ) public view virtual override returns (string memory) {
        _requireMinted(tokenId);

        string memory baseURI = _baseURI();
        return
            bytes(baseURI).length > 0
                ? string(abi.encodePacked(baseURI, tokenId.toString()))
                : "";
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overridden in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not token owner or approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(
        uint256 tokenId
    ) public view virtual override returns (address) {
        _requireMinted(tokenId);

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(
        address operator,
        bool approved
    ) public virtual override {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(
        address owner,
        address operator
    ) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public payable virtual override {
        //solhint-disable-next-line max-line-length
        require(
            _isApprovedOrOwner(_msgSender(), tokenId),
            "ERC721: caller is not token owner or approved"
        );

        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public payable virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public payable virtual override {
        require(
            _isApprovedOrOwner(_msgSender(), tokenId),
            "ERC721: caller is not token owner or approved"
        );
        _safeTransfer(from, to, tokenId, data);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * `data` is additional data, it has no specified format and it is sent in call to `to`.
     *
     * This internal function is equivalent to {safeTransferFrom}, and can be used to e.g.
     * implement alternative mechanisms to perform token transfer, such as signature-based.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) internal virtual {
        _transfer(from, to, tokenId);
        require(
            _checkOnERC721Received(from, to, tokenId, data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
    }

    /**
     * @dev Returns the owner of the `tokenId`. Does NOT revert if token doesn't exist
     */
    function _ownerOf(uint256 tokenId) internal view virtual returns (address) {
        return _owners[tokenId];
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     * and stop existing when they are burned (`_burn`).
     */
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _ownerOf(tokenId) != address(0);
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedOrOwner(
        address spender,
        uint256 tokenId
    ) internal view virtual returns (bool) {
        address owner = ERC721.ownerOf(tokenId);
        return (spender == owner ||
            isApprovedForAll(owner, spender) ||
            getApproved(tokenId) == spender);
    }

    /**
     * @dev Safely mints `tokenId` and transfers it to `to`.
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }

    /**
     * @dev Same as {xref-ERC721-_safeMint-address-uint256-}[`_safeMint`], with an additional `data` parameter which is
     * forwarded in {IERC721Receiver-onERC721Received} to contract recipients.
     */
    function _safeMint(
        address to,
        uint256 tokenId,
        bytes memory data
    ) internal virtual {
        _mint(to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
    }

    /**
     * @dev Mints `tokenId` and transfers it to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {_safeMint} whenever possible
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - `to` cannot be the zero address.
     *
     * Emits a {Transfer} event.
     */
    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _beforeTokenTransfer(address(0), to, tokenId, 1);

        // Check that tokenId was not minted by `_beforeTokenTransfer` hook
        require(!_exists(tokenId), "ERC721: token already minted");

        unchecked {
            // Will not overflow unless all 2**256 token ids are minted to the same owner.
            // Given that tokens are minted one by one, it is impossible in practice that
            // this ever happens. Might change if we allow batch minting.
            // The ERC fails to describe this case.
            _balances[to] += 1;
        }

        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);

        _afterTokenTransfer(address(0), to, tokenId, 1);
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     * This is an internal function that does not check if the sender is authorized to operate on the token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId) internal virtual {
        address owner = ERC721.ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId, 1);

        // Update ownership in case tokenId was transferred by `_beforeTokenTransfer` hook
        owner = ERC721.ownerOf(tokenId);

        // Clear approvals
        delete _tokenApprovals[tokenId];

        unchecked {
            // Cannot overflow, as that would require more tokens to be burned/transferred
            // out than the owner initially received through minting and transferring in.
            _balances[owner] -= 1;
        }
        delete _owners[tokenId];

        emit Transfer(owner, address(0), tokenId);

        _afterTokenTransfer(owner, address(0), tokenId, 1);
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *  As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     *
     * Emits a {Transfer} event.
     */
    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        require(
            ERC721.ownerOf(tokenId) == from,
            "ERC721: transfer from incorrect owner"
        );
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId, 1);

        // Check that tokenId was not transferred by `_beforeTokenTransfer` hook
        require(
            ERC721.ownerOf(tokenId) == from,
            "ERC721: transfer from incorrect owner"
        );

        // Clear approvals from the previous owner
        delete _tokenApprovals[tokenId];

        unchecked {
            // `_balances[from]` cannot overflow for the same reason as described in `_burn`:
            // `from`'s balance is the number of token held, which is at least one before the current
            // transfer.
            // `_balances[to]` could overflow in the conditions described in `_mint`. That would require
            // all 2**256 token ids to be minted, which in practice is impossible.
            _balances[from] -= 1;
            _balances[to] += 1;
        }
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);

        _afterTokenTransfer(from, to, tokenId, 1);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits an {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721.ownerOf(tokenId), to, tokenId);
    }

    /**
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Emits an {ApprovalForAll} event.
     */
    function _setApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) internal virtual {
        require(owner != operator, "ERC721: approve to caller");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    /**
     * @dev Reverts if the `tokenId` has not been minted yet.
     */
    function _requireMinted(uint256 tokenId) internal view virtual {
        require(_exists(tokenId), "ERC721: invalid token ID");
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) private returns (bool) {
        if (to.isContract()) {
            try
                IERC721Receiver(to).onERC721Received(
                    _msgSender(),
                    from,
                    tokenId,
                    data
                )
            returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert(
                        "ERC721: transfer to non ERC721Receiver implementer"
                    );
                } else {
                    /// @solidity memory-safe-assembly
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting and burning. If {ERC721Consecutive} is
     * used, the hook may be called as part of a consecutive (batch) mint, as indicated by `batchSize` greater than 1.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s tokens will be transferred to `to`.
     * - When `from` is zero, the tokens will be minted for `to`.
     * - When `to` is zero, ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     * - `batchSize` is non-zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 firstTokenId,
        uint256 batchSize
    ) internal virtual {}

    /**
     * @dev Hook that is called after any token transfer. This includes minting and burning. If {ERC721Consecutive} is
     * used, the hook may be called as part of a consecutive (batch) mint, as indicated by `batchSize` greater than 1.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s tokens were transferred to `to`.
     * - When `from` is zero, the tokens were minted for `to`.
     * - When `to` is zero, ``from``'s tokens were burned.
     * - `from` and `to` are never both zero.
     * - `batchSize` is non-zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 firstTokenId,
        uint256 batchSize
    ) internal virtual {}

    /**
     * @dev Unsafe write access to the balances, used by extensions that "mint" tokens using an {ownerOf} override.
     *
     * WARNING: Anyone calling this MUST ensure that the balances remain consistent with the ownership. The invariant
     * being that for any address `a` the value returned by `balanceOf(a)` must be equal to the number of tokens such
     * that `ownerOf(tokenId)` is `a`.
     */
    // solhint-disable-next-line func-name-mixedcase
    function __unsafe_increaseBalance(
        address account,
        uint256 amount
    ) internal {
        _balances[account] += amount;
    }
}

// File: @openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol

// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/extensions/ERC721URIStorage.sol)

pragma solidity ^0.8.0;

/**
 * @dev ERC721 token with storage based token URI management.
 */
abstract contract ERC721URIStorage is ERC721 {
    using Strings for uint256;

    // Optional mapping for token URIs
    mapping(uint256 => string) private _tokenURIs;

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(
        uint256 tokenId
    ) public view virtual override returns (string memory) {
        _requireMinted(tokenId);

        string memory _tokenURI = _tokenURIs[tokenId];
        string memory base = _baseURI();

        // If there is no base URI, return the token URI.
        if (bytes(base).length == 0) {
            return _tokenURI;
        }
        // If both are set, concatenate the baseURI and tokenURI (via abi.encodePacked).
        if (bytes(_tokenURI).length > 0) {
            return string(abi.encodePacked(base, _tokenURI));
        }

        return super.tokenURI(tokenId);
    }

    /**
     * @dev Sets `_tokenURI` as the tokenURI of `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _setTokenURI(
        uint256 tokenId,
        string memory _tokenURI
    ) internal virtual {
        require(
            _exists(tokenId),
            "ERC721URIStorage: URI set of nonexistent token"
        );
        _tokenURIs[tokenId] = _tokenURI;
    }

    /**
     * @dev See {ERC721-_burn}. This override additionally checks to see if a
     * token-specific URI was set for the token, and if so, it deletes the token URI from
     * the storage mapping.
     */
    function _burn(uint256 tokenId) internal virtual override {
        super._burn(tokenId);

        if (bytes(_tokenURIs[tokenId]).length != 0) {
            delete _tokenURIs[tokenId];
        }
    }
}

// File: contracts/giankynft.sol

pragma solidity ^0.8.0;

// Add the interfaces for Uniswap-like router and pair contracts
interface IPancakeSwapRouter {
    function getAmountsOut(
        uint256 amountIn,
        address[] memory path
    ) external view returns (uint256[] memory amounts);

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);
}

interface IPancakeSwapFactory {
    function getPair(
        address tokenA,
        address tokenB
    ) external view returns (address pair);
}

interface IWETH {
    function deposit() external payable;

    function withdraw(uint256 wad) external;
}

contract Gianky is ERC721, ERC721URIStorage {
    using Counters for Counters.Counter;
    using SafeERC20 for IERC20;
    using Strings for uint256;
    using Base64 for bytes;

    mapping(uint256 => Counters.Counter) private _typeTokenIds;

    uint256 private constant STARTER = 0;
    uint256 private constant BASIC = 1;
    uint256 private constant STANDARD = 2;
    uint256 private constant VIP = 3;
    uint256 private constant PREMIUM = 4;
    uint256 private constant DIAMOND = 5;

    uint256 private STARTER_r = 400 * 10 ** 18;
    uint256 private BASIC_r = 1000 * 10 ** 18;
    uint256 private STANDARD_r = 2000 * 10 ** 18;
    uint256 private VIP_r = 10000 * 10 ** 18;
    uint256 private PREMIUM_r = 20000 * 10 ** 18;
    uint256 private DIAMOND_r = 100000 * 10 ** 18;

    uint256 private constant STARTER_MIN_ID = 1;
    uint256 private constant STARTER_MAX_ID = 1000000;
    uint256 private constant BASIC_MIN_ID = 1000001;
    uint256 private constant BASIC_MAX_ID = 2000000;
    uint256 private constant STANDARD_MIN_ID = 2000001;
    uint256 private constant STANDARD_MAX_ID = 3000000;
    uint256 private constant VIP_MIN_ID = 3000001;
    uint256 private constant VIP_MAX_ID = 4000000;
    uint256 private constant PREMIUM_MIN_ID = 4000001;
    uint256 private constant PREMIUM_MAX_ID = 5000000;
    uint256 private constant DIAMOND_MIN_ID = 5000001;
    uint256 private constant DIAMOND_MAX_ID = 6000000;

    // Add the token prices in MATIC
    uint256 private STARTER_PRICE = 0.01 ether; // 0.01 MATIC on POLYGON
    uint256 private BASIC_PRICE = 50 ether; // 0.02 MATIC on POLYGON
    uint256 private STANDARD_PRICE = 100 ether; // 0.03 MATIC on POLYGON
    uint256 private VIP_PRICE = 500 ether; // 0.04 MATIC on POLYGON
    uint256 private PREMIUM_PRICE = 1000 ether; // 0.05 MATIC on POLYGON
    uint256 private DIAMOND_PRICE = 5000 ether; // 0.06 MATIC on POLYGON

    // Mapping of token ID to the number of referrals
    mapping(uint256 => uint256) public referralCounts;
    // Mapping of token ID to the number of referrals
    mapping(uint256 => uint256) public referralCountsstarter;
    mapping(uint256 => uint256) public referralCountsbasic;
    mapping(uint256 => uint256) public referralCountsstandard;
    mapping(uint256 => uint256) public referralCountsvip;
    mapping(uint256 => uint256) public referralCountspremium;
    mapping(uint256 => uint256) public referralCountsdiamond;

    mapping(address => mapping(uint256 => uint256))
        public addressToReferralCountsStarter;
    mapping(address => mapping(uint256 => uint256))
        public addressToReferralCountsBasic;
    mapping(address => mapping(uint256 => uint256))
        public addressToReferralCountsStandard;
    mapping(address => mapping(uint256 => uint256))
        public addressToReferralCountsVip;
    mapping(address => mapping(uint256 => uint256))
        public addressToReferralCountsPremium;
    mapping(address => mapping(uint256 => uint256))
        public addressToReferralCountsDiamond;

    // Add the Gianky token reward rate
    uint256 public GIANKY_REWARD_RATE = 500; // 0.005 dollars per Gianky token

    mapping(uint256 => string) private _tokenURIs;
    IPancakeSwapRouter public pancakeSwapRouter;
    IPancakeSwapFactory public pancakeSwapFactory;
    IERC20 public giankyToken;
    // Add the address for Gianky tokens

    address public whitelistAddress_alpha;
    address private constant WBNB_ADDRESS =
        0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c;
    IERC20 public wbnbToken;

    // URI for each token type
    string private constant STARTER_URI =
        "https://ipfs.io/ipfs/QmencsyehufWVHzK9MjnRGtHbszfo8XtrLsteQaymEaxBx/0";
    string private constant BASIC_URI =
        "https://ipfs.io/ipfs/QmXKJC2VBJ4YP5DT4fiQN5yxok5iWsGp7MMQVBMkkHuz88/1";
    string private constant STANDARD_URI =
        "https://ipfs.io/ipfs/QmPheP1CxiqGaQBWKgiiF1Yr6GaZHi44HqFqkfwNRKZemr/2";
    string private constant VIP_URI =
        "https://ipfs.io/ipfs/Qme5k6PeNwzn4zByrBKUve24zuqNLP8kCYzaA4xGgCWMMN/3";
    string private constant PREMIUM_URI =
        "https://ipfs.io/ipfs/QmTiB4GxqAusoBLueTSyUuvWFpATSsy1YaiUdK2gZz6aB3/4";
    string private constant DIAMOND_URI =
        "https://ipfs.io/ipfs/QmdiiNiS8brkqieCjRtY8neht69WkNFneQbXLMBJzNZpnZ/5";

    // NFT structure
    struct NFT {
        uint256 id;
        address owner;
        uint256 referralId;
    }

    // Payment splitter contract
    address payable public splitter;

    address payable public owner;

    modifier onlyOwner() {
        require(
            msg.sender == owner,
            "Only contract owner can call this function"
        );
        _;
    }

    // Referral percentages
    uint256[] public referralPercentages = [0, 1250, 800, 400, 200];
    mapping(uint256 => uint256) public nftRewards;

    // Mapping of NFT IDs to their corresponding referral IDs
    mapping(uint256 => uint256) public nftReferrals;
    uint256 private _totalSupply;
    // Events
    event NFTMinted(
        uint256 indexed id,
        address indexed owner,
        uint256 referralId
    );

    function incrementReferralCountStarter(uint256 _nftId) private {
        addressToReferralCountsStarter[msg.sender][_nftId]++;
    }

    function incrementReferralCountBasic(uint256 _nftId) private {
        addressToReferralCountsBasic[msg.sender][_nftId]++;
    }

    function incrementReferralCountStandard(uint256 _nftId) private {
        addressToReferralCountsStandard[msg.sender][_nftId]++;
    }

    function incrementReferralCountVip(uint256 _nftId) private {
        addressToReferralCountsVip[msg.sender][_nftId]++;
    }

    function incrementReferralCountPremium(uint256 _nftId) private {
        addressToReferralCountsPremium[msg.sender][_nftId]++;
    }

    function incrementReferralCountDiamond(uint256 _nftId) private {
        addressToReferralCountsDiamond[msg.sender][_nftId]++;
    }

    constructor(
        IERC20 _giankyToken,
        address payable _splitter
    ) ERC721("GIANKY NFT", "GK") {
        giankyToken = _giankyToken;
        whitelistAddress_alpha = 0x1Fad82e1bA7ABFFebBBbf02ee5a7a35eF79b7BFa;
        splitter = _splitter;
        owner = payable(msg.sender);
    }

    // Update the referral count for the referrer
    function _updateReferralCount(uint256 _referrerId) private {
        referralCounts[_referrerId] += 1;
    }

    function _updateReferralCountstarter(uint256 _referrerId) private {
        referralCountsstarter[_referrerId] += 1;
    }

    function _updateReferralCountbasic(uint256 _referrerId) private {
        referralCountsbasic[_referrerId] += 1;
    }

    function _updateReferralCountstandard(uint256 _referrerId) private {
        referralCountsstandard[_referrerId] += 1;
    }

    function _updateReferralpremium(uint256 _referrerId) private {
        referralCountspremium[_referrerId] += 1;
    }

    function _updateReferralvip(uint256 _referrerId) private {
        referralCountsvip[_referrerId] += 1;
    }

    function _updateReferraldiamond(uint256 _referrerId) private {
        referralCountsdiamond[_referrerId] += 1;
    }

    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    function getTokenURI(uint256 tokenId) public view returns (string memory) {
        if (tokenId >= STARTER_MIN_ID && tokenId <= STARTER_MAX_ID) {
            bytes memory dataURI = abi.encodePacked(
                "{",
                '"name": "STARTER COMMUNITY #"',
                tokenId.toString(),
                '",',
                '"description": "Resides At The Lowest Level. Starter NFT Holders Receives Royalties And Rewards Only For Starter NFT Referrals"",',
                '"image": "ipfs://QmdvJi9c4dEw8Wbk7EUGPwCvE4mUk6wvbFkE33z5ka4Mkd/0.gif"',
                "}"
            );

            return
                string(
                    abi.encodePacked(
                        "data:application/json;base64,",
                        Base64.encode(bytes(dataURI))
                    )
                );
        }

        if (tokenId >= BASIC_MIN_ID && tokenId <= BASIC_MAX_ID) {
            bytes memory dataURI = abi.encodePacked(
                "{",
                '"name": "BASIC COMMUNITY #"',
                tokenId.toString(),
                ",",
                '"description": "Resides At The Fifth Top Most Level. Basic NFT Holders Receives Royalties And Rewards For Basic And Starter NFT Referrals",',
                '"attributes": [',
                "{",
                '"trait_type": "RANK",',
                '"value": "',
                referralCountsbasic[tokenId].toString(),
                '"',
                "}",
                "],",
                '"image": "ipfs://QmTYsVzQ5VUvE3uuV9yb3nyWsZHG3W2gTR96dvs833wEL8/1.gif"',
                "}"
            );

            return
                string(
                    abi.encodePacked(
                        "data:application/json;base64,",
                        Base64.encode(dataURI)
                    )
                );
        }

        if (tokenId >= STANDARD_MIN_ID && tokenId <= STANDARD_MAX_ID) {
            bytes memory dataURI = abi.encodePacked(
                "{",
                '"name": "STANDARD COMMUNITY #"',
                tokenId.toString(),
                ",",
                '"description": "Resides At The Fourth Top Most Level. Standard NFT Holders Receives Royalties And Rewards For Standard, Basic And Starter NFT Referrals",',
                '"attributes": [',
                "{",
                '"trait_type": "RANK",',
                '"value": "',
                referralCountsstandard[tokenId].toString(),
                '"',
                "}",
                "],",
                '"image": "ipfs://QmZLGgHKNk8YCNNkGNGWcAK4NbkijKVSYE9QXRaDcWCtCN/2.gif"',
                "}"
            );

            return
                string(
                    abi.encodePacked(
                        "data:application/json;base64,",
                        Base64.encode(dataURI)
                    )
                );
        }

        if (tokenId >= VIP_MIN_ID && tokenId <= VIP_MAX_ID) {
            bytes memory dataURI = abi.encodePacked(
                "{",
                '"name": "VIP COMMUNITY #"',
                tokenId.toString(),
                ",",
                '"description": "Resides At The Third Top Most Level. Vip NFT Holders Receives Royalties And Rewards For Vip, Standard, Basic And Starter NFT Referrals",',
                '"attributes": [',
                "{",
                '"trait_type": "RANK",',
                '"value": "',
                referralCountsvip[tokenId].toString(),
                '"',
                "}",
                "],",
                '"image":"ipfs://QmXtFunGzF6nBPamryijgJCqSNsnZ9Dnh6QCdfzvfq83Ai/3.gif"',
                "}"
            );

            return
                string(
                    abi.encodePacked(
                        "data:application/json;base64,",
                        Base64.encode(dataURI)
                    )
                );
        }

        if (tokenId >= PREMIUM_MIN_ID && tokenId <= PREMIUM_MAX_ID) {
            bytes memory dataURI = abi.encodePacked(
                "{",
                '"name": "PREMIUM COMMUNITY #"',
                tokenId.toString(),
                ",",
                '"description": "Resides At The Second Top Most Level. Premium NFT Holders Receives Royalties And Rewards For Premium, Vip, Standard, Basic And Starter NFT Referrals",',
                '"attributes": [',
                "{",
                '"trait_type": "RANK",',
                '"value": "',
                referralCountspremium[tokenId].toString(),
                '"',
                "}",
                "],",
                '"image": "ipfs://QmVXTRmcDgKDjVABiFUpqcomLGTGiCyY2TJLfWC5SwpckH/4.gif"',
                "}"
            );

            return
                string(
                    abi.encodePacked(
                        "data:application/json;base64,",
                        Base64.encode(dataURI)
                    )
                );
        }

        if (tokenId >= DIAMOND_MIN_ID && tokenId <= DIAMOND_MAX_ID) {
            bytes memory dataURI = abi.encodePacked(
                "{",
                '"name": "DIAMOND COMMUNITY #"',
                tokenId.toString(),
                ",",
                '"description": "Reside At The  Top Most Level. Diamond NFT Holders Receives Royalties And Reward For All Kind Of NFT Referrals",',
                '"attributes": [',
                "{",
                '"trait_type": "RANK",',
                '"value": "',
                referralCountsdiamond[tokenId].toString(),
                '"',
                "}",
                "],",
                '"image": "ipfs://Qmd2NBN8AyQjj49t2eKCb5V5jscwBwbGzx5n6c1wG3GpQQ/5.gif"',
                "}"
            );

            return
                string(
                    abi.encodePacked(
                        "data:application/json;base64,",
                        Base64.encode(dataURI)
                    )
                );
        }

        //Explicit return statement with a default value
        return "";
    }

    function mintStarter(uint256 _referralId) public payable returns (uint256) {
        require(msg.value >= STARTER_PRICE, "Insufficient MATIC Sent");
        require(
            _referralId >= STARTER_MIN_ID && _referralId <= DIAMOND_MAX_ID,
            "ENTER LOW LEVEL REFERRAL ID"
        );
        address _to = msg.sender;
        uint256 newTokenId = _typeTokenIds[STARTER].current() + STARTER_MIN_ID;
        uint256 _id = newTokenId;
        require(
            newTokenId <= STARTER_MAX_ID,
            "All starter tokens have been minted"
        );
        _safeMint(msg.sender, newTokenId);
        _setTokenURI(newTokenId, string(abi.encodePacked(STARTER_URI)));
        //_setTokenURI(newTokenId, getTokenURI(newTokenId));
        _typeTokenIds[STARTER].increment();

        giankyToken.safeTransfer(msg.sender, STARTER_r);
        nftReferrals[_id] = _referralId;

        // Emit the NFTMinted event
        emit NFTMinted(_id, _to, _referralId);
        distributeRewards(_id);
        // Update the referral count for the referrer if a referral ID was provided
        if (_referralId != 0) {
            _updateReferralCount(_referralId);
        }
        if (_referralId != 0) {
            _updateReferralCountstarter(_referralId);
            incrementReferralCountStarter(newTokenId);
        }
        return newTokenId;
    }

    function mintBasic(uint256 _referralId) public payable returns (uint256) {
        address _to = msg.sender;
        require(
            _referralId >= BASIC_MIN_ID && _referralId <= DIAMOND_MAX_ID,
            "ENTER LOW LEVEL REFERRAL ID"
        );
        require(msg.value >= BASIC_PRICE, "Insufficient MATIC Sent");
        uint256 newTokenId = _typeTokenIds[BASIC].current() + BASIC_MIN_ID;
        uint256 _id = newTokenId;
        require(
            newTokenId <= BASIC_MAX_ID,
            "All basic tokens have been minted"
        );
        _safeMint(msg.sender, newTokenId);
        _setTokenURI(newTokenId, string(abi.encodePacked(BASIC_URI)));
        //_setTokenURI(newTokenId, getTokenURI(newTokenId));
        _typeTokenIds[BASIC].increment();
        //_sendReward(msg.value);
        giankyToken.safeTransfer(msg.sender, BASIC_r);
        // Set the NFT referral ID
        nftReferrals[_id] = _referralId;

        // Emit the NFTMinted event
        emit NFTMinted(_id, _to, _referralId);
        distributeRewards(_id);
        // Update the referral count for the referrer if a referral ID was provided
        if (_referralId != 0) {
            _updateReferralCount(_referralId);
        }

        if (_referralId != 0) {
            _updateReferralCountbasic(_referralId);
            incrementReferralCountBasic(newTokenId);
        }

        return newTokenId;
    }

    function mintStandard(
        uint256 _referralId
    ) public payable returns (uint256) {
        address _to = msg.sender;
        require(
            _referralId >= STANDARD_MIN_ID && _referralId <= DIAMOND_MAX_ID,
            "ENTER LOW LEVEL REFERRAL ID"
        );
        require(msg.value >= STANDARD_PRICE, "Insufficient MATIC Sent");
        uint256 newTokenId = _typeTokenIds[STANDARD].current() +
            STANDARD_MIN_ID;
        uint256 _id = newTokenId;
        require(
            newTokenId <= STANDARD_MAX_ID,
            "All standard tokens have been minted"
        );
        _safeMint(msg.sender, newTokenId);
        _setTokenURI(newTokenId, string(abi.encodePacked(STANDARD_URI)));
        //_setTokenURI(newTokenId, getTokenURI(newTokenId));
        _typeTokenIds[STANDARD].increment();
        // Set the NFT referral ID
        nftReferrals[_id] = _referralId;

        // Emit the NFTMinted event
        emit NFTMinted(_id, _to, _referralId);
        distributeRewards(_id);
        //_sendReward(msg.value);
        giankyToken.safeTransfer(msg.sender, STANDARD_r);
        // Update the referral count for the referrer if a referral ID was provided
        if (_referralId != 0) {
            _updateReferralCount(_referralId);
        }
        if (_referralId != 0) {
            _updateReferralCountstandard(_referralId);
            incrementReferralCountStandard(newTokenId);
        }
        return newTokenId;
    }

    function mintVIP(uint256 _referralId) public payable returns (uint256) {
        address _to = msg.sender;
        require(
            _referralId >= VIP_MIN_ID && _referralId <= DIAMOND_MAX_ID,
            "ENTER LOW LEVEL REFERRAL ID"
        );
        require(msg.value >= VIP_PRICE, "Insufficient MATIC Sent");
        uint256 newTokenId = _typeTokenIds[VIP].current() + VIP_MIN_ID;
        require(newTokenId <= VIP_MAX_ID, "All VIP tokens have been minted");
        uint256 _id = newTokenId;
        _safeMint(msg.sender, newTokenId);
        _setTokenURI(newTokenId, string(abi.encodePacked(VIP_URI)));
        //_setTokenURI(newTokenId, getTokenURI(newTokenId));
        _typeTokenIds[VIP].increment();
        //_sendReward(msg.value);
        giankyToken.safeTransfer(msg.sender, VIP_r);
        // Set the NFT referral ID
        nftReferrals[_id] = _referralId;

        // Emit the NFTMinted event
        emit NFTMinted(_id, _to, _referralId);
        distributeRewards(_id);
        // Update the referral count for the referrer if a referral ID was provided
        if (_referralId != 0) {
            _updateReferralCount(_referralId);
        }
        if (_referralId != 0) {
            _updateReferralvip(_referralId);
            incrementReferralCountVip(newTokenId);
        }
        return newTokenId;
    }

    function mintPremium(uint256 _referralId) public payable returns (uint256) {
        address _to = msg.sender;
        require(msg.value >= PREMIUM_PRICE, "Insufficient MATIC Sent");
        require(
            _referralId >= PREMIUM_MIN_ID && _referralId <= DIAMOND_MAX_ID,
            "ENTER LOW LEVEL REFERRAL ID"
        );
        uint256 newTokenId = _typeTokenIds[PREMIUM].current() + PREMIUM_MIN_ID;
        require(
            newTokenId <= PREMIUM_MAX_ID,
            "All premium tokens have been minted"
        );
        uint256 _id = newTokenId;
        _safeMint(msg.sender, newTokenId);
        _setTokenURI(newTokenId, string(abi.encodePacked(PREMIUM_URI)));
        //_setTokenURI(newTokenId, getTokenURI(newTokenId));
        _typeTokenIds[PREMIUM].increment();
        //_sendReward(msg.value);
        giankyToken.safeTransfer(msg.sender, PREMIUM_r);
        // Set the NFT referral ID
        nftReferrals[_id] = _referralId;

        // Emit the NFTMinted event
        emit NFTMinted(_id, _to, _referralId);
        distributeRewards(_id);
        // Update the referral count for the referrer if a referral ID was provided
        if (_referralId != 0) {
            _updateReferralCount(_referralId);
        }
        if (_referralId != 0) {
            _updateReferralpremium(_referralId);
            incrementReferralCountPremium(newTokenId);
        }
        return newTokenId;
    }

    function mintDiamond(uint256 _referralId) public payable returns (uint256) {
        address _to = msg.sender;
        require(
            _referralId >= DIAMOND_MIN_ID && _referralId <= DIAMOND_MAX_ID,
            "ENTER LOW LEVEL REFERRAL ID"
        );
        require(msg.value >= DIAMOND_PRICE, "Insufficient MATIC Sent");
        uint256 newTokenId = _typeTokenIds[DIAMOND].current() + DIAMOND_MIN_ID;
        require(
            newTokenId <= DIAMOND_MAX_ID,
            "All diamond tokens have been minted"
        );
        uint256 _id = newTokenId;
        _safeMint(msg.sender, newTokenId);
        _setTokenURI(newTokenId, string(abi.encodePacked(DIAMOND_URI)));
        //_setTokenURI(newTokenId, getTokenURI(newTokenId));
        _typeTokenIds[DIAMOND].increment();
        //_sendReward(msg.value);
        giankyToken.safeTransfer(msg.sender, DIAMOND_r);
        // Set the NFT referral ID
        nftReferrals[_id] = _referralId;

        // Emit the NFTMinted event
        emit NFTMinted(_id, _to, _referralId);
        distributeRewards(_id);
        // Update the referral count for the referrer if a referral ID was provided
        if (_referralId != 0) {
            _updateReferralCount(_referralId);
        }
        if (_referralId != 0) {
            _updateReferralvip(_referralId);
            incrementReferralCountDiamond(newTokenId);
        }
        return newTokenId;
    }

    function _burn(
        uint256 tokenId
    ) internal virtual override(ERC721, ERC721URIStorage) {
        ERC721URIStorage._burn(tokenId);
    }

    function tokenURI(
        uint256 tokenId
    )
        public
        view
        virtual
        override(ERC721, ERC721URIStorage)
        returns (string memory)
    {
        return ERC721URIStorage.tokenURI(tokenId);
    }

    function setSTARTER_r(uint256 newValue) public onlyOwner {
        STARTER_r = newValue;
    }

    function setBASIC_r(uint256 newValue) public onlyOwner {
        BASIC_r = newValue;
    }

    function setSTANDARD_r(uint256 newValue) public onlyOwner {
        STANDARD_r = newValue;
    }

    function setVIP_r(uint256 newValue) public onlyOwner {
        VIP_r = newValue;
    }

    function setPREMIUM_r(uint256 newValue) public onlyOwner {
        PREMIUM_r = newValue;
    }

    function setDIAMOND_r(uint256 newValue) public onlyOwner {
        DIAMOND_r = newValue;
    }

    function mintToalpha(uint256 tokenType, address to, uint256 amount) public {
        require(
            tokenType >= STARTER && tokenType <= DIAMOND,
            "Invalid token type"
        );
        require(msg.sender == whitelistAddress_alpha);

        for (uint256 i = 0; i < amount; i++) {
            uint256 newTokenId = _typeTokenIds[tokenType].current();
            uint256 minId;
            uint256 maxId;

            if (tokenType == STARTER) {
                minId = STARTER_MIN_ID;
                maxId = STARTER_MAX_ID;
            } else if (tokenType == BASIC) {
                minId = BASIC_MIN_ID;
                maxId = BASIC_MAX_ID;
            } else if (tokenType == STANDARD) {
                minId = STANDARD_MIN_ID;
                maxId = STANDARD_MAX_ID;
            } else if (tokenType == VIP) {
                minId = VIP_MIN_ID;
                maxId = VIP_MAX_ID;
            } else if (tokenType == PREMIUM) {
                minId = PREMIUM_MIN_ID;
                maxId = PREMIUM_MAX_ID;
            } else if (tokenType == DIAMOND) {
                minId = DIAMOND_MIN_ID;
                maxId = DIAMOND_MAX_ID;
            }

            newTokenId += minId;
            require(
                newTokenId <= maxId,
                "All tokens of this type have been minted"
            );

            _safeMint(to, newTokenId);

            // Set the token URI based on the token type
            if (tokenType == STARTER) {
                _setTokenURI(newTokenId, string(abi.encodePacked(STARTER_URI)));
            } else if (tokenType == BASIC) {
                _setTokenURI(newTokenId, string(abi.encodePacked(BASIC_URI)));
            } else if (tokenType == STANDARD) {
                _setTokenURI(
                    newTokenId,
                    string(abi.encodePacked(STANDARD_URI))
                );
            } else if (tokenType == VIP) {
                _setTokenURI(newTokenId, string(abi.encodePacked(VIP_URI)));
            } else if (tokenType == PREMIUM) {
                _setTokenURI(newTokenId, string(abi.encodePacked(PREMIUM_URI)));
            } else if (tokenType == DIAMOND) {
                _setTokenURI(newTokenId, string(abi.encodePacked(DIAMOND_URI)));
            }

            _typeTokenIds[tokenType].increment();
        }
    }

    function mintStarter_without_id() public payable returns (uint256) {
        require(msg.value >= STARTER_PRICE, "Insufficient MATIC Sent");
        uint256 newTokenId = _typeTokenIds[STARTER].current() + STARTER_MIN_ID;
        require(
            newTokenId <= STARTER_MAX_ID,
            "All starter tokens have been minted"
        );
        _safeMint(msg.sender, newTokenId);
        _setTokenURI(newTokenId, string(abi.encodePacked(STARTER_URI)));
        //_setTokenURI(newTokenId, getTokenURI(newTokenId));
        _typeTokenIds[STARTER].increment();

        giankyToken.safeTransfer(msg.sender, STARTER_r);
        uint256 amountToSend = (msg.value * 9) / 10; // Calculate 90% of msg.value
        splitter.transfer(amountToSend); // Send the amount to the simple address
        incrementReferralCountStarter(newTokenId);

        return newTokenId;
    }

    function mintBasic_without_id() public payable returns (uint256) {
        require(msg.value >= BASIC_PRICE, "Insufficient MATIC Sent");
        uint256 newTokenId = _typeTokenIds[BASIC].current() + BASIC_MIN_ID;
        require(
            newTokenId <= BASIC_MAX_ID,
            "All basic tokens have been minted"
        );
        _safeMint(msg.sender, newTokenId);
        _setTokenURI(newTokenId, string(abi.encodePacked(BASIC_URI)));
        //_setTokenURI(newTokenId, getTokenURI(newTokenId));
        _typeTokenIds[BASIC].increment();

        giankyToken.safeTransfer(msg.sender, BASIC_r);
        uint256 amountToSend = (msg.value * 9) / 10; // Calculate 90% of msg.value
        splitter.transfer(amountToSend); // Send the amount to the simple address
        incrementReferralCountBasic(newTokenId);

        return newTokenId;
    }

    function mintStandard_without_id() public payable returns (uint256) {
        require(msg.value >= STANDARD_PRICE, "Insufficient MATIC Sent");
        uint256 newTokenId = _typeTokenIds[STANDARD].current() +
            STANDARD_MIN_ID;
        require(
            newTokenId <= STANDARD_MAX_ID,
            "All standard tokens have been minted"
        );
        _safeMint(msg.sender, newTokenId);
        _setTokenURI(newTokenId, string(abi.encodePacked(STANDARD_URI)));
        //_setTokenURI(newTokenId, getTokenURI(newTokenId));
        _typeTokenIds[STANDARD].increment();

        // //uint256 tenPercent = msg.value.mul(10).div(100);
        // uint256 reward = _calculateReward(msg.value);
        // //uint256 reward = msg.value;
        // reward = reward * 10000;
        // // Give the reward in the form of Gianky tokens without using the liquidity pool
        // uint256 giankyAmount = reward / GIANKY_REWARD_RATE;
        giankyToken.safeTransfer(msg.sender, STANDARD_r);
        //_sendReward(msg.value);
        incrementReferralCountStandard(newTokenId);
        //address payable simpleAddress = payable(0x6125B54D8735f7e4Ca35C41805f9Bb67B2B9a71C); // Replace with the actual address
        uint256 amountToSend = (msg.value * 9) / 10; // Calculate 90% of msg.value
        splitter.transfer(amountToSend); // Send the amount to the simple address

        return newTokenId;
    }

    function mintVIP_without_id() public payable returns (uint256) {
        require(msg.value >= VIP_PRICE, "Insufficient MATIC Sent");
        uint256 newTokenId = _typeTokenIds[VIP].current() + VIP_MIN_ID;
        require(newTokenId <= VIP_MAX_ID, "All VIP tokens have been minted");
        _safeMint(msg.sender, newTokenId);
        _setTokenURI(newTokenId, string(abi.encodePacked(VIP_URI)));
        //_setTokenURI(newTokenId, getTokenURI(newTokenId));
        _typeTokenIds[VIP].increment();
        // //uint256 tenPercent = msg.value.mul(10).div(100);
        // uint256 reward = _calculateReward(msg.value);
        // //uint256 reward = msg.value;
        // reward = reward * 10000;
        // // Give the reward in the form of Gianky tokens without using the liquidity pool
        // uint256 giankyAmount = reward / GIANKY_REWARD_RATE;
        giankyToken.safeTransfer(msg.sender, VIP_r);
        //_sendReward(msg.value);

        //address payable simpleAddress = payable(0x6125B54D8735f7e4Ca35C41805f9Bb67B2B9a71C); // Replace with the actual address
        uint256 amountToSend = (msg.value * 9) / 10; // Calculate 90% of msg.value
        splitter.transfer(amountToSend); // Send the amount to the simple address
        incrementReferralCountVip(newTokenId);

        return newTokenId;
    }

    function mintPremium_without_id() public payable returns (uint256) {
        require(msg.value >= PREMIUM_PRICE, "Insufficient MATIC Sent");
        uint256 newTokenId = _typeTokenIds[PREMIUM].current() + PREMIUM_MIN_ID;
        require(
            newTokenId <= PREMIUM_MAX_ID,
            "All premium tokens have been minted"
        );
        _safeMint(msg.sender, newTokenId);
        _setTokenURI(newTokenId, string(abi.encodePacked(PREMIUM_URI)));
        //_setTokenURI(newTokenId, getTokenURI(newTokenId));
        _typeTokenIds[PREMIUM].increment();

        // //uint256 tenPercent = msg.value.mul(10).div(100);
        // uint256 reward = _calculateReward(msg.value);
        // //uint256 reward = msg.value;
        // reward = reward * 10000;
        // // Give the reward in the form of Gianky tokens without using the liquidity pool
        // uint256 giankyAmount = reward / GIANKY_REWARD_RATE;
        giankyToken.safeTransfer(msg.sender, PREMIUM_r);
        //_sendReward(msg.value);

        //address payable simpleAddress = payable(0x6125B54D8735f7e4Ca35C41805f9Bb67B2B9a71C); // Replace with the actual address
        uint256 amountToSend = (msg.value * 9) / 10; // Calculate 90% of msg.value
        splitter.transfer(amountToSend); // Send the amount to the simple address
        incrementReferralCountPremium(newTokenId);

        return newTokenId;
    }

    function mintDiamond_without_id() public payable returns (uint256) {
        require(msg.value >= DIAMOND_PRICE, "Insufficient MATIC Sent");
        uint256 newTokenId = _typeTokenIds[DIAMOND].current() + DIAMOND_MIN_ID;
        require(
            newTokenId <= DIAMOND_MAX_ID,
            "All diamond tokens have been minted"
        );
        _safeMint(msg.sender, newTokenId);
        _setTokenURI(newTokenId, string(abi.encodePacked(DIAMOND_URI)));
        //_setTokenURI(newTokenId, getTokenURI(newTokenId));
        _typeTokenIds[DIAMOND].increment();
        // //uint256 tenPercent = msg.value.mul(10).div(100);
        // uint256 reward = _calculateReward(msg.value);
        // //uint256 reward = msg.value;
        // reward = reward * 10000;
        // // Give the reward in the form of Gianky tokens without using the liquidity pool
        //uint256 giankyAmount = reward / GIANKY_REWARD_RATE;
        giankyToken.safeTransfer(msg.sender, DIAMOND_r);
        //_sendReward(msg.value);

        //address payable simpleAddress = payable(0x6125B54D8735f7e4Ca35C41805f9Bb67B2B9a71C); // Replace with the actual address
        uint256 amountToSend = (msg.value * 9) / 10; // Calculate 90% of msg.value
        splitter.transfer(amountToSend); // Send the amount to the simple address
        incrementReferralCountDiamond(newTokenId);

        return newTokenId;
    }

    function transferFrom(
        address _from,
        address _to,
        uint256 _tokenId
    ) public payable override {
        super.transferFrom(_from, _to, _tokenId);
        if (msg.value > 0) {
            address payable uown = payable(_from);
            distributeRewardsroY(_tokenId, uown);
        }
    }

    function safeTransferFrom(
        address _from,
        address _to,
        uint256 _tokenId
    ) public payable override {
        super.transferFrom(_from, _to, _tokenId);
        if (msg.value > 0) {
            address payable uown = payable(_from);
            distributeRewardsroY(_tokenId, uown);
        }
    }

    // Distribute rewards based on the referral system
    function distributeRewards(uint256 _id) public payable {
        // Get the NFT
        NFT memory nft = NFT(_id, ownerOf(_id), nftReferrals[_id]);

        // Calculate the referral percentages
        uint256[5] memory referralAmounts;
        uint256 referralId = nft.referralId;
        for (uint256 i = 1; i <= 4; i++) {
            if (referralId == 0) {
                referralAmounts[i] = 0;
            } else {
                referralAmounts[i] =
                    (msg.value * referralPercentages[i]) /
                    10000;
                payable(ownerOf(referralId)).transfer(referralAmounts[i]);
                referralId = nftReferrals[referralId];
            }
        }

        // Transfer the remaining balance to the payment splitter
        uint256 remainingBalance = msg.value -
            referralAmounts[1] -
            referralAmounts[2] -
            referralAmounts[3] -
            referralAmounts[4];
        remainingBalance = (remainingBalance * 90) / 100;
        splitter.transfer(remainingBalance);
    }

    function distributeRewardsroY(
        uint256 _id,
        address payable _to
    ) public payable {
        // Get the NFT
        NFT memory nft = NFT(_id, ownerOf(_id), nftReferrals[_id]);

        // Calculate the referral percentages
        uint256[5] memory referralAmounts;
        uint256 referralId = nft.referralId;
        for (uint256 i = 1; i <= 4; i++) {
            if (referralId == 0) {
                referralAmounts[i] = 0;
            } else {
                referralAmounts[i] =
                    (((msg.value * 5) / 100) * referralPercentages[i]) /
                    10000;
                payable(ownerOf(referralId)).transfer(referralAmounts[i]);
                referralId = nftReferrals[referralId];
            }
        }

        // Transfer the remaining balance to the payment splitter
        uint256 remainingBalance = ((msg.value * 5) / 100) -
            referralAmounts[1] -
            referralAmounts[2] -
            referralAmounts[3] -
            referralAmounts[4];
        //remainingBalance = (remainingBalance * 90) / 100;
        //address payable uown = payable(msg.sender);
        splitter.transfer(remainingBalance);
        _to.transfer((msg.value * 90) / 100);
        //_to.transfer(remainingBalance);
    }

    function getGiankyRewardRate() public view returns (uint256) {
        return GIANKY_REWARD_RATE;
    }

    function setGiankyRewardRate(uint256 newRate) public onlyOwner {
        GIANKY_REWARD_RATE = newRate;
    }

    function withdrawBNB(address payable recipient) public onlyOwner {
        require(
            msg.sender == owner,
            "Only contract owner can call this function"
        );
        recipient.transfer(address(this).balance);
    }

    function setPrice(uint256 level, uint256 price) public onlyOwner {
        if (level == 1) {
            STARTER_PRICE = price;
        } else if (level == 2) {
            BASIC_PRICE = price;
        } else if (level == 3) {
            STANDARD_PRICE = price;
        } else if (level == 4) {
            VIP_PRICE = price;
        } else if (level == 5) {
            PREMIUM_PRICE = price;
        } else if (level == 6) {
            DIAMOND_PRICE = price;
        } else {
            revert("Invalid level provided");
        }
    }

    function setOwner(address payable _owner) public onlyOwner {
        owner = _owner;
    }

    function withdrawTokens(uint256 amount) public onlyOwner {
        require(giankyToken.transfer(owner, amount), "Token transfer failed");
    }
}