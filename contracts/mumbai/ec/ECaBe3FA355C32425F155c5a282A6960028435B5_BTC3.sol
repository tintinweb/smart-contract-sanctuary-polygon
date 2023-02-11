/**
 *Submitted for verification at polygonscan.com on 2023-02-10
*/

// SPDX-License-Identifier: UNLICENSED

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

contract BTC3 is IBTC3 {
    using String for uint256;
    using SafeMath for uint256;

    uint256 internal _totalSupply;
    uint256 internal _totalHolder;
    uint256 internal _totalWallet;

    uint256 internal _totalExchange;
    uint256 internal _totalLocking;
    uint256 internal _totalBurn;

    uint256 internal _maxCap;
    uint256 internal _nPrice;
    uint256 internal _ether_nUsd;
    uint256 internal _perYear;

    uint256 internal _secondYr;
    uint256 internal _secondMo;
    uint256 internal _nano;

    address payable internal _owner;
    address internal _contract;
    // address public usde;
    IUSD3 internal usd3;
    mapping(address => uint256) internal _balances;

    mapping(address => IStake) internal _stakings;
    mapping(address => ILock) internal _lockings;

    mapping(address => mapping(address => uint256)) internal _allowed;

    constructor() {
        _maxCap = 2000**9;
        _nano = 10**6;
        _perYear = 20;
        _secondMo = 30 * 24 * 3600;
        _secondYr = 360 * 30 * 24 * 3600;
        _owner = payable(msg.sender);
        _contract = payable(address(this));
        // _nPrice = 1000; // 1000 namo usd = 1micro usd = 0.001 usd;
        // _ether_nUsd = 1600000000; // 1600000 micro usd = 1600 usd;
    }

    function addOwner(address newOwner) public isOwner {
        require(address(newOwner) == newOwner, "can't add not address");
        require(isContract(newOwner) == false, "Can't add contract");
        _owner = payable(newOwner);
    }

    function addToken(address contract_) public isOwner {
        require(isContract(contract_), "can't set not contract");
        require(address(usd3) == address(0), "contract have already");
        usd3 = IUSD3(contract_);
    }

    function addConfig(
        uint256 btc3_nanoUSD,
        uint256 ether_nanoUSD,
        uint256 percent_Year
    ) public isOwner {
        _ether_nUsd = ether_nanoUSD;
        _nPrice = btc3_nanoUSD;
        _perYear = percent_Year;
    }

    function maxCap() external view returns (uint256) {
        return _maxCap;
    }

    function totalExchange() external view returns (uint256) {
        return _totalExchange;
    }

    function totalHolder() external view returns (uint256) {
        return _totalHolder;
    }

    function totalWallet() external view returns (uint256) {
        return _totalWallet;
    }

    function locker(address wallet) public view returns (ILock memory) {
        return _lockings[wallet];
    }

    function earnStake(address wallet, uint256 month_) public {
        IStake memory staker_ = usd3.staker(wallet);
        // (uint256 earned_, uint256 amountSpon_) = _calculate(wallet);
        (uint256 earned_, uint256 monthing_) = _rewar(wallet);
        (uint256 amountSpon_, ) = _rewar(staker_.sponsor);

        // uint256 monthing_ = staker_.stakeMonth;
        uint256 m_ = month_ >= monthing_ ? month_ : monthing_;

        address sponsor_ = staker_.sponsor;
        bool staked_ = usd3.stakeFrom(sponsor_, wallet, 0, m_);
        require(staked_ == true, "error update stake");

        _transfer(address(0), wallet, earned_);
        _transfer(address(0), sponsor_, amountSpon_);
    }

    function lockeFrom(
        address wallet_,
        uint256 amount_,
        uint256 month
    ) public isOwner {
        require(_balance(wallet_) >= amount_, scan(wallet_));
        _totalLocking += amount_;
        _lockings[wallet_].lockMonth = month;
        _lockings[wallet_].unLockAt = block.timestamp + month * _secondMo;
        _lockings[wallet_].amount += amount_;
        emit Lock(_lockings[wallet_]);
    }

    function unLockFrom(address wallet_, uint256 amount_) public isOwner {
        uint256 locked_ = _lockings[wallet_].amount;
        require(locked_ >= amount_, scan(wallet_));
        _lockings[wallet_].amount -= amount_;
        emit Lock(_lockings[wallet_]);
    }

    function lock(uint256 amount, uint256 month) public {
        require(_balance(msg.sender) >= amount && amount > 0, scan(msg.sender));

        _totalLocking += amount;

        _lockings[msg.sender].lockMonth = month;
        _lockings[msg.sender].unLockAt = block.timestamp + month; // * 30 * 24 *3600
        _lockings[msg.sender].amount += amount;

        emit Lock(_lockings[msg.sender]);
    }

    function unLock() public {
        uint256 locked_ = _lockings[msg.sender].amount;
        uint256 unLockAt_ = _lockings[msg.sender].unLockAt;
        // require(locked_ > 0, scan(msg.sender));
        bool canUnlock_ = locked_ > 0 && unLockAt_ < block.timestamp;
        require(canUnlock_, scan(msg.sender));

        _totalLocking -= locked_;

        _lockings[msg.sender].amount = 0;
        _lockings[msg.sender].lockMonth = 0;
        _lockings[msg.sender].unLockAt = 0;

        emit Lock(_lockings[msg.sender]);
        delete _lockings[msg.sender];
    }

    function contractOf() public view returns (address) {
        return address(usd3);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    function name() public pure returns (string memory) {
        return "Bitcoin Web3";
    }

    function symbol() public pure returns (string memory) {
        return "BTC3";
    }

    function decimals() public pure returns (uint256) {
        return 18;
    }

    function rewars() public view returns (uint256) {
        uint256 supply_ = _maxCap - _totalSupply;
        return (supply_ * _perYear) / _secondYr / 100;
    }

    function price() public view returns (uint256) {
        return _nPrice;
        // _nPrice / decimails() = price usd;
        // 1usd  = _nPrice * decimails();
    }

    function staker(address wallet) public view returns (IStake memory) {
        return usd3.staker(wallet);
        // return _stakings[staker_];
    }

    function stake(
        address sponsor,
        uint256 usd,
        uint256 month
    ) public isConnect {
        require(usd3.balance(msg.sender) >= usd, usd3.scan(msg.sender));
        usd3.stakeFrom(sponsor, msg.sender, usd, month);
    }

    function unStake(uint256 month) public isConnect {
        // earning(msg.sender);
        // check time unStake;
        earnStake(msg.sender, month);
        usd3.unStakeFrom(msg.sender);
    }

    function usdToBtc(uint256 usd) public isConnect returns (bool) {
        uint256 btc3_ = _usdToBtc(usd);

        require(usd3.balance(msg.sender) >= usd, usd3.scan(msg.sender));
        uint256 total_ = _totalSupply + btc3_;
        require(total_ <= _maxCap, "Max cap");

        bool isBurn_ = usd3.burnFrom(msg.sender, usd);
        require(isBurn_ == true, "Can't burn usd");

        if (_totalBurn >= btc3_) {
            _totalBurn -= btc3_;
        }
        return _transfer(address(this), msg.sender, btc3_);

        // _balances[msg.sender] += usd_;
        // _totalSupply += usd_;
        // emit Transfer(address(0), msg.sender, usd_);

        // if (_balances[address(this)] == 0) {
        //     _transfer(address(this), msg.sender, btc3_);
        // } else {
        //     _transfer(address(this), msg.sender, btc3_);
        // }
    }

    function btcToUsd(uint256 amount) public isConnect returns (bool) {
        require(_balance(msg.sender) >= amount, scan(msg.sender));
        uint256 usd_ = _btcToUsd(amount); // / 10 ** decimals();
        require(usd_ > 0, "can't mint zero");
        bool isMint = usd3.mintFrom(msg.sender, usd_) == true;
        require(isMint == true, "Error mint usd");
        // _balances[msg.sender] -= amount;
        // _totalSupply -= amount;
        // emit Transfer(msg.sender, address(0), amount);
        // _burn(msg.sender, amount);
        return _transfer(msg.sender, address(this), amount);
    }

    function isContract(address wallet) internal view returns (bool) {
        return wallet.code.length > 0;
    }

    //// public get information

    function totalBurn() public view returns (uint256) {
        return _totalBurn;
    }

    function supply() public view returns (uint256) {
        return _totalSupply - _totalLocking;
    }

    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    function totalStaking() public view returns (uint256) {
        return usd3.totalStaking();
    }

    function totalLocking() public view returns (uint256) {
        return _totalLocking;
    }

    function balanceOf(address wallet_) public view returns (uint256) {
        return _balances[wallet_];
    }

    function balance(address wallet) public view returns (uint256) {
        return _balance(wallet);
    }

    function coinOf(address wallet) public view returns (uint256) {
        return address(wallet).balance;
    }

    function transfer(address to, uint256 amount) public returns (bool) {
        string memory note_ = "Can't transfer to other contract";
        require(address(to) != address(usd3), note_);
        require(_balance(msg.sender) >= amount && amount > 0, scan(msg.sender));

        if (to == _contract) {
            return withdrawCoin(_coinToUsd3(amount));
        }

        _transfer(msg.sender, to, amount);
        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool) {
        string memory note_ = "Can't transfer to other contract";
        require(address(to) != address(usd3), note_);

        require(amount > 0, "can't transfer zero");
        require(to != _contract, "Can't send to the contract");
        string memory str1 = "exceed the remaining limit";
        require(_allowed[from][msg.sender] >= amount, str1);
        require(_balance(from) >= amount, scan(msg.sender));

        _transfer(from, to, amount);
        _allowed[from][msg.sender] -= amount; // on total approved
        emit Approval(from, msg.sender, allowance(from, msg.sender) - amount);
        return true;
    }

    function approve(address spender, uint256 amount)
        external
        isWallet(spender)
        returns (bool)
    {
        require(_balance(msg.sender) >= amount, scan(msg.sender));
        string memory note_ = "please approve for other address your";
        require(spender != msg.sender, note_);

        _allowed[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function scan(address wallet) public view returns (string memory) {
        return _scan(wallet);
    }

    // function _toString(uint256 number) internal pure returns (string memory) {
    //     return string(abi.encodePacked(number.toString()));
    // }

    // function wrapUsd3(uint256 amount_btc) external returns (bool) {
    //     // contract btc             contract usd
    //     // uint256 balanceUsd = balanceOf(msg.sender);
    //     // uint256 balanceUsd = usd3.balanceOf(msg.sender);

    //     string memory str_ = " not authority for wrap from btc";
    //     string memory gtk = string(abi.encodePacked(usd3.contractOf(), str_));
    //     require(address(this) == usd3.contractOf(), gtk); // msg.sender address

    //     require(_balances[msg.sender] >= amount_btc, "Not balance btc");
    //     require(amount_btc >= 100, "Not balance btc");
    //     bool isMount = usd3.mintFrom(msg.sender, amount_btc / 100) == true;
    //     require(isMount, "Error tokenMint usd");
    //     // burn(amount_btc);
    //     _burn(msg.sender, amount_btc);

    //     return true;
    // }

    function mint(address to, uint256 amount) public isOwner returns (bool) {
        uint256 total_ = _totalSupply + amount;
        require(total_ <= _maxCap, "Max cap");
        return _transfer(address(0), to, amount);
        // return _mintTo(to, amount);
    }

    function burn(uint256 amount) public returns (bool) {
        require(_balance(msg.sender) >= amount, scan(msg.sender));

        // _burn(msg.sender, amount);
        _transfer(msg.sender, address(4), amount);
        return true;
    }

    function withdrawCoin(uint256 ethers) public payable returns (bool) {
        uint256 amount = _ethToBtc3(ethers);
        string memory str2 = _contract.balance.toString();
        string memory str = string(abi.encodePacked("max ether: ", str2));
        require(_balance(msg.sender) >= amount, scan(msg.sender));
        require(_contract.balance >= ethers, str);

        // FROM address(this); to msg.sender or to wallet
        bool sent_ = payable(msg.sender).send(ethers);
        require(sent_, "failed to withdraw ether");
        emit Withdraw(msg.sender, ethers);
        return _transfer(msg.sender, address(0), amount);
    }

    function depositCoin() public payable returns (bool) {
        (bool sent_, ) = _contract.call{value: msg.value}(""); // working with contract wallet
        require(sent_, "etherToContract: Failed to send Ether");
        emit Deposit(msg.sender, msg.value);
        return _transfer(address(0), msg.sender, _ethToBtc3(msg.value));
    }

    function allowance(address from, address spender)
        public
        view
        returns (uint256)
    {
        return _allowed[from][spender];
    }

    ////////// INTERNAL ///////////

    function _plus(string memory string_, uint256 number)
        internal
        pure
        returns (string memory)
    {
        return string(abi.encodePacked(string_, number.toString()));
    }

    function _bonus(uint256 month_) internal pure returns (uint256) {
        if (month_ == 1) {
            return 50;
        } else if (month_ == 6) {
            return 75;
        } else if (month_ == 12) {
            return 100;
        } else if (month_ == 24) {
            return 180;
        } else if (month_ == 36) {
            return 300;
        } else if (month_ == 60) {
            return 400;
        }
        return 0;
    }

    function _rewar(address wallet) internal view returns (uint256, uint256) {
        uint256 totalStaking_ = usd3.totalStaking();
        IStake memory staker_ = usd3.staker(wallet);

        uint256 amount_ = staker_.amount;
        uint256 seconds_ = block.timestamp - staker_.updateAt;

        uint256 supply_ = _maxCap - _totalSupply;

        uint256 numerator = supply_ * amount_ * seconds_ * _perYear;
        uint256 denominator = totalStaking_ * _secondYr * 100;

        return (numerator / denominator, staker_.stakeMonth);
    }

    function _balance(address wallet) internal view returns (uint256) {
        uint256 staking_ = _stakings[wallet].amount;
        uint256 locking_ = _lockings[wallet].amount;
        return _balances[wallet] - locking_ - staking_;
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
            _totalBurn += amount;
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

    function _usdToBtc(uint256 amount) internal view returns (uint256) {
        return (amount * _nano) / _nPrice;
    }

    function _btcToUsd(uint256 amount) internal view returns (uint256) {
        return (amount * _nPrice) / _nano;
    }

    function _ethToBtc3(uint256 amount) internal view returns (uint256) {
        // ether => usd => btc3
        // usd = amount * _ether_nUsd / 1000
        //
        // uint256 usd3_ = amount * _ether_nUsd / _nano;
        // uint256 btc3_ = _usdToBtc(usd3_);

        return _usdToBtc((amount * _ether_nUsd) / _nano);
    }

    function _btc3ToEth(uint256 amount) internal view returns (uint256) {
        // ok done
        // 2000 btc3 price 0.001 usd
        // 2000 * (_nPrice / 1000) / (_ether_nUsd / 1000)
        // 2000 *
        uint256 usd3_ = (amount * _nPrice) / _nano;
        // uint256 ether_ = usd3_ * _nano / _nPrice;
        return (usd3_ * _nano) / _nPrice;
    }

    function _coinToUsd3(uint256 ethers) internal view returns (uint256) {
        uint256 usd3_ = (ethers / _ether_nUsd);

        return usd3_;
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
        string memory unStakeAt_ = _plus(", unStakeAt: ", unStakekAt_);

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
                    unStakeAt_,
                    dcm_,
                    "}"
                )
            );
    }

    modifier isConnect() {
        address addr_ = usd3.contractOf();
        string memory ncn_ = " not connected ";
        string memory gtk = string(abi.encodePacked(addr_, ncn_, _contract));
        require(address(this) == addr_, gtk);
        _;
    }

    modifier isWallet(address wallet) {
        string memory note_ = "can't use address zero";
        require(wallet != address(0), note_);
        _;
    }

    modifier isOwner() {
        require(_owner == msg.sender, "not authorized");
        _;
    }

    fallback() external payable {}

    receive() external payable {}
}