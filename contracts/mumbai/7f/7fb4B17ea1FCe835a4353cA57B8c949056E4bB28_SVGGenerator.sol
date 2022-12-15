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
pragma solidity ^0.8.14;

/*///////////////////////////////////////
─────────────────────────────────────────
──┌───┐───────────────────┌───┬───┬───┐──
──│┌─┐│───────────────────└┐┌┐│┌─┐│┌─┐│──
──│└─┘├──┬─┬──┬──┬──┬─┐┌──┐│││││─│││─││──
──│┌──┤┌┐│┌┤┌┐│┌┐│┌┐│┌┐┤──┤││││└─┘││─││──
──││──│┌┐│││┌┐│└┘│└┘│││├──├┘└┘│┌─┐│└─┘│──
──└┘──└┘└┴┘└┘└┴─┐├──┴┘└┴──┴───┴┘─└┴───┘──
──────────────┌─┘│───────────────────────
──────────────└──┘───────────────────────
─────────────────────────────────────────
///////////////////////////////////////*/

interface IPlayerManagement {
    struct PlayerData {
        bytes32 playerName;
        uint64 playerRank;
        uint64 mintDate;
    }

    function claimPlayerXp(bytes memory signature, uint256 pxpAmount, uint256 claimCount) external;

    function setPlayerName(bytes32 newName) external;

    function upgradePlayerRank() external;

    function getPlayerData(uint256 id) external view returns (PlayerData memory playerData_);

    function getPlayersInRank(uint256 rank) external view returns (uint256 playersInRank_);

    function getPdpMintCost(bool whitelist) external view returns (uint256 pdtCost_);

    function getNameChangeCost() external view returns (uint256 pdtCost_);

    function getRankUpCosts(uint256 rank) external view returns (uint256 pdtCost_, uint256 pxpCost_);

    function getMinRankForTransfers() external view returns (uint256 minRankForTransfers_);

    function getClaimCount(uint256 playerId) external view returns (uint256 claimCount_);

    function getPDTPrice() external view returns (uint256 pdtPrice_);

    function getTotalPXPEarned(uint256 rank) external view returns (uint256 totalPxpEarned_);

    function getRankMultiplierBasisPoints() external view returns (uint256 rankMultiplierBasisPoints_);

    function getLevelMultiplier(uint256 rank) external view returns (uint256 levelMultiplier_);

    function getMaxRank() external view returns (uint256 maxRank_);

    function initializePlayerData(uint256 id, bytes32 name) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

import "./IPlayerManagement.sol";

/*///////////////////////////////////////
─────────────────────────────────────────
──┌───┐───────────────────┌───┬───┬───┐──
──│┌─┐│───────────────────└┐┌┐│┌─┐│┌─┐│──
──│└─┘├──┬─┬──┬──┬──┬─┐┌──┐│││││─│││─││──
──│┌──┤┌┐│┌┤┌┐│┌┐│┌┐│┌┐┤──┤││││└─┘││─││──
──││──│┌┐│││┌┐│└┘│└┘│││├──├┘└┘│┌─┐│└─┘│──
──└┘──└┘└┴┘└┘└┴─┐├──┴┘└┴──┴───┴┘─└┴───┘──
──────────────┌─┘│───────────────────────
──────────────└──┘───────────────────────
─────────────────────────────────────────
///////////////////////////////////////*/

interface ISVGGenerator {
    function generateSVG(
        uint256 tokenId,
        address owner,
        IPlayerManagement.PlayerData memory data
    ) external view returns (string memory svgXml_);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

/*///////////////////////////////////////
─────────────────────────────────────────
──┌───┐───────────────────┌───┬───┬───┐──
──│┌─┐│───────────────────└┐┌┐│┌─┐│┌─┐│──
──│└─┘├──┬─┬──┬──┬──┬─┐┌──┐│││││─│││─││──
──│┌──┤┌┐│┌┤┌┐│┌┐│┌┐│┌┐┤──┤││││└─┘││─││──
──││──│┌┐│││┌┐│└┘│└┘│││├──├┘└┘│┌─┐│└─┘│──
──└┘──└┘└┴┘└┘└┴─┐├──┴┘└┴──┴───┴┘─└┴───┘──
──────────────┌─┘│───────────────────────
──────────────└──┘───────────────────────
─────────────────────────────────────────
///////////////////////////////////////*/

interface ISVGPart {
    function generateSVGPart() external pure returns (string memory svgXml_);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

//  ==========  EXTERNAL IMPORTS    ==========

import "@openzeppelin/contracts/utils/Strings.sol";

//  ==========  INTERNAL IMPORTS    ==========

import "../interfaces/ISVGGenerator.sol";
import "../interfaces/ISVGPart.sol";

/*///////////////////////////////////////
─────────────────────────────────────────
──┌───┐───────────────────┌───┬───┬───┐──
──│┌─┐│───────────────────└┐┌┐│┌─┐│┌─┐│──
──│└─┘├──┬─┬──┬──┬──┬─┐┌──┐│││││─│││─││──
──│┌──┤┌┐│┌┤┌┐│┌┐│┌┐│┌┐┤──┤││││└─┘││─││──
──││──│┌┐│││┌┐│└┘│└┘│││├──├┘└┘│┌─┐│└─┘│──
──└┘──└┘└┴┘└┘└┴─┐├──┴┘└┴──┴───┴┘─└┴───┘──
──────────────┌─┘│───────────────────────
──────────────└──┘───────────────────────
─────────────────────────────────────────
///////////////////////////////////////*/

/**
 * @author  0xFirekeeper
 * @title   ParagonsDAO Player ID SVG Image Generator.
 * @dev     Constructs an SVG image including latest PlayerData.
 * @notice  Creates an SVG that includes a ParagonsDAO Player's Data and returns its bytes representation.
 */

contract SVGGenerator is ISVGGenerator {
    using Strings for uint256;
    using Strings for address;

    ISVGPart[] private _svgParts;

    constructor(ISVGPart[] memory svgParts) {
        _svgParts = svgParts;
    }

    /*///////////////////////////////////////////////////////////////
                                SVG Generation
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice  Generate dynamic SVG that include Player data.
     * @dev     Concatenates different SVG parts to create the image on-chain.
     * @param   tokenId  PDP token ID.
     * @param   owner  PDP owner address.
     * @param   data  Latest Player Data.
     * @return  svgXml_  The generated SVG XML string.
     */
    function generateSVG(
        uint256 tokenId,
        address owner,
        IPlayerManagement.PlayerData memory data
    ) public view returns (string memory svgXml_) {
        string memory rankName;
        uint256 rank = data.playerRank;
        if (rank < 4) rankName = "NEWBIE";
        else if (rank < 8) rankName = "GAMER";
        else rankName = "GOD";

        uint256 totalPxpSpent = data.playerRank == 0
            ? 0
            : ((2000 + (2 ** data.playerRank * 1000)) * (data.playerRank - 1)) / 2;

        // prettier-ignore
        string memory svgXml = string.concat(
            _svgParts[0].generateSVGPart(),
            'ParagonsDAO Player ID #', tokenId.toString(),
            '</tspan></text><text id="address.text" fill="gray" xml:space="preserve" style="white-space:pre" font-family="Noto Sans" font-size="12" letter-spacing="0em"><tspan x="119.834" y="617.656">',
            owner.toHexString(),
            '</tspan></text></g><g id="top.frame"><g id="pxp.frame"><path id="pxp.shadow" d="M344 148.366H191.5c-4.142 0-7.5 2.496-7.5 5.576v22.3c0 3.08 3.358 5.576 7.5 5.576H344c4.142 0 7.5-2.496 7.5-5.576v-22.3c0-3.08-3.358-5.576-7.5-5.576Z" fill="#0B0F18" fill-opacity=".1" style="stroke-dasharray:391 393;stroke-dashoffset:392;animation:oQbfJolm_draw_21 3600ms ease-in 0ms infinite,oQbfJolm_fade 3600ms linear 0ms infinite"/><path id="pxp.outer" d="m206.5 173.574-7.987-8.482 7.987-8.482 7.988 8.482-7.988 8.482Z" stroke="#8CDC48" style="stroke-dasharray:47 49;stroke-dashoffset:48;animation:oQbfJolm_draw_22 3600ms ease-in 0ms infinite,oQbfJolm_fade 3600ms linear 0ms infinite"/><path id="pxp.inner" d="m202.75 165.092 3.75-3.717 3.75 3.717-3.75 3.717-3.75-3.717Z" fill="#8CDC48" style="stroke-dasharray:22 24;stroke-dashoffset:23;animation:oQbfJolm_draw_23 3600ms ease-in 0ms infinite,oQbfJolm_fade 3600ms linear 0ms infinite"/><text id="pxp.text" fill="#8CDC48" xml:space="preserve" style="white-space:pre" font-family="Noto Sans" font-size="28" letter-spacing="0em"><tspan x="235" y="175.864">',
            totalPxpSpent.toString(),
            '</tspan></text></g><g id="rank.frame"><path id="rank.shadow" d="M402.662 107.481h-94.074a5.582 5.582 0 0 0-5.588 5.576v22.301c0 3.079 2.502 5.575 5.588 5.575h94.074c3.086 0 5.588-2.496 5.588-5.575v-22.301a5.582 5.582 0 0 0-5.588-5.576Z" fill="#0B0F18" fill-opacity=".1" style="stroke-dasharray:268 270;stroke-dashoffset:269;animation:oQbfJolm_draw_24 3600ms ease-in 0ms infinite,oQbfJolm_fade 3600ms linear 0ms infinite"/><g id="rank.icon"><path d="M321.016 118.175v14.693h-5.744l5.744-14.693Zm.612-3.26-7.259 18.584h7.259v-18.584Z" fill="url(#paint6_linear_1_2)" style="stroke-dasharray:83 85;stroke-dashoffset:84;animation:oQbfJolm_draw_25 3600ms ease-in 0ms infinite,oQbfJolm_fade 3600ms linear 0ms infinite"/><path d="m316.19 118.715-6.32 14.153h-5.532l11.852-14.153Zm2.367-3.8L303 133.499h7.259l8.298-18.584Z" fill="url(#paint7_linear_1_2)" style="stroke-dasharray:92 94;stroke-dashoffset:93;animation:oQbfJolm_draw_26 3600ms ease-in 0ms infinite,oQbfJolm_fade 3600ms linear 0ms infinite"/></g><text id="rank.value" fill="url(#paint8_linear_1_2)" xml:space="preserve" style="white-space:pre" font-family="Noto Sans" font-size="28" letter-spacing="0em"><tspan x="334" y="134.864">',
            (rank+1).toString(),
            '</tspan></text></g><g id="rankname.frame"><path id="rankname.shadow" d="M269.25 107.481H135.5c-4.142 0-7.5 2.497-7.5 5.576v22.301c0 3.079 3.358 5.575 7.5 5.575h133.75c4.142 0 7.5-2.496 7.5-5.575v-22.301c0-3.079-3.358-5.576-7.5-5.576Z" fill="#0B0F18" fill-opacity=".1" style="stroke-dasharray:354 356;stroke-dashoffset:355;animation:oQbfJolm_draw_27 3600ms ease-in 0ms infinite,oQbfJolm_fade 3600ms linear 0ms infinite"/><text id="rankname.text" fill="#fff" xml:space="preserve" style="white-space:pre" font-family="Noto Sans" font-size="28" letter-spacing="0em"><tspan x="134" y="138.148">',
            rankName,
            '</tspan></text></g><g id="username.frame"><path id="username.shadow" d="M400.5 55.446h-265c-4.142 0-7.5 2.496-7.5 5.575v33.452c0 3.079 3.358 5.575 7.5 5.575h265c4.142 0 7.5-2.496 7.5-5.575V61.02c0-3.079-3.358-5.575-7.5-5.575Z" fill="#0B0F18" fill-opacity=".1" style="stroke-dasharray:639 641;stroke-dashoffset:640;animation:oQbfJolm_draw_28 3600ms ease-in 0ms infinite,oQbfJolm_fade 3600ms linear 0ms infinite"/><g id="username.text" filter="url(#filter0_d_1_2)"><text fill="#fff" xml:space="preserve" style="white-space:pre" font-family="Noto Sans" font-size="40" letter-spacing="0em"><tspan x="153" y="93.52">',
            bytes32ToString(data.playerName),
            '</tspan></text></g></g></g></g><defs><linearGradient id="paint0_linear_1_2" x1="250.001" y1="630" x2="250.001" y2=".001" gradientUnits="userSpaceOnUse"><stop stop-color="#4895DC" stop-opacity=".4"/><stop offset="1" stop-color="#35A375"/></linearGradient><linearGradient id="paint1_linear_1_2" x1="215.351" y1="309.946" x2="215.904" y2="309.946" gradientUnits="userSpaceOnUse"><stop stop-color="#4895DC" stop-opacity=".4"/><stop offset="1" stop-color="#35A375"/></linearGradient><linearGradient id="paint2_linear_1_2" x1="250" y1="0" x2="250" y2="254.602" gradientUnits="userSpaceOnUse"><stop stop-color="#0B0F18"/><stop offset="1" stop-color="#0B0F18" stop-opacity="0"/></linearGradient><linearGradient id="paint3_linear_1_2" x1="250" y1="630.434" x2="250" y2="518" gradientUnits="userSpaceOnUse"><stop stop-color="#0B0F18"/><stop offset="1" stop-color="#0B0F18" stop-opacity="0"/></linearGradient><linearGradient id="paint4_linear_1_2" x1="34.5" y1=".926" x2="34.5" y2="629.074" gradientUnits="userSpaceOnUse"><stop stop-color="#4895DC"/><stop offset="1" stop-color="#35A375"/></linearGradient><linearGradient id="paint5_linear_1_2" x1="250.5" y1="-.933" x2="250.5" y2="631.933" gradientUnits="userSpaceOnUse"><stop stop-color="#4895DC"/><stop offset="1" stop-color="#35A375"/></linearGradient><linearGradient id="paint6_linear_1_2" x1="312.314" y1="114.915" x2="312.314" y2="133.499" gradientUnits="userSpaceOnUse"><stop stop-color="#4895DC"/><stop offset="1" stop-color="#35A375"/></linearGradient><linearGradient id="paint7_linear_1_2" x1="310.778" y1="114.915" x2="310.778" y2="133.499" gradientUnits="userSpaceOnUse"><stop stop-color="#4895DC"/><stop offset="1" stop-color="#35A375"/></linearGradient><linearGradient id="paint8_linear_1_2" x1="371" y1="110" x2="371" y2="138" gradientUnits="userSpaceOnUse"><stop stop-color="#4895DC"/><stop offset="1" stop-color="#35A375"/></linearGradient><clipPath id="clip0_1_2"><path fill="#fff" d="M0 0h500v630H0Z" style="stroke-dasharray:2260 2262;stroke-dashoffset:2261;animation:oQbfJolm_draw_29 3600ms ease-in 0ms infinite,oQbfJolm_fade 3600ms linear 0ms infinite"/></clipPath><clipPath id="clip1_1_2"><path fill="#fff" transform="translate(28)" d="M0 0h13v630H0Z" style="stroke-dasharray:1286 1288;stroke-dashoffset:1287;animation:oQbfJolm_draw_30 3600ms ease-in 0ms infinite,oQbfJolm_fade 3600ms linear 0ms infinite"/></clipPath><filter id="filter0_d_1_2" x="150.8" y="63.6" width="235.771" height="48" filterUnits="userSpaceOnUse" color-interpolation-filters="sRGB"><feFlood flood-opacity="0" result="BackgroundImageFix"/><feColorMatrix in="SourceAlpha" values="0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 127 0" result="hardAlpha"/><feOffset dy="4"/><feGaussianBlur stdDeviation="2"/><feComposite in2="hardAlpha" operator="out"/><feColorMatrix values="0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0.25 0"/><feBlend in2="BackgroundImageFix" result="effect1_dropShadow_1_2"/><feBlend in="SourceGraphic" in2="effect1_dropShadow_1_2" result="shape"/></filter></defs><style data-made-with="vivus-instant">@keyframes oQbfJolm_draw{to{stroke-dashoffset:0}}@keyframes oQbfJolm_fade{0%,94.44444444444444%{stroke-opacity:1}to{stroke-opacity:0}}@keyframes oQbfJolm_draw_0{5.555555555555555%{stroke-dashoffset:2261}61.111111111111114%,to{stroke-dashoffset:0}}@keyframes oQbfJolm_draw_1{6.481481481481481%{stroke-dashoffset:2261}62.037037037037045%,to{stroke-dashoffset:0}}@keyframes oQbfJolm_draw_2{7.407407407407408%{stroke-dashoffset:441}62.962962962962955%,to{stroke-dashoffset:0}}@keyframes oQbfJolm_draw_3{8.333333333333332%{stroke-dashoffset:298}63.888888888888886%,to{stroke-dashoffset:0}}@keyframes oQbfJolm_draw_4{9.25925925925926%{stroke-dashoffset:298}64.81481481481481%,to{stroke-dashoffset:0}}@keyframes oQbfJolm_draw_5{10.185185185185187%{stroke-dashoffset:300}65.74074074074073%,to{stroke-dashoffset:0}}@keyframes oQbfJolm_draw_6{11.11111111111111%{stroke-dashoffset:300}66.66666666666666%,to{stroke-dashoffset:0}}@keyframes oQbfJolm_draw_7{12.037037037037038%{stroke-dashoffset:300}67.5925925925926%,to{stroke-dashoffset:0}}@keyframes oQbfJolm_draw_8{12.962962962962962%{stroke-dashoffset:300}68.5185185185185%,to{stroke-dashoffset:0}}@keyframes oQbfJolm_draw_9{13.88888888888889%{stroke-dashoffset:300}69.44444444444444%,to{stroke-dashoffset:0}}@keyframes oQbfJolm_draw_10{14.814814814814817%{stroke-dashoffset:300}70.37037037037037%,to{stroke-dashoffset:0}}@keyframes oQbfJolm_draw_11{15.740740740740744%{stroke-dashoffset:300}71.2962962962963%,to{stroke-dashoffset:0}}@keyframes oQbfJolm_draw_12{16.666666666666664%{stroke-dashoffset:300}72.22222222222221%,to{stroke-dashoffset:0}}@keyframes oQbfJolm_draw_13{17.59259259259259%{stroke-dashoffset:300}73.14814814814815%,to{stroke-dashoffset:0}}@keyframes oQbfJolm_draw_14{18.51851851851852%{stroke-dashoffset:298}74.07407407407408%,to{stroke-dashoffset:0}}@keyframes oQbfJolm_draw_15{19.444444444444446%{stroke-dashoffset:298}75%,to{stroke-dashoffset:0}}@keyframes oQbfJolm_draw_16{20.370370370370374%{stroke-dashoffset:9082}75.92592592592592%,to{stroke-dashoffset:0}}@keyframes oQbfJolm_draw_17{21.296296296296298%{stroke-dashoffset:1511}76.85185185185186%,to{stroke-dashoffset:0}}@keyframes oQbfJolm_draw_18{22.22222222222222%{stroke-dashoffset:1226}77.77777777777779%,to{stroke-dashoffset:0}}@keyframes oQbfJolm_draw_19{23.14814814814815%{stroke-dashoffset:2202}78.70370370370371%,to{stroke-dashoffset:0}}@keyframes oQbfJolm_draw_20{24.074074074074076%{stroke-dashoffset:2257}79.62962962962963%,to{stroke-dashoffset:0}}@keyframes oQbfJolm_draw_21{25%{stroke-dashoffset:392}80.55555555555556%,to{stroke-dashoffset:0}}@keyframes oQbfJolm_draw_22{25.925925925925924%{stroke-dashoffset:48}81.4814814814815%,to{stroke-dashoffset:0}}@keyframes oQbfJolm_draw_23{26.851851851851855%{stroke-dashoffset:23}82.40740740740742%,to{stroke-dashoffset:0}}@keyframes oQbfJolm_draw_24{27.77777777777778%{stroke-dashoffset:269}83.33333333333334%,to{stroke-dashoffset:0}}@keyframes oQbfJolm_draw_25{28.70370370370371%{stroke-dashoffset:84}84.25925925925927%,to{stroke-dashoffset:0}}@keyframes oQbfJolm_draw_26{29.629629629629633%{stroke-dashoffset:93}85.18518518518519%,to{stroke-dashoffset:0}}@keyframes oQbfJolm_draw_27{30.555555555555557%{stroke-dashoffset:355}86.11111111111111%,to{stroke-dashoffset:0}}@keyframes oQbfJolm_draw_28{31.481481481481488%{stroke-dashoffset:640}87.03703703703705%,to{stroke-dashoffset:0}}@keyframes oQbfJolm_draw_29{32.407407407407405%{stroke-dashoffset:2261}87.96296296296298%,to{stroke-dashoffset:0}}@keyframes oQbfJolm_draw_30{33.33333333333333%{stroke-dashoffset:1287}88.88888888888889%,to{stroke-dashoffset:0}}</style></svg>'
        );
        return svgXml;
    }

    /*///////////////////////////////////////////////////////////////
                               UTILITY FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice  Converts a bytes32 into string format.
     * @dev     Used for playerName which is bytes32 on-chain.
     * @param   bytes32_  The bytes32 input.
     * @return  convertedString_  The string equivalent of the bytes32 input.
     */
    function bytes32ToString(bytes32 bytes32_) internal pure returns (string memory convertedString_) {
        uint8 i = 0;
        while (i < 32 && bytes32_[i] != 0) {
            i++;
        }
        bytes memory bytesArray = new bytes(i);
        for (i = 0; i < 32 && bytes32_[i] != 0; i++) {
            bytesArray[i] = bytes32_[i];
        }
        return string(bytesArray);
    }
}