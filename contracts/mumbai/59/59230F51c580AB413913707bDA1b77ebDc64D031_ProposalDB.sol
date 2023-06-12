/**
 *Submitted for verification at polygonscan.com on 2023-06-11
*/

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

// File: @openzeppelin/contracts/security/ReentrancyGuard.sol


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

// File: @openzeppelin/contracts/security/Pausable.sol


// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

pragma solidity ^0.8.0;


/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        _requireNotPaused();
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        _requirePaused();
        _;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Throws if the contract is paused.
     */
    function _requireNotPaused() internal view virtual {
        require(!paused(), "Pausable: paused");
    }

    /**
     * @dev Throws if the contract is not paused.
     */
    function _requirePaused() internal view virtual {
        require(paused(), "Pausable: not paused");
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
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

// File: contracts/ProposalDB.sol



pragma solidity >=0.8.0 ;











//import "@openzeppelin/contracts/access/Roles.sol";

//ReentrancyGuard
/// @title Proposal_Database
contract ProposalDB is   Ownable  , AccessControl , Pausable{

    
    using SafeMath for uint; // 
    using Counters for Counters.Counter;


    bytes32 public constant Admin = keccak256("Admin");
    bytes32 public constant Contracts = keccak256("Contracts");
    bytes32 public constant Contributer = keccak256("Contributer");


    Counters.Counter private proposalIDs;


    event CreateProposal ( address applicant , Proposal p , uint256 time , string description  );
    event UpdateProposal ( address applicant , Proposal p , uint256 time , string description  );
    event AbortProposal ( address applicant , Proposal p , uint256 time , string description  );
    event ProposalProfit ( Proposal p , returnProfit r , uint256 time , string description  ) ;


    
    struct returnProfit
    {
        uint256 deadline ; 
        uint256 amount ; 
        uint256 paymentDate ; 
        bool enabled ; 
        bool paid ; 
        uint256 id ; 
        bool penalty ; 
        uint256 penaltyAmount ; 
        bool exist ; 
        uint256 received ; 
        
    }

    struct Proposal
    {
        uint256 id ; 
        string fullName ; 
        string bussinessName ; 
        string logo ; 
        string webURL ; 
        string title ; 
        string whitePaper ; 
        string bussinessPlan ; 
        bool debtBased ; 
        address applicant; // the applicant who wishes to become a member - this key will be used for withdrawals
        address token; // the tribute token reference for subscription or alternative contribution
        uint256 fundsRequested; // the funds requested for applicant 
        string details; // proposal details - could be IPFS hash, plaintext, or JSON
        uint256 startingPeriod; // the period in which voting can start for this proposal
        uint256 endingPeriod; // the period in which voting can start for this proposal
        uint256 score ; 
        bool premium ; 
        uint256 duration ;
        uint256 profit ; //percent
        uint256 slice ; 
        uint256 fundsAllocatedAfterTax; // the funds requested for applicant 
        uint256 submitDate ; 
        uint256 lockL2StartDate ;
        uint256 lockL2EndDate ; 
        uint256 lockL3StartDate ;
        uint256 lockL3EndDate ; 
        

        uint256 paidAmount ;
        uint256 returnedAmount ; 
        uint256 DAOAmount ;
        bool DAOInvested ;
        bool enabled ;
        uint256 Locked ;  // 0 unlock , 1 locked , 2 fundlocked , 3 dao lock
        bool processed; // true only if the proposal has been processed
        bool didPass; // true only if the proposal passed
        bool aborted; // true only if applicant calls "abort" before end of voting period
        bool paid ;  // true only if the proposal is funded
        bool fundReturned ;  // true only if the proposal is funded
        bool exist ; 

        //returnProfit[]  returnOfInvestment ; 
        
        
    }




    mapping ( uint256 => Proposal ) private Props;
    mapping ( address => uint256[] ) private AddressProps;
    mapping ( uint256 => mapping( uint256 => returnProfit)) private ProposalProfitReturn ; 

    uint256[] private premiumProposals ; 



    constructor(   )  
    {

        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        
        _setRoleAdmin(Admin, DEFAULT_ADMIN_ROLE);
        _setRoleAdmin(Contracts, DEFAULT_ADMIN_ROLE);
        _setRoleAdmin(Contributer, DEFAULT_ADMIN_ROLE);


        //token = IERC20(token_contract) ;
        proposalIDs.increment();
    }




    /// @dev Restricted to members of the user role.
    modifier onlyAdmin()
    {
        require(isAdmin(msg.sender) || isRootAdmin(msg.sender) , "Restricted to Admins");
        _;
    }

    modifier onlyRootAdmin()
    {
        require( isRootAdmin(msg.sender) , "Restricted to Admins");
        _;
    }

    modifier onlyContracts()
    {
        require( isContract(msg.sender) , "Restricted to Contracts");
        _;
    }

    modifier onlyContractOrAdmin()
    {
        require(   isAdmin(msg.sender) || isRootAdmin(msg.sender) || isContract(msg.sender) , "Restricted to Admin/Contracts");
        _;
    }


    function isContract(address account) public  view returns (bool)
    {
        return hasRole(Contracts, account);
    }

    function addContract(address account) public  onlyAdmin
    {
        grantRole(Contracts, account);
    }
  /// @dev Add an account to the admin role. Restricted to admins.
    function RemoveContract(address account) public  onlyRootAdmin
    {
        //require( isRootAdmin(account) == false , "Removing Root Admin is not Allowed" );
        revokeRole(Contracts, account);
    }


    function isRootAdmin(address account) public  view returns (bool)
    {
        return hasRole(DEFAULT_ADMIN_ROLE, account);
    }
    /// @dev Return `true` if the account belongs to the user role.
    function isAdmin(address account) public  view returns (bool)
    {
        return hasRole(Admin, account);
    }

    function addAdmin(address account) public  onlyAdmin
    {
        grantRole(Admin, account);
    }
  /// @dev Add an account to the admin role. Restricted to admins.
    function RemoveAdmin(address account) public  onlyRootAdmin
    {
        require( isRootAdmin(account) == false , "Removing Root Admin is not Allowed" );
        revokeRole(Admin, account);
    }



    function  PauseContract() public onlyAdmin //onlyAdmins
    {
        _pause();
    }

    function UnPauseContract() public onlyAdmin //onlyAdmins
    {
        _unpause();
    }


    function createProposal ( Proposal memory proposal ) public  onlyContractOrAdmin whenNotPaused    returns (  uint256 )
    {
        

        //returnProfit[]  storage rp = new returnProfit[](0) ; 
        uint256 index = proposalIDs.current();
        //IERC20 token_contract = IERC20(token) ;
        Proposal storage p = Props[index] ; 
        //Proposal memory p = Proposal( applicant , token , fundsRequested , details ,  block.timestamp  , block.timestamp + 90 days , 0 , premium , duration , profit , slice ,  fundsAllocatedAfterTax , 0 , 0 , 0  , false  , true  , 0 , false ,false , false , false , false , new returnProfit[](0)  );
        //Props[index] = p ; 
        p.applicant = proposal.applicant ; 
        p.id = index ; 
        p.fullName = proposal.fullName ; 
        p.bussinessName = proposal.bussinessName ; 
        p.logo = proposal.logo ; 
        p.webURL = proposal.webURL ; 
        p.title = proposal.title ; 
        p.whitePaper  = proposal.whitePaper ; 
        p.bussinessPlan = proposal.bussinessPlan ; 
        p.debtBased = proposal.debtBased ; 
        p.token = proposal.token ; 
        p.fundsRequested = proposal.fundsRequested ; 
        p.details = proposal.details ;
        p.premium = proposal.premium ; 
        p.duration = proposal.duration ;
        p.profit = proposal.profit ;
        p.slice = proposal.slice ; 
        p.fundsAllocatedAfterTax = proposal.fundsAllocatedAfterTax ;  
        p.score = 0 ; 
        p.paidAmount = 0 ; 
        p.returnedAmount = 0 ; 
        p.DAOAmount = 0 ;
        p.DAOInvested = false ; 
        p.enabled = true ; 
        p.Locked = 0 ;
        p.processed = false ;
        p.didPass = false ;
        p.aborted = false ; 
        p.paid = false ; 
        p.fundReturned = false ;  
        p.exist = true ;
        p.submitDate = block.timestamp ; 

        p.lockL2StartDate = 0  ;
        p.lockL2EndDate = 0 ; 
        p.lockL3StartDate = 0  ;
        p.lockL3EndDate = 0  ; 
        //p.returnProfit = new returnProfit[](0) ;

        if ( p.premium == true )
        {
            premiumProposals.push(index);
        }

        emit CreateProposal(proposal.applicant, p, block.timestamp , "Create");

        AddressProps[proposal.applicant].push(index);
        proposalIDs.increment();

        return index ; 
    }

    function updateProposal ( uint256 index ,  Proposal memory  proposal ) public  onlyContractOrAdmin whenNotPaused    returns (  uint256 )
    {
        

        require ( Props[index].enabled == true , "E1") ;
        require ( Props[index].Locked == 0 , "E2");
        require ( Props[index].aborted == false , "E3");
        require ( Props[index].paid == false , "E4");
        //returnProfit[]  storage rp = new returnProfit[](0) ; 
        //uint256 index = proposalIDs.current();
        //IERC20 token_contract = IERC20(token) ;
        Proposal storage p = Props[index] ; 
        //Proposal memory p = Proposal( applicant , token , fundsRequested , details ,  block.timestamp  , block.timestamp + 90 days , 0 , premium , duration , profit , slice ,  fundsAllocatedAfterTax , 0 , 0 , 0  , false  , true  , 0 , false ,false , false , false , false , new returnProfit[](0)  );
        //Props[index] = p ; 
        //p.applicant = applicant ; 
        p.token = proposal.token ; 
        p.fundsRequested = proposal.fundsRequested ; 
        p.details = proposal.details ;
        //p.premium = proposal.premium ; 
        p.duration = proposal.duration ;
        p.profit = proposal.profit ; 
        p.slice = proposal.slice ; 
        p.fundsAllocatedAfterTax = proposal.fundsAllocatedAfterTax ;  
        //p.score =  proposal.score ; 
        p.fullName = proposal.fullName ; 
        p.bussinessName = proposal.bussinessName ; 
        p.logo = proposal.logo ; 
        p.webURL = proposal.webURL ; 
        p.title = proposal.title ; 
        p.whitePaper  = proposal.whitePaper ; 
        p.bussinessPlan = proposal.bussinessPlan ; 

        emit UpdateProposal(p.applicant, p, block.timestamp, "Update");

        //p.returnProfit = new returnProfit[](0) ;

        //AddressProps[applicant].push(index);
        //proposalIDs.increment();

        return index ; 
    }


    function abortProposal ( uint256 index  ) public  onlyContractOrAdmin whenNotPaused    returns (  uint256 )
    {
        
        require ( Props[index].enabled == true , "E1") ;
        require ( Props[index].Locked <= 1 , "E2");
        require ( Props[index].aborted == false , "E3");
        
        //Props[index].endingPeriod = block.timestamp  ; 
        Props[index].aborted = true ; 
        emit AbortProposal(Props[index].applicant, Props[index], block.timestamp, "Abort");


        return index ; 
    }

    function ProcessProposal ( uint256 index  ) public  onlyContractOrAdmin whenNotPaused    returns (  uint256 )
    {
        
        // require ( Props[index].enabled == true , "E1") ;
        // require ( Props[index].Locked == 1 , "E2");
        // require ( Props[index].aborted == false , "E3");
        // require ( Props[index].processed == false , "E4");

        
        Props[index].processed = true ; 
        emit UpdateProposal(Props[index].applicant, Props[index], block.timestamp, "Process Proposal");


        return index ; 
    }

    function acceptProposal ( uint256 index  ) public  onlyContractOrAdmin whenNotPaused    returns (  uint256 )
    {
        
        // require ( Props[index].enabled == true , "E1") ;
        // //require ( Props[index].Locked <= 1 , "E2");
        // require ( Props[index].Locked == 1 , "E2");

        // require ( Props[index].aborted == false , "E3");
        // require ( Props[index].processed == true , "E4");
        
        Props[index].didPass = true ; 
        // Props[index].startingPeriod = block.timestamp  ; 
        // Props[index].endingPeriod = block.timestamp + 90 days  ; 

        emit UpdateProposal(Props[index].applicant, Props[index], block.timestamp, "Accept");




        return index ; 
    }

    function rejectProposal ( uint256 index  ) public  onlyContractOrAdmin whenNotPaused    returns (  uint256 )
    {

        // require ( Props[index].enabled == true , "E1") ;
        // //require ( Props[index].Locked <= 1 , "E2");
        // require ( Props[index].Locked == 1 , "E2");
        // require ( Props[index].aborted == false , "E3");
        // require ( Props[index].processed == true , "E4");
        
        Props[index].didPass = false ; 
        //Props[index].startingPeriod = block.timestamp  ; 
        //Props[index].endingPeriod = block.timestamp  ; 

        emit UpdateProposal(Props[index].applicant, Props[index], block.timestamp, "Reject");




        return index ; 
    }

    function lockProposal ( uint256 index  , uint256 lock , uint256 start , uint256 end ) public  onlyContractOrAdmin whenNotPaused    returns (  uint256 )
    {
        
        // require ( Props[index].enabled == true , "E1") ;
        // require ( Props[index].Locked == 0 , "E2");
        // require ( Props[index].aborted == false , "E3");
        // require ( Props[index].processed == false , "E4");
        // //require ( Props[index].didPass == true , "E5");

        if ( lock == 2 )
        {
            Props[index].Locked = 2 ; 
            Props[index].lockL2StartDate = start ; 
            Props[index].lockL2EndDate = end ; 
        }

        if ( lock == 3 )
        {
            Props[index].Locked = 2 ; 
            Props[index].lockL3StartDate = start ; 
            Props[index].lockL3EndDate = end ; 
        }
        

        emit UpdateProposal(Props[index].applicant, Props[index], block.timestamp, "Lock");


        return index ; 
    }

    function unlockProposal ( uint256 index  , uint256 lock  ) public  onlyContractOrAdmin whenNotPaused    returns (  uint256 )
    {
        
        require ( Props[index].enabled == true , "E1") ;
        require ( Props[index].Locked == 1 , "E2");
        require ( Props[index].aborted == false , "E3");
        //require ( Props[index].processed == true , "E4");
        //require ( Props[index].didPass == true , "E5");


        
        Props[index].Locked = lock ;
        emit UpdateProposal(Props[index].applicant, Props[index], block.timestamp, "UnLock");
 

        return index ; 
    }


    // function lockFundProposal ( uint256 index  , uint256 start , uint256 end  ) public  onlyContractOrAdmin whenNotPaused    returns (  uint256 )
    // {
        
    //     require ( Props[index].enabled == true , "E1") ;
    //     require ( Props[index].Locked == 1 , "E2");
    //     require ( Props[index].aborted == false , "E3");
    //     require ( Props[index].processed == true , "E4");
    //     require ( Props[index].didPass == true , "E5");

        
    //     Props[index].Locked = 2 ; 
    //     Props[index].lockL2StartDate = start ; 
    //     Props[index].lockL2EndDate = end ; 

    //     //uint256 lockL2EndDate ; 
    //     emit UpdateProposal(Props[index].applicant, Props[index], block.timestamp, "Lock-Fund");


    //     return index ; 
    // }

    // function unlockFundProposal ( uint256 index , uint256 lock ) public  onlyContractOrAdmin whenNotPaused    returns (  uint256 )
    // {
        
    //     require ( Props[index].enabled == true , "E1") ;
    //     require ( Props[index].Locked == 2 , "E2");
    //     require ( Props[index].aborted == false , "E3");
    //     require ( Props[index].processed == true , "E4");
    //     require ( Props[index].didPass == true , "E5");

        
    //     Props[index].Locked = lock ; 
    //     emit UpdateProposal(Props[index].applicant, Props[index], block.timestamp, "Unlock-Fund");


    //     return index ; 
    // }

    // function lockDAO ( uint256 index  , uint256 start , uint256 end ) public  onlyContractOrAdmin whenNotPaused    returns (  uint256 )
    // {
        
    //     require ( Props[index].enabled == true , "E1") ;
    //     require ( Props[index].Locked == 2 , "E2");
    //     require ( Props[index].aborted == false , "E3");
    //     require ( Props[index].processed == true , "E4");
    //     require ( Props[index].didPass == true , "E5");

        
    //     Props[index].Locked = 3 ; 
    //     Props[index].lockL3StartDate = start ; 
    //     Props[index].lockL3EndDate = end ; 
    //     // uint256 lockL3EndDate ; 

    //     emit UpdateProposal(Props[index].applicant, Props[index], block.timestamp, "Lock-DAO");


    //     return index ; 
    // }

    // function unlockDAO ( uint256 index , uint256 lock  ) public  onlyContractOrAdmin whenNotPaused    returns (  uint256 )
    // {
        
    //     require ( Props[index].enabled == true , "E1") ;
    //     require ( Props[index].Locked == 3 , "E2");
    //     require ( Props[index].aborted == false , "E3");
    //     require ( Props[index].processed == true , "E4");
    //     require ( Props[index].didPass == true , "E5");

        
    //     Props[index].Locked = lock ; 
    //     emit UpdateProposal(Props[index].applicant, Props[index], block.timestamp, "Unlock-DAO");


    //     return index ; 
    // }



    function promoteProposal ( uint256 index  ) public  onlyContractOrAdmin whenNotPaused    returns (  uint256 )
    {
        
        require ( Props[index].enabled == true , "E1") ;
        require ( Props[index].Locked <= 1 , "E2");
        require ( Props[index].aborted == false , "E3");
        //require ( Props[index].processed == true , "Proposal is not Processed");
        //require ( Props[index].didPass == true , "Proposal is not Passed");
        require ( Props[index].premium == false , "E4");

        if ( checkProposalExistInPremiumList( index) == false  )
        {
            premiumProposals.push(index);
        }
        
        Props[index].premium = true ; 

        emit UpdateProposal(Props[index].applicant, Props[index], block.timestamp, "Promote");


        return index ; 
    }

    function demoteProposal ( uint256 index  ) public  onlyContractOrAdmin whenNotPaused    returns (  uint256 )
    {
        
        require ( Props[index].enabled == true , "E1") ;
        require ( Props[index].Locked <= 1 , "E2");
        require ( Props[index].aborted == false , "E3");
        //require ( Props[index].processed == true , "Proposal is not Processed");
        //require ( Props[index].didPass == true , "Proposal is not Passed");
        require ( Props[index].premium == true , "E4");

        
        if ( checkProposalExistInPremiumList( index) == true  )
        {
            uint256 position = findProposalIndexInPremiumList(index);
            premiumProposals[position] = premiumProposals[ premiumProposals.length.sub(1) ] ; 
            premiumProposals.pop();
        }

        Props[index].premium = false ; 

        emit UpdateProposal(Props[index].applicant, Props[index], block.timestamp, "Demote");


        return index ; 
    }


    function directFundProposal ( uint256 index   ) public  onlyContractOrAdmin whenNotPaused    returns (  uint256 )
    {
        
        require ( Props[index].enabled == true , "E1") ;
        require ( Props[index].Locked == 2 , "E2");
        require ( Props[index].aborted == false , "E3");
        require ( Props[index].processed == true , "E4");
        require ( Props[index].didPass == true , "E5");
        require ( Props[index].paid == false , "E6");

        
        Props[index].paid = true ; 
        Props[index].DAOInvested = false ;  

        Props[index].startingPeriod = block.timestamp  ; 
        Props[index].endingPeriod = block.timestamp  + Props[index].duration  ; 
        emit UpdateProposal(Props[index].applicant, Props[index], block.timestamp, "Direct Fund");




        for ( uint256 i = 0 ; i < Props[index].slice ; i++  )
        {
            uint256 nextDeadline = Props[index].startingPeriod.add(  Props[index].duration.div( Props[index].slice  ).mul( i + 1) );
            uint256 amountToBePaid =  Props[index].fundsRequested.add( Props[index].fundsRequested.mul(Props[index].profit).div(1000)  ).div(Props[index].slice);
            returnProfit memory rp = returnProfit ( nextDeadline , amountToBePaid ,  0  , true , false , i+1 , false  , 0  , true , 0 ) ; 
            //Props[index].returnOfInvestment.push(rp);
            ProposalProfitReturn[index][i+1] = rp ;
        }

        //Props[index].endingPeriod = block.timestamp  ; 


        return index ; 
    }

    function fundProposalByDAO ( uint256 index , uint256 amount  ) public  onlyContractOrAdmin whenNotPaused    returns (  uint256 )
    {
        
        require ( Props[index].enabled == true , "E1") ;
        require ( Props[index].Locked == 3 , "E2");
        require ( Props[index].aborted == false , "E3");
        require ( Props[index].processed == true , "E4");
        require ( Props[index].didPass == true , "E5");
        require ( Props[index].paid == false , "E6");


        Props[index].startingPeriod = block.timestamp  ; 
        Props[index].endingPeriod = block.timestamp  + Props[index].duration  ;
        emit UpdateProposal(Props[index].applicant, Props[index], block.timestamp, "DAO Fund");
 

        for ( uint256 i = 0 ; i < Props[index].slice ; i++  )
        {
            uint256 nextDeadline = Props[index].startingPeriod.add(  Props[index].duration.div( Props[index].slice  ).mul( i  +1) );
            uint256 amountToBePaid =  Props[index].fundsRequested.add( Props[index].fundsRequested.mul(Props[index].profit).div(1000)  ).div(Props[index].slice);
            returnProfit memory rp = returnProfit ( nextDeadline , amountToBePaid ,  0  , true , false , i+1 , false  , 0 , true , 0 ) ; 
            //Props[index].returnOfInvestment.push(rp);
            ProposalProfitReturn[index][i+1] = rp ;
        }

        
        Props[index].DAOInvested = true ;  
        Props[index].paid = true ; 
        Props[index].DAOAmount = amount  ;
        //Props[index].endingPeriod = block.timestamp  ; 


        return index ; 
    }

    // function changeDuration ( uint256 index , uint256 duration  ) public  onlyContractOrAdmin whenNotPaused    returns (  uint256 )
    // {
        
    //     require ( Props[index].enabled == true , "E1") ;
    //     require ( Props[index].Locked == 0 , "E2");
    //     require ( Props[index].aborted == false , "E3");
    //     require ( Props[index].paid == false , "E4");

        
    //     Props[index].duration = duration ; 
    //     Props[index].didPass = false ; 

    //     emit UpdateProposal(Props[index].applicant, Props[index], block.timestamp, "Change Duration");


    //     // Props[index].endingPeriod = block.timestamp  ; 


    //     return index ; 
    // }

    // function changeProfit ( uint256 index , uint256 profit  ) public  onlyContractOrAdmin whenNotPaused    returns (  uint256 )
    // {
        
    //     require ( Props[index].enabled == true , "E1") ;
    //     require ( Props[index].Locked == 0 , "E2");
    //     require ( Props[index].aborted == false , "E3");
    //     require ( Props[index].paid == false , "E4");

        
    //     Props[index].profit = profit ; 
    //     Props[index].didPass = false ; 
    //     // Props[index].endingPeriod = block.timestamp  ; 

    //     emit UpdateProposal(Props[index].applicant, Props[index], block.timestamp, "Change Profit");



    //     return index ; 
    // }

    // function changeSlice ( uint256 index , uint256 slice  ) public  onlyContractOrAdmin whenNotPaused    returns (  uint256 )
    // {
        
    //     require ( Props[index].enabled == true , "E1") ;
    //     require ( Props[index].Locked == 0 , "E2");
    //     require ( Props[index].aborted == false , "E3");
    //     require ( Props[index].paid == false , "E4");

        
    //     Props[index].slice = slice ; 
    //     Props[index].didPass = false ; 

    //     emit UpdateProposal(Props[index].applicant, Props[index], block.timestamp, "Change Slice");

    //     // Props[index].endingPeriod = block.timestamp  ; 


    //     return index ; 
    // }

    // function changeSubmitDate ( uint256 index , uint256 submitDate  ) public  onlyContractOrAdmin whenNotPaused    returns (  uint256 )
    // {
        
    //     require ( Props[index].enabled == true , "E1") ;
    //     require ( Props[index].Locked == 0 , "E2");
    //     require ( Props[index].aborted == false , "E3");
    //     require ( Props[index].paid == false , "E4");

        
    //     Props[index].submitDate = submitDate ; 
    //     //Props[index].didPass = false ; 

    //     emit UpdateProposal(Props[index].applicant, Props[index], block.timestamp, "Change Submit Date");

    //     // Props[index].endingPeriod = block.timestamp  ; 


    //     return index ; 
    // }

    // function changeFundRequested ( uint256 index , uint256 fundsRequested  ) public  onlyContractOrAdmin whenNotPaused    returns (  uint256 )
    // {
        
    //     require ( Props[index].enabled == true , "E1") ;
    //     require ( Props[index].Locked == 0 , "E2");
    //     require ( Props[index].aborted == false , "E3");
    //     require ( Props[index].paid == false , "E4");

        
    //     Props[index].fundsRequested = fundsRequested ; 
    //     Props[index].didPass = false ; 
    //     // Props[index].endingPeriod = block.timestamp  ; 

    //     emit UpdateProposal(Props[index].applicant, Props[index], block.timestamp, "Change Fund");

    //     return index ; 
    // }

    function setInvestmentReturned ( uint256 index , bool status  ) public  onlyContractOrAdmin whenNotPaused    returns (  uint256 )
    {
        
        require ( Props[index].enabled == true , "E1") ;
        require ( Props[index].Locked == 3 || Props[index].Locked == 2  , "E2");
        require ( Props[index].aborted == false , "E3");
        require ( Props[index].processed == true , "E4");
        require ( Props[index].didPass == true , "E5");
        require ( ( Props[index].paid == true &&  Props[index].DAOInvested == true  ) || ( Props[index].paid == true &&  Props[index].DAOInvested == false  )  , "E6");

        
        Props[index].fundReturned = status ; 
        // Props[index].endingPeriod = block.timestamp  ; 

        emit UpdateProposal(Props[index].applicant, Props[index], block.timestamp, "Investment Return");



        return index ; 
    }


    function scoreProposal ( uint256 index  , uint256 score ) public  onlyContractOrAdmin     returns (  uint256 )
    {
        
        require ( Props[index].enabled == true , "E1") ;
        require ( Props[index].Locked == 1 , "E2");
        require ( Props[index].aborted == false , "E3");
        require ( Props[index].processed == true , "E4");

        
        Props[index].score = score ; 


        return index ; 
    }


    function setPaidAmount ( uint256 index , uint256 amount  ) public  onlyContractOrAdmin whenNotPaused    returns (  uint256 )
    {
        
        require ( Props[index].enabled == true , "E1") ;
        require ( Props[index].Locked == 2 || Props[index].Locked == 3  , "E2");
        require ( Props[index].aborted == false , "E3");
        require ( Props[index].processed == true , "E4");
        require ( Props[index].didPass == true , "E5");
        require ( ( Props[index].paid == true &&  Props[index].DAOInvested == true  ) || ( Props[index].paid == true &&  Props[index].DAOInvested == false  )  , "E6");
        require (  Props[index].paidAmount.add(amount) <=  Props[index].fundsAllocatedAfterTax , "E7");

        
        // Props[index].DAOInvested = true ;  
        Props[index].paidAmount = Props[index].paidAmount.add( amount ) ; 

        emit UpdateProposal(Props[index].applicant, Props[index], block.timestamp, "Payment Proposal");

        // Props[index].DAOAmount = amount  ;
        // Props[index].endingPeriod = block.timestamp  ; 


        return index ; 
    }

    function setReturnedAmount ( uint256 index , uint256 amount  ) public  onlyContractOrAdmin whenNotPaused    returns (  uint256 )
    {
        
        require ( Props[index].enabled == true , "E1") ;
        require ( Props[index].Locked == 2 || Props[index].Locked == 3  , "E2");
        require ( Props[index].aborted == false , "E3");
        require ( Props[index].processed == true , "E4");
        require ( Props[index].didPass == true , "E5");
        require ( ( Props[index].paid == true &&  Props[index].DAOInvested == true  ) || ( Props[index].paid == true &&  Props[index].DAOInvested == false  )  , "E6");
        require (  Props[index].returnedAmount.add(amount) <=  ( Props[index].fundsRequested.add ( Props[index].fundsRequested.mul( Props[index].profit ).div(1000) )  ), "E7");



        //Props[index].endingPeriod = block.timestamp ; 
        // Props[index].DAOInvested = true ;  
        Props[index].returnedAmount = Props[index].returnedAmount.add( amount ) ; 
        if ( Props[index].returnedAmount == ( Props[index].fundsRequested.add ( Props[index].fundsRequested.mul( Props[index].profit ).div(1000) )  )  )
        {
            Props[index].fundReturned = true ; 
        }
        // Props[index].DAOAmount = amount  ;
        // Props[index].endingPeriod = block.timestamp  ; 


        return index ; 
    }

    // function checkReturnedAmount ( uint256 index   ) public view  onlyContractOrAdmin whenNotPaused    returns (  bool )
    // {
        
    //     require ( Props[index].enabled == true , "E1") ;
    //     require ( Props[index].Locked == 2 || Props[index].Locked == 3  , "E2");
    //     require ( Props[index].aborted == false , "E3");
    //     require ( Props[index].processed == true , "E4");
    //     require ( Props[index].didPass == true , "E5");
    //     require ( ( Props[index].paid == true &&  Props[index].DAOInvested == true  ) || ( Props[index].paid == true &&  Props[index].DAOInvested == false  )  , "E6");
    //     //require (  Props[index].returnedAmount.add(amount) <=  ( Props[index].fundsRequested.add ( Props[index].fundsRequested.mul( Props[index].profit ).div(100) )  ), "E7");


    //     if (  Props[index].returnedAmount ==  ( Props[index].fundsRequested.add ( Props[index].fundsRequested.mul( Props[index].profit ).div(1000)  )   )  )
    //     {
    //         return true ;
    //     }
    //     else 
    //     {
    //         return false ; 
    //     }
    //     // Props[index].DAOInvested = true ;  
    //     //Props[index].returnedAmount = Props[index].returnedAmount.add( amount ) ; 
    //     // Props[index].DAOAmount = amount  ;
    //     // Props[index].endingPeriod = block.timestamp  ; 



    // }



    function setProposalReturnProfit ( uint256 index , uint256 deadline , uint256 amount , uint256 paymentDate , bool enabled ,  bool paid , uint256 id ,  bool penalty , uint256 penaltyAmount , uint256 received   ) public   onlyContractOrAdmin whenNotPaused 
    {
        returnProfit memory rp = returnProfit ( deadline , amount ,  paymentDate  , enabled , paid , id , penalty  , penaltyAmount , true , received ) ; 
            //Props[index].returnOfInvestment.push(rp);
        ProposalProfitReturn[index][id] = rp ;

    }

    function getProposalReturnProfitById ( uint256 index , uint256 paymentID) public  view returns  ( returnProfit memory )
    {
        return ProposalProfitReturn[index][paymentID] ;
    } 

    function recordProposalReturnProfitById ( uint256 index , uint256 paymentID , uint256 amount , uint256 date )  public   onlyContractOrAdmin whenNotPaused
    {
        if ( ProposalProfitReturn[index][paymentID].exist == true && ProposalProfitReturn[index][paymentID].paid == false   )
        {
            ProposalProfitReturn[index][paymentID].paid = true ; 
            ProposalProfitReturn[index][paymentID].received = amount ; 
            ProposalProfitReturn[index][paymentID].paymentDate  = date ; 
            //emit ProposalProfit( Props[index] , ProposalProfitReturn[index][paymentID], block.timestamp , "R");
        }

    }

    function getProposalCount() public view returns (uint256)
    {
        return  proposalIDs.current().sub(1);

    }

    function getProposal( uint256 index) public view returns ( Proposal memory  )
    {
        return  Props[index];

    }
    // function getProposalReturnProfit( uint256 index) public view returns ( returnProfit[] memory  )
    // {
    //     return  Props[index].returnOfInvestment;

    // }

    function getProposals( uint256 page , uint256  size) public view returns ( Proposal[] memory  )
    {

        require ( page > 0 && size > 0  , "page/size != 0");
        Proposal[] memory  result  = new  Proposal[] (  size );
        
        uint256 index = 0 ; 
        for ( uint256 i = 1 ; i <= size  ; i++ )
        {
            //UserStake storage temp = this.StakeUserInfo(msg.sender , ( page.sub(1) ).mul(size).add(i) ) ;
            if ( Props[ (page.sub(1) ).mul(size).add(i) ].exist == true  )
            {
                Proposal memory temp = Props[ (page.sub(1) ).mul(size).add(i) ] ;
                result[index] = temp ;
                index = index.add(1);
            }

            //result.push(temp ); 
        }
        return result ; 
        //return  Props[index];

    }

    function getProposalsProfitReturn( uint256 index ,  uint256 page , uint256  size) public view returns ( returnProfit[] memory  )
    {

        require ( page > 0 && size > 0  , "page/size != 0");
        returnProfit[] memory  result  = new returnProfit[] ( size ) ;
        
        uint256 array_index = 0 ; 
        for ( uint256 i = 1 ; i <= size  ; i++ )
        {

            if(  ProposalProfitReturn[index][ (page.sub(1) ).mul(size).add(i) ].exist == true  )
            {
                returnProfit memory temp = ProposalProfitReturn[index][ (page.sub(1) ).mul(size).add(i) ] ;
                result[array_index] = temp ;
                index = index.add(1);
            }
            //UserStake storage temp = this.StakeUserInfo(msg.sender , ( page.sub(1) ).mul(size).add(i) ) ;

            //result.push(temp ); 
        }
        return result ; 
        //return  Props[index];

    }


    function getProposalByAddress( address applicant) public view returns ( uint256[] memory  )
    {
        return  AddressProps[applicant];

    }

    function updateProposalLockTime ( uint256 index ,  uint256 startL2 ,uint256 endL2 , uint256 startL3 ,uint256  endL3) public   onlyContractOrAdmin whenNotPaused
    {

        //         uint256 lockL2StartDate ;
        // uint256 lockL2EndDate ; 
        // uint256 lockL3StartDate ;
        // uint256 lockL3EndDate ;
        Props[index].lockL2StartDate =  startL2  ;
        Props[index].lockL2EndDate   = endL2   ;
        Props[index].lockL3StartDate   = startL3   ;
        Props[index].lockL3EndDate    = endL3  ;
    }


    // function getPremiumProposals ( uint256 page , uint256  size) public view returns ( Proposal[] memory  )
    // {
    //     require ( page > 0 && size > 0  , "page/size != 0");
    //     Proposal[] memory  result  = new  Proposal[] (  size );
        
    //     uint256 index = 0 ; 
    //     for ( uint256 i = 1 ; i <= size  ; i++ )
    //     {
    //         //UserStake storage temp = this.StakeUserInfo(msg.sender , ( page.sub(1) ).mul(size).add(i) ) ;
    //         if ( Props[ (page.sub(1) ).mul(size).add(i) ].exist == true  )
    //         {
    //             Proposal memory temp = Props[ (page.sub(1) ).mul(size).add(i) ] ;
    //             result[index] = temp ;
    //             index = index.add(1);
    //         }

    //         //result.push(temp ); 
    //     }
    //     return result ; 
    // }

    

    function checkProposalExistInPremiumList ( uint256 index ) public view returns ( bool )
    {
        for ( uint256 i = 0 ; i < premiumProposals.length ; i++ )
        {
            if ( premiumProposals[i] == index  )
            {
                return true ;
            }
        }
        return false ; 
    }

    function findProposalIndexInPremiumList ( uint256 index ) public view returns ( uint256 )
    {
        for ( uint256 i = 0 ; i < premiumProposals.length ; i++ )
        {
            if ( premiumProposals[i] == index  )
            {
                return i ;
            }
        }
        return 0 ; 
    }

    function getPremiumList ( ) public view returns ( uint256[] memory )
    {
        return premiumProposals  ;
    }
    




}