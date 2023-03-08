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

pragma solidity 0.8.10;

import '@openzeppelin/contracts/utils/Base64.sol';
import '@openzeppelin/contracts/utils/Strings.sol';

library ProfileTokenURILogic {
    uint8 internal constant DEFAULT_FONT_SIZE = 24;
    uint8 internal constant MAX_HANDLE_LENGTH_WITH_DEFAULT_FONT_SIZE = 17;

    /**
     * @notice Generates the token URI for the profile NFT.
     *
     * @dev The decoded token URI JSON metadata contains the following fields: name, description, image and attributes.
     * The image field contains a base64-encoded SVG. Both the JSON metadata and the image are generated fully on-chain.
     *
     * @param id The token ID of the profile.
     * @param followers The number of profile's followers.
     * @param owner The address which owns the profile.
     * @param handle The profile's handle.
     * @param imageURI The profile's picture URI. An empty string if has not been set.
     *
     * @return string The profile's token URI as a base64-encoded JSON string.
     */
    function getProfileTokenURI(
        uint256 id,
        uint256 followers,
        address owner,
        string memory handle,
        string memory imageURI
    ) external pure returns (string memory) {
        string memory handleWithAtSymbol = string(abi.encodePacked('@', handle));
        return
            string(
                abi.encodePacked(
                    'data:application/json;base64,',
                    Base64.encode(
                        abi.encodePacked(
                            '{"name":"',
                            handleWithAtSymbol,
                            '","description":"',
                            handleWithAtSymbol,
                            ' - Lens profile","image":"data:image/svg+xml;base64,',
                            _getSVGImageBase64Encoded(handleWithAtSymbol, imageURI),
                            '","attributes":[{"trait_type":"id","value":"#',
                            Strings.toString(id),
                            '"},{"trait_type":"followers","value":"',
                            Strings.toString(followers),
                            '"},{"trait_type":"owner","value":"',
                            Strings.toHexString(uint160(owner)),
                            '"},{"trait_type":"handle","value":"',
                            handleWithAtSymbol,
                            '"}]}'
                        )
                    )
                )
            );
    }

    /**
     * @notice Generates the token image.
     *
     * @dev If the image URI was set and meets URI format conditions, it will be embedded in the token image.
     * Otherwise, a default picture will be used. Handle font size is a function of handle length.
     *
     * @param handleWithAtSymbol The profile's handle beginning with "@" symbol.
     * @param imageURI The profile's picture URI. An empty string if has not been set.
     *
     * @return string The profile token image as a base64-encoded SVG.
     */
    function _getSVGImageBase64Encoded(string memory handleWithAtSymbol, string memory imageURI)
        internal
        pure
        returns (string memory)
    {
        return
            Base64.encode(
                abi.encodePacked(
                    '<svg width="450" height="450" viewBox="0 0 450 450" fill="none" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink"><defs><style>@font-face{font-family:"Space Grotesk";src:url(data:application/font-woff;charset=utf-8;base64,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) format("woff"); font-weight:normal;font-style:normal;} </style><linearGradient id="rounded-border-transparency-detail" x1="-137" y1="-236" x2="415" y2="486" gradientUnits="userSpaceOnUse"><stop stop-color="white"/><stop offset="1" stop-color="white" stop-opacity="0.2"/></linearGradient><clipPath id="outer-rounded-border"><rect width="450" height="450" rx="16" fill="white"/></clipPath></defs><g><g clip-path="url(#outer-rounded-border)">',
                    _getSVGProfilePicture(imageURI),
                    '<rect id="bottom-background" y="370" width="450" height="80" fill="#ABFE2C"/><text id="handle" fill="#00501E" text-anchor="middle" dominant-baseline="middle" x="225" y="410" font-family="Space Grotesk" font-size="',
                    Strings.toString(_handleLengthToFontSize(bytes(handleWithAtSymbol).length)),
                    '" font-weight="500" letter-spacing="0em">',
                    handleWithAtSymbol,
                    '</text><rect id="background-border" x="2.5" y="2.5" width="444" height="444" rx="13" stroke="url(#rounded-border-transparency-detail)" stroke-width="5"/><path id="bottom-logo" d="M70 423a14 14 0 0 1-13-1c2 1 5 1 8-1l-1-2h-1a9 9 0 0 1-8 0 9 9 0 0 1-4-6c3-1 11-2 17-8v-1a8 8 0 0 0 3-6c0-2-1-4-3-5-1-2-3-3-5-3l-5 1-3-4c-2-2-4-2-6-2s-4 0-5 2l-3 4-5-1-6 3-2 5a8 8 0 0 0 2 6l1 1c6 6 14 7 17 8a9 9 0 0 1-4 6 9 9 0 0 1-9 0l-2 2h1c2 2 5 2 8 1a14 14 0 0 1-13 1h-1l-1 2 1 1c3 1 7 2 10 1a16 16 0 0 0 10-6v6h3v-6a16 16 0 0 0 13 6l7-1 1-1-2-2Zm-27-29v-1c1-4 4-6 6-6 3 0 6 2 6 6v5l2-3h1v-1c3-2 6-1 8 0 2 2 3 6 0 8v1c-7 7-17 7-17 7s-9 0-16-7l-1-1c-3-2-2-6 0-8l4-1 4 1 1 1 3 3-1-4Z" fill="#fff" fill-opacity=".8"/></g></g></svg>'
                )
            );
    }

    /**
     * @notice Gets the fragment of the SVG correponding to the profile picture.
     *
     * @dev If the image URI was set and meets URI format conditions, this will return an image tag referencing it.
     * Otherwise, a group tag that renders the default picture will be returned.
     *
     * @param imageURI The profile's picture URI. An empty string if has not been set.
     *
     * @return string The fragment of the SVG token's image correspondending to the profile picture.
     */
    function _getSVGProfilePicture(string memory imageURI) internal pure returns (string memory) {
        if (_shouldUseCustomPicture(imageURI)) {
            return
                string(
                    abi.encodePacked(
                        '<image id="custom-picture" preserveAspectRatio="xMidYMid slice" height="450" width="450" href="',
                        imageURI,
                        '"/>'
                    )
                );
        } else {
            return
                '<g id="default-picture"><rect id="default-picture-background" x="0" width="450" height="450" fill="#ABFE2C"/><g id="default-picture-logo" transform="translate(60,30)"><style><![CDATA[#ez1M8bKaIyB3_to {animation: ez1M8bKaIyB3_to__to 6000ms linear infinite normal forwards}@keyframes ez1M8bKaIyB3_to__to { 0% { transform: translate3d(0,0,0); transform: translate(161px,137px) rotate(0.05deg);animation-timing-function: cubic-bezier(0.5,0.1,0.7,0.5)} 41% {transform: translate(157px,133px) rotate(0.05deg);animation-timing-function: cubic-bezier(0.2,0.5,0.5,0.9)} 100% {transform: translate(161px,137px) rotate(0.05deg)}} #ez1M8bKaIyB6_to {animation: ez1M8bKaIyB6_to__to 6000ms linear infinite normal forwards}@keyframes ez1M8bKaIyB6_to__to { 0% {transform: translate(160px,136px) rotate(0.05deg);animation-timing-function: cubic-bezier(0.5,0.1,0.7,0.2)} 26% {transform: translate(176px,138px) rotate(0.05deg);animation-timing-function: cubic-bezier(0.2,0.6,0.3,1)} 43% {transform: translate(176px,138px) rotate(0.05deg);animation-timing-function: cubic-bezier(0.2,0.6,0.3,1)} 83% {transform: translate(154px,145px) rotate(0.05deg)} 100% {transform: translate(160px,136px) rotate(0.05deg)}}]]></style><path d="m171.3 315.6.1.2-.3-67a113.6 113.6 0 0 0 99.7 58.6 115 115 0 0 0 48.9-10.8l-5.8-10a103.9 103.9 0 0 1-120.5-25.5l4.3 2.9a77 77 0 0 0 77.9 1l-5.7-10-2 1.1a66.4 66.4 0 0 1-96.5-54c19-1.1-30.8-1.1-12 .1A66.4 66.4 0 0 1 60.9 255l-5.7 10 2.4 1.2a76.1 76.1 0 0 0 79.8-5 103.9 103.9 0 0 1-120.6 25.5l-5.7 9.9a115 115 0 0 0 138.5-32.2c3.8-4.8 7.2-10 10-15.3l.6 66.9v-.4h11Z" fill="#00501e"/><g id="ez1M8bKaIyB3_to" transform="translate(162 137.5)"><g><g transform="translate(-165.4 -143.9)"><path d="M185 159.2c-2.4 6.6-9.6 12.2-19.2 12.2-9.3 0-17.3-5.3-19.4-12.4" fill="none" stroke="#00501e" stroke-width="8.3" stroke-linejoin="round"/><g id="ez1M8bKaIyB6_to" transform="translate(160 136.6)"><g transform="translate(0 -1.3)" fill="#00501e"><path d="M124.8 144.7a11.9 11.9 0 1 1-23.8 0 11.9 11.9 0 0 1 23.8 0Z" transform="translate(-154.1 -145)"/><path d="M209.5 144.7a11.9 11.9 0 1 1-23.8 0 11.9 11.9 0 0 1 23.8 0Z" transform="translate(-155 -145)"/></g></g><path d="M92.2 142.8c0-14.6 13.8-26.4 30.8-26.4s30.8 11.8 30.8 26.4M177 142.8c0-14.6 13.8-26.4 30.8-26.4s30.8 11.8 30.8 26.4" fill="none" stroke="#00501e" stroke-width="8.3" stroke-linejoin="round"/></g></g></g><path d="m219.1 70.3-3.2 3.3.1-4.6v-4.7c-1.8-65.4-100.3-65.4-102.1 0l-.1 4.7v4.6l-3.1-3.3-3.4-3.3C59.8 22-10 91.7 35 139.2l3.3 3.4C92.6 196.8 164.9 197 164.9 197s72.3-.2 126.5-54.4l3.3-3.4C339.7 91.7 270 22 222.5 67l-3.4 3.3Z" fill="none" stroke="#00501e" stroke-width="11.2" stroke-miterlimit="10"/></g></g>';
        }
    }

    /**
     * @notice Maps the handle length to a font size.
     *
     * @dev Gives the font size as a function of handle length using the following formula:
     *
     *      fontSize(handleLength) = 24                              when handleLength <= 17
     *      fontSize(handleLength) = 24 - (handleLength - 12) / 2    when handleLength  > 17
     *
     * @param handleLength The profile's handle length.
     * @return uint256 The font size.
     */
    function _handleLengthToFontSize(uint256 handleLength) internal pure returns (uint256) {
        return
            handleLength <= MAX_HANDLE_LENGTH_WITH_DEFAULT_FONT_SIZE
                ? DEFAULT_FONT_SIZE
                : DEFAULT_FONT_SIZE - (handleLength - 12) / 2;
    }

    /**
     * @notice Decides if Profile NFT should use user provided custom profile picture or the default one.
     *
     * @dev It checks if there is a custom imageURI set and makes sure it does not contain double-quotes to prevent
     * injection attacks through the generated SVG.
     *
     * @param imageURI The imageURI set by the profile owner.
     *
     * @return bool A boolean indicating whether custom profile picture should be used or not.
     */
    function _shouldUseCustomPicture(string memory imageURI) internal pure returns (bool) {
        bytes memory imageURIBytes = bytes(imageURI);
        if (imageURIBytes.length == 0) {
            return false;
        }
        uint256 imageURIBytesLength = imageURIBytes.length;
        for (uint256 i = 0; i < imageURIBytesLength; ) {
            if (imageURIBytes[i] == '"') {
                // Avoids embedding a user provided imageURI containing double-quotes to prevent injection attacks
                return false;
            }
            unchecked {
                ++i;
            }
        }
        return true;
    }
}