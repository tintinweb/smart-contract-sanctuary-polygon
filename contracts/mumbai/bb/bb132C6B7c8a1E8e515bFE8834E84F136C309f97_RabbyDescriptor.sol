// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Base64.sol)

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
    string internal constant _TABLE = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

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

                mstore8(resultPtr, mload(add(tablePtr, and(shr(18, input), 0x3F))))
                resultPtr := add(resultPtr, 1) // Advance

                mstore8(resultPtr, mload(add(tablePtr, and(shr(12, input), 0x3F))))
                resultPtr := add(resultPtr, 1) // Advance

                mstore8(resultPtr, mload(add(tablePtr, and(shr(6, input), 0x3F))))
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

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "@openzeppelin/contracts/utils/Base64.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

interface IRabbyDescriptor {
    function tokenURI(uint256 tokenId, uint256 seed) external view returns (string memory);
}

contract RabbyDescriptor is IRabbyDescriptor {

    struct Trait {
        string content;
        string name;
    }

    function tokenURI(uint256 tokenId, uint256 seed) external pure override returns (string memory) {
      return string.concat(
        'data:application/json;base64,',
        Base64.encode(bytes(getJson(tokenId, seed)))
      );
    }

    function getJson(uint256 tokenId, uint256 seed) internal pure returns (string memory) {
      return string.concat(
        '{',
        '"name":"Podtown Citizen #', Strings.toString(tokenId), '",',
        '"description":"', 'Podtown Citizen nft collection', '",',
        '"image":"data:image/svg+xml;base64,', Base64.encode(bytes(getImage(seed))),'",',
        '"attributes": [{"trait_type": "Character", "value": "', 
        getCharacter(seed / 1000000000000).name,
        '"},',
        '{"trait_type": "Aspect", "value": "',
        getAspect(seed % 1000000000000 / 10000000000).name,
        '"},',
        '{"trait_type": "Blood type", "value": "',
        getBloodType(seed % 10000000000 / 100000000).name,
        '"},',
        '{"trait_type": "Element", "value": "',
        getElement(seed % 100000000 / 1000000).name,
        '"},',
        '{"trait_type": "Background", "value": "', 
        getBackground(seed % 1000000 / 10000).name,
        '"},',
        '{"trait_type": "Birthday", "value": "', 
        getBirthday(seed % 10000).name,
        '"},',
        '{"trait_type": "zodiac", "value": "', 
        getZodiac(seed % 10000).name,
         '"}',
        ']',
        '}'
      );
    }

    function getImage(uint256 seed) internal pure returns (string memory) {
      return string.concat(
        '<svg width="320" height="320" viewBox="0 0 320 320" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink"> <rect width="100%" height="100%" fill="#121212"/> <style> .small { font: 16px monospace; fill: white;} </style>',
        getCharacter(seed / 1000000000000).content,
        getAspect(seed % 1000000000000 / 10000000000).content,
        getBloodType(seed % 10000000000 / 100000000).content,
        getElement(seed % 100000000 / 1000000).content,
        getBackground(seed % 1000000 / 10000).content,
        getBirthday(seed % 10000).content,
        getZodiac(seed % 10000).content,
        '</svg>'
      );
    }


    function getCharacter(uint256 seed) internal pure returns (Trait memory) {
        string memory content;
        string memory name;
        if (seed == 10) {
            content = unicode"🐸 PEPE";
            name = "Pepe";
        }
        if (seed == 11) {
            content = unicode"😸 NEKO";
            name = "Neko";
        }
        if (seed == 12) {
            content = unicode"🦉 OWL";
            name = "Owl";
        }
        if (seed == 13) {
            content = unicode"🐰 RABBY";
            name = "Rabby";
        }
        return Trait(string.concat('<text dx="10" dy="130" class="small">', content, '</text>'), name);
    }

    function getAspect(uint256 seed) internal pure returns (Trait memory) {
        string memory content;
        string memory name;
        if (seed == 10) {
            content = "Ying";
            name = "Ying";
        }
        if (seed == 11) {
            content = "Yang";
            name = "Yang";
        }
        return Trait(string.concat('<text dx="10" dy="150" class="small">', content, '</text>'), name);
    }

    function getBloodType(uint256 seed) internal pure returns (Trait memory) {
        string memory content;
        string memory name;
        if (seed == 10) {
            content = "AB";
            name = "AB";
        }
        if (seed == 11) {
            content = "B";
            name = "B";
        }
        if (seed == 12) {
            content = "O";
            name = "O";
        }
        if (seed == 13) {
            content = "A";
            name = "A";
        }
        return Trait(string.concat('<text dx="10" dy="170" class="small">', content, '</text>'), name);
    }

    function getBackground(uint256 seed) internal pure returns (Trait memory) {
        string memory content;
        string memory name;
        if (seed == 10) {
            content = 'Aquamarine';
            name = 'Aquamarine';
        }
        if (seed == 11) {
            content = 'Astronaut Blue';
            name = 'Astronaut Blue';
        }
        if (seed == 12) {
            content = 'Blue Lotus';
            name = 'Blue Lotus';
        }
        return Trait(string.concat('<text dx="10" dy="190" class="small">', content, '</text>'), name);
    }

    function getElement(uint256 seed) internal pure returns (Trait memory) {
        string memory content;
        string memory name;
        if (seed == 10) {
            content = "Metal";
            name = "Metal";
        }
        if (seed == 11) {
            content = "Wood";
            name = "Wood";
        }
        if (seed == 12) {
            content = "Water";
            name = "Water";
        }
        if (seed == 13) {
            content = "Fire";
            name = "Fire";
        }
        if (seed == 14) {
            content = "Earth";
            name = "Earth";
        }
        return Trait(string.concat('<text dx="10" dy="210" class="small">', content, '</text>'), name);
    }

    function getBirthday(uint256 seed) internal pure returns (Trait memory) {
      uint256 date = getDate(seed);
      string memory datePrefix = '';
      if (date < 10) {
        datePrefix = '0'; 
      }
      uint256 month = getMonth(seed);
      string memory monthPrefix = '';
      if (month < 10) {
        monthPrefix = '0';
      }
      uint256 year = getYear(seed);
      string memory birthday = string.concat(
        datePrefix,
        Strings.toString(date),
        '.',
        monthPrefix,
        Strings.toString(month),
        '.',
        Strings.toString(year)
      );
      return Trait(string.concat('<text dx="10" dy="230" class="small">', birthday, '</text>'), birthday);
    }

    function getZodiac(uint256 seed) internal pure returns (Trait memory) {
      uint256 date = getDate(seed);
      uint256 month = getMonth(seed);
      string memory zodiac;
      if (month == 12) {
        zodiac = "Sagittarius";
        if (date > 21) {
          zodiac = "Capricornus";
        }
      }
      if (month == 1) {
        zodiac = "Capricornus";
        if (date > 19) {
          zodiac = "Aquarius";
        }
      }
      if (month == 2) {
        zodiac = "Aquarius";
        if (date > 18) {
          zodiac = "Pisces";
        }
      }
      if (month == 3) {
        zodiac = "Pisces";
        if (date > 20) {
          zodiac = "Aries";
        }
      }
      if (month == 4) {
        zodiac = "Aries";
        if (date > 19) {
          zodiac = "Taurus";
        }
      }
      if (month == 5) {
        zodiac = "Taurus";
        if (date > 20) {
          zodiac = "Gemini";
        }
      }
      if (month == 6) {
        zodiac = "Gemini";
        if (date > 20) {
          zodiac = "Cancer";
        }
      }
      if (month == 7) {
        zodiac = "Cancer";
        if (date > 22) {
          zodiac = "Leo";
        }
      }
      if (month == 8) {
        zodiac = "Leo";
        if (date > 22) {
          zodiac = "Virgo";
        }
      }
      if (month == 9) {
        zodiac = "Virgo";
        if (date > 22) {
          zodiac = "Libra";
        }
      }
      if (month == 10) {
        zodiac = "Libra";
        if (date > 22) {
          zodiac = "Scorpio";
        }
      }
      if (month == 11) {
        zodiac = "Scorpio";
        if (date > 21) {
          zodiac = "Sagittarius";
        }
      }
      return Trait(string.concat('<text dx="10" dy="250" class="small">', zodiac, '</text>'), zodiac);
    }

    function getDate(uint256 seed) internal pure returns (uint256) {
      uint256 month = getMonth(seed);
      uint256 limit = 28;
      if (month == 1 || month == 3 || month == 5 || month == 7 || month == 8 || month == 10 || month == 12) {
        limit = 31;
      } 
      if (month == 4 || month == 6 || month == 9 || month == 11) {
        limit = 30;
      }
      return seed % limit + 1;
    }

    function getMonth(uint256 seed) internal pure returns (uint256) {
      return seed % 12 + 1;
    }

    function getYear(uint256 seed) internal pure returns (uint256) {
      return seed % 324 + 1700;
    }
}