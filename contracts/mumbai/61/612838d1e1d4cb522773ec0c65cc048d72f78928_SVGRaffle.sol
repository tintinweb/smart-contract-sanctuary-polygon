// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

import "./math/Math.sol";
import "./math/SignedMath.sol";

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
     * @dev Converts a `int256` to its ASCII `string` decimal representation.
     */
    function toString(int256 value) internal pure returns (string memory) {
        return string(abi.encodePacked(value < 0 ? "-" : "", toString(SignedMath.abs(value))));
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

    /**
     * @dev Returns true if the two strings are equal.
     */
    function equal(string memory a, string memory b) internal pure returns (bool) {
        return keccak256(bytes(a)) == keccak256(bytes(b));
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
    function mulDiv(uint256 x, uint256 y, uint256 denominator) internal pure returns (uint256 result) {
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
                // Solidity will revert if denominator == 0, unlike the div opcode on its own.
                // The surrounding unchecked block does not change this fact.
                // See https://docs.soliditylang.org/en/latest/control-structures.html#checked-or-unchecked-arithmetic.
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
    function mulDiv(uint256 x, uint256 y, uint256 denominator, Rounding rounding) internal pure returns (uint256) {
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
    function log10(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log10(value);
            return result + (rounding == Rounding.Up && 10 ** result < value ? 1 : 0);
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
    function log256(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log256(value);
            return result + (rounding == Rounding.Up && 1 << (result << 3) < value ? 1 : 0);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/math/SignedMath.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard signed math utilities missing in the Solidity language.
 */
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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// ----------------------------------------------------------------------------
// DateTime Library v2.0
//
// A gas-efficient Solidity date and time library
//
// https://github.com/bokkypoobah/BokkyPooBahsDateTimeLibrary
//
// Tested date range 1970/01/01 to 2345/12/31
//
// Conventions:
// Unit      | Range         | Notes
// :-------- |:-------------:|:-----
// timestamp | >= 0          | Unix timestamp, number of seconds since 1970/01/01 00:00:00 UTC
// year      | 1970 ... 2345 |
// month     | 1 ... 12      |
// day       | 1 ... 31      |
// hour      | 0 ... 23      |
// minute    | 0 ... 59      |
// second    | 0 ... 59      |
// dayOfWeek | 1 ... 7       | 1 = Monday, ..., 7 = Sunday
//
//
// Enjoy. (c) BokkyPooBah / Bok Consulting Pty Ltd 2018-2019. The MIT Licence.
// ----------------------------------------------------------------------------

library DateTime {
    uint256 constant SECONDS_PER_DAY = 24 * 60 * 60;
    uint256 constant SECONDS_PER_HOUR = 60 * 60;
    uint256 constant SECONDS_PER_MINUTE = 60;
    int256 constant OFFSET19700101 = 2440588;

    uint256 constant DOW_MON = 1;
    uint256 constant DOW_TUE = 2;
    uint256 constant DOW_WED = 3;
    uint256 constant DOW_THU = 4;
    uint256 constant DOW_FRI = 5;
    uint256 constant DOW_SAT = 6;
    uint256 constant DOW_SUN = 7;

    // ------------------------------------------------------------------------
    // Calculate the number of days from 1970/01/01 to year/month/day using
    // the date conversion algorithm from
    //   http://aa.usno.navy.mil/faq/docs/JD_Formula.php
    // and subtracting the offset 2440588 so that 1970/01/01 is day 0
    //
    // days = day
    //      - 32075
    //      + 1461 * (year + 4800 + (month - 14) / 12) / 4
    //      + 367 * (month - 2 - (month - 14) / 12 * 12) / 12
    //      - 3 * ((year + 4900 + (month - 14) / 12) / 100) / 4
    //      - offset
    // ------------------------------------------------------------------------
    function _daysFromDate(uint256 year, uint256 month, uint256 day) internal pure returns (uint256 _days) {
        require(year >= 1970);
        int256 _year = int256(year);
        int256 _month = int256(month);
        int256 _day = int256(day);

        int256 __days = _day - 32075 + (1461 * (_year + 4800 + (_month - 14) / 12)) / 4
            + (367 * (_month - 2 - ((_month - 14) / 12) * 12)) / 12
            - (3 * ((_year + 4900 + (_month - 14) / 12) / 100)) / 4 - OFFSET19700101;

        _days = uint256(__days);
    }

    // ------------------------------------------------------------------------
    // Calculate year/month/day from the number of days since 1970/01/01 using
    // the date conversion algorithm from
    //   http://aa.usno.navy.mil/faq/docs/JD_Formula.php
    // and adding the offset 2440588 so that 1970/01/01 is day 0
    //
    // int L = days + 68569 + offset
    // int N = 4 * L / 146097
    // L = L - (146097 * N + 3) / 4
    // year = 4000 * (L + 1) / 1461001
    // L = L - 1461 * year / 4 + 31
    // month = 80 * L / 2447
    // dd = L - 2447 * month / 80
    // L = month / 11
    // month = month + 2 - 12 * L
    // year = 100 * (N - 49) + year + L
    // ------------------------------------------------------------------------
    function _daysToDate(uint256 _days) internal pure returns (uint256 year, uint256 month, uint256 day) {
        unchecked {
            int256 __days = int256(_days);

            int256 L = __days + 68569 + OFFSET19700101;
            int256 N = (4 * L) / 146097;
            L = L - (146097 * N + 3) / 4;
            int256 _year = (4000 * (L + 1)) / 1461001;
            L = L - (1461 * _year) / 4 + 31;
            int256 _month = (80 * L) / 2447;
            int256 _day = L - (2447 * _month) / 80;
            L = _month / 11;
            _month = _month + 2 - 12 * L;
            _year = 100 * (N - 49) + _year + L;

            year = uint256(_year);
            month = uint256(_month);
            day = uint256(_day);
        }
    }

    function timestampFromDate(uint256 year, uint256 month, uint256 day) internal pure returns (uint256 timestamp) {
        timestamp = _daysFromDate(year, month, day) * SECONDS_PER_DAY;
    }

    function timestampFromDateTime(
        uint256 year,
        uint256 month,
        uint256 day,
        uint256 hour,
        uint256 minute,
        uint256 second
    )
        internal
        pure
        returns (uint256 timestamp)
    {
        timestamp = _daysFromDate(year, month, day) * SECONDS_PER_DAY + hour * SECONDS_PER_HOUR
            + minute * SECONDS_PER_MINUTE + second;
    }

    function timestampToDate(uint256 timestamp) internal pure returns (uint256 year, uint256 month, uint256 day) {
        unchecked {
            (year, month, day) = _daysToDate(timestamp / SECONDS_PER_DAY);
        }
    }

    function timestampToDateTime(uint256 timestamp)
        internal
        pure
        returns (uint256 year, uint256 month, uint256 day, uint256 hour, uint256 minute, uint256 second)
    {
        unchecked {
            (year, month, day) = _daysToDate(timestamp / SECONDS_PER_DAY);
            uint256 secs = timestamp % SECONDS_PER_DAY;
            hour = secs / SECONDS_PER_HOUR;
            secs = secs % SECONDS_PER_HOUR;
            minute = secs / SECONDS_PER_MINUTE;
            second = secs % SECONDS_PER_MINUTE;
        }
    }

    function isValidDate(uint256 year, uint256 month, uint256 day) internal pure returns (bool valid) {
        if (year >= 1970 && month > 0 && month <= 12) {
            uint256 daysInMonth = _getDaysInMonth(year, month);
            if (day > 0 && day <= daysInMonth) {
                valid = true;
            }
        }
    }

    function isValidDateTime(uint256 year, uint256 month, uint256 day, uint256 hour, uint256 minute, uint256 second)
        internal
        pure
        returns (bool valid)
    {
        if (isValidDate(year, month, day)) {
            if (hour < 24 && minute < 60 && second < 60) {
                valid = true;
            }
        }
    }

    function isLeapYear(uint256 timestamp) internal pure returns (bool leapYear) {
        (uint256 year,,) = _daysToDate(timestamp / SECONDS_PER_DAY);
        leapYear = _isLeapYear(year);
    }

    function _isLeapYear(uint256 year) internal pure returns (bool leapYear) {
        leapYear = ((year % 4 == 0) && (year % 100 != 0)) || (year % 400 == 0);
    }

    function isWeekDay(uint256 timestamp) internal pure returns (bool weekDay) {
        weekDay = getDayOfWeek(timestamp) <= DOW_FRI;
    }

    function isWeekEnd(uint256 timestamp) internal pure returns (bool weekEnd) {
        weekEnd = getDayOfWeek(timestamp) >= DOW_SAT;
    }

    function getDaysInMonth(uint256 timestamp) internal pure returns (uint256 daysInMonth) {
        (uint256 year, uint256 month,) = _daysToDate(timestamp / SECONDS_PER_DAY);
        daysInMonth = _getDaysInMonth(year, month);
    }

    function _getDaysInMonth(uint256 year, uint256 month) internal pure returns (uint256 daysInMonth) {
        if (month == 1 || month == 3 || month == 5 || month == 7 || month == 8 || month == 10 || month == 12) {
            daysInMonth = 31;
        } else if (month != 2) {
            daysInMonth = 30;
        } else {
            daysInMonth = _isLeapYear(year) ? 29 : 28;
        }
    }

    // 1 = Monday, 7 = Sunday
    function getDayOfWeek(uint256 timestamp) internal pure returns (uint256 dayOfWeek) {
        uint256 _days = timestamp / SECONDS_PER_DAY;
        dayOfWeek = ((_days + 3) % 7) + 1;
    }

    function getYear(uint256 timestamp) internal pure returns (uint256 year) {
        (year,,) = _daysToDate(timestamp / SECONDS_PER_DAY);
    }

    function getMonth(uint256 timestamp) internal pure returns (uint256 month) {
        (, month,) = _daysToDate(timestamp / SECONDS_PER_DAY);
    }

    function getDay(uint256 timestamp) internal pure returns (uint256 day) {
        (,, day) = _daysToDate(timestamp / SECONDS_PER_DAY);
    }

    function getHour(uint256 timestamp) internal pure returns (uint256 hour) {
        uint256 secs = timestamp % SECONDS_PER_DAY;
        hour = secs / SECONDS_PER_HOUR;
    }

    function getMinute(uint256 timestamp) internal pure returns (uint256 minute) {
        uint256 secs = timestamp % SECONDS_PER_HOUR;
        minute = secs / SECONDS_PER_MINUTE;
    }

    function getSecond(uint256 timestamp) internal pure returns (uint256 second) {
        second = timestamp % SECONDS_PER_MINUTE;
    }

    function addYears(uint256 timestamp, uint256 _years) internal pure returns (uint256 newTimestamp) {
        (uint256 year, uint256 month, uint256 day) = _daysToDate(timestamp / SECONDS_PER_DAY);
        year += _years;
        uint256 daysInMonth = _getDaysInMonth(year, month);
        if (day > daysInMonth) {
            day = daysInMonth;
        }
        newTimestamp = _daysFromDate(year, month, day) * SECONDS_PER_DAY + (timestamp % SECONDS_PER_DAY);
        require(newTimestamp >= timestamp);
    }

    function addMonths(uint256 timestamp, uint256 _months) internal pure returns (uint256 newTimestamp) {
        (uint256 year, uint256 month, uint256 day) = _daysToDate(timestamp / SECONDS_PER_DAY);
        month += _months;
        year += (month - 1) / 12;
        month = ((month - 1) % 12) + 1;
        uint256 daysInMonth = _getDaysInMonth(year, month);
        if (day > daysInMonth) {
            day = daysInMonth;
        }
        newTimestamp = _daysFromDate(year, month, day) * SECONDS_PER_DAY + (timestamp % SECONDS_PER_DAY);
        require(newTimestamp >= timestamp);
    }

    function addDays(uint256 timestamp, uint256 _days) internal pure returns (uint256 newTimestamp) {
        newTimestamp = timestamp + _days * SECONDS_PER_DAY;
        require(newTimestamp >= timestamp);
    }

    function addHours(uint256 timestamp, uint256 _hours) internal pure returns (uint256 newTimestamp) {
        newTimestamp = timestamp + _hours * SECONDS_PER_HOUR;
        require(newTimestamp >= timestamp);
    }

    function addMinutes(uint256 timestamp, uint256 _minutes) internal pure returns (uint256 newTimestamp) {
        newTimestamp = timestamp + _minutes * SECONDS_PER_MINUTE;
        require(newTimestamp >= timestamp);
    }

    function addSeconds(uint256 timestamp, uint256 _seconds) internal pure returns (uint256 newTimestamp) {
        newTimestamp = timestamp + _seconds;
        require(newTimestamp >= timestamp);
    }

    function subYears(uint256 timestamp, uint256 _years) internal pure returns (uint256 newTimestamp) {
        (uint256 year, uint256 month, uint256 day) = _daysToDate(timestamp / SECONDS_PER_DAY);
        year -= _years;
        uint256 daysInMonth = _getDaysInMonth(year, month);
        if (day > daysInMonth) {
            day = daysInMonth;
        }
        newTimestamp = _daysFromDate(year, month, day) * SECONDS_PER_DAY + (timestamp % SECONDS_PER_DAY);
        require(newTimestamp <= timestamp);
    }

    function subMonths(uint256 timestamp, uint256 _months) internal pure returns (uint256 newTimestamp) {
        (uint256 year, uint256 month, uint256 day) = _daysToDate(timestamp / SECONDS_PER_DAY);
        uint256 yearMonth = year * 12 + (month - 1) - _months;
        year = yearMonth / 12;
        month = (yearMonth % 12) + 1;
        uint256 daysInMonth = _getDaysInMonth(year, month);
        if (day > daysInMonth) {
            day = daysInMonth;
        }
        newTimestamp = _daysFromDate(year, month, day) * SECONDS_PER_DAY + (timestamp % SECONDS_PER_DAY);
        require(newTimestamp <= timestamp);
    }

    function subDays(uint256 timestamp, uint256 _days) internal pure returns (uint256 newTimestamp) {
        newTimestamp = timestamp - _days * SECONDS_PER_DAY;
        require(newTimestamp <= timestamp);
    }

    function subHours(uint256 timestamp, uint256 _hours) internal pure returns (uint256 newTimestamp) {
        newTimestamp = timestamp - _hours * SECONDS_PER_HOUR;
        require(newTimestamp <= timestamp);
    }

    function subMinutes(uint256 timestamp, uint256 _minutes) internal pure returns (uint256 newTimestamp) {
        newTimestamp = timestamp - _minutes * SECONDS_PER_MINUTE;
        require(newTimestamp <= timestamp);
    }

    function subSeconds(uint256 timestamp, uint256 _seconds) internal pure returns (uint256 newTimestamp) {
        newTimestamp = timestamp - _seconds;
        require(newTimestamp <= timestamp);
    }

    function diffYears(uint256 fromTimestamp, uint256 toTimestamp) internal pure returns (uint256 _years) {
        require(fromTimestamp <= toTimestamp);
        (uint256 fromYear,,) = _daysToDate(fromTimestamp / SECONDS_PER_DAY);
        (uint256 toYear,,) = _daysToDate(toTimestamp / SECONDS_PER_DAY);
        _years = toYear - fromYear;
    }

    function diffMonths(uint256 fromTimestamp, uint256 toTimestamp) internal pure returns (uint256 _months) {
        require(fromTimestamp <= toTimestamp);
        (uint256 fromYear, uint256 fromMonth,) = _daysToDate(fromTimestamp / SECONDS_PER_DAY);
        (uint256 toYear, uint256 toMonth,) = _daysToDate(toTimestamp / SECONDS_PER_DAY);
        _months = toYear * 12 + toMonth - fromYear * 12 - fromMonth;
    }

    function diffDays(uint256 fromTimestamp, uint256 toTimestamp) internal pure returns (uint256 _days) {
        require(fromTimestamp <= toTimestamp);
        _days = (toTimestamp - fromTimestamp) / SECONDS_PER_DAY;
    }

    function diffHours(uint256 fromTimestamp, uint256 toTimestamp) internal pure returns (uint256 _hours) {
        require(fromTimestamp <= toTimestamp);
        _hours = (toTimestamp - fromTimestamp) / SECONDS_PER_HOUR;
    }

    function diffMinutes(uint256 fromTimestamp, uint256 toTimestamp) internal pure returns (uint256 _minutes) {
        require(fromTimestamp <= toTimestamp);
        _minutes = (toTimestamp - fromTimestamp) / SECONDS_PER_MINUTE;
    }

    function diffSeconds(uint256 fromTimestamp, uint256 toTimestamp) internal pure returns (uint256 _seconds) {
        require(fromTimestamp <= toTimestamp);
        _seconds = toTimestamp - fromTimestamp;
    }
}

// SPDX-License-Identifier: BSD-3-Clause
pragma solidity ^0.8.8;

import 'openzeppelin-contracts/contracts/utils/Strings.sol';
import {ISVGRaffle, RaffleConfig} from '../interfaces/ISVGRaffle.sol';
import {ParseUtils} from '../libs/ParseUtils.sol';
import {NumberUtils} from '../libs/NumberUtils.sol';

contract SVGRaffle is ISVGRaffle {
  function getSvg(
    string calldata _raffleId,
    string calldata _maxPrice,
    string calldata _minPrice,
    string calldata _numberTickets,
    uint256 _expiration,
    RaffleConfig.RaffleStates _state
  ) external pure returns (string memory) {
    return
      string(
        abi.encodePacked(
          _getInitial(),
          _getBody(
            _raffleId,
            _maxPrice,
            _minPrice,
            _numberTickets,
            _expiration,
            _state
          ),
          '</g></svg>'
        )
      );
  }

  function _getInitial() internal pure returns (string memory) {
    return
      '<?xml version="1.0" encoding="utf-8"?><svg viewBox="0 0 631 1014" fill="none" xmlns="http://www.w3.org/2000/svg"><defs><clipPath id="clip0_322_158"><rect width="631" height="1014" rx="50" fill="white"/></clipPath><filter id="filter0_f_322_158" x="-71.8157" y="-39.7104" width="1113.87" height="1108.2" filterUnits="userSpaceOnUse" color-interpolation-filters="sRGB"><feFlood flood-opacity="0" result="BackgroundImageFix"/><feBlend mode="normal" in="SourceGraphic" in2="BackgroundImageFix" result="shape"/><feGaussianBlur stdDeviation="197" result="effect1_foregroundBlur_322_158"/></filter><linearGradient id="paint0_linear_322_158" x1="405.075" y1="404.757" x2="799.7" y2="636.567" gradientUnits="userSpaceOnUse"><stop stop-color="#7BA49A"/><stop offset="1" stop-color="#159777"/></linearGradient><filter id="filter1_f_322_158" x="-286.441" y="-258.346" width="692.91" height="687.817" filterUnits="userSpaceOnUse" color-interpolation-filters="sRGB"><feFlood flood-opacity="0" result="BackgroundImageFix"/><feBlend mode="normal" in="SourceGraphic" in2="BackgroundImageFix" result="shape"/><feGaussianBlur stdDeviation="100" result="effect1_foregroundBlur_322_158"/></filter><linearGradient id="paint1_linear_322_158" x1="-11.9329" y1="-12.9826" x2="342.783" y2="195.384" gradientUnits="userSpaceOnUse"><stop stop-color="#7BA49A"/><stop offset="1" stop-color="#159777"/></linearGradient><clipPath id="clip1_322_158"><rect width="631" height="1014" fill="white"/></clipPath></defs><g clip-path="url(#clip0_322_158)"><rect width="631" height="1014" rx="50" fill="#040914"/><g filter="url(#filter0_f_322_158)"><ellipse cx="485.117" cy="514.389" rx="162.935" ry="160.093" transform="rotate(177.742 485.117 514.389)" fill="url(#paint0_linear_322_158)"/></g><g filter="url(#filter1_f_322_158)"><ellipse cx="60.0141" cy="85.5623" rx="146.457" ry="143.903" transform="rotate(177.742 60.0141 85.5623)" fill="url(#paint1_linear_322_158)"/></g><g style="mix-blend-mode:overlay" opacity="0.85" clip-path="url(#clip1_322_158)"/><rect x="78" y="143.75" width="11.25" height="11.25" fill="white"/><rect x="78" y="132.5" width="11.25" height="11.25" fill="white"/><rect x="78" y="121.25" width="11.25" height="11.25" fill="white"/><rect x="78" y="110" width="11.25" height="11.25" fill="white"/><rect x="89.25" y="110" width="11.25" height="11.25" fill="white"/><rect x="89.25" y="132.5" width="11.25" height="11.25" fill="white"/><rect x="100.5" y="143.75" width="11.25" height="11.25" fill="white"/><rect x="100.5" y="121.25" width="11.25" height="11.25" fill="white"/><rect x="117.375" y="143.75" width="11.25" height="11.25" fill="white"/><rect x="117.375" y="132.5" width="11.25" height="11.25" fill="white"/><rect x="117.375" y="121.25" width="11.25" height="11.25" fill="white"/><rect x="117.375" y="110" width="11.25" height="11.25" fill="white"/><rect x="128.625" y="110" width="11.25" height="11.25" fill="white"/><rect x="128.625" y="132.5" width="11.25" height="11.25" fill="white"/><rect x="139.875" y="132.5" width="11.25" height="11.25" fill="white"/><rect x="139.875" y="143.75" width="11.25" height="11.25" fill="white"/><rect x="139.875" y="121.25" width="11.25" height="11.25" fill="white"/><rect x="139.875" y="110" width="11.25" height="11.25" fill="white"/><rect x="156.75" y="143.75" width="11.25" height="11.25" fill="white"/><rect x="156.75" y="132.5" width="11.25" height="11.25" fill="white"/><rect x="156.75" y="121.25" width="11.25" height="11.25" fill="white"/><rect x="156.75" y="110" width="11.25" height="11.25" fill="white"/><rect x="168" y="110" width="11.25" height="11.25" fill="white"/><rect x="168" y="132.5" width="11.25" height="11.25" fill="white"/><rect x="179.25" y="110" width="11.25" height="11.25" fill="white"/><rect x="196.125" y="143.75" width="11.25" height="11.25" fill="white"/><rect x="196.125" y="132.5" width="11.25" height="11.25" fill="white"/><rect x="196.125" y="121.25" width="11.25" height="11.25" fill="white"/><rect x="196.125" y="110" width="11.25" height="11.25" fill="white"/><rect x="207.375" y="110" width="11.25" height="11.25" fill="white"/><rect x="207.375" y="132.5" width="11.25" height="11.25" fill="white"/><rect x="218.625" y="110" width="11.25" height="11.25" fill="white"/><rect width="11.25" height="11.25" transform="matrix(1 0 0 -1 235.5 121.25)" fill="white"/><rect width="11.25" height="11.25" transform="matrix(1 0 0 -1 235.5 132.5)" fill="white"/><rect width="11.25" height="11.25" transform="matrix(1 0 0 -1 235.5 143.75)" fill="white"/><rect width="11.25" height="11.25" transform="matrix(1 0 0 -1 235.5 155)" fill="white"/><rect width="11.25" height="11.25" transform="matrix(1 0 0 -1 246.75 155)" fill="white"/><rect width="11.25" height="11.25" transform="matrix(1 0 0 -1 258 155)" fill="white"/><rect x="274.875" y="121.25" width="11.25" height="11.25" fill="white"/><rect x="274.875" y="110" width="11.25" height="11.25" fill="white"/><rect x="286.125" y="132.5" width="11.25" height="11.25" fill="white"/><rect x="286.125" y="143.75" width="11.25" height="11.25" fill="white"/><rect x="297.375" y="121.25" width="11.25" height="11.25" fill="white"/><rect x="297.375" y="110" width="11.25" height="11.25" fill="white"/><path style="mix-blend-mode:overlay"/><g style="mix-blend-mode:overlay"><rect x="74" y="196" width="140" height="40" rx="15" fill="black" fill-opacity="0.6"/></g><g style="mix-blend-mode:overlay"><rect x="74" y="333" width="140" height="40" rx="15" fill="black" fill-opacity="0.6"/></g><g style="mix-blend-mode:overlay"><rect x="74" y="471" width="245" height="40" rx="15" fill="black" fill-opacity="0.6"/></g><g style="mix-blend-mode:overlay"><rect x="74" y="580" width="213" height="40" rx="15" fill="black" fill-opacity="0.6"/></g><g style="mix-blend-mode:overlay"><rect x="74" y="689" width="88" height="40" rx="15" fill="black" fill-opacity="0.6"/></g><rect x="41.5" y="41.5" width="548" height="931" rx="48.5" stroke="white" stroke-width="3"/><text style="fill: rgb(255, 255, 255); font-family: Arial, sans-serif; font-size: 20.2px; font-weight: 700; white-space: pre;" x="85.211" y="222.372">MAX PRICE</text><text style="fill: rgb(255, 255, 255); font-family: Arial, sans-serif; font-size: 20.2px; font-weight: 700; white-space: pre;" x="85.211" y="359.031">MIN PRICE</text><text style="fill: rgb(255, 255, 255); font-family: Arial, sans-serif; font-size: 20.2px; font-weight: 700; white-space: pre;" x="85.211" y="499.553">NUMBER OF TICKETS</text><text style="fill: rgb(255, 255, 255); font-family: Arial, sans-serif; font-size: 20.2px; font-weight: 700; white-space: pre;" x="85.211" y="606.873">EXPIRATION DATE</text><text style="fill: rgb(255, 255, 255); font-family: Arial, sans-serif; font-size: 20.2px; font-weight: 700; white-space: pre;" x="85.211" y="716.11">STATE</text>';
  }

  function _getText(string memory y, string memory value)
    internal
    pure
    returns (string memory)
  {
    return
      string(
        abi.encodePacked(
          '<text style="fill: rgb(255, 255, 255); font-family: Arial, sans-serif; font-size: 34px; white-space: pre;" x="82.438" y="',
          y,
          '">',
          value,
          '</text>'
        )
      );
  }

  function _getBubble(RaffleConfig.RaffleStates _state)
    internal
    pure
    returns (string memory)
  {
    return
      RaffleConfig.RaffleStates.ACTIVE == _state
        ? ' <circle cx="205.017" cy="763.741" r="7" fill="#8FFF00"/>'
        : ' <circle cx="205.017" cy="763.741" r="7" style="fill: rgb(255, 0, 0);"/>';
  }

  function _getStaticBody(
    string calldata _raffleId,
    string calldata _maxPrice,
    string calldata _minPrice,
    string calldata _numberTickets
  ) internal pure returns (string memory) {
    return
      string(
        abi.encodePacked(
          _getText('295.936', _maxPrice),
          _getText('435.529', _minPrice),
          _getText('558.104', _numberTickets),
          _getText('1002.084', _raffleId)
        )
      );
  }

  function _getDynamicBody(
    uint256 _expiration,
    RaffleConfig.RaffleStates _state
  ) internal pure returns (string memory) {
    return
      string(
        abi.encodePacked(
          _getText('671.562', ParseUtils._parseTimestamp(_expiration)),
          _getText('776.286', ParseUtils._parseState(_state)),
          _getBubble(_state)
        )
      );
  }

  function _getBody(
    string calldata _raffleId,
    string calldata _maxPrice,
    string calldata _minPrice,
    string calldata _numberTickets,
    uint256 _expiration,
    RaffleConfig.RaffleStates _state
  ) internal pure returns (string memory) {
    return
      string(
        abi.encodePacked(
          _getStaticBody(_raffleId, _maxPrice, _minPrice, _numberTickets),
          _getDynamicBody(_expiration, _state)
        )
      );
  }
}

// SPDX-License-Identifier: BSD-3-Clause
pragma solidity ^0.8.0;

interface IRaffleTicket {
  /**
   * @notice object containing a raffle information
   * @param raffleId id of the raffle that the tickets will be associated to
   * @param pricePerTicket price cost of one ticket
   * @param maxTickets maximum number of thickets that can be associated with the raffle
   * @param ticketSVGComposer contract address in charge of creating the raffle ticket svg string
   * @param paymentTokenDecimals decimals of the token used to purchase a ticket
   * @param paymentTokenSymbol symbol string of the token used to purchase a ticket
   */
  struct RaffleTicketConfiguration {
    uint256 raffleId;
    uint256 pricePerTicket;
    uint256 maxTickets;
    address ticketSVGComposer;
    uint8 paymentTokenDecimals;
    string paymentTokenSymbol;
  }

  /**
   * @notice method to get tha raffle address the tickets are associated to
   * @return address of the raffle
   */
  function RAFFLE() external view returns (address);

  /**
   * @notice method to get the address of the contract in charge of creating the tickets svg string
   * @return address of the svg composer contract
   */
  function TICKET_SVG_COMPOSER() external view returns (address);

  /**
   * @notice method to get the id of the raffle nft the tickets are associated to
   * @return id of the raffle
   */
  function RAFFLE_ID() external view returns (uint256);

  /**
   * @notice method to get the price cost per one ticket of the raffle
   * @return price cost of a ticket
   */
  function PRICE_PER_TICKET() external view returns (uint256);

  /**
   * @notice method to get the maximum number of thickets that can be created for the associated raffle
   * @return maximum number of tickets
   */
  function MAX_TICKETS() external view returns (uint256);

  /**
   * @notice method to get the decimals of the token used for purchasing a ticket
   * @return token decimals
   */
  function PAYMENT_TOKEN_DECIMALS() external view returns (uint8);

  /**
   * @notice method to create a number of tickets associated to a raffle for a specified address
   * @param receiver address that will receive the raffle tickets
   * @param quantity number of tickets of a raffle that need to be sent to the receiver address
   */
  function createTickets(address receiver, uint256 quantity) external;

  /**
   * @notice method to get how many tickets of the associated raffle have been sold
   * @return number of sold tickets
   */
  function ticketsSold() external view returns (uint256);

  /**
   * @notice method to eliminate (burn) a ticket
   * @param ticketId id that needs to be eliminated
   * @dev unsafely burns a ticket nft (without owners approval). only callable by Raffle contract. This is
          so owners dont need to spend gas by allowing the burn.
   */
  function destroyTicket(uint256 ticketId) external;

  /**
   * @notice method to get the symbol of the token used for ticket payment
   * @return string of the payment token symbol
   */
  function getPaymentTokenSymbol() external view returns (string memory);
}

// SPDX-License-Identifier: BSD-3-Clause
pragma solidity ^0.8.8;

import {RaffleConfig} from '../libs/RaffleConfig.sol';

interface ISVGRaffle {
  function getSvg(
    string calldata raffleId,
    string calldata maxPrice,
    string calldata minPrice,
    string calldata numberTickets,
    uint256 expiration,
    RaffleConfig.RaffleStates state
  ) external view returns (string memory);
}

// SPDX-License-Identifier: BSD-3-Clause
pragma solidity ^0.8.8;

import 'openzeppelin-contracts/contracts/utils/Strings.sol';

library NumberUtils {
  using Strings for uint256;

  function numToFixedLengthStr(uint256 decimalPlaces, uint256 num)
    internal
    pure
    returns (string memory result)
  {
    bytes memory byteString;
    uint256 real = num / 1 ether;
    for (uint256 i = 0; i < decimalPlaces; i++) {
      uint256 remainder = num % 10;
      byteString = abi.encodePacked(remainder.toString(), byteString);
      num = num / 10;
    }

    result = string(abi.encodePacked(real.toString(), '.', string(byteString)));
  }
}

// SPDX-License-Identifier: BSD-3-Clause
pragma solidity ^0.8.8;

import {RaffleConfig} from './RaffleConfig.sol';
import 'solidity-datetime.git/contracts/DateTime.sol';

library ParseUtils {
  function _parseTimestamp(uint256 _timestamp)
    internal
    pure
    returns (string memory)
  {
    (
      uint256 year,
      uint256 month,
      uint256 day,
      uint256 hour,
      uint256 minute,
      uint256 second
    ) = DateTime.timestampToDateTime(_timestamp);
    return
      string(
        abi.encodePacked(
          month,
          '/',
          day,
          '/',
          year,
          ' ',
          hour,
          ':',
          minute,
          ':',
          second
        )
      );
  }

  function _parseState(RaffleConfig.RaffleStates state)
    internal
    pure
    returns (string memory)
  {
    if (RaffleConfig.RaffleStates.ACTIVE == state) return 'ACTIVE';
    if (RaffleConfig.RaffleStates.RAFFLE_SUCCESSFUL == state) return 'SUCESS';
    if (RaffleConfig.RaffleStates.FINISHED == state) return 'FINISHED';
    return 'EXPIRED';
  }
}

pragma solidity ^0.8.0;

import {IRaffleTicket} from '../interfaces/IRaffleTicket.sol';

library RaffleConfig {
  /**
  * @notice method to get the time in seconds of the start buffer.
  * @return start buffer time in seconds
  * @dev This time is to have a waiting period between raffle creation and raffle start (raffle tickets can be purchased)
         so raffle creator can cancel if something went wrong on creation.
  */
  uint16 public constant RAFFLE_START_BUFFER = 3600; // 1 hour

  /// @notice defines the possible raffle states
  enum RaffleStates {
    CREATED,
    ACTIVE, // users can buy raffle tickets
    RAFFLE_SUCCESSFUL, // ready to execute random number to choose winner
    CANCELED,
    EXPIRED, // not reached soft cap and has expired
    FINISHED // winner has been chosen,
  }

  // TODO: provably add more stuff like timestamps block numbers etc
  /**
   * @notice object with a Raffle information
   * @param raffleId sequential number identifying the raffle. Its the NFT id
   * @param minTickets minimum number of tickets to be sold before raffle duration for a raffle to be successful
   * @param canceled flag indicating if the raffle has been canceled
   * @param ticketSalesCollected flag indicating if the ticket sales balance has been withdrawn to raffle creator
   * @param maxTickets maximum number of tickets that the raffle can sell.
   * @param prizeNftCollected flag indicating if the raffle winner has collected the prize NFT
   * @param randomWordFulfilled flag indicating if a random word has already been received by Chainlink VRF
   * @param creationTimestamp time in seconds of the raffle creation
   * @param expirationDate raffle expiration timestamp in seconds
   * @param raffleDuration raffle duration in seconds
   * @param pricePerTicket price that a raffle ticket is sold for. Denominated in gas token where the
            Raffle has been deployed
   * @param prizeNftId id of the raffle prize NFT. NFT that is being raffled
   * @param prizeNftAddress address of the raffle prize NFT
   * @param vrfRequestId identification number of the VRF request to get a random work
   * @param randomWord word resulting of querying VRF
   * @param vrfRequestIdCost gas cost of requesting a random word to VRF
   * @param ticketWinner raffle ticket that has been selected as raffle winner. Owner of the raffle ticket NFT will be
            able to withdraw the prize NFT.
   * @param ticketWinnerSelected flag indicating if if a raffle ticket has been selected as winner
   */
  struct RaffleConfiguration {
    uint256 raffleId;
    uint40 minTickets;
    address raffleTicket;
    bool canceled;
    bool ticketSalesCollected;
    uint40 maxTickets;
    bool prizeNftCollected;
    bool randomWordFulfilled;
    uint40 creationTimestamp;
    uint40 expirationDate;
    uint40 raffleDuration;
    uint256 pricePerTicket;
    uint256 prizeNftId;
    address prizeNftAddress;
    uint256 ticketWinner;
    bool ticketWinnerSelected; // TODO: provably not needed if we use ticketWinner??
  }

  /**
   * @notice method to get the current state of a raffle NFT
   * @param raffleConfig raffle Nft configuration object
   * @return raffle NFT current state
   */
  function getRaffleState(RaffleConfiguration memory raffleConfig)
    external
    view
    returns (RaffleStates)
  {
    if (raffleConfig.ticketWinnerSelected) {
      return RaffleStates.FINISHED;
    } else if (
      IRaffleTicket(raffleConfig.raffleTicket).ticketsSold() ==
      raffleConfig.maxTickets ||
      (IRaffleTicket(raffleConfig.raffleTicket).ticketsSold() >
        raffleConfig.minTickets &&
        raffleConfig.expirationDate < uint40(block.timestamp))
    ) {
      return RaffleStates.RAFFLE_SUCCESSFUL;
    } else if (raffleConfig.canceled) {
      return RaffleStates.CANCELED;
    } else if (raffleConfig.expirationDate < uint40(block.timestamp)) {
      return RaffleStates.EXPIRED;
    } else if (
      raffleConfig.creationTimestamp + RAFFLE_START_BUFFER <
      uint40(block.timestamp)
    ) {
      return RaffleStates.ACTIVE;
    } else {
      return RaffleStates.CREATED;
    }
  }
}