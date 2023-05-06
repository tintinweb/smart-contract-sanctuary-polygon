// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AggregatorV3Interface {
  function decimals() external view returns (uint8);

  function description() external view returns (string memory);

  function version() external view returns (uint256);

  function getRoundData(uint80 _roundId)
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );
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
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
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
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
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
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
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
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
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
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
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

pragma solidity ^0.8.8;

import { IERC165 } from './IERC165.sol';
import { IERC1155Internal } from './IERC1155Internal.sol';

/**
 * @title ERC1155 interface
 * @dev see https://github.com/ethereum/EIPs/issues/1155
 */
interface IERC1155 is IERC1155Internal, IERC165 {
    /**
     * @notice query the balance of given token held by given address
     * @param account address to query
     * @param id token to query
     * @return token balance
     */
    function balanceOf(
        address account,
        uint256 id
    ) external view returns (uint256);

    /**
     * @notice query the balances of given tokens held by given addresses
     * @param accounts addresss to query
     * @param ids tokens to query
     * @return token balances
     */
    function balanceOfBatch(
        address[] calldata accounts,
        uint256[] calldata ids
    ) external view returns (uint256[] memory);

    /**
     * @notice query approval status of given operator with respect to given address
     * @param account address to query for approval granted
     * @param operator address to query for approval received
     * @return whether operator is approved to spend tokens held by account
     */
    function isApprovedForAll(
        address account,
        address operator
    ) external view returns (bool);

    /**
     * @notice grant approval to or revoke approval from given operator to spend held tokens
     * @param operator address whose approval status to update
     * @param status whether operator should be considered approved
     */
    function setApprovalForAll(address operator, bool status) external;

    /**
     * @notice transfer tokens between given addresses, checking for ERC1155Receiver implementation if applicable
     * @param from sender of tokens
     * @param to receiver of tokens
     * @param id token ID
     * @param amount quantity of tokens to transfer
     * @param data data payload
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

    /**
     * @notice transfer batch of tokens between given addresses, checking for ERC1155Receiver implementation if applicable
     * @param from sender of tokens
     * @param to receiver of tokens
     * @param ids list of token IDs
     * @param amounts list of quantities of tokens to transfer
     * @param data data payload
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

/**
 * @title Partial ERC1155 interface needed by internal functions
 */
interface IERC1155Internal {
    event TransferSingle(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256 id,
        uint256 value
    );

    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

    event ApprovalForAll(
        address indexed account,
        address indexed operator,
        bool approved
    );
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import { IERC165Internal } from './IERC165Internal.sol';

/**
 * @title ERC165 interface registration interface
 * @dev see https://eips.ethereum.org/EIPS/eip-165
 */
interface IERC165 is IERC165Internal {
    /**
     * @notice query whether contract has registered support for given interface
     * @param interfaceId interface id
     * @return bool whether interface is supported
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import { IERC165Internal } from './IERC165Internal.sol';

/**
 * @title ERC165 interface registration interface
 */
interface IERC165Internal {

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import { IERC1155MetadataInternal } from './IERC1155MetadataInternal.sol';

/**
 * @title ERC1155Metadata interface
 */
interface IERC1155Metadata is IERC1155MetadataInternal {
    /**
     * @notice get generated URI for given token
     * @return token URI
     */
    function uri(uint256 tokenId) external view returns (string memory);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

/**
 * @title Partial ERC1155Metadata interface needed by internal functions
 */
interface IERC1155MetadataInternal {
    event URI(string value, uint256 indexed tokenId);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IMarketStorage.sol";

interface IMarketRoleManager is IMarketStorage {
    event RoleAuthEvent(address indexed account, uint8 roleId, bool enable);

    function hasRole(address account, uint8 roleId) external view returns (bool);

    function triggerRole(address account, uint8 roleId, bool enable, bool single) external;

    function findRoleSingleAccount(uint8 roleId) external view returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IMarketStorage {

    function authorizeToContract(address parentContract, bool authed) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ITxnHubSimpleNFT.sol";
import "./IMarketStorage.sol";

interface IMintableMarket is IMarketStorage {
    struct GoodsInfo {
        uint32 price;
        bool onSale;
        ITxnHubSimpleNFT nftContract;
    }

    event GoodsOnSaleEvent(uint128 indexed goodsId, bool onSale);

    event MintGoodsEvent(uint128 indexed goodsId,
        address nftContract,
        address mintTo,
        uint128 amount,
        uint128 usdPrice,
        uint256 paidFee,
        uint256 rate
    );

    struct NftBurnRecord {
        address contractAddress;
        address owner;
        uint128 tokenId;
    }

    event NftBurnEvent(uint256 indexed burnId, uint256 quantity, string email);

    function addGoods(uint128 goodsId, address nftContract, uint32 price) external;

    function goodsInfo(uint128 goodsId_) external view returns (GoodsInfo memory goods);

    function goodsOnSale(uint128 goodsId_, bool onSale_) external;

    function mintNft(address operator, uint128 goodsId_, uint128 amount, address to, uint256 paid, uint256 rate) external;

    function burnRecord(uint256 burnId_) external view returns (NftBurnRecord memory);

    function burn(address operator, address contractAddress, uint128 tokenId, uint256 quantity, string calldata email) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IMarketStorage.sol";

interface INftSaleMarket is IMarketStorage {
    struct SellList {
        bool onSale;
        uint64 price;
    }

    event SaleChangeEvent (
        address indexed seller,
        address indexed nftContract,
        uint128 indexed tokenId,
        bool onSale
    );

    function querySaleStatus(address seller_, address nftContractAddr_, uint128 tokenId_) external view returns (
        uint128 balance,
        uint64 price
    );

    function onSale(address operator_,
        address nftContract_,
        uint128 tokenId_,
        uint64 price_
    ) external;

    function cancelSale(address operator_, address nftContractAddr_, uint128 tokenId_) external;


}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@solidstate/contracts/interfaces/IERC1155.sol";
import "@solidstate/contracts/token/ERC1155/metadata/IERC1155Metadata.sol";

interface ITxnHubNftBase is IERC1155, IERC1155Metadata{
    event AuthorizedToContract(address contractAddress);
    event AgentMint(address operator,
        address sender,
        address indexed to,
        uint256 id,
        uint256 amount
    );
    event AgentMintBatch(address operator,
        address sender,
        address indexed to,
        uint256[] id,
        uint256[] amount
    );
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Strings.sol";
import "./ITxnHubNftBase.sol";

interface ITxnHubSimpleNFT is ITxnHubNftBase {

    function agentMintId(address operator, address to, uint256 id, uint256 amount, bytes memory data) external;

    function agentMintIdBatch(address operator, address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data) external;

    function agentBurn(address from, uint256 id, uint256 amount) external;

    function isTxnHubSimpleContract() external pure returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../../interfaces/IMarketRoleManager.sol";
import "../../support/UpgradableOwnableV1.sol";

/**
 * @dev Role Definition:
 * - ROOT, config sensitive contract.
 * - OPERATOR=1, able to manage goods, contract args
 * - OBSERVER=2, web2 backend process
 * - ASSET=3, single account, account for withdraw
 */
abstract contract TxnMarketPermissionSupportV1 is UpgradableOwnableV1 {
    IMarketRoleManager private _roleManager;


    function updateRoleManager(address contractAddr) public onlyOwner {
        _roleManager = IMarketRoleManager(contractAddr);
    }

    function _checkOperator() internal view virtual {
        require(owner() == _msgSender() || _isRole(_msgSender(), 1) || _isRole(_msgSender(), 3), "Operation: caller is neither owner nor operator");
    }

    function _isRole(address account, uint8 role) internal view virtual returns (bool) {
        return _roleManager.hasRole(account, role);
    }

    function isOperator(address account) external view returns (bool) {
        return _isRole(account, 1);
    }

    function isObserver(address account) external view returns (bool) {
        return _isRole(account, 2);
    }

    function currentAsset() public view returns (address) {
        return _roleManager.findRoleSingleAccount(3);
    }

    function _checkObserver() internal view virtual {
        require(owner() == _msgSender() || _isRole(_msgSender(), 1) || _isRole(_msgSender(), 2), "Operation: caller is neither owner nor operator nor observer");
    }

    function configOperator(address account, bool enable) external onlyOwner {
        _roleManager.triggerRole(account, 1, enable, false);
    }

    function configObserver(address account, bool enable) external onlyOwner {
        _roleManager.triggerRole(account, 2, enable, false);
    }

    function configAssetAccount(address account) external onlyOwner {
        _roleManager.triggerRole(account, 3, true, true);
    }

    modifier onlyOperator() {
        _checkOperator();
        _;
    }

    modifier onlyObserver(){
        _checkObserver();
        _;
    }

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@solidstate/contracts/interfaces/IERC1155.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "../../interfaces/ITxnHubSimpleNFT.sol";
import "../../interfaces/IMintableMarket.sol";
import "../../interfaces/IMarketRoleManager.sol";
import "../../interfaces/INftSaleMarket.sol";
import "../v1/TxnMarketPermissionSupportV1.sol";
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';

contract TxnSimpleMarketV4 is TxnMarketPermissionSupportV1 {


    //start exchange rate

    AggregatorV3Interface internal priceFeed;//USD/USDT 到 数字货币的汇率源
    bool internal priceInverse;//汇率是否需要反向，true: usd_price/rate; false: usd_price * rate
    uint8 private _chainBalanceDigits;
    //add market floating rate - 2023-02-13
    //汇率浮动
    uint16 private floatingRate_;

    function updateFloatingRate(uint16 newFloatingRate) external onlyOperator {
        floatingRate_ = newFloatingRate;
    }

    function currentFloatingRate() external view onlyOperator returns (uint16){
        return floatingRate_;
    }

    function _modifyChainBalanceDigits(uint8 digits) internal {
        _chainBalanceDigits = digits;
    }

    function modifyChainBalanceDigits(uint8 digits) external onlyOwner {
        _modifyChainBalanceDigits(digits);
    }

    function _chainDigits() internal virtual view returns (uint8){
        return _chainBalanceDigits;
    }

    function _updatePriceFeed(address priceFeedAddr, bool inverseFlag) internal virtual {
        priceFeed = AggregatorV3Interface(priceFeedAddr);
        priceInverse = inverseFlag;
    }

    function updatePriceFeed(address priceFeedAddr, bool inverseFlag) external onlyOwner {
        _updatePriceFeed(priceFeedAddr, inverseFlag);
    }

    function currentExchangeRate() public view returns (uint256 rate, uint8 decimals) {
        (uint256 _floatRate, uint8 decimal, ,) = currentExchangeRateOfRound(uint80(0));
        return (_floatRate, decimal);
    }

    function currentExchangeRateOfRound(uint80 roundId_) public view returns (uint256 rate, uint8 decimals, uint80 roundId, uint256 startAt) {
        uint8 decimal = priceFeed.decimals();
        (uint80 resRoundId,int256 price,uint256 startAt_, ,) = roundId_ > 0 ? priceFeed.getRoundData(roundId_) : priceFeed.latestRoundData();
        uint256 _rate = uint256(price);
        if (priceInverse) {
            _rate = (10 ** (decimal * 2)) / _rate;
        }
        uint256 _floatedRate = _divRound(_rate * (10000 + floatingRate_), 10000);
        return (_floatedRate, decimal, resRoundId, startAt_);
    }
    //end exchange rate

    //storage contracts

    IMintableMarket private _mintableMarket;
    INftSaleMarket private _nftSaleMarket;

    function updateMintableMarket(address contractAddr) external onlyOwner {
        _mintableMarket = IMintableMarket(contractAddr);
    }

    function updateNftSaleMarket(address contractAddr) external onlyOwner {
        _nftSaleMarket = INftSaleMarket(contractAddr);
    }

    function addGoods(uint128 goodsId, address nftContract, uint32 price) external onlyOperator {
        _mintableMarket.addGoods(goodsId, nftContract, price);
    }

    function batchAddGoods(address nftContract, uint128[] calldata goodsIds, uint32[] calldata prices) external onlyOperator {
        uint goodsCount = goodsIds.length;
        require(goodsCount == prices.length, "Market: id and price count not match");
        for (uint i = 0; i < goodsCount; i++) {
            _mintableMarket.addGoods(goodsIds[i], nftContract, prices[i]);
        }
    }

    function goodsInfo(uint128 goodsId_) external onlyOperator view returns (IMintableMarket.GoodsInfo memory goods) {
        return _mintableMarket.goodsInfo(goodsId_);
    }

    function setOnSale(uint128 goodsId_, bool onSale_) external onlyOperator {
        _mintableMarket.goodsOnSale(goodsId_, onSale_);
    }

    function _calculateChainPrice(uint128 goodsId_, uint128 amount, uint16 stableId, uint80 roundId_) internal view returns (uint256 total, uint256 rate, uint80 roundId){
        IMintableMarket.GoodsInfo memory goods = _mintableMarket.goodsInfo(goodsId_);
        uint128 goodsPrice = goods.price;
        (uint _rate, uint decimals, uint80 rateRoundId, uint256 startAt) = currentStableExchangeRate(stableId, roundId_);
        uint256 curTime = block.timestamp;
        require(startAt + _rateTimeOffsetSeconds > curTime, "Exchange rate expired");
        uint8 digits = stableId != uint16(0) ? stablePriceDecimals[stableId] : _chainDigits();
        uint256 chainPrice = _divRound(goodsPrice * _rate * (10 ** digits), (10 ** (decimals + 2)));
        uint256 totalPrice = chainPrice * amount;
        return (totalPrice, _rate, rateRoundId);
    }

    function mintPriceEstimate(uint128 goodsId_, uint128 amount) external view returns (uint256 total, uint80 roundId) {
        (uint256 totalFee, ,uint80 rateRoundId) = _calculateChainPrice(goodsId_, amount, uint16(0), uint80(0));
        return (totalFee, rateRoundId);
    }

    function mintPriceStableEstimate(uint128 goodsId_, uint128 amount, uint16 stableId) external view returns (uint256 total, uint80 roundId) {
        (uint256 totalFee, ,uint80 rateRoundId) = _calculateChainPrice(goodsId_, amount, stableId, uint80(0));
        return (totalFee, rateRoundId);
    }

    function ownerMint(uint128 goodsId_, uint128 amount, address to) external onlyOperator {
        (uint256 rate,) = currentExchangeRate();
        _mintableMarket.mintNft(_msgSender(), goodsId_, amount, to, 0, rate);
    }

    function customerMint(uint128 goodsId_, uint128 amount) external payable {
        (uint256 totalPrice, uint256 rate,) = _calculateChainPrice(goodsId_, amount, uint16(0), uint80(0));
        require(msg.value >= totalPrice, "Market: price not match");
        _mintableMarket.mintNft(_msgSender(), goodsId_, amount, _msgSender(), msg.value, rate);
    }

    function customerMintInRound(uint128 goodsId_, uint128 amount, uint80 roundId_) external payable {
        (uint256 totalPrice, uint256 rate,) = _calculateChainPrice(goodsId_, amount, uint16(0), roundId_);
        require(msg.value >= totalPrice, "Market: price not match");
        _mintableMarket.mintNft(_msgSender(), goodsId_, amount, _msgSender(), msg.value, rate);
    }

    function customerMintStable(uint128 goodsId_, uint128 amount, uint16 stableId) external {
        require(stableId > 0, 'Currency not determined');
        address erc20ContractAddr = stableContracts[stableId];
        require(erc20ContractAddr != address(0), 'Not configured currency');
        IERC20 erc20Contract = IERC20(erc20ContractAddr);

        (uint256 totalPrice, uint256 rate,) = _calculateChainPrice(goodsId_, amount, stableId, uint80(0));

        uint256 allowance_amt = erc20Contract.allowance(_msgSender(), address(this));
        require(allowance_amt >= totalPrice, "Allowance balance insufficient");

        address asset = currentAsset();
        bool success = erc20Contract.transferFrom(_msgSender(), asset, totalPrice);
        require(success, "ERC20 Deduction failed");

        uint256 evtPrice = uint256(stableId) << 240;
        evtPrice = evtPrice | totalPrice;
        _mintableMarket.mintNft(_msgSender(), goodsId_, amount, _msgSender(), evtPrice, rate);
    }

    function customerMintStableInRound(uint128 goodsId_, uint128 amount, uint16 stableId, uint80 roundId_) external {
        require(stableId > 0, 'Currency not determined');
        address erc20ContractAddr = stableContracts[stableId];
        require(erc20ContractAddr != address(0), 'Not configured currency');
        IERC20 erc20Contract = IERC20(erc20ContractAddr);

        (uint256 totalPrice, uint256 rate,) = _calculateChainPrice(goodsId_, amount, stableId, roundId_);

        uint256 allowance_amt = erc20Contract.allowance(_msgSender(), address(this));
        require(allowance_amt >= totalPrice, "Allowance balance insufficient");

        address asset = currentAsset();
        bool success = erc20Contract.transferFrom(_msgSender(), asset, totalPrice);
        require(success, "ERC20 Deduction failed");

        uint256 evtPrice = uint256(stableId) << 240;
        evtPrice = evtPrice | totalPrice;
        _mintableMarket.mintNft(_msgSender(), goodsId_, amount, _msgSender(), evtPrice, rate);
    }

    //end mintable goods

    //start burn

    function burnRecord(uint256 burnId_) external onlyOperator view returns (IMintableMarket.NftBurnRecord memory){
        return _mintableMarket.burnRecord(burnId_);
    }

    function burn(address contractAddress, uint128 tokenId, string calldata email) external {
        _mintableMarket.burn(_msgSender(), contractAddress, tokenId, 1, email);
    }
    //end burn
    //start nft market
    event TradeEvent(
        address indexed _nftContract,
        address indexed _seller,
        address _buyer,
        uint128 indexed _tokenId,
        uint32 _amount,
        uint256 _totalPrice,
        uint256 _rate);

    function querySaleStatus(address seller_, address nftContractAddr_, uint128 tokenId_) external view returns (
        uint128 balance,
        uint64 price
    ){
        return _nftSaleMarket.querySaleStatus(seller_, nftContractAddr_, tokenId_);
    }

    function onSale(address nftContract_,
        uint128 tokenId_,
        uint64 price_
    ) external {
        _nftSaleMarket.onSale(_msgSender(), nftContract_, tokenId_, price_);
    }

    function cancelSale(address nftContractAddr_, uint128 tokenId_) external {
        _nftSaleMarket.cancelSale(_msgSender(), nftContractAddr_, tokenId_);
    }

    function _buyTokenEstimate(address seller_, address nftContractAddr_, uint128 tokenId_, uint32 amount_, uint16 stableId_, uint80 roundId_) internal view returns (uint256 total, uint256 rate, uint80 roundId) {
        (, uint64 price) = _nftSaleMarket.querySaleStatus(seller_, nftContractAddr_, tokenId_);
        (uint256 rate_,uint8 decimals, uint80 rateRoundId, uint256 startAt) = currentStableExchangeRate(stableId_, roundId_);
        uint256 curTime = block.timestamp;
        require(startAt + _rateTimeOffsetSeconds > curTime, "Rate expired");
        uint8 digits = stableId_ != uint16(0) ? stablePriceDecimals[stableId_] : _chainDigits();
        uint256 singlePrice = _divRound(price * rate_ * (10 ** digits), 10 ** (decimals + 2));
        uint256 totalPrice = singlePrice * amount_;
        return (totalPrice, rate_, rateRoundId);
    }

    function buyTokenEstimate(address seller_, address nftContractAddr_, uint128 tokenId_, uint32 amount_) public view returns (uint256 total, uint80 roundId) {
        (uint256 totalPrice,,uint80 rateRoundId) = _buyTokenEstimate(seller_, nftContractAddr_, tokenId_, amount_, uint16(0), uint80(0));
        return (totalPrice, rateRoundId);
    }

    function buyTokenWithStableEstimate(address seller_, address nftContractAddr_, uint128 tokenId_, uint32 amount_, uint16 stableId_) public view returns (uint256 total, uint80 roundId) {
        (uint256 totalPrice,,uint80 rateRoundId) = _buyTokenEstimate(seller_, nftContractAddr_, tokenId_, amount_, stableId_, uint80(0));
        return (totalPrice, rateRoundId);
    }

    /**
      @param seller_ This is the seller address
      @param nftContractAddr_ This is nft contract address
      @param tokenId_ This is nft token id
      @param amount_ This is buy amount of selling tokens
    **/
    function buyToken(address payable seller_, address nftContractAddr_, uint128 tokenId_, uint32 amount_) external payable {
        (uint256 totalPrice, uint256 rate,) = _buyTokenEstimate(seller_, nftContractAddr_, tokenId_, amount_, uint16(0), uint80(0));
        require(_msgSender() != seller_, "Market: You are selling to yourself");
        require(amount_ > 0, "Market: Must buy at least 1");
        require(msg.value >= totalPrice, "Market: Paid amount needs to be greater or equals total price.");

        IERC1155(nftContractAddr_).safeTransferFrom(seller_,
            _msgSender(),
            tokenId_,
            amount_,
            "0x0");

        emit TradeEvent(nftContractAddr_,
            seller_,
            _msgSender(),
            tokenId_,
            amount_,
            msg.value,
            rate);

        bool sent = seller_.send(msg.value);
        require(sent, "Market: send value failed");

    }

    /**
      @param seller_ This is the seller address
      @param nftContractAddr_ This is nft contract address
      @param tokenId_ This is nft token id
      @param amount_ This is buy amount of selling tokens
      @param roundId_ Rate round id to use history rate to prevent insufficient funds
    **/
    function buyTokenInRound(address payable seller_, address nftContractAddr_, uint128 tokenId_, uint32 amount_, uint80 roundId_) external payable {
        (uint256 totalPrice, uint256 rate,) = _buyTokenEstimate(seller_, nftContractAddr_, tokenId_, amount_, uint16(0), roundId_);
        require(_msgSender() != seller_, "Market: You are selling to yourself");
        require(amount_ > 0, "Market: Must buy at least 1");
        require(msg.value >= totalPrice, "Market: Paid amount needs to be greater or equals total price.");

        IERC1155(nftContractAddr_).safeTransferFrom(seller_,
            _msgSender(),
            tokenId_,
            amount_,
            "0x0");

        emit TradeEvent(nftContractAddr_,
            seller_,
            _msgSender(),
            tokenId_,
            amount_,
            msg.value,
            rate);

        bool sent = seller_.send(msg.value);
        require(sent, "Market: send value failed");

    }

    function buyTokenStable(address payable seller_, address nftContractAddr_, uint128 tokenId_, uint32 amount_, uint16 stableId_) external {
        require(stableId_ > 0, "Currency not detected");
        address erc20Addr = stableContracts[stableId_];
        require(erc20Addr != address(0), "Currency not configured");

        (uint256 totalPrice, uint256 rate,) = _buyTokenEstimate(seller_, nftContractAddr_, tokenId_, amount_, stableId_, uint80(0));
        require(_msgSender() != seller_, "Market: You are selling to yourself");
        require(amount_ > 0, "Market: Must buy at least 1");
        IERC20 erc20Contract = IERC20(erc20Addr);
        uint256 allowance_amt = erc20Contract.allowance(_msgSender(), address(this));
        require(allowance_amt >= totalPrice, "Market: Allowance insufficient");

        IERC1155(nftContractAddr_).safeTransferFrom(seller_,
            _msgSender(),
            tokenId_,
            amount_,
            "0x0");

        bool sent = erc20Contract.transferFrom(_msgSender(), seller_, totalPrice);
        require(sent, "Market: transfer erc20 failed");

        uint256 evtAmount = uint256(stableId_) << 240;
        evtAmount = evtAmount | totalPrice;

        emit TradeEvent(nftContractAddr_,
            seller_,
            _msgSender(),
            tokenId_,
            amount_,
            evtAmount,
            rate);

    }

    function buyTokenStableInRound(address payable seller_, address nftContractAddr_, uint128 tokenId_, uint32 amount_, uint16 stableId_, uint80 roundId_) external {
        require(stableId_ > 0, "Currency not detected");
        address erc20Addr = stableContracts[stableId_];
        require(erc20Addr != address(0), "Currency not configured");

        (uint256 totalPrice, uint256 rate,) = _buyTokenEstimate(seller_, nftContractAddr_, tokenId_, amount_, stableId_, roundId_);
        require(_msgSender() != seller_, "Market: You are selling to yourself");
        require(amount_ > 0, "Market: Must buy at least 1");
        IERC20 erc20Contract = IERC20(erc20Addr);
        uint256 allowance_amt = erc20Contract.allowance(_msgSender(), address(this));
        require(allowance_amt >= totalPrice, "Market: Allowance insufficient");

        IERC1155(nftContractAddr_).safeTransferFrom(seller_,
            _msgSender(),
            tokenId_,
            amount_,
            "0x0");

        bool sent = erc20Contract.transferFrom(_msgSender(), seller_, totalPrice);
        require(sent, "Market: transfer erc20 failed");

        uint256 evtAmount = uint256(stableId_) << 240;
        evtAmount = evtAmount | totalPrice;

        emit TradeEvent(nftContractAddr_,
            seller_,
            _msgSender(),
            tokenId_,
            amount_,
            evtAmount,
            rate);

    }

    function contractBalance() public view onlyOperator returns (uint256 balance) {
        return address(this).balance;
    }

    function withdrawAll() external onlyOperator {
        uint256 balance = contractBalance();
        require(balance > 0, "not enough balance");
        address assetAccount = currentAsset();
        require(assetAccount != address(0), "invalid asset account");
        bool sent = payable(assetAccount).send(balance);
        require(sent, "Withdraw: withdraw failed");
    }

    //2023-04-17 add usdt and other stable currency support
    mapping(uint16 => address) internal stableContracts;
    mapping(uint16 => address) internal stablePriceFeeds;
    mapping(uint16 => bool) internal stablePriceInverses;
    mapping(uint16 => uint8) internal stablePriceDecimals;

    event StableCurrencyToggle(uint16 indexed stableId,
        bool indexed activeFlag,
        bool priceFeedInverse,
        address indexed erc20Contract,
        address priceFeed);

    function _configStableCurrency(uint16 stableId, uint8 decimals, address priceFeedAddr, bool inverseFlag, address contractAddr) internal virtual {
        require(contractAddr != address(0), "Already configured stableId");
        AggregatorV3Interface stablePriceFeed = AggregatorV3Interface(priceFeedAddr);
        uint8 decimal = stablePriceFeed.decimals();
        require(decimal > 0, "Price Feed addr not valid");
        IERC20 erc20Contract = IERC20(contractAddr);
        uint256 supply = erc20Contract.totalSupply();
        require(supply > 0, "Invalid erc20 contract");
        stableContracts[stableId] = contractAddr;
        stablePriceFeeds[stableId] = priceFeedAddr;
        stablePriceInverses[stableId] = inverseFlag;
        stablePriceDecimals[stableId] = decimals;
        emit StableCurrencyToggle(stableId, true, inverseFlag, contractAddr, priceFeedAddr);
    }

    function configStableCurrency(uint16 stableId, uint8 decimals, address priceFeedAddr, bool inverseFlag, address contractAddr) external onlyOperator {
        _configStableCurrency(stableId, decimals, priceFeedAddr, inverseFlag, contractAddr);
    }

    function disableStableCurrency(uint16 stableId) external onlyOperator {
        address contractAddr = stableContracts[stableId];
        require(contractAddr != address(0), "Already disabled");
        address priceFeedAddr = stablePriceFeeds[stableId];
        bool priceFeedInverse = stablePriceInverses[stableId];
        stableContracts[stableId] = address(0);
        emit StableCurrencyToggle(stableId, false, priceFeedInverse, contractAddr, priceFeedAddr);
    }

    function stableCurrencyInfo(uint16 stableId) external view returns (address erc20Contract, address priceFeedContract, bool inverse) {
        return (stableContracts[stableId], stablePriceFeeds[stableId], stablePriceInverses[stableId]);
    }

    function currentStableExchangeRate(uint16 stableId, uint80 roundId_) public view returns (uint256 rate, uint8 decimals, uint80 roundId, uint256 startAt) {
        if (stableId == uint16(0)) {
            return currentExchangeRateOfRound(roundId_);
        }
        address feedAddr = stablePriceFeeds[stableId];
        require(feedAddr != address(0), 'Not configured stable currency price feed');
        AggregatorV3Interface feed = AggregatorV3Interface(feedAddr);
        uint8 decimal = feed.decimals();
        (uint80 resRoundId, int256 price, uint256 startAt_, ,) = roundId_ > 0 ? feed.getRoundData(roundId_) : feed.latestRoundData();
        uint256 _rate = uint256(price);
        if (stablePriceInverses[stableId]) {
            _rate = (10 ** (decimal * 2)) / _rate;
        }
        uint256 _floatedRate = _divRound(_rate * (10000 + floatingRate_), 10000);
        return (_floatedRate, decimal, resRoundId, startAt_);
    }

    //2023-04-22 rate valid time
    uint8 internal _rateTimeOffset;
    uint16 internal _rateTimeOffsetSeconds;

    function currentRateTimeOffset() external view returns (uint16) {
        return _rateTimeOffsetSeconds;
    }

    function configRateTimeOffset(uint16 second_count) external onlyOperator {
        _rateTimeOffsetSeconds = second_count;
    }

    //init
    function initialize(address roleManagerContract, address mintableMarketContract, address nftSaleMarketContract,
        address priceFeedAddress, bool priceInverse_, uint8 chainDigits_, uint8 rateTimeOffset_) external initializer {
        _transferOwnership(_msgSender());
        _updatePriceFeed(priceFeedAddress, priceInverse_);
        _modifyChainBalanceDigits(chainDigits_);
        updateRoleManager(roleManagerContract);
        _mintableMarket = IMintableMarket(mintableMarketContract);
        _nftSaleMarket = INftSaleMarket(nftSaleMarketContract);
        _rateTimeOffsetSeconds = rateTimeOffset_;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '@openzeppelin/contracts/utils/Context.sol';
import "./UpgradeBase.sol";

abstract contract UpgradableOwnableV1 is Context, UpgradeBase {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

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
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

abstract contract UpgradeBase {
    using SafeMath for uint256;
    /**
 * @dev Indicates that the contract has been initialized.
     * @custom:oz-retyped-from bool
     */
    uint8 private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Triggered when the contract has been initialized or reinitialized.
     */
    event Initialized(uint8 version);

    modifier initializer() {
        bool isTopLevelCall = !_initializing;
        require(
            (isTopLevelCall && _initialized < 1),
            "Initializable: contract is already initialized"
        );
        _initialized = 1;
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(1);
        }
    }

    /**
 * @dev A modifier that defines a protected reinitializer function that can be invoked at most once, and only if the
     * contract hasn't been initialized to a greater version before. In its scope, `onlyInitializing` functions can be
     * used to initialize parent contracts.
     *
     * A reinitializer may be used after the original initialization step. This is essential to configure modules that
     * are added through upgrades and that require initialization.
     *
     * When `version` is 1, this modifier is similar to `initializer`, except that functions marked with `reinitializer`
     * cannot be nested. If one is invoked in the context of another, execution will revert.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
     *
     * WARNING: setting the version to 255 will prevent any future reinitialization.
     *
     * Emits an {Initialized} event.
     */
    modifier reinitializer(uint8 version) {
        require(!_initializing && _initialized < version, "Initializable: contract is already initialized");
        _initialized = version;
        _initializing = true;
        _;
        _initializing = false;
        emit Initialized(version);
    }

    //common function
    function _divRound(uint x, uint y) pure internal returns (uint)  {
        return (x + (y / 2)) / y;
    }

    function currentContractVersion() view external returns (uint8) {
        return _initialized;
    }
}