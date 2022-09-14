/**
 *Submitted for verification at polygonscan.com on 2022-09-13
*/

// File: github.com/OpenZeppelin/openzeppelin-contracts/contracts/utils/math/SignedSafeMath.sol


// OpenZeppelin Contracts v4.4.1 (utils/math/SignedSafeMath.sol)

pragma solidity ^0.8.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SignedSafeMath` is no longer needed starting with Solidity 0.8. The compiler
 * now has built in overflow checking.
 */
library SignedSafeMath {
    /**
     * @dev Returns the multiplication of two signed integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(int256 a, int256 b) internal pure returns (int256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two signed integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(int256 a, int256 b) internal pure returns (int256) {
        return a / b;
    }

    /**
     * @dev Returns the subtraction of two signed integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(int256 a, int256 b) internal pure returns (int256) {
        return a - b;
    }

    /**
     * @dev Returns the addition of two signed integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(int256 a, int256 b) internal pure returns (int256) {
        return a + b;
    }
}

// File: github.com/OpenZeppelin/openzeppelin-contracts/contracts/utils/math/SafeMath.sol


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

// File: github.com/OpenZeppelin/openzeppelin-contracts/contracts/utils/math/Math.sol


// OpenZeppelin Contracts (last updated v4.7.0) (utils/math/Math.sol)

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

// File: github.com/OpenZeppelin/openzeppelin-contracts/contracts/utils/Strings.sol


// OpenZeppelin Contracts (last updated v4.7.0) (utils/Strings.sol)

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

// File: github.com/OpenZeppelin/openzeppelin-contracts/contracts/utils/Context.sol


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

// File: github.com/OpenZeppelin/openzeppelin-contracts/contracts/access/Ownable.sol


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

// File: github.com/OpenZeppelin/openzeppelin-contracts/contracts/utils/Address.sol


// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

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
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
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
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, "Address: low-level call failed");
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
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
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
        require(address(this).balance >= value, "Address: insufficient balance for call");
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
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
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
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
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
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

    function _revert(bytes memory returndata, string memory errorMessage) private pure {
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

// File: thewallcoupons.sol

/*
This file is part of the TheWall project.

The TheWall Contract is free software: you can redistribute it and/or
modify it under the terms of the GNU lesser General Public License as published
by the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

The TheWall Contract is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
GNU lesser General Public License for more details.

You should have received a copy of the GNU lesser General Public License
along with the TheWall Contract. If not, see <http://www.gnu.org/licenses/>.

@author Ilya Svirin <[email protected]>
*/


pragma solidity ^0.8.0;





abstract contract ERC223ReceivingContract
{
    function tokenFallback(address sender, uint amount, bytes memory data) public virtual;
}


contract TheWallCoupons is Context
{
    using SafeMath for uint256;
    using Address for address;

    string public standard='Token 0.1';
    string public name='TheWall';
    string public symbol='TWC';
    uint8 public decimals=0;
    
    event Transfer(address indexed sender, address indexed receiver, uint256 amount, bytes data);

    mapping(address => uint256) public balanceOf;
    uint256 public totalSupply;

    address private _thewallusers;

    function setTheWallUsers(address thewallusers) public
    {
        require(thewallusers != address(0), "TheWallCoupons: non-zero address is required");
        require(_thewallusers == address(0), "TheWallCoupons: _thewallusers can be initialized only once");
        _thewallusers = thewallusers;
    }

    modifier onlyTheWallUsers()
    {
        require(_msgSender() == _thewallusers, "TheWallCoupons: can be called from _theWallusers only");
        _;
    }

    function transfer(address receiver, uint256 amount, bytes memory data) public returns(bool)
    {
        _transfer(_msgSender(), receiver, amount, data);
        return true;
    }
    
    function transfer(address receiver, uint256 amount) public returns(bool)
    {
        bytes memory empty = hex"00000000";
         _transfer(_msgSender(), receiver, amount, empty);
         return true;
    }

    function _transfer(address sender, address receiver, uint amount, bytes memory data) internal
    {
        require(receiver != address(0), "TheWallCoupons: Transfer to zero-address is forbidden");

        balanceOf[sender] = balanceOf[sender].sub(amount);
        balanceOf[receiver] = balanceOf[receiver].add(amount);
        
        if (receiver.isContract())
        {
            ERC223ReceivingContract r = ERC223ReceivingContract(receiver);
            r.tokenFallback(sender, amount, data);
        }
        emit Transfer(sender, receiver, amount, data);
    }

    function _mint(address account, uint256 amount) onlyTheWallUsers public
    {
        require(account != address(0), "TheWallCoupons: mint to the zero address");

        totalSupply = totalSupply.add(amount);
        balanceOf[account] = balanceOf[account].add(amount);
        bytes memory empty = hex"00000000";
        emit Transfer(address(0), account, amount, empty);
    }

    function _burn(address account, uint256 amount) onlyTheWallUsers public
    {
        require(account != address(0), "TheWallCoupons: burn from the zero address");

        balanceOf[account] = balanceOf[account].sub(amount, "TheWallCoupons: burn amount exceeds balance");
        totalSupply = totalSupply.sub(amount);
        bytes memory empty = hex"00000000";
        emit Transfer(account, address(0), amount, empty);
    }
}

// File: thewallusers.sol

/*
This file is part of the TheWall project.

The TheWall Contract is free software: you can redistribute it and/or
modify it under the terms of the GNU lesser General Public License as published
by the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

The TheWall Contract is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
GNU lesser General Public License for more details.

You should have received a copy of the GNU lesser General Public License
along with the TheWall Contract. If not, see <http://www.gnu.org/licenses/>.

@author Ilya Svirin <[email protected]>
*/


pragma solidity ^0.8.0;






contract TheWallUsers is Ownable
{
    using SafeMath for uint256;
    using Address for address payable;

    struct User
    {
        string          nickname;
        bytes           avatar;
        address payable referrer;
    }
    
    TheWallCoupons private _coupons;

    mapping (address => User) public _users;
    
    event NicknameChanged(address indexed user, string nickname);
    event AvatarChanged(address indexed user, bytes avatar);

    event CouponsCreated(address indexed owner, uint256 created);
    event CouponsUsed(address indexed owner, uint256 used);

    event ReferrerChanged(address indexed me, address indexed referrer);
    event ReferralPayment(address indexed referrer, address indexed referral, uint256 amountWei);

    constructor (address coupons)
    {
        _coupons = TheWallCoupons(coupons);
        _coupons.setTheWallUsers(address(this));
    }

    function setNickname(string memory nickname) public
    {
        _users[_msgSender()].nickname = nickname;
        emit NicknameChanged(_msgSender(), nickname);
    }

    function setAvatar(bytes memory avatar) public
    {
        _users[_msgSender()].avatar = avatar;
        emit AvatarChanged(_msgSender(), avatar);
    }
    
    function setNicknameAvatar(string memory nickname, bytes memory avatar) public
    {
        setNickname(nickname);
        setAvatar(avatar);
    }
    
    function _useCoupons(address owner, uint256 count) internal returns(uint256 used)
    {
        used = _coupons.balanceOf(owner);
        if (count < used)
        {
            used = count;
        }
        if (used > 0)
        {
            _coupons._burn(owner, used);
            emit CouponsUsed(owner, used);
        }
    }

    function giveCoupons(address owner, uint256 count) public onlyOwner
    {
        _giveCoupons(owner, count);
    }
    
    function giveCouponsMulti(address[] memory owners, uint256 count) public onlyOwner
    {
        for(uint i = 0; i < owners.length; ++i)
        {
            _giveCoupons(owners[i], count);
        }
    }
    
    function _giveCoupons(address owner, uint256 count) internal
    {
        require(owner != address(0));
        _coupons._mint(owner, count);
        emit CouponsCreated(owner, count);
    }
    
    function _processRef(address me, address payable referrerCandidate, uint256 amountWei) internal returns(uint256)
    {
        User storage user = _users[me];
        if (referrerCandidate != address(0) && !referrerCandidate.isContract() && user.referrer == address(0))
        {
            user.referrer = referrerCandidate;
            emit ReferrerChanged(me, referrerCandidate);
        }
        
        uint256 alreadyPayed = 0;
        uint256 refPayment = amountWei.mul(6).div(100);

        address payable ref = user.referrer;
        if (ref != address(0))
        {
            ref.sendValue(refPayment);
            alreadyPayed = refPayment;
            emit ReferralPayment(ref, me, refPayment);
            
            ref = _users[ref].referrer;
            if (ref != address(0))
            {
                ref.sendValue(refPayment);
                alreadyPayed = refPayment.mul(2);
                emit ReferralPayment(ref, me, refPayment);
            }
        }
        
        return alreadyPayed;
    }
}

// File: thewallcore.sol

/*
This file is part of the TheWall project.

The TheWall Contract is free software: you can redistribute it and/or
modify it under the terms of the GNU lesser General Public License as published
by the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

The TheWall Contract is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
GNU lesser General Public License for more details.

You should have received a copy of the GNU lesser General Public License
along with the TheWall Contract. If not, see <http://www.gnu.org/licenses/>.

@author Ilya Svirin <[email protected]>
*/


pragma solidity ^0.8.0;







contract TheWallCore is TheWallUsers
{
    using SafeMath for uint256;
    using SignedSafeMath for int256;
    using Address for address;
    using Address for address payable;
    using Strings for uint256;

    event SizeChanged(int256 wallWidth, int256 wallHeight);
    event AreaCostChanged(uint256 costWei);
    event FeeChanged(uint256 feePercents);
    event FundsReceiverChanged(address fundsReceiver);
    event SecretCommited(uint256 secret, bytes32 hashOfSecret);
    event SecretUpdated(bytes32 hashOfNewSecret);

    enum Status
    {
        None,
        ForSale,
        ForRent,
        Rented
    }

    enum TokenType
    {
        Unknown,
        Area,
        Cluster
    }

    struct Token
    {
        TokenType  tt;
        Status     status;
        string     link;
        string     tags;
        string     title;
        uint256    cost;
        uint256    rentDuration;
        address    tenant;
        bytes      content;
    }
    
    struct Area
    {
        int256     x;
        int256     y;
        bool       premium;
        uint256    cluster;
        bytes      image;
        bytes32    hashOfSecret;
        uint256    nonce;
    }

    struct Cluster
    {
        uint256[]  areas;
        mapping (uint256 => uint256) areaToIndex;
        uint256    revision;
    }

    // x => y => area erc-721
    mapping (int256 => mapping (int256 => uint256)) private _areasOnTheWall;

    // erc-721 => Token, Area or Cluster
    mapping (uint256 => Token) private _tokens;
    mapping (uint256 => Area) private _areas;
    mapping (uint256 => Cluster) private _clusters;

    mapping (bytes32 => uint256) private _secrets;
    bytes32 private _hashOfSecret;
    bytes32 private _hashOfSecretToCommit;

    int256  public  _wallWidth;
    int256  public  _wallHeight;
    uint256 public  _costWei;
    uint256 public  _feePercents;
    address payable private _fundsReceiver;
    address private _thewall;

    constructor (address coupons) TheWallUsers(coupons)
    {
        _wallWidth = 500;
        _wallHeight = 500;
        _costWei = 1 ether / 10;
        _feePercents = 30;
        _fundsReceiver = payable(_msgSender());
        emit SizeChanged(_wallWidth, _wallHeight);
        emit AreaCostChanged(_costWei);
        emit FeeChanged(_feePercents);
        emit FundsReceiverChanged(_fundsReceiver);
    }

    function setTheWall(address thewall) public
    {
        require(thewall != address(0) && _thewall == address(0));
        _thewall = thewall;
    }

    modifier onlyTheWall()
    {
        require(_msgSender() == _thewall);
        _;
    }
    
    function setWallSize(int256 wallWidth, int256 wallHeight) public onlyOwner
    {
        require(_wallWidth <= wallWidth && _wallHeight <= wallHeight);
        _wallWidth = wallWidth;
        _wallHeight = wallHeight;
        emit SizeChanged(wallWidth, wallHeight);
    }

    function setCostWei(uint256 costWei) public onlyOwner
    {
        _costWei = costWei;
        emit AreaCostChanged(costWei);
    }

    function setFee(uint256 feePercents) public onlyOwner
    {
        _feePercents = feePercents;
        emit FeeChanged(feePercents);
    }

    function setFundsReceiver(address payable fundsReceiver) public onlyOwner
    {
        require(fundsReceiver != address(0));
        _fundsReceiver = fundsReceiver;
        emit FundsReceiverChanged(fundsReceiver);
    }

    function commitSecret(uint256 secret) public onlyOwner
    {
        require(_hashOfSecretToCommit == keccak256(abi.encodePacked(secret)));
        _secrets[_hashOfSecretToCommit] = secret;
        emit SecretCommited(secret, _hashOfSecretToCommit);
        delete _hashOfSecretToCommit;
    }

    function updateSecret(bytes32 hashOfNewSecret) public onlyOwner
    {
        _hashOfSecretToCommit = _hashOfSecret;
        _hashOfSecret = hashOfNewSecret;
        emit SecretUpdated(hashOfNewSecret);
    }

    function _canBeTransferred(uint256 tokenId) public view returns(TokenType)
    {
        Token storage token = _tokens[tokenId];
        require(token.tt != TokenType.Unknown, "TheWallCore: No such token found");
        require(token.status != Status.Rented || token.rentDuration < block.timestamp, "TheWallCore: Can't transfer rented item");
        if (token.tt == TokenType.Area)
        {
            Area memory area = _areas[tokenId];
            require(area.cluster == uint256(0), "TheWallCore: Can't transfer area owned by cluster");
        }
        else
        {
            Cluster storage cluster = _clusters[tokenId];
            require(cluster.areas.length > 0, "TheWallCore: Can't transfer empty cluster");
        }
        return token.tt;
    }

    function _isOrdinaryArea(uint256 areaId) public view
    {
        Token storage token = _tokens[areaId];
        require(token.tt == TokenType.Area, "TheWallCore: Token is not area");
        require(token.status != Status.Rented || token.rentDuration < block.timestamp, "TheWallCore: Unordinary status");
        Area memory area = _areas[areaId];
        require(area.cluster == uint256(0), "TheWallCore: Area is owned by cluster");
    }

    function _areasInCluster(uint256 clusterId) public view returns(uint256[] memory)
    {
        return _clusters[clusterId].areas;
    }

    function _forSale(uint256 tokenId, uint256 priceWei) onlyTheWall public
    {
        _canBeTransferred(tokenId);
        Token storage token = _tokens[tokenId];
        token.cost = priceWei;
        token.status = Status.ForSale;
    }

    function _forRent(uint256 tokenId, uint256 priceWei, uint256 durationSeconds) onlyTheWall public
    {
        _canBeTransferred(tokenId);
        Token storage token = _tokens[tokenId];
        token.cost = priceWei;
        token.status = Status.ForRent;
        token.rentDuration = durationSeconds;
    }

    function _createCluster(uint256 tokenId, bytes memory content) onlyTheWall public
    {
        Token storage token = _tokens[tokenId];
        token.tt = TokenType.Cluster;
        token.status = Status.None;
        token.content = content;

        Cluster storage cluster = _clusters[tokenId];
        cluster.revision = 1;
    }

    function _removeCluster(uint256 tokenId) onlyTheWall public
    {
        Token storage token = _tokens[tokenId];
        require(token.tt == TokenType.Cluster, "TheWallCore: no cluster found for remove");
        require(token.status != Status.Rented || token.rentDuration < block.timestamp, "TheWallCore: can't remove rented cluster");

        Cluster storage cluster = _clusters[tokenId];
        for(uint i=0; i<cluster.areas.length; ++i)
        {
            uint256 areaId = cluster.areas[i];
            
            Token storage areaToken = _tokens[areaId];
            areaToken.status = token.status;
            areaToken.link = token.link;
            areaToken.tags = token.tags;
            areaToken.title = token.title;

            Area storage area = _areas[areaId];
            area.cluster = 0;
        }
        delete _clusters[tokenId];
        delete _tokens[tokenId];
    }
    
    function _abs(int256 v) pure public returns (int256)
    {
        if (v < 0)
        {
            v = -v;
        }
        return v;
    }

    function _create(uint256 tokenId, int256 x, int256 y, uint256 clusterId, uint256 nonce, bytes memory content) onlyTheWall public returns (uint256 revision, bytes32 hashOfSecret)
    {
        _areasOnTheWall[x][y] = tokenId;

        Token storage token = _tokens[tokenId];
        token.tt = TokenType.Area;
        token.status = Status.None;
        token.content = content;

        Area storage area = _areas[tokenId];
        area.x = x;
        area.y = y;
        if (_abs(x) <= 100 && _abs(y) <= 100)
        {
            area.premium = true;
        }
        else
        {
            area.nonce = nonce;
            area.hashOfSecret = _hashOfSecret;
        }

        revision = 0;
        if (clusterId !=0)
        {
            area.cluster = clusterId;
        
            Cluster storage cluster = _clusters[clusterId];
            cluster.revision += 1;
            revision = cluster.revision;
            cluster.areas.push(tokenId);
            cluster.areaToIndex[tokenId] = cluster.areas.length - 1;
        }
        
        return (revision, area.hashOfSecret);
    }

    function _areaOnTheWall(int256 x, int256 y) public view returns(uint256)
    {
        return _areasOnTheWall[x][y];
    }

    function _buy(address payable tokenOwner, uint256 tokenId, address me, uint256 weiAmount, uint256 revision, address payable referrerCandidate) payable onlyTheWall public
    {
        Token storage token = _tokens[tokenId];
        require(token.tt != TokenType.Unknown, "TheWallCore: No token found");
        require(token.status == Status.ForSale, "TheWallCore: Item is not for sale");
        require(weiAmount == token.cost, string(abi.encodePacked("TheWallCore: Invalid amount of wei ", weiAmount.toString(), "/", token.cost.toString())));

        bool premium = false;
        if (token.tt == TokenType.Area)
        {
            Area storage area = _areas[tokenId];
            require(area.cluster == 0, "TheWallCore: Owned by cluster area can't be sold");
            premium = _isPremium(area, tokenId);
        }
        else
        {
            require(_clusters[tokenId].revision == revision, "TheWallCore: Incorrect cluster's revision");
        }
        
        token.status = Status.None;

        uint256 fee;
        if (!premium)
        {
            fee = msg.value.mul(_feePercents).div(100);
            uint256 alreadyPayed = _processRef(me, referrerCandidate, fee);
            _fundsReceiver.sendValue(fee.sub(alreadyPayed));
        }
        tokenOwner.sendValue(msg.value.sub(fee));
    }
    
    function _rent(address payable tokenOwner, uint256 tokenId, address me, uint256 weiAmount, uint256 revision, address payable referrerCandidate) payable onlyTheWall public returns(uint256 rentDuration)
    {
        Token storage token = _tokens[tokenId];
        require(token.tt != TokenType.Unknown, "TheWallCore: No token found");
        require(token.status == Status.ForRent, "TheWallCore: Item is not for rent");
        require(weiAmount == token.cost, string(abi.encodePacked("TheWallCore: Invalid amount of wei ", weiAmount.toString(), "/", token.cost.toString())));

        bool premium = false;
        if (token.tt == TokenType.Area)
        {
            Area storage area = _areas[tokenId];
            require(area.cluster == 0, "TheWallCore: Owned by cluster area can't be rented");
            premium = _isPremium(area, tokenId);
        }
        else
        {
            require(_clusters[tokenId].revision == revision, "TheWall: Incorrect cluster's revision");
        }

        rentDuration = block.timestamp.add(token.rentDuration);
        token.status = Status.Rented;
        token.cost = 0;
        token.rentDuration = rentDuration;
        token.tenant = me;
        
        uint256 fee;
        if (!premium)
        {
            fee = msg.value.mul(_feePercents).div(100);
            uint256 alreadyPayed = _processRef(me, referrerCandidate, fee);
            _fundsReceiver.sendValue(fee.sub(alreadyPayed));
        }
        tokenOwner.sendValue(msg.value.sub(fee));

        return rentDuration;
    }

    function _isPremium(Area storage area, uint256 tokenId) internal returns(bool)
    {
        if (area.hashOfSecret != bytes32(0))
        {
            uint256 secret = _secrets[area.hashOfSecret];
            if (secret != 0)
            {
                uint256 factor = uint256(keccak256(abi.encodePacked(secret, tokenId, area.nonce)));
                area.premium = ((factor % 1000) == 1);
                area.hashOfSecret = bytes32(0);
            }
        }
        return area.premium;
    }

    function _rentTo(uint256 tokenId, address tenant, uint256 durationSeconds) onlyTheWall public returns(uint256 rentDuration)
    {
        _canBeTransferred(tokenId);
        rentDuration = block.timestamp.add(durationSeconds);
        Token storage token = _tokens[tokenId];
        token.status = Status.Rented;
        token.cost = 0;
        token.rentDuration = rentDuration;
        token.tenant = tenant;
        return rentDuration;
    }

    function _cancel(uint256 tokenId) onlyTheWall public
    {
        Token storage token = _tokens[tokenId];
        require(token.tt != TokenType.Unknown, "TheWallCore: No token found");
        require(token.status == Status.ForRent || token.status == Status.ForSale, "TheWallCore: item is not for rent or for sale");
        token.cost = 0;
        token.status = Status.None;
        token.rentDuration = 0;
    }
    
    function _finishRent(address who, uint256 tokenId) onlyTheWall public
    {
        Token storage token = _tokens[tokenId];
        require(token.tt != TokenType.Unknown, "TheWallCore: No token found");
        require(token.tenant == who, "TheWall: Only tenant can finish rent");
        require(token.status == Status.Rented && token.rentDuration > block.timestamp, "TheWallCore: item is not rented");
        token.status = Status.None;
        token.rentDuration = 0;
        token.cost = 0;
        token.tenant = address(0);
    }
    
    function _addToCluster(address me, address areaOwner, address clusterOwner, uint256 areaId, uint256 clusterId) onlyTheWall public returns(uint256 revision)
    {
        require(areaOwner == clusterOwner, "TheWallCore: Area and Cluster have different owners");
        require(areaOwner == me, "TheWallCore: Can be called from owner only");

        Token storage areaToken = _tokens[areaId];
        Token storage clusterToken = _tokens[clusterId];
        require(areaToken.tt == TokenType.Area, "TheWallCore: Area not found");
        require(clusterToken.tt == TokenType.Cluster, "TheWallCore: Cluster not found");
        require(areaToken.status != Status.Rented || areaToken.rentDuration < block.timestamp, "TheWallCore: Area is rented");
        require(clusterToken.status != Status.Rented || clusterToken.rentDuration < block.timestamp, "TheWallCore: Cluster is rented");

        Area storage area = _areas[areaId];
        require(area.cluster == 0, "TheWallCore: Area already in cluster");
        area.cluster = clusterId;
        
        areaToken.status = Status.None;
        areaToken.rentDuration = 0;
        areaToken.cost = 0;
        
        Cluster storage cluster = _clusters[clusterId];
        cluster.revision += 1;
        cluster.areas.push(areaId);
        cluster.areaToIndex[areaId] = cluster.areas.length - 1;
        return cluster.revision;
    }

    function _removeFromCluster(address me, address areaOwner, address clusterOwner, uint256 areaId, uint256 clusterId) onlyTheWall public returns(uint256 revision)
    {
        require(areaOwner == clusterOwner, "TheWallCore: Area and Cluster have different owners");
        require(areaOwner == me, "TheWallCore: Can be called from owner only");

        Token storage areaToken = _tokens[areaId];
        Token storage clusterToken = _tokens[clusterId];
        require(areaToken.tt == TokenType.Area, "TheWallCore: Area not found");
        require(clusterToken.tt == TokenType.Cluster, "TheWallCore: Cluster not found");
        require(clusterToken.status != Status.Rented || clusterToken.rentDuration < block.timestamp, "TheWallCore: Cluster is rented");

        Area storage area = _areas[areaId];
        require(area.cluster == clusterId, "TheWallCore: Area is not in cluster");
        area.cluster = 0;

        Cluster storage cluster = _clusters[clusterId];
        cluster.revision += 1;
        uint index = cluster.areaToIndex[areaId];
        if (index != cluster.areas.length - 1)
        {
            uint256 movedAreaId = cluster.areas[cluster.areas.length - 1];
            cluster.areaToIndex[movedAreaId] = index;
            cluster.areas[index] = movedAreaId;
        }
        delete cluster.areaToIndex[areaId];
        cluster.areas.pop();
        return cluster.revision;
    }

    function _canBeManaged(address who, address owner, uint256 tokenId) internal view returns (TokenType t)
    {
        Token storage token = _tokens[tokenId];
        t = token.tt;
        require(t != TokenType.Unknown, "TheWallCore: No token found");
        if (t == TokenType.Area)
        {
            Area storage area = _areas[tokenId];
            if (area.cluster != uint256(0))
            {
                token = _tokens[area.cluster];
                require(token.tt == TokenType.Cluster, "TheWallCore: No cluster token found");
            }
        }
        
        if (token.status == Status.Rented && token.rentDuration > block.timestamp)
        {
            require(who == token.tenant, "TheWallCore: Rented token can be managed by tenant only");
        }
        else
        {
            require(who == owner, "TheWallCore: Only owner can manager token");
        }
    }

    function _setContent(address who, address owner, uint256 tokenId, bytes memory content) onlyTheWall public
    {
        _canBeManaged(who, owner, tokenId);
        Token storage token = _tokens[tokenId];
        token.content = content;
    }

    function _setAttributesComplete(address who, address owner, uint256 tokenId, bytes memory image, string memory link, string memory tags, string memory title) onlyTheWall public
    {
        TokenType tt = _canBeManaged(who, owner, tokenId);
        require(tt == TokenType.Area, "TheWallCore: Image can be set to area only");
        Area storage area = _areas[tokenId];
        area.image = image;
        Token storage token = _tokens[tokenId];
        token.link = link;
        token.tags = tags;
        token.title = title;
        delete token.content;
    }

    function _setAttributes(address who, address owner, uint256 tokenId, string memory link, string memory tags, string memory title) onlyTheWall public
    {
        _canBeManaged(who, owner, tokenId);
        Token storage token = _tokens[tokenId];
        token.link = link;
        token.tags = tags;
        token.title = title;
        delete token.content;
    }

    function _setImage(address who, address owner, uint256 tokenId, bytes memory image) onlyTheWall public
    {
        TokenType tt = _canBeManaged(who, owner, tokenId);
        require(tt == TokenType.Area, "TheWallCore: Image can be set to area only");
        Area storage area = _areas[tokenId];
        area.image = image;
        delete _tokens[tokenId].content;
    }

    function _setLink(address who, address owner, uint256 tokenId, string memory link) onlyTheWall public
    {
        _canBeManaged(who, owner, tokenId);
        Token storage token = _tokens[tokenId];
        token.link = link;
        delete token.content;
    }

    function _setTags(address who, address owner, uint256 tokenId, string memory tags) onlyTheWall public
    {
        _canBeManaged(who, owner, tokenId);
        Token storage token = _tokens[tokenId];
        token.tags = tags;
        delete token.content;
    }

    function _setTitle(address who, address owner, uint256 tokenId, string memory title) onlyTheWall public
    {
        _canBeManaged(who, owner, tokenId);
        Token storage token = _tokens[tokenId];
        token.title = title;
        delete token.content;
    }

    function tokenInfo(uint256 tokenId) public view returns(bytes memory, string memory, string memory, string memory, bytes memory)
    {
        Token memory token = _tokens[tokenId];
        bytes memory image;
        if (token.tt == TokenType.Area)
        {
            Area storage area = _areas[tokenId];
            image = area.image;
        }
        return (image, token.link, token.tags, token.title, token.content);
    }

    function _canBeCreated(int256 x, int256 y) view public
    {
        require(_abs(x) < _wallWidth && _abs(y) < _wallHeight, "TheWallCore: Out of wall");
        require(_areaOnTheWall(x, y) == uint256(0), "TheWallCore: Area is busy");
    }

    function _processPaymentCreate(address me, uint256 weiAmount, uint256 areasNum, address payable referrerCandidate) onlyTheWall public payable returns(uint256)
    {
        uint256 usedCoupons = _useCoupons(me, areasNum);
        areasNum -= usedCoupons;
        return _processPayment(me, weiAmount, areasNum, referrerCandidate);
    }
    
    function _processPayment(address me, uint256 weiAmount, uint256 itemsAmount, address payable referrerCandidate) internal returns (uint256)
    {
        uint256 payValue = _costWei.mul(itemsAmount);
        require(payValue <= weiAmount, string(abi.encodePacked("TheWallCore: Invalid amount of wei ", payValue.toString(), "/", weiAmount.toString())));
        if (weiAmount > payValue)
        {
            payable(me).sendValue(weiAmount.sub(payValue));
        }
        if (payValue > 0)
        {
            uint256 alreadyPayed = _processRef(me, referrerCandidate, payValue);
            _fundsReceiver.sendValue(payValue.sub(alreadyPayed));
        }
        return payValue;
    }

    function _canBeCreatedMulti(int256 x, int256 y, int256 width, int256 height) view public
    {
        require(_abs(x) < _wallWidth &&
                _abs(y) < _wallHeight &&
                _abs(x.add(width)) < _wallWidth &&
                _abs(y.add(height)) < _wallHeight,                
                "TheWallCpre: Out of wall");
        require(width > 0 && height > 0, "TheWallCore: dimensions must be greater than zero");
    }

    function _buyCoupons(address me, uint256 weiAmount, address payable referrerCandidate) public payable onlyTheWall returns (uint256)
    {
        uint256 couponsAmount = weiAmount.div(_costWei);
        uint payValue = _processPayment(me, weiAmount, couponsAmount, referrerCandidate);
        if (payValue > 0)
        {
            _giveCoupons(me, couponsAmount);
        }
        return payValue;
    }
    
    function _clusterOf(uint256 tokenId) view public returns (uint256)
    {
        return _areas[tokenId].cluster;
    }
}

// File: github.com/OpenZeppelin/openzeppelin-contracts/contracts/token/ERC721/IERC721Receiver.sol


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

// File: github.com/OpenZeppelin/openzeppelin-contracts/contracts/utils/introspection/IERC165.sol


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

// File: github.com/OpenZeppelin/openzeppelin-contracts/contracts/utils/introspection/ERC165.sol


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

// File: github.com/OpenZeppelin/openzeppelin-contracts/contracts/token/ERC721/IERC721.sol


// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;


/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

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
    ) external;

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
    ) external;

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
    ) external;

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
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

// File: github.com/OpenZeppelin/openzeppelin-contracts/contracts/token/ERC721/extensions/IERC721Metadata.sol


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

// File: github.com/OpenZeppelin/openzeppelin-contracts/contracts/token/ERC721/ERC721.sol


// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/ERC721.sol)

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
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: address zero is not a valid owner");
        return _balances[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
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
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        _requireMinted(tokenId);

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
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
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        _requireMinted(tokenId);

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner or approved");

        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
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
    ) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner or approved");
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
        require(_checkOnERC721Received(from, to, tokenId, data), "ERC721: transfer to non ERC721Receiver implementer");
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
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        address owner = ERC721.ownerOf(tokenId);
        return (spender == owner || isApprovedForAll(owner, spender) || getApproved(tokenId) == spender);
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

        _beforeTokenTransfer(address(0), to, tokenId);

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

        _afterTokenTransfer(address(0), to, tokenId);
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

        _beforeTokenTransfer(owner, address(0), tokenId);

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

        _afterTokenTransfer(owner, address(0), tokenId);
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
        require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer from incorrect owner");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        // Check that tokenId was not transferred by `_beforeTokenTransfer` hook
        require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer from incorrect owner");

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

        _afterTokenTransfer(from, to, tokenId);
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
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, data) returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
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
     * @dev Hook that is called before any (single) token transfer. This includes minting and burning.
     * See {_beforeConsecutiveTokenTransfer}.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}

    /**
     * @dev Hook that is called after any (single) transfer of tokens. This includes minting and burning.
     * See {_afterConsecutiveTokenTransfer}.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}

    /**
     * @dev Hook that is called before consecutive token transfers.
     * Calling conditions are similar to {_beforeTokenTransfer}.
     *
     * The default implementation include balances updates that extensions such as {ERC721Consecutive} cannot perform
     * directly.
     */
    function _beforeConsecutiveTokenTransfer(
        address from,
        address to,
        uint256, /*first*/
        uint96 size
    ) internal virtual {
        if (from != address(0)) {
            _balances[from] -= size;
        }
        if (to != address(0)) {
            _balances[to] += size;
        }
    }

    /**
     * @dev Hook that is called after consecutive token transfers.
     * Calling conditions are similar to {_afterTokenTransfer}.
     */
    function _afterConsecutiveTokenTransfer(
        address, /*from*/
        address, /*to*/
        uint256, /*first*/
        uint96 /*size*/
    ) internal virtual {}
}

// File: thewall.sol

/*
This file is part of the TheWall project.

The TheWall Contract is free software: you can redistribute it and/or
modify it under the terms of the GNU lesser General Public License as published
by the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

The TheWall Contract is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
GNU lesser General Public License for more details.

You should have received a copy of the GNU lesser General Public License
along with the TheWall Contract. If not, see <http://www.gnu.org/licenses/>.

@author Ilya Svirin <[email protected]>
*/


pragma solidity ^0.8.0;






contract TheWall is ERC721, Ownable, IERC721Receiver
{
    using SafeMath for uint256;

    event Payment(address indexed sender, uint256 amountWei);

    event AreaCreated(uint256 indexed tokenId, address indexed owner, int256 x, int256 y, uint256 nonce, bytes32 hashOfSecret, bytes content);
    event ClusterCreated(uint256 indexed tokenId, address indexed owner, bytes content);
    event ClusterRemoved(uint256 indexed tokenId);

    event AreaAddedToCluster(uint256 indexed areaTokenId, uint256 indexed clusterTokenId, uint256 revision);
    event AreaRemovedFromCluster(uint256 indexed areaTokenId, uint256 indexed clusterTokenId, uint256 revision);

    event AreaImageChanged(uint256 indexed tokenId, bytes image);
    event ItemLinkChanged(uint256 indexed tokenId, string link);
    event ItemTagsChanged(uint256 indexed tokenId, string tags);
    event ItemTitleChanged(uint256 indexed tokenId, string title);
    event ItemContentChanged(uint256 indexed tokenId, bytes content);

    event ItemTransferred(uint256 indexed tokenId, address indexed from, address indexed to);
    event ItemForRent(uint256 indexed tokenId, uint256 priceWei, uint256 durationSeconds);
    event ItemForSale(uint256 indexed tokenId, uint256 priceWei);
    event ItemRented(uint256 indexed tokenId, address indexed tenant, uint256 finishTime);
    event ItemBought(uint256 indexed tokenId, address indexed buyer);
    event ItemReset(uint256 indexed tokenId);
    event ItemRentFinished(uint256 indexed tokenId);
    
    event ReceivedExternalNFT(uint256 indexed externalTokenId, address indexed contractAddress, address indexed owner, string tokenURI);
    event WithdrawExternalNFT(uint256 indexed externalTokenId, address indexed contractAddress, address indexed to);
    event AttachedExternalNFT(uint256 indexed externalTokenId, address indexed contractAddress, uint256 areaId);
    event DetachedExternalNFT(uint256 indexed externalTokenId, address indexed contractAddress);

    TheWallCore private _core;
    uint256     private _minterCounter;
    uint256     private _externalTokensCounter;
    string      private _base;

    struct ExternalToken
    {
        address contractAddress;
        uint256 externalTokenId;
        address owner;
        uint256 attachedAreaId;
    }

    // internalId => ExternalToken
    mapping (uint256 => ExternalToken) private _externalTokens;

    // contractAddress => externalTokenId => internalId
    mapping (address => mapping (uint256 => uint256)) private _externalTokensId;
    
    // area => internalId
    mapping (uint256 => uint256) private _attachedExternalTokens;

    constructor(address core) ERC721("TheWall", "TWG")
    {
        _core = TheWallCore(core);
        _core.setTheWall(address(this));
        setBaseURI("https://thewall.global/erc721/");
    }

    function setBaseURI(string memory baseURI) public onlyOwner
    {
        _base = baseURI;
    }
    
    function _baseURI() internal view override returns (string memory)
    {
        return _base;
    }
    
    function safeTransferFrom(address from, address to, uint256 tokenId) public override
    {
        safeTransferFrom(from, to, tokenId, "");
    }

    function transferFrom(address from, address to, uint256 tokenId) public override
    {
        require(_isApprovedOrOwner(_msgSender(), tokenId));
        _core._canBeTransferred(tokenId);
        _transfer(from, to, tokenId);
        emit ItemTransferred(tokenId, from, to);
    }

    function safeTransferFromKeepingControl(address from, address to, uint256 tokenId) public onlyOwner
    {
        safeTransferFrom(from, to, tokenId);
        _approve(from, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public override
    {
        require(_isApprovedOrOwner(_msgSender(), tokenId));
        _core._canBeTransferred(tokenId);
        _safeTransfer(from, to, tokenId, data);
        emit ItemTransferred(tokenId, from, to);
    }

    function forSale(uint256 tokenId, uint256 priceWei) public
    {
        require(_isApprovedOrOwner(_msgSender(), tokenId));
        _core._forSale(tokenId, priceWei);
        emit ItemForSale(tokenId, priceWei);
    }

    function forRent(uint256 tokenId, uint256 priceWei, uint256 durationSeconds) public
    {
        require(_isApprovedOrOwner(_msgSender(), tokenId));
        _core._forRent(tokenId, priceWei, durationSeconds);
        emit ItemForRent(tokenId, priceWei, durationSeconds);
    }

    function createCluster(bytes memory content) public returns (uint256)
    {
        address me = _msgSender();

        _minterCounter = _minterCounter.add(1);
        uint256 tokenId = _minterCounter;
        _safeMint(me, tokenId);
        _core._createCluster(tokenId, content);

        emit ClusterCreated(tokenId, me, content);
        return tokenId;
    }

    function removeCluster(uint256 tokenId) public
    {
        require(_isApprovedOrOwner(_msgSender(), tokenId));
        uint256[] memory tokens = _core._areasInCluster(tokenId);
        address clusterOwner = ownerOf(tokenId);
        for(uint i = 0; i < tokens.length; ++i)
        {
            address oldOwner = ownerOf(tokens[i]);
            if (oldOwner != clusterOwner)
            {
                uint256 token = tokens[i];
                _safeTransfer(oldOwner, clusterOwner, token, "");
            }
        }
        _core._removeCluster(tokenId);
        _burn(tokenId);
        emit ClusterRemoved(tokenId);
    }
    
    function _create(address owner, int256 x, int256 y, uint256 clusterId, uint256 nonce, bytes memory content) internal returns (uint256)
    {
        _minterCounter = _minterCounter.add(1);
        uint256 tokenId = _minterCounter;
        _safeMint(owner, tokenId);
        
        uint256 revision;
        bytes32 hashOfSecret;
        (revision, hashOfSecret) = _core._create(tokenId, x, y, clusterId, nonce, content);
        
        emit AreaCreated(tokenId, owner, x, y, nonce, hashOfSecret, content);
        if (clusterId != 0)
        {
            emit AreaAddedToCluster(tokenId, clusterId, revision);
        }
        
        return tokenId;
    }

    function create(int256 x, int256 y, uint256 clusterId, address payable referrerCandidate, uint256 nonce, bytes memory content) public payable returns (uint256)
    {
        address me = _msgSender();
        _core._canBeCreated(x, y);
        uint256 area = _create(me, x, y, clusterId, nonce, content);
        
        uint256 payValue = _core._processPaymentCreate{value: msg.value}(me, msg.value, 1, referrerCandidate);
        if (payValue > 0)
        {
            emit Payment(me, payValue);
        }

        return area;
    }

    function createMulti(int256 x, int256 y, int256 width, int256 height, address payable referrerCandidate, uint256 nonce) public payable returns (uint256)
    {
        bytes memory emptyContent;
        uint256 cluster =  createCluster(emptyContent);
        _createMulti(x, y, width, height, cluster, referrerCandidate, nonce);
        return cluster;
    }

    function createMultiNoCluster(int256 x, int256 y, int256 width, int256 height, address payable referrerCandidate, uint256 nonce) public payable
    {
        _createMulti(x, y, width, height, 0, referrerCandidate, nonce);
    }

    function _createMulti(int256 x, int256 y, int256 width, int256 height, uint256 cluster, address payable referrerCandidate, uint256 nonce) internal
    {
        address me = _msgSender();
        _core._canBeCreatedMulti(x, y, width, height);

        uint256 areasNum = 0;
        int256 i;
        int256 j;
        bytes memory emptyContent;
        for(i = 0; i < width; ++i)
        {
            for(j = 0; j < height; ++j)
            {
                if (_core._areaOnTheWall(x + i, y + j) == uint256(0))
                {
                    areasNum = areasNum.add(1);
                    _create(me, x + i, y + j, cluster, nonce, emptyContent);
                }
            }
        }

        uint256 payValue = _core._processPaymentCreate{value: msg.value}(me, msg.value, areasNum, referrerCandidate);
        if (payValue > 0)
        {
            emit Payment(me, payValue);
        }
    }

    function buy(uint256 tokenId, uint256 revision, address payable referrerCandidate) payable public
    {
        address me = _msgSender();
        address payable tokenOwner = payable(actualOwnerOf(tokenId));
        _core._buy{value: msg.value}(tokenOwner, tokenId, me, msg.value, revision, referrerCandidate);
        emit Payment(me, msg.value);
        _safeTransfer(tokenOwner, me, tokenId, "");
        emit ItemBought(tokenId, me);
        emit ItemTransferred(tokenId, tokenOwner, me);
        emit ItemReset(tokenId);
    }

    function rent(uint256 tokenId, uint256 revision, address payable referrerCandidate) payable public
    {
        address me = _msgSender();
        address payable tokenOwner = payable(actualOwnerOf(tokenId));
        uint256 rentDuration;
        rentDuration = _core._rent{value: msg.value}(tokenOwner, tokenId, me, msg.value, revision, referrerCandidate);
        emit Payment(me, msg.value);
        emit ItemRented(tokenId, me, rentDuration);
    }
    
    function rentTo(uint256 tokenId, address tenant, uint256 durationSeconds) public
    {
        require(_isApprovedOrOwner(_msgSender(), tokenId));
        uint256 rentDuration;
        rentDuration = _core._rentTo(tokenId, tenant, durationSeconds);
        emit ItemRented(tokenId, tenant, rentDuration);
    }
    
    function cancel(uint256 tokenId) public
    {
        require(_isApprovedOrOwner(_msgSender(), tokenId));
        _core._cancel(tokenId);
        emit ItemReset(tokenId);
    }
    
    function finishRent(uint256 tokenId) public
    {
        _core._finishRent(_msgSender(), tokenId);
        emit ItemRentFinished(tokenId);
    }
    
    function addToCluster(uint256 areaId, uint256 clusterId) public
    {
        uint256 revision = _core._addToCluster(_msgSender(), actualOwnerOf(areaId), ownerOf(clusterId), areaId, clusterId);
        emit AreaAddedToCluster(areaId, clusterId, revision);
    }

    function removeFromCluster(uint256 areaId, uint256 clusterId) public
    {
        address me = _msgSender();
        uint256 revision = _core._removeFromCluster(me, actualOwnerOf(areaId), ownerOf(clusterId), areaId, clusterId);
        if (ownerOf(areaId) != me)
        {
            _safeTransfer(ownerOf(areaId), me, areaId, "");
        }
        emit AreaRemovedFromCluster(areaId, clusterId, revision);
    }

    function setAttributesComplete(uint256 tokenId, bytes memory image, string memory link, string memory tags, string memory title) public
    {
        _core._setAttributesComplete(_msgSender(), actualOwnerOf(tokenId), tokenId, image, link, tags, title);
        emit AreaImageChanged(tokenId, image);
        emit ItemLinkChanged(tokenId, link);
        emit ItemTagsChanged(tokenId, tags);
        emit ItemTitleChanged(tokenId, title);
    }

    function setAttributes(uint256 tokenId, string memory link, string memory tags, string memory title) public
    {
        _core._setAttributes(_msgSender(), actualOwnerOf(tokenId), tokenId, link, tags, title);
        emit ItemLinkChanged(tokenId, link);
        emit ItemTagsChanged(tokenId, tags);
        emit ItemTitleChanged(tokenId, title);
    }

    function setImage(uint256 tokenId, bytes memory image) public
    {
        _core._setImage(_msgSender(), actualOwnerOf(tokenId), tokenId, image);
        emit AreaImageChanged(tokenId, image);
    }

    function setLink(uint256 tokenId, string memory link) public
    {
        _core._setLink(_msgSender(), actualOwnerOf(tokenId), tokenId, link);
        emit ItemLinkChanged(tokenId, link);
    }

    function setTags(uint256 tokenId, string memory tags) public
    {
        _core._setTags(_msgSender(), actualOwnerOf(tokenId), tokenId, tags);
        emit ItemTagsChanged(tokenId, tags);
    }

    function setTitle(uint256 tokenId, string memory title) public
    {
        _core._setTitle(_msgSender(), actualOwnerOf(tokenId), tokenId, title);
        emit ItemTitleChanged(tokenId, title);
    }

    function setContent(uint256 tokenId, bytes memory content) public
    {
        _core._setContent(_msgSender(), actualOwnerOf(tokenId), tokenId, content);
        emit ItemContentChanged(tokenId, content);
    }

    function setContentMulti(uint256[] memory tokens, bytes[] memory contents) public
    {
        require(tokens.length == contents.length, "TheWall: length must be equal");
        for(uint i = 0; i < tokens.length; ++i)
        {
            uint256 tokenId = tokens[i];
            bytes memory content = contents[i];
            _core._setContent(_msgSender(), actualOwnerOf(tokenId), tokenId, content);
            emit ItemContentChanged(tokenId, content);
        }
    }
    
    function buyCoupons(address payable referrerCandidate) payable public
    {
        address me = _msgSender();
        uint256 payValue = _core._buyCoupons{value: msg.value}(me, msg.value, referrerCandidate);
        if (payValue > 0)
        {
            emit Payment(me, payValue);
        }
    }
    
    receive () payable external
    {
        buyCoupons(payable(address(0)));
    }
    
    function actualOwnerOf(uint256 tokenId) public view returns (address)
    {
        uint256 clusterId = _core._clusterOf(tokenId);
        if (clusterId != 0)
        {
            tokenId = clusterId;
        }
        return ownerOf(tokenId);
    }
    
    function onERC721Received(address operator, address /*from*/, uint256 tokenId, bytes calldata /*data*/) public override returns (bytes4)
    {
        ExternalToken memory nft;
        nft.contractAddress = _msgSender();
        nft.owner = operator;
        nft.externalTokenId = tokenId;
        nft.attachedAreaId = 0;
        
        require(_externalTokensId[nft.contractAddress][tokenId] == 0, "TheWall: External NFT already exists");

        _externalTokensCounter = _externalTokensCounter.add(1);
        uint256 internalId = _externalTokensCounter;
        _externalTokens[internalId] = nft;
        _externalTokensId[nft.contractAddress][tokenId] = internalId;

        string memory uri = "";
        if (IERC165(nft.contractAddress).supportsInterface(type(IERC721Metadata).interfaceId))
        {
            uri = IERC721Metadata(nft.contractAddress).tokenURI(tokenId);
        }
        emit ReceivedExternalNFT(tokenId, nft.contractAddress, nft.owner, uri);
        return this.onERC721Received.selector;
    }
    
    function withdrawExternalNFT(uint256 externalTokenId, address contractAddress, address to) public
    {
        uint256 internalId = _externalTokensId[contractAddress][externalTokenId];
        require(internalId != 0, "TheWall: No external token found");
        ExternalToken storage nft = _externalTokens[internalId];
        if (nft.attachedAreaId != 0)
        {
            _core._isOrdinaryArea(nft.attachedAreaId);
            require(actualOwnerOf(nft.attachedAreaId) == _msgSender(), "TheWall: Permission denied");
            delete _attachedExternalTokens[nft.attachedAreaId];
        }
        else
        {
            require(nft.owner == _msgSender(), "TheWall: Permission denied");
        }
        delete _externalTokens[internalId];
        delete _externalTokensId[contractAddress][externalTokenId];
        IERC721(contractAddress).safeTransferFrom(address(this), to, externalTokenId);
        emit WithdrawExternalNFT(externalTokenId, contractAddress, to);
    }
    
    function ownerWithdrawExternalNFT(uint256 externalTokenId, address contractAddress, address to) public onlyOwner
    {
        uint256 internalId = _externalTokensId[contractAddress][externalTokenId];
        require(internalId == 0 || _externalTokens[internalId].owner == address(this), "TheWall: External token has owner");
        IERC721(contractAddress).safeTransferFrom(address(this), to, externalTokenId);
    }

    function attachExternalNFT(uint256 externalTokenId, address contractAddress, uint256 areaId) public
    {
        _core._isOrdinaryArea(areaId);
        uint256 internalId = _attachedExternalTokens[areaId];
        if (internalId != 0)
        {
            ExternalToken storage pnft = _externalTokens[internalId];
            pnft.owner = actualOwnerOf(pnft.attachedAreaId);
            delete pnft.attachedAreaId;
            emit DetachedExternalNFT(pnft.externalTokenId, pnft.contractAddress);
        }
        internalId = _externalTokensId[contractAddress][externalTokenId];
        require(internalId != 0, "TheWall: No external token found");
        ExternalToken storage nft = _externalTokens[internalId];
        require(nft.attachedAreaId == 0, "TheWall: Already attached");
        require(nft.owner == _msgSender(), "TheWall: Permission denied");
        require(actualOwnerOf(areaId) == _msgSender(), "TheWall: Not owner of area");
        _attachedExternalTokens[areaId] = internalId;
        nft.attachedAreaId = areaId;
        emit AttachedExternalNFT(externalTokenId, contractAddress, areaId);
    }

    function detachExternalNFT(uint256 externalTokenId, address contractAddress) public
    {
        uint256 internalId = _externalTokensId[contractAddress][externalTokenId];
        require(internalId != 0, "TheWall: No external token found");
        ExternalToken storage nft = _externalTokens[internalId];
        require(nft.attachedAreaId != 0, "TheWall: No attached area");
        nft.owner = actualOwnerOf(nft.attachedAreaId);
        require(nft.owner == _msgSender(), "TheWall: Permission denied");
        _core._isOrdinaryArea(nft.attachedAreaId);
        delete _attachedExternalTokens[nft.attachedAreaId];
        delete nft.attachedAreaId;
        emit DetachedExternalNFT(externalTokenId, contractAddress);
    }
}

// File: github.com/OpenZeppelin/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol


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

// File: thewallstaking.sol

/*
This file is part of the TheWall project.

The TheWall Contract is free software: you can redistribute it and/or
modify it under the terms of the GNU lesser General Public License as published
by the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

The TheWall Contract is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
GNU lesser General Public License for more details.

You should have received a copy of the GNU lesser General Public License
along with the TheWall Contract. If not, see <http://www.gnu.org/licenses/>.

@author Ilya Svirin <[email protected]>
*/


pragma solidity ^0.8.0;




contract TheWallStaking is Context, IERC721Receiver, ERC223ReceivingContract
{
    event Deployed(address governance);
    event StakedToken(address indexed owner, uint256 indexed tokenId, bool areaNotCluster, uint256 areasCount);
    event UnstakedToken(address indexed owner, uint256 indexed tokenId);
    event StakedCoupons(address indexed owner, uint256 amount);
    event UnstakedCoupons(address indexed owner, uint256 amount);

    TheWall        public _thewall;
    TheWallCore    public _thewallcore;
    TheWallCoupons public _thewallcoupons;
    IERC20         public _governance;

    uint256 public constant multiplier = 10 ** 18;

    mapping (uint256 => address) public _tokens;
    mapping (address => uint256) public _coupons;
    
    constructor(
        address payable thewall,
        address         thewallcore,
        address         thewallcoupons,
        address         governance)
    {
        _thewall = TheWall(thewall);
        _thewallcore = TheWallCore(thewallcore);
        _thewallcoupons = TheWallCoupons(thewallcoupons);
        _governance = IERC20(governance);
        _thewallcore.setNickname("The Wall Staking Protocol V1");
        _thewallcore.setAvatar('\x06\x01\x55\x12\x20\xd2\xce\x9f\x0c\x43\x8a\x5b\x10\xba\x02\x0f\x02\xef\xda\xcf\x5f\xa5\x58\x39\xe1\xac\xad\xf1\x3a\x2f\x10\x83\x9b\x8a\xd7\xd0\x40');
        emit Deployed(governance);
    }

    function onERC721Received(address /*operator*/, address /*from*/, uint256 /*tokenId*/, bytes calldata /*data*/) public view override returns (bytes4)
    {
        require(_msgSender() == address(_thewall), "TheWallStaking: can receive TheWall Global tokens only");
        return this.onERC721Received.selector;
    }

    function stakeToken(uint256 tokenId) public
    {
        uint256 amount;
        bool areaNotCluster;
        (amount, areaNotCluster) = areasInside(tokenId);
        require(amount > 0, "TheWallStaking: invalid token");
        require(_governance.transfer(_msgSender(), amount * multiplier), "TheWallStaking: not enough governance tokens");
        _thewall.safeTransferFrom(_msgSender(), address(this), tokenId);
        _tokens[tokenId] = _msgSender();

        /* We need to clear the listing flags for sale or rent for an area/cluster,
         * but we have no way of knowing if it is listed for sale or for rent.
         * Using try-catch solves the problem, but results in a scary message
         * in polygonscan. Therefore, we first put the area/cluster up for sale and
         * immediately cancel the operation.
         */
        //try _thewall.cancel(tokenId) {} catch {}
        _thewall.forSale(tokenId, 0);
        _thewall.cancel(tokenId);

        emit StakedToken(_msgSender(), tokenId, areaNotCluster, amount);
    }

    function unstakeToken(uint256 tokenId) public
    {
        require(_tokens[tokenId] == _msgSender(), "TheWallStaking: not token's owner");
        uint256 amount;
        (amount, ) = areasInside(tokenId);
        require(_governance.transferFrom(_msgSender(), address(this), amount * multiplier), "TheWallStaking: can't get governance tokens back");
        _thewall.safeTransferFrom(address(this), _msgSender(), tokenId);
        delete _tokens[tokenId];
        emit UnstakedToken(_msgSender(), tokenId);
    }

    function tokenFallback(address sender, uint amount, bytes memory /*data*/) public override
    {
        require(_msgSender() == address(_thewallcoupons), "TheWallStaking: can receive TheWall Global tokens only");
        require(_governance.transfer(_msgSender(), amount * multiplier), "TheWallStaking: not enough governance tokens");
        _coupons[sender] += amount;
        emit StakedCoupons(sender, amount);
    }

    function unstakeCoupons(uint256 amount) public
    {
        require(_coupons[_msgSender()] >= amount, "TheWallStaking: not enought staked coupons");
        _coupons[_msgSender()] -= amount;
        require(_thewallcoupons.transfer(_msgSender(), amount), "TheWallStaking: not enough coupons");
        require(_governance.transferFrom(_msgSender(), address(this), amount * multiplier), "TheWallStaking: TheWallStaking: can't get governance tokens back");
        emit UnstakedCoupons(_msgSender(), amount);
    }

    function areasInside(uint256 tokenId) public view returns(uint256 amount, bool areaNotCluster)
    {
        require(_thewall.ownerOf(tokenId) == _msgSender(), "TheWallStaking: not token's owner");
        amount = _thewallcore._areasInCluster(tokenId).length;
        if (amount > 0)
        {
            areaNotCluster = false;
        }
        else
        {
            _thewallcore._isOrdinaryArea(tokenId);
            amount = 1;
            areaNotCluster = true;
        }
    }

    function setContent(uint256 tokenId, bytes memory content) public
    {
        require(_tokens[tokenId] == _msgSender(), "TheWallStaking: not token's owner");
        _thewall.setContent(tokenId, content);
    }
}