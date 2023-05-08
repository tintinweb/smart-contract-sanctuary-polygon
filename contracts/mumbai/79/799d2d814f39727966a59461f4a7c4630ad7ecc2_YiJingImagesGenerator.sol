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

// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

import { Strings } from "@openzeppelin/contracts/utils/Strings.sol";
import { Base64 } from "@openzeppelin/contracts/utils/Base64.sol";
import { Initializable } from "src/utils/Initializable.sol";

/// @author Stephane Chaunard <linktr.ee/stephanechaunard>
/// @title images for Yi Jing App & NFT
contract YiJingImagesGenerator is Initializable {
    string constant SVG_DEFS =
        '<defs><radialGradient id="def1"> <stop offset="20%" stop-color="white" /> <stop offset="100%" stop-color="gold" /> </radialGradient> <radialGradient id="GradientReflect" cx="0.5" cy="0.5" r="0.4" fx="0.75" fy="0.75" spreadMethod="reflect"><stop offset="0%" stop-color="red"/><stop offset="100%" stop-color="blue"/></radialGradient></defs>';
    string constant SVG_STYLE =
        "<style> svg {filter: drop-shadow(3px 5px 2px rgb(0 0 0 / 0.4));}svg text {font: italic 6px sans-serif; text-anchor: middle;}</style>";
    string constant SVG_ONE_STYLE =
        "<style> svg {filter: drop-shadow(2px 3px 1px rgb(0 0 0 / 0.3));}</style>";
    string constant PATH_BEGIN = '<path d="M-16,-';
    string constant PATH_END = '" fill="black" stroke="black"/>';
    string constant NEW_YIN = "h12v2h-12Zm20,0h12v2h-12Z";
    string constant NEW_YANG = "h32v2h-32Z";
    string constant OLD_YIN = "h12v2h-12Zm14,-1.5l4,5m-4,0l4,-5m2,1.5h12v2h-12Z";
    string constant OLD_YANG_PART_ONE =
        'h13v2h-13Zm19,0h13v2h-13Z" fill="black" stroke="black"/><circle cx="0" cy="-';
    string constant OLD_YANG_PART_TWO =
        '" r="2.5" fill="transparent" fill-opacity="0" stroke="black"/>';
    string constant TAIJITU =
        '<g class="taijitu"><circle r="39"/><path fill="#fff" d="M0,38a38,38 0 0 1 0,-76a19,19 0 0 1 0,38a19,19 0 0 0 0,38"/><circle r="5" cy="19" fill="#fff"/><circle r="5" cy="-19"/><animateTransform attributeName="transform" attributeType="XML" type="rotate" from="0 0 0" to="360 0 0" dur="5s" repeatCount="indefinite"/></g>';
    string constant YI_JING =
        '<path id="yijing" d="m-60 148c-4 1-7 1-11 1-3 1-7 1-10 1 0 2-1 4-1 6 3 2 4 4 3 4 0 1-1 2-3 3 13-1 23-2 30-2 6-1 11-2 13-3 3-1 5 0 8 2 2 2 5 4 7 6 3 2 3 4 1 5-1 1-3 4-4 9-2 5-3 11-6 18-2 7-5 12-9 15-3 3-7 6-11 7-4 2-6 1-6-1 0-3-2-6-7-11-5-4-4-5 3-2 6 4 11 3 15 0 4-4 7-10 10-19 3-8 4-14 3-18-1-3-4-5-8-5-3 0-8 1-16 1 6 5 8 8 6 10-2 1-5 4-9 8-4 5-10 11-19 17-8 6-15 9-21 11-6 1-7 1-2-1 5-3 10-7 17-13 7-6 13-11 18-16 4-5 6-10 7-16-7 1-12 2-16 2 1 2 2 3 4 5 1 1 1 2-1 3-1 0-5 3-10 7-5 4-10 7-16 8-5 1-5 1-1-2 4-2 9-5 13-9 5-4 8-8 9-12l-5-1c-9 6-17 10-23 13-7 2-7 1-1-2 6-4 11-7 14-10 3-4 7-7 10-11-1-8-1-15-1-23-1-8-2-13-4-16-3-4-2-5 2-5 3 1 9 1 16 0 7-1 11-3 12-4 2-1 5 0 9 2 4 2 6 3 5 4 0 2-1 4-3 7-1 3-1 8-1 14 0 7-1 12-3 15-2 4-3 6-4 6 0-1-1-3-3-8zm-21-2 12-2c3 0 6 0 7 1 2 0 3 0 4-1 1-2 1-6 1-15 0-8 0-13-1-14-1-1-4-2-8-1-4 1-9 2-15 3l0 13c4-1 7-2 10-3 2-1 5 0 7 1 2 2 0 3-4 4-5 1-9 1-13 1v13zm165-1c15 3 24 6 28 10 4 4 6 7 5 11 0 3-3 3-8-1-5-3-14-9-26-18-3 3-6 7-11 10-3 4-8 7-15 9-6 3-6 1 2-4 7-6 14-13 20-20 5-8 8-13 9-17-5 1-9 2-14 4-5 2-9 2-12 0-3-2-3-3 1-3 5-1 10-2 16-3 7-2 10-4 11-5 1-1 3-1 5 0 2 1 4 2 6 4 2 1 2 3-1 4-2 1-4 4-7 7-2 4-5 8-9 12zm-1 32c3 1 4 3 3 5-1 3-2 8-2 17 12-1 19-2 23-3 4-1 8 0 11 3 3 3 2 4-3 4-5 0-10 0-15 0-5 0-13 0-22 2-10 1-17 2-20 3-3 1-7 0-11-2-4-3-4-4 0-4 4 0 15-1 31-3 0-12-1-19-1-20 0-1-2-1-6-1-3 0-6 0-9-1-3-2-2-3 1-3 3 0 7-1 11-2 4-1 9-2 15-3 6-2 10-2 12-1 3 2 3 3-1 4-3 2-9 3-17 5zm-45-30c5-8 8-13 7-16 0-3 0-4 3-3 3 2 5 3 6 5 2 1 1 3-2 6-2 2-10 11-22 28 9-1 15-2 19-2 4-1 2 1-7 4-8 4-14 7-17 9-3 2-5 1-6-2-1-3 0-6 2-7 2-1 7-7 15-19-10 2-16 3-17 5-2 1-3 1-4-3-1-3 0-5 2-5 2-1 4-3 6-6 2-3 4-7 6-13 2-5 2-9 1-12-1-3 0-4 2-3 3 1 5 2 7 5 2 1 2 3 0 5-2 1-6 10-14 24h13zm-2 40c16-5 18-5 7 1-10 7-16 11-19 13-2 2-5 1-10-2-4-4-4-6 0-6 4 0 12-2 22-6z" fill="black"/>';

    string constant YI_JING_ANIMATION =
        '<path d="m3-2-3-14-3 14-9 2 9 2 3 13 3-13 9-2-9-2z" fill="url(#def1)"><animateTransform attributeName="transform" attributeType="XML" type="scale" values="0;0.5;0" dur="1s" repeatCount="indefinite"/><animateMotion dur="60s" repeatCount="indefinite"><mpath xlink:href="#yijing"/></animateMotion></path>';
    string constant CARD =
        '<rect id="square" x="-200" y="-240" width="400" height="480" rx="15" ry="15" fill="pink" fill-opacity="0.3" stroke="url(#GradientReflect)" stroke-width="6" stroke-opacity="0.7"/>';
    uint256 constant V_BASE_POSITION = 32;

    /*////////////////////////////////////////////////////
                      INTERNALS FUNCTIONS
    ////////////////////////////////////////////////////*/
    function _getNewYin(uint8 position) internal pure returns (string memory) {
        return
            string.concat(
                PATH_BEGIN,
                Strings.toString(V_BASE_POSITION + 7 * position),
                NEW_YIN,
                PATH_END
            );
    }

    function _getNewYang(uint8 position) internal pure returns (string memory) {
        return
            string.concat(
                PATH_BEGIN,
                Strings.toString(V_BASE_POSITION + 7 * position),
                NEW_YANG,
                PATH_END
            );
    }

    function _getOldYin(uint8 position) internal pure returns (string memory) {
        return
            string.concat(
                PATH_BEGIN,
                Strings.toString(V_BASE_POSITION + 7 * position),
                OLD_YIN,
                PATH_END
            );
    }

    function _getOldYang(uint8 position) internal pure returns (string memory) {
        return
            string.concat(
                PATH_BEGIN,
                Strings.toString(V_BASE_POSITION + 7 * position),
                OLD_YANG_PART_ONE,
                Strings.toString(V_BASE_POSITION - 1 + 7 * position),
                OLD_YANG_PART_TWO
            );
    }

    function _getTrait(uint8 value, uint8 position) internal pure returns (string memory) {
        string memory trait;
        if (value == 0) {
            trait = _getNewYin(position);
        } else if (value == 1) {
            trait = _getNewYang(position);
        } else if (value == 2) {
            trait = _getOldYin(position);
        } else {
            assert(value == 3);
            trait = _getOldYang(position);
        }

        return string.concat('<g class="', Strings.toString(position + 1), '">', trait, "</g>");
    }

    function _getText(
        uint8[6] memory lines,
        uint8 variation
    ) internal pure returns (string memory) {
        string memory text;
        if (variation == 0) {
            text = "draw";
        } else if (variation == 1) {
            text = string.concat("from ", Strings.toString(_getNumber(lines)));
        } else {
            assert(variation == 2);
            text = string.concat("to ", Strings.toString(_getNumber(lines)));
        }

        return
            string.concat(
                '<text x="0" y="-',
                Strings.toString(V_BASE_POSITION - 12),
                '" class="small">',
                text,
                "</text>"
            );
    }

    function _getAnimationTransform(string memory params) internal pure returns (string memory) {
        return
            string.concat(
                '<animateTransform attributeName="transform" attributeType="XML" ',
                params,
                ' dur="20s" repeatCount="indefinite"/>'
            );
    }

    function _getRotateAnimation(
        string memory from,
        string memory to
    ) internal pure returns (string memory) {
        return
            _getAnimationTransform(
                string.concat('type="rotate" from="', from, ' 0 0" to="', to, ' 0 0"')
            );
    }

    function _getScaleAnimation(string memory values) internal pure returns (string memory) {
        return
            _getAnimationTransform(
                string.concat('type="scale" calcMode="linear" values="', values, '" additive="sum"')
            );
    }

    function _getAnimations(uint8 variation) internal pure returns (string memory) {
        if (variation == 1)
            return
                string.concat(
                    _getRotateAnimation("-120", "240"),
                    _getScaleAnimation("1;2;3;2;1;0.5;1")
                );
        if (variation == 2)
            return
                string.concat(
                    _getRotateAnimation("-240", "120"),
                    _getScaleAnimation("1;0.5;1;2;3;2;1")
                );
        assert(variation == 0);
        return
            string.concat(_getRotateAnimation("0", "360"), _getScaleAnimation("3;2;1;0.5;1;2;3"));
    }

    function _getThe6Bits(
        uint8[6] memory lines,
        uint8 variation
    ) internal pure returns (uint8[6] memory) {
        if (variation == 1) return _getFrom6Bits(lines);
        if (variation == 2) return _getTo6Bits(lines);
        assert(variation == 0);
        return lines;
    }

    function _getGroups(uint8[6] memory lines) internal pure returns (string[3] memory) {
        //slither-disable-next-line uninitialized-local
        string[3] memory svg;
        for (uint8 variation = 0; variation < 3; variation++) {
            uint8[6] memory the6Bits = _getThe6Bits(lines, variation);
            svg[variation] = "<g>";
            for (uint8 id; id < 6; id++) {
                svg[variation] = string.concat(svg[variation], _getTrait(the6Bits[5 - id], 5 - id));
            }

            svg[variation] = string.concat(
                svg[variation],
                _getText(the6Bits, variation),
                _getAnimations(variation),
                "</g>"
            );
        }

        return svg;
    }

    function _getSVG(uint8[6] memory lines) internal pure returns (string memory) {
        string[3] memory groups = _getGroups(lines);
        string memory svg = string.concat(
            '<svg xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" width="512" height="512" viewBox="-256 -256 512 512">',
            SVG_DEFS,
            SVG_STYLE,
            CARD
        );
        for (uint8 variation = 0; variation < 3; variation++) {
            svg = string.concat(svg, groups[variation]);
        }

        return string.concat(svg, TAIJITU, YI_JING, YI_JING_ANIMATION, "</svg>");
    }

    function _getFrom6Bits(uint8[6] memory lines) internal pure returns (uint8[6] memory) {
        //slither-disable-next-line uninitialized-local
        uint8[6] memory from6Bits;
        for (uint8 i = 0; i < 6; i++) {
            from6Bits[i] = lines[i] % 2;
        }

        return from6Bits;
    }

    function _getTo6Bits(uint8[6] memory lines) internal pure returns (uint8[6] memory) {
        //slither-disable-next-line uninitialized-local
        uint8[6] memory to6Bits;
        for (uint8 i = 0; i < 6; i++) {
            to6Bits[i] = (lines[i] == 0 || lines[i] == 3) ? (lines[i] + 1) % 2 : lines[i] % 2;
        }

        return to6Bits;
    }

    // Use the King Wen sequence
    // https://oeis.org/A102241
    function _getNumber(uint8[6] memory a6Bits) internal pure returns (uint256) {
        // Inverse of the King Wen sequence
        uint8[64] memory from6BitsToNumber = [
            2,
            24,
            7,
            19,
            15,
            36,
            46,
            11,
            16,
            51,
            40,
            54,
            62,
            55,
            32,
            34,
            8,
            3,
            29,
            60,
            39,
            63,
            48,
            5,
            45,
            17,
            47,
            58,
            31,
            49,
            28,
            43,
            23,
            27,
            4,
            41,
            52,
            22,
            18,
            26,
            35,
            21,
            64,
            38,
            56,
            30,
            50,
            14,
            20,
            42,
            59,
            61,
            53,
            37,
            57,
            9,
            12,
            25,
            6,
            10,
            33,
            13,
            44,
            1
        ];

        uint256 n = (a6Bits[5] << 5) +
            (a6Bits[4] << 4) +
            (a6Bits[3] << 3) +
            (a6Bits[2] << 2) +
            (a6Bits[1] << 1) +
            (a6Bits[0] << 0);

        return from6BitsToNumber[n];
    }

    /*/////////////////////////////////////////////////////
                      EXTERNALS FUNCTIONS
    //////////////////////////////////////////////////// */

    /// Retrieve base64 hexagram image for a variation
    /// @param lines an hexagram is composed by 6 lines defined by a number in the range [0;3]
    /// @param variation 0 is 'Draw' hexagram, 1 is for 'From' hexagram and 2 is for 'To' hexagram
    /// @return uint256 hexagram number
    /// @return string svg base64 image
    function getHexagramImageForVariation(
        uint8[6] memory lines,
        uint8 variation
    ) external pure returns (uint256, string memory) {
        uint8[6] memory the6Bits = _getThe6Bits(lines, variation);
        string memory svg = string.concat(
            '<svg xmlns="http://www.w3.org/2000/svg" width="46" height="46" viewBox="-23 -76 46 56">',
            SVG_ONE_STYLE
        );
        for (uint8 id = 0; id < 6; id++) {
            svg = string.concat(svg, _getTrait(the6Bits[5 - id], 5 - id));
        }

        svg = string.concat(svg, "</svg>");

        // svg Data
        svg = string.concat("data:image/svg+xml;base64,", Base64.encode(abi.encodePacked(svg)));

        return (variation == 0 ? 0 : _getNumber(the6Bits), svg);
    }

    /// Retrieve base64 image for NFT
    /// @param lines an hexagram is composed by 6 lines defined by a number in the range [0;3]
    /// @return string svg base64 image
    function getNftImage(uint8[6] memory lines) external pure returns (string memory) {
        return (
            string.concat(
                "data:image/svg+xml;base64,",
                Base64.encode(abi.encodePacked(_getSVG(lines)))
            )
        );
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import { Pausable } from "src/utils/Pausable.sol";

abstract contract Caller is Pausable {
    address _caller;

    modifier onlyFromCaller() {
        require(msg.sender == _caller, "Caller: not good one");
        _;
    }

    function getCaller() public view returns (address) {
        return _caller;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import { Caller } from "src/utils/Caller.sol";

abstract contract Initializable is Caller {
    bool _initialized;

    function init(address caller) external onlyOwner whenPaused {
        require(!_initialized, "Initializable: already done");
        _initialized = true;
        _caller = caller;
        _togglePause();
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";

abstract contract Pausable is Ownable {
    bool private _paused;

    /// @dev Initializes the contract in paused state.
    constructor() {
        _paused = true;
    }

    /// @dev Modifier to make a function callable only when the contract is not paused.
    modifier whenNotPaused() {
        require(!_paused, "Pausable: paused");
        _;
    }

    modifier whenPaused() {
        require(_paused, "Pausable: not paused");
        _;
    }

    /// @dev Toggle paused state.
    function togglePause() external onlyOwner {
        _togglePause();
    }

    function _togglePause() internal {
        _paused = !_paused;
    }

    function paused() external view returns (bool) {
        return _paused;
    }
}