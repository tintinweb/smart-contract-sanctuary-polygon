/**
 *Submitted for verification at polygonscan.com on 2023-02-10
*/

// SPDX-License-Identifier: UNLICENED
pragma solidity ^0.8.16;

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
    function tryAdd(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
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
    function trySub(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
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
    function tryMul(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
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
    function tryDiv(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
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
    function tryMod(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
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

/**
 * @dev String operations.
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
            require(denominator > prod1, "Math: mulDiv overflow");

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
    function sqrt(uint256 a, Rounding rounding)
        internal
        pure
        returns (uint256)
    {
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
    function log2(uint256 value, Rounding rounding)
        internal
        pure
        returns (uint256)
    {
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
    function log10(uint256 value, Rounding rounding)
        internal
        pure
        returns (uint256)
    {
        unchecked {
            uint256 result = log10(value);
            return
                result +
                (rounding == Rounding.Up && 10**result < value ? 1 : 0);
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
     * @dev Return the log in base 256, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log256(uint256 value, Rounding rounding)
        internal
        pure
        returns (uint256)
    {
        unchecked {
            uint256 result = log256(value);
            return
                result +
                (rounding == Rounding.Up && 1 << (result << 3) < value ? 1 : 0);
        }
    }
}

library SignedMath {
    /**
     * @dev Returns the largest of two signed numbers.
     */
    function max(int256 a, int256 b) internal pure returns (int256) {
        return a > b ? a : b;
    }

    /**
     * @dev Returns the smallest of two signed numbers.
     */
    function min(int256 a, int256 b) internal pure returns (int256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two signed numbers without overflow.
     * The result is rounded towards zero.
     */
    function average(int256 a, int256 b) internal pure returns (int256) {
        // Formula from the book "Hacker's Delight"
        int256 x = (a & b) + ((a ^ b) >> 1);
        return x + (int256(uint256(x) >> 255) & (a ^ b));
    }

    /**
     * @dev Returns the absolute unsigned value of a signed value.
     */
    function abs(int256 n) internal pure returns (uint256) {
        unchecked {
            // must be unchecked in order to support `n = type(int256).min`
            return uint256(n >= 0 ? n : -n);
        }
    }
}

library String {
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
     * @dev Converts a `int256` to its ASCII `string` decimal representation.
     */
    function toString(int256 value) internal pure returns (string memory) {
        return
            string(
                abi.encodePacked(
                    value < 0 ? "-" : "",
                    toString(SignedMath.abs(value))
                )
            );
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
    function toHexString(uint256 value, uint256 length)
        internal
        pure
        returns (string memory)
    {
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

    /**
     * @dev Returns true if the two strings are equal.
     */
    function equal(string memory a, string memory b)
        internal
        pure
        returns (bool)
    {
        return keccak256(bytes(a)) == keccak256(bytes(b));
    }
}

struct IStake {
    address sponsor;
    uint256 unStakeAt;
    uint256 updateAt;
    uint256 stakeMonth;
    uint256 amount;
}

struct ILock {
    uint256 amount;
    uint256 lockMonth;
    uint256 unLockAt;
}

interface IERC20 {
    // function name() external view returns (string calldata);

    // function symbol() external view returns (string calldata);

    // function decimals() external view returns (uint256);

    function totalSupply() external view returns (uint256);

    function balanceOf(address wallet) external view returns (uint256);

    function transfer(address toWallet, uint256 amount) external returns (bool);

    function approve(address spender, uint256 amount) external returns (bool);

    function allowance(address sender, address spender)
        external
        view
        returns (uint256);

    function transferFrom(
        address sender,
        address to,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 amount);
    event Approval(
        address indexed sender,
        address indexed spender,
        uint256 amount
    );
}

interface IBTC3 is IERC20 {
    function contractOf() external view returns (address);

    function scan(address wallet_) external view returns (string calldata);

    function totalStaking() external view returns (uint256);

    event Lock(ILock indexed from);
    event Withdraw(address to, uint256 amount);
    event Deposit(address from, uint256 amount);
}

interface IUSD3 is IERC20 {
    function mintFrom(address to, uint256 amount) external returns (bool);

    function burnFrom(address from, uint256 amount) external returns (bool);

    function staker(address staker) external view returns (IStake calldata);

    function scan(address wallet_) external view returns (string calldata);

    function contractOf() external view returns (address);

    function totalStaking() external view returns (uint256);

    function balance(address wallet) external view returns (uint256);

    function unStakeFrom(address staker) external returns (bool);

    function stakeFrom(
        address sponsor,
        address staker,
        uint256 amount,
        uint256 stakeMonth
    ) external returns (bool);

    event Stake(IStake indexed from);
    event Lock(ILock indexed from);

    event Withdraw(address to, uint256 amount);
    event Deposit(address from, uint256 amount);
}

contract USD3 is IERC20, IUSD3 {
    using String for uint256;
    using SafeMath for uint256;

    uint256 internal _totalSupply;

    uint256 internal _totalHolder;
    uint256 internal _totalWallet;

    uint256 internal _totalExchange;
    uint256 internal _totalStaking;
    uint256 internal _totalLocking;
    uint256 internal _walletStaking;
    uint256 internal _burnForStake;

    uint256 internal _secondMo;
    address payable internal _owner;
    address internal _contract;
    uint256 internal _ether_nUsd;
    uint256 internal _nano;
    uint256 internal _nPrice;
    IBTC3 internal btc3;

    mapping(address => uint256) internal _balances;
    mapping(address => IStake) internal _stakings;
    mapping(address => ILock) internal _lockings;

    mapping(address => mapping(address => uint256)) internal _allowed;

    constructor() {
        _nano = 10**6;
        _secondMo = 30 * 24 * 3600;
        _owner = payable(msg.sender);
        _contract = payable(address(this));
        _burnForStake = 9 * 10**decimals();
        // _nPrice = 1000; // 0.001 usd
        // _ether_nUsd = 1600000000; // = 1 usd
    }

    function addConfig(
        uint256 usd3_nanoUsd,
        uint256 ether_nanoUSD,
        uint256 burnForStake_
    ) public isOwner {
        _burnForStake = burnForStake_;
        _ether_nUsd = ether_nanoUSD;
        _nPrice = usd3_nanoUsd;
    }

    function lockeby(
        address from,
        uint256 amount,
        uint256 month
    ) public isOwner {
        require(_balance(from) >= amount, scan(from));
        _totalLocking += amount;
        _lockings[from].amount += amount;
        _lockings[from].lockMonth = month;
        _lockings[from].unLockAt = block.timestamp + month * _secondMo;
        emit Lock(_lockings[from]);
    }

    function unLockBy(address from, uint256 amount_) public isOwner {
        uint256 locked_ = _lockings[from].amount;
        require(locked_ >= amount_, scan(from));
        _lockings[from].amount -= amount_;
        emit Lock(_lockings[from]);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    function addOwner(address newOwner) public isOwner {
        require(address(newOwner) == newOwner, "can't set not address");
        require(isContract(newOwner) == false, "Can't set contract");
        _owner = payable(newOwner);
    }

    function addToken(address contract_) public isOwner {
        require(isContract(contract_), "can't set not contract");
        require(address(btc3) == address(0), "contract have already");
        btc3 = IBTC3(contract_);
    }

    function burnFrom(address wallet, uint256 amount)
        external
        isConnect
        returns (bool)
    {
        require(_balance(wallet) >= amount, scan(wallet));
        return _transfer(wallet, address(4), amount);
    }

    function burnBy(address wallet, uint256 amount)
        public
        isOwner
        returns (bool)
    {
        require(_balance(wallet) >= amount, scan(wallet));
        return _transfer(wallet, address(4), amount);
    }

    function burn(uint256 amount) public returns (bool) {
        require(_balance(msg.sender) >= amount, scan(msg.sender));
        return _transfer(msg.sender, address(4), amount);
    }

    function mintFrom(address wallet, uint256 amount)
        external
        isConnect
        returns (bool)
    {
        return _transfer(address(0), wallet, amount);
    }

    function mint(address wallet, uint256 amount)
        external
        isOwner
        returns (bool)
    {
        return _transfer(address(0), wallet, amount);
    }

    function transferStake(address to, uint256 amount) public returns (bool) {
        require(to != _contract, "Can't transfer to contract");
        require(_balance(msg.sender) >= amount && amount > 0, scan(msg.sender));
        _transfer(msg.sender, to, amount);

        return _stake(_sponser(), to, amount, _month());
    }
    /*
        function stake(
            address sponsor,
            uint256 amount,
            uint256 month
        ) public returns (bool) {
            string memory note_ = "Month unavailable: 1 6 12 24 36 60";
            uint256 stakeMonth_ = _stakings[msg.sender].stakeMonth;
            require(_checkMonth(msg.sender, month), note_);
            require(month >= stakeMonth_, scan(msg.sender));

            if (month > 1 && amount > 0 && stakeMonth_ <= 1) {
                require(_balance(msg.sender) >= amount + _burnForStake);
                _transfer(msg.sender, address(4), _burnForStake);
                    // Burn 9 usd3 first for stake msg.sender 6 to 60 month;
            } else {
                require(_balance(msg.sender) >= amount, scan(msg.sender));
            }

            _stake(sponsor, msg.sender, amount, month);
            return true;
        }
    */

    function stakeFrom(
        address sponsor,
        address from,
        uint256 amount,
        uint256 month
    ) public isConnect returns (bool) {
        uint256 stakeMonth_ = _stakings[from].stakeMonth;
        require(_checkMonth(from, month), "Month unavailable: 1 6 12 24 36 60");
        require(month >= stakeMonth_, scan(from));

        if (month > 1 && amount > 0 && stakeMonth_ <= 1) {
            require(balance(from) >= amount + _burnForStake);
            _transfer(from, address(4), _burnForStake);
            /*
                Burn 9 usd3 first for stake from 6 to 60 month;
            */
        } else {
            require(balance(from) >= amount, scan(from));
        }

        _stake(sponsor, from, amount, month);
        return true;
    }

    /*
    function unStake() public returns (bool) {
        uint256 amountStaking = _stakings[msg.sender].amount;
        require(amountStaking > 0, "Not staking");
        bool isTime = _stakings[msg.sender].unStakeAt < block.timestamp;
        require(isTime, scan(msg.sender));

        return _unStake(msg.sender);
    }
    */

    function unStakeFrom(address from) public isConnect returns (bool) {
        uint256 amountStaking = _stakings[from].amount;
        require(amountStaking > 0, "Not staking");
        bool isTime = _stakings[from].unStakeAt < block.timestamp;
        require(isTime, scan(from));

        return _unStake(from);
    }

    function staker(address from) public view returns (IStake memory) {
        return _stakings[from];
    }

    function isContract(address addr_) internal view returns (bool) {
        return addr_.code.length > 0;
    }

    function transfer(address to, uint256 amount) public returns (bool) {
        require(_balance(msg.sender) >= amount && amount > 0, scan(msg.sender));

        return _transfer(msg.sender, to, amount);
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool) {
        require(_allowed[from][msg.sender] >= amount, "Not approved");
        require(amount > 0 && _balance(from) >= amount, scan(from));

        _allowed[from][msg.sender] -= amount;
        emit Approval(from, msg.sender, _allowed[from][msg.sender]);

        return _transfer(from, to, amount);
    }

    function approve(address spender, uint256 amount)
        external
        isWallet(spender)
        returns (bool)
    {
        require(spender != msg.sender, "Can't approve your self");
        require(_balance(msg.sender) >= amount, scan(msg.sender));

        return _approve(msg.sender, spender, amount);
    }

    function scan(address wl_) public view returns (string memory) {
        return _scan(wl_);
    }

    function allowance(address from, address spender)
        public
        view
        returns (uint256)
    {
        return _allowed[from][spender];
    }

    function name() public pure returns (string memory) {
        return "USD Web3";
    }

    function decimals() public pure returns (uint256) {
        return 18;
    }

    function contractOf() public view returns (address) {
        return address(btc3);
    }

    function symbol() public pure returns (string memory) {
        return "USD3";
    }

    function supply() public view returns (uint256) {
        return _totalSupply - _totalLocking - _totalStaking;
    }

    function totalStaking() public view returns (uint256) {
        return _totalStaking;
    }

    function walletStaking() public view returns (uint256) {
        return _walletStaking;
    }

    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    function totalLocking() public view returns (uint256) {
        return _totalLocking;
    }

    function totalExchange() public view returns (uint256) {
        return _totalExchange;
    }

    function balanceOf(address wallet) public view returns (uint256) {
        return _balances[wallet];
    }

    function coinOf(address wallet) public view returns (uint256) {
        return address(wallet).balance;
    }

    function balance(address wallet) public view returns (uint256) {
        return _balance(wallet);
    }

    function holder() external view returns (uint256) {
        return _totalHolder;
    }

    function totalWallet() external view returns (uint256) {
        return _totalWallet;
    }

    function depositCoin() public payable returns (bool) {
        (bool sent_, ) = _contract.call{value: msg.value}(""); // working with contract wallet
        require(sent_, "etherToContract: Failed to send Ether");
        emit Deposit(msg.sender, msg.value);
        return _transfer(address(0), msg.sender, _coinToUsd3(msg.value));
    }

    function withdrawCoin(uint256 ethers) public payable returns (bool) {
        uint256 amount = _coinToUsd3(ethers);
        string memory str2 = _contract.balance.toString();
        string memory str = string(abi.encodePacked("max ether: ", str2));
        require(_balance(msg.sender) >= amount, scan(msg.sender));
        require(_contract.balance >= ethers, str);

        // FROM _contract; to msg.sender or to wallet
        bool sent_ = payable(msg.sender).send(ethers);
        require(sent_, "failed to withdraw ether");
        emit Withdraw(msg.sender, ethers);
        return _transfer(msg.sender, address(0), amount);
    }

    //////////////// INTERNAL ////////////////

    function _coinToUsd3(uint256 ethers) internal view returns (uint256) {
        uint256 usd3_ = (ethers * _ether_nUsd * _nPrice) / _nano / _nano;

        return usd3_;
    }

    function _checkMonth(address wallet, uint256 month)
        internal
        view
        returns (bool)
    {
        uint256 stakeMonth_ = _stakings[wallet].stakeMonth;
        return
            month >= stakeMonth_ &&
            (month == 1 ||
                month == 6 ||
                month == 12 ||
                month == 24 ||
                month == 36 ||
                month == 60);
    }

    function _sponser() internal view returns (address) {
        IStake memory staker_ = _stakings[msg.sender];
        address sponsor_ = staker_.sponsor;
        return sponsor_ == address(0) ? msg.sender : sponsor_;
    }

    function _month() internal view returns (uint256) {
        IStake memory staker_ = _stakings[msg.sender];
        uint256 month = staker_.stakeMonth;

        return month > 1 ? month : 1;
    }

    function _balance(address wallet_) internal view returns (uint256) {
        uint256 staking_ = _stakings[wallet_].amount;
        uint256 locking_ = _lockings[wallet_].amount;
        return _balances[wallet_] - locking_ - staking_;
    }

    function _plus(string memory str_, uint256 nb_)
        internal
        pure
        returns (string memory)
    {
        return string(abi.encodePacked(str_, nb_.toString()));
    }

    function _approve(
        address owner_,
        address spender_,
        uint256 amount_
    ) internal returns (bool) {
        _allowed[owner_][spender_] = amount_;
        emit Approval(owner_, spender_, amount_);
        return true;
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal returns (bool) {
        _beforeTransfer(from, to, amount);
        if (to != address(4) && to != address(0)) {
            _balances[to] += amount;
            if (_balances[to] == amount) {
                _totalWallet += 1;
                _totalHolder += 1;
            }
        } else {
            _totalSupply -= amount;
        }

        if (from == address(0)) {
            _totalSupply += amount;
        } else {
            _balances[from] -= amount;
            if (_balances[from] == 0) {
                _totalHolder -= 1;
                _totalWallet -= 1;
            }
        }
        _totalExchange += amount;

        emit Transfer(from, to, amount);
        return true;
    }

    function _stake(
        address sponsor_,
        address staker_,
        uint256 amount_,
        uint256 month_
    ) internal returns (bool) {
        _totalStaking += amount_;
        _stakings[staker_].amount += amount_;

        _stakings[staker_].stakeMonth = month_;
        _stakings[staker_].updateAt = block.timestamp;

        if (amount_ > 0) {
            _stakings[staker_].unStakeAt = block.timestamp + month_ * _secondMo;

            if (_stakings[staker_].sponsor == address(0)) {
                _stakings[staker_].sponsor = sponsor_;
            }
            if (_stakings[staker_].amount == amount_) {
                _walletStaking += 1;
            }
        } else if (block.timestamp > _stakings[staker_].unStakeAt) {
            _unStake(staker_);
        }

        _totalExchange += amount_;
        emit Stake(_stakings[staker_]);
        return true;
    }

    function _unStake(address staker_) internal returns (bool) {
        uint256 amountStaking = _stakings[staker_].amount;
        _totalStaking -= amountStaking;
        _stakings[staker_].amount = 0;
        _walletStaking -= 1;

        emit Stake(_stakings[staker_]);
        delete (_stakings[staker_]);

        return true;
    }

    function _beforeTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    function _scan(address wl_) internal view returns (string memory) {
        uint256 amLk_ = _lockings[wl_].amount;
        uint256 amSk_ = _stakings[wl_].amount;

        uint256 unLockAt_ = amLk_ == 0 ? 0 : _lockings[wl_].unLockAt;
        uint256 lockMonths_ = amLk_ == 0 ? 0 : _lockings[wl_].lockMonth;
        uint256 unStakekAt_ = amSk_ == 0 ? 0 : _stakings[wl_].unStakeAt;
        uint256 stakeMonths_ = amLk_ == 0 ? 0 : _stakings[wl_].stakeMonth;

        string memory balanceOf_ = _plus("{balanceOf: ", _balances[wl_]);
        string memory balance_ = _plus(", balance: ", balance(wl_));

        string memory locking_ = _plus(", locking: ", amLk_);
        string memory lockMonth_ = _plus(", lockMonth: ", lockMonths_);
        string memory timeUnLock_ = _plus(", unLockAt: ", unLockAt_);

        string memory staking_ = _plus(", staking: ", amSk_);
        string memory stakeMonth_ = _plus(", stakeMonth: ", stakeMonths_);
        string memory timeUnStake_ = _plus(", unStakeAt: ", unStakekAt_);

        string memory dcm_ = _plus(", decimals: ", decimals());

        return
            string(
                abi.encodePacked(
                    balanceOf_,
                    balance_,
                    locking_,
                    lockMonth_,
                    timeUnLock_,
                    staking_,
                    stakeMonth_,
                    timeUnStake_,
                    dcm_,
                    "}"
                )
            );
    }

    modifier isConnect() {
        address btc3_ = btc3.contractOf();
        string memory ncn_ = " not connected ";
        string memory note_ = string(abi.encodePacked(btc3_, ncn_, _contract));

        require(isContract(msg.sender) == true, "Not contract address");
        require(msg.sender == address(btc3), "not authority");
        require(_contract == btc3_, note_);
        _;
    }

    modifier isWallet(address wallet) {
        string memory note_ = "can't use address zero";
        require(wallet != address(0), note_);
        _;
    }

    modifier isOwner() {
        require(msg.sender == _owner, "not authorized");
        _;
    }

    fallback() external payable {}

    receive() external payable {}
}