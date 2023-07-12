// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (utils/Strings.sol)

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
// OpenZeppelin Contracts (last updated v4.9.0) (utils/math/Math.sol)

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

//SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

library Constants {  
  uint256 constant MAX_COLOR = type(uint24).max; // 0xffffff
  uint256 constant NUMBER_OF_BACKGROUNDS = 4;
  uint256 constant NUMBER_OF_ARMS = 4;
  uint256 constant NUMBER_OF_EYEBROWS = 3;
  uint256 constant NUMBER_OF_MOUTHS = 6;
  uint256 constant NUMBER_OF_MOUSTACHE = 5;
  uint256 constant NUMBER_OF_HATS = 3;
  uint256 constant kidTime_MIN = 2 hours;
  uint256 constant adultTime_MIN = 2 weeks;
  uint256 constant oldTime_MIN = 20 hours;
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "./Structs.sol";

interface IERC721short {
  function ownerOf(uint256 tokenId) external view returns (address);
}

interface IPeepsMetadata {
  function getTimes(uint256 genes) external view returns (
    uint32 kidTime,
    uint32 adultTime,
    uint32 oldTime
  );
  function tokenURI(Peep calldata peep, uint256 id) external view returns (string memory);
  function getPM2() external view returns (address);
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "./base64.sol";
import { Strings } from "@openzeppelin/contracts/utils/Strings.sol";
import "./Structs.sol";
import "./Constants.sol";
import "./SVGData.sol";
import { PeepsMetadata2 } from "./PeepsMetadata2.sol";
import { IERC721short } from "./Interfaces.sol";


/**
 * @title PeepsMetadata (part 1)
 * @notice all functions are view 
 */
contract PeepsMetadata {
  using Strings for uint256;
  PeepsMetadata2 immutable PM2;

  // avoiding contract size limit
  constructor() payable {
    PM2 = new PeepsMetadata2();
  }

  /**
   * @dev returns tokenURI with 
   * a name, discription, attributes and SVG image
   */
  function tokenURI(Peep calldata peep, uint256 id) external view returns (string memory) {
    string memory description;
    if (peep.isBuried) {
      description = "This is a buried Peep!";
    } else if (block.timestamp < peep.kidTime) {
      description = "This is a kid Peep!";
    } else if (block.timestamp < peep.adultTime) {
      description = "This is an adult Peep!";
    } else if (block.timestamp < peep.oldTime) {
      description = "This is an old Peep!";
    } else {
      description = "This is a dead Peep!";
    }
    
    string memory attributes = PM2.getAttributes(peep);
    string memory image = Base64.encode(bytes(
      generatePeep(peep, id)
    ));

    return generateSVGTokenURI(peep.peepName, description, image, attributes);
  }

  /**
   * @dev returns the SVG image of a peep
   */
  function generatePeep(Peep calldata peep, uint256 id) internal view returns (string memory) {
    string memory header = '<svg xmlns="http://www.w3.org/2000/svg" width="400" height="400">';
    string memory footer = '</svg>';
    if (!peep.isBuried) {
      if (block.timestamp < peep.kidTime) {
        return string(abi.encodePacked(header, getKid(peep), footer));
      } else if (block.timestamp < peep.adultTime) {
        return string(abi.encodePacked(header, getAdult(peep, id), footer));
      } else if (block.timestamp < peep.oldTime) {
        return string(abi.encodePacked(header, getOld(peep), footer));
      } else {
        return string(abi.encodePacked(header, getDead(peep), footer));
      } 
    } else {
      return string(abi.encodePacked(header, 
        PM2.getGravestone(
          peep,
          IERC721short(msg.sender).ownerOf(id)
        ), footer
      ));
    }
  }

  /**
   * @dev returns the SVG image of a kid
   */
  function getKid(Peep calldata peep) internal view returns (string memory svg) {
    uint256 genes = peep.genes;    
    // avoiding 'Stack too deep' error
    uint256 x1;
    uint256 x2;
    uint256 x3;
    uint256 x4;

    // background
    x1 = genes % Constants.NUMBER_OF_BACKGROUNDS;
    genes /= 10; // changing the number
    x2 = genes % Constants.MAX_COLOR;
    genes /= 10;
    x3 = genes % Constants.MAX_COLOR;
    svg = PM2.getBackground(x1, uint24(x2), uint24(x3));

    // legs
    svg = string(abi.encodePacked(svg,
      '<path d="M190 180, 190 280, 180 290" fill="none" stroke="black" stroke-width="3"/>',
      '<path d="M210 180, 210 280, 220 290" fill="none" stroke="black" stroke-width="3"/>'
    ));

    // arms
    genes /= 10;
    x1 = genes % 2;
    genes /= 10;
    x2 = genes % 2;
    genes /= 10;
    x3 = genes % Constants.NUMBER_OF_ARMS;
    genes /= 10;
    x4 = genes % Constants.NUMBER_OF_ARMS; 
    svg = string(abi.encodePacked(svg,
      SVGData.getKidArms(x1, x2, x3, x4)
    ));

    // body
    svg = string(abi.encodePacked(svg,
      '<ellipse cx="200" cy="200" rx="30" ry="45" fill="#',
      SVGData.toColor(peep.bodyColor1),
      '" stroke="black"/>'
    ));

    // head
    svg = string(abi.encodePacked(svg,
      '<ellipse cx="200" cy="145" rx="15" ry="20" fill="white"  stroke="black"/>'
    ));

    // eyebrows
    genes /= 10;
    x1 = genes % Constants.NUMBER_OF_EYEBROWS;
    svg = string(abi.encodePacked(svg,
      SVGData.getKidEyebrows(x1)
    ));

    // eyes
    string memory color = SVGData.toColor(peep.eyesColor);
    svg = string(abi.encodePacked(svg,
      '<circle cx="193" cy="141" r="2" fill="#',
      color,
      '" stroke="black"/>',
      '<circle cx="205" cy="141" r="2" fill="#',
      color,
      '" stroke="black"/>'
    ));

    // mouth
    genes /= 100;
    x1 = genes % Constants.NUMBER_OF_MOUTHS;
    svg = string(abi.encodePacked(svg,
      SVGData.getKidMouth(x1)
    ));

    // hat
    svg = string(abi.encodePacked(svg,
      SVGData.getKidHat(peep.hasHat)
    ));
  }

  /**
   * @dev returns the SVG image of an adult
   */
  function getAdult(Peep calldata peep, uint256 id) internal view returns (string memory svg) {
    uint256 genes = peep.genes;    
    // avoiding 'Stack too deep' error
    uint256 x1;
    uint256 x2;
    uint256 x3;
    uint256 x4;

    // background
    x1 = genes % Constants.NUMBER_OF_BACKGROUNDS;
    genes /= 10; // changing the number
    x2 = genes % Constants.MAX_COLOR;
    genes /= 10;
    x3 = genes % Constants.MAX_COLOR;
    svg = PM2.getBackground(x1, uint24(x2), uint24(x3));

    // legs
    svg = string(abi.encodePacked(svg,
      SVGData.getAdultLegs()
    ));

    // arms
    genes /= 10;
    x1 = genes % 2;
    genes /= 10;
    x2 = genes % 2;
    genes /= 10;
    x3 = genes % Constants.NUMBER_OF_ARMS;
    genes /= 10;
    x4 = genes % Constants.NUMBER_OF_ARMS; 
    svg = string(abi.encodePacked(svg,
      SVGData.getAdultArms(x1,x2,x3,x4,false)
    ));

    // body
    string memory idString = id.toString();
    svg = string(abi.encodePacked(svg,
      '<defs><linearGradient id="',
      idString,
      '" gradientUnits="userSpaceOnUse" x1="150" y1="150" x2="250" y2="250"><stop offset="0%" stop-color="#',
      SVGData.toColor(peep.bodyColor1),
      '"/><stop offset="120%" stop-color="#',
      SVGData.toColor(peep.bodyColor2),
      '"/></linearGradient></defs><ellipse cx="200" cy="200" rx="60" ry="90" fill="url(#',
      idString,
      ')" stroke="black"/>'
    ));

    // head
    svg = string(abi.encodePacked(svg,
      SVGData.getAdultHead()
    ));

    // eyebrows
    genes /= 10;
    x1 = genes % Constants.NUMBER_OF_EYEBROWS;
    svg = string(abi.encodePacked(svg,
      SVGData.getAdultEyebrows(x1)
    ));

    // eyes
    svg = string(abi.encodePacked(svg,
      SVGData.getAdultEyes(peep.eyesColor)
    ));

    // moustache
    genes /= 10;
    x1 = genes % Constants.NUMBER_OF_MOUSTACHE;
    svg = string(abi.encodePacked(svg,
      SVGData.getMoustache(x1)
    ));

    // mouth
    genes /= 10;
    x1 = genes % Constants.NUMBER_OF_MOUTHS;
    svg = string(abi.encodePacked(svg,
      SVGData.getAdultMouth(x1)
    ));

    // hat
    svg = string(abi.encodePacked(svg,
      SVGData.getAdultHat(peep.hasHat)
    ));
  }

  /**
   * @dev returns the SVG image of an old
   */
  function getOld(Peep calldata peep) internal view returns (string memory svg) {
    uint256 genes = peep.genes;    
    // avoiding 'Stack too deep' error
    uint256 x1;
    uint256 x2;
    uint256 x3;
    uint256 x4;

    // background
    x1 = genes % Constants.NUMBER_OF_BACKGROUNDS;
    genes /= 10; // changing the number
    x2 = genes % Constants.MAX_COLOR;
    genes /= 10;
    x3 = genes % Constants.MAX_COLOR;
    svg = PM2.getBackground(x1, uint24(x2), uint24(x3));

    // legs
    svg = string(abi.encodePacked(svg,
      SVGData.getAdultLegs()
    ));

    // arms
    genes /= 10;
    x1 = genes % 2;
    genes /= 10;
    x2 = genes % 2;
    genes /= 10;
    x3 = genes % Constants.NUMBER_OF_ARMS;
    genes /= 10;
    x4 = genes % Constants.NUMBER_OF_ARMS; 
    svg = string(abi.encodePacked(svg,
      SVGData.getAdultArms(x1,x2,x3,x4,true)
    ));

    // body
    svg = string(abi.encodePacked(svg,
      '<ellipse cx="200" cy="200" rx="60" ry="90" fill="#',
      SVGData.toColor(peep.bodyColor2),
      '" stroke="black"/>'
    ));

    // head
    svg = string(abi.encodePacked(svg,
      SVGData.getAdultHead()
    ));

    // eyebrows
    genes /= 10;
    x1 = genes % Constants.NUMBER_OF_EYEBROWS;
    svg = string(abi.encodePacked(svg,
      SVGData.getAdultEyebrows(x1)
    ));

    // eyes
    svg = string(abi.encodePacked(svg,
      SVGData.getAdultEyes(peep.eyesColor)
    ));

    // wrinkles
    svg = string(abi.encodePacked(svg,
      SVGData.getWrinkles()
    ));

    // moustache
    genes /= 10;
    x1 = genes % Constants.NUMBER_OF_MOUSTACHE;
    svg = string(abi.encodePacked(svg,
      SVGData.getMoustache(x1)
    ));

    // mouth
    genes /= 10;
    x1 = genes % Constants.NUMBER_OF_MOUTHS;
    svg = string(abi.encodePacked(svg,
      SVGData.getAdultMouth(x1)
    ));

    // hat
    svg = string(abi.encodePacked(svg,
      SVGData.getAdultHat(peep.hasHat)
    ));
  }
  
  /**
   * @dev returns the SVG image of a dead
   */
  function getDead(Peep calldata peep) internal view returns (string memory svg) {
    uint256 genes = peep.genes;    
    // avoiding 'Stack too deep' error
    uint256 x1;
    uint256 x2;
    uint256 x3;

    // background
    x1 = genes % Constants.NUMBER_OF_BACKGROUNDS;
    genes /= 10; // changing the number
    x2 = genes % Constants.MAX_COLOR;
    genes /= 10;
    x3 = genes % Constants.MAX_COLOR;
    svg = PM2.getBackground(x1, uint24(x2), uint24(x3));

    // legs
    svg = string(abi.encodePacked(svg,
      SVGData.getAdultLegs()
    ));

    // arms
    genes /= 1000;
    x1 = genes % Constants.NUMBER_OF_ARMS;
    genes /= 10;
    x2 = genes % Constants.NUMBER_OF_ARMS; 
    svg = string(abi.encodePacked(svg,
      SVGData.getAdultArms(0,0,x1,x2,false)
    ));

    // body
    svg = string(abi.encodePacked(svg,
      '<ellipse cx="200" cy="200" rx="60" ry="90" fill="grey" stroke="black"/>'
    ));

    // head
    svg = string(abi.encodePacked(svg,
      SVGData.getAdultHead()
    ));

    // eyebrows
    genes /= 10;
    x1 = genes % Constants.NUMBER_OF_EYEBROWS;
    svg = string(abi.encodePacked(svg,
      SVGData.getAdultEyebrows(x1)
    ));

    // eyes
    svg = string(abi.encodePacked(svg,
      '<line x1="192" y1="76" x2="181" y2="84" stroke="black"/><line x1="182" y1="76" x2="191" y2="84" stroke="black"/><line x1="215" y1="76" x2="204" y2="84" stroke="black"/><line x1="205" y1="76" x2="214" y2="84" stroke="black"/>'
    ));

    // wrinkles
    svg = string(abi.encodePacked(svg,
      SVGData.getWrinkles()
    ));

    // moustache
    genes /= 10;
    x1 = genes % Constants.NUMBER_OF_MOUSTACHE;
    svg = string(abi.encodePacked(svg,
      SVGData.getMoustache(x1)
    ));

    // mouth
    genes /= 10;
    x1 = genes % Constants.NUMBER_OF_MOUTHS;
    svg = string(abi.encodePacked(svg,
      SVGData.getAdultMouth(x1)
    ));

    // hat
    svg = string(abi.encodePacked(svg,
      SVGData.getAdultHat(peep.hasHat)
    ));
  }

  function generateSVGTokenURI(
    string memory name,
    string memory description,
    string memory image,
    string memory attributes
  ) internal pure returns (string memory) {
    return
      string(
        abi.encodePacked(
          "data:applicaton/json;base64,",
          Base64.encode(
            bytes(
              abi.encodePacked(
                '{"name": "',
                name,
                '", "description": "',
                description,
                '", "image": "data:image/svg+xml;base64,',
                image,
                '", "attributes": ',
                attributes,
                '}'
              )
            )
          )
        )
      );
  }

  /**
   * @dev returns ages of a peep
   */
  function getTimes(uint256 genes) external view returns (
    uint32 kidTime,
    uint32 adultTime,
    uint32 oldTime
  ) {
      kidTime = uint32(genes % Constants.kidTime_MIN + block.timestamp + Constants.kidTime_MIN);
      adultTime = uint32(genes % Constants.adultTime_MIN + Constants.adultTime_MIN) + kidTime;
      oldTime = uint32(genes % Constants.oldTime_MIN + Constants.oldTime_MIN) + adultTime;
  }

  function getPM2() external view returns (address) {
    return address(PM2);
  }
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import { Strings } from "@openzeppelin/contracts/utils/Strings.sol";
import "./Structs.sol";
import "./Constants.sol";

/**
 * @title PeepsMetadata (part 2)
 * @notice all functions are pure 
 */
contract PeepsMetadata2 {
  using Strings for uint256;
  bytes16 internal constant ALPHABET = '0123456789abcdef';

  /**
   * @dev returns the attributes of a peep
   */
  function getAttributes(Peep calldata peep) external pure returns (string memory attributes) {
    uint256 genes = peep.genes;
    uint256 x1;
    uint256 x2;
    uint256 x3;

    attributes = string(abi.encodePacked(attributes,
      '[{"trait_type": "Birth time", "value": "',
      uint256(peep.birthTime).toString(),
      '"},'
    ));

    attributes = string(abi.encodePacked(attributes,
      '{"trait_type": "Adulthood", "value": "',
      uint256(peep.kidTime).toString(),
      '"},'
    ));

    attributes = string(abi.encodePacked(attributes,
      '{"trait_type": "Old age", "value": "',
      uint256(peep.adultTime).toString(),
      '"},'
    ));

    attributes = string(abi.encodePacked(attributes,
      '{"trait_type": "Death", "value": "',
      uint256(peep.oldTime).toString(),
      '"},'
    ));

    // background
    x1 = genes % Constants.NUMBER_OF_BACKGROUNDS;
    genes /= 10;
    x2 = genes % Constants.MAX_COLOR;
    genes /= 10;
    x3 = genes % Constants.MAX_COLOR;
    attributes = string(abi.encodePacked(attributes,
      '{"trait_type": "Background type", "value": "',
      x1.toString(),
      '"},'
    ));

    attributes = string(abi.encodePacked(attributes,
      '{"trait_type": "Background color 1", "value": "#',
      toColor(uint24(x2)),
      '"},'
    ));

    attributes = string(abi.encodePacked(attributes,
      '{"trait_type": "Background color 2", "value": "#',
      toColor(uint24(x3)),
      '"},'
    ));

    // arms
    genes /= 10;
    x1 = genes % 2;
    genes /= 10;
    x2 = genes % 2;
    attributes = string(abi.encodePacked(attributes,
      '{"trait_type": "Is left arm animated", "value": "',
      boolToString(x1),
      '"},'
    ));

    attributes = string(abi.encodePacked(attributes,
      '{"trait_type": "Is right arm animated", "value": "',
      boolToString(x2),
      '"},'
    ));

    genes /= 10;
    x1 = genes % Constants.NUMBER_OF_ARMS;
    genes /= 10;
    x2 = genes % Constants.NUMBER_OF_ARMS;
    attributes = string(abi.encodePacked(attributes,
      '{"trait_type": "Left arm type", "value": "',
      x1.toString(),
      '"},'
    ));

    attributes = string(abi.encodePacked(attributes,
      '{"trait_type": "Right arm type", "value": "',
      x2.toString(),
      '"},'
    ));

    // body colors
    attributes = string(abi.encodePacked(attributes,
      '{"trait_type": "Body color 1", "value": "#',
      toColor(peep.bodyColor1),
      '"},'
    ));

    attributes = string(abi.encodePacked(attributes,
      '{"trait_type": "Body color 2", "value": "#',
      toColor(peep.bodyColor2),
      '"},'
    ));

    // eyebrows
    genes /= 10;
    x1 = genes % Constants.NUMBER_OF_EYEBROWS;
    attributes = string(abi.encodePacked(attributes,
      '{"trait_type": "Eyebrows type", "value": "',
      x1.toString(),
      '"},'
    ));

    // eyes
    attributes = string(abi.encodePacked(attributes,
      '{"trait_type": "Eye color", "value": "#',
      toColor(peep.eyesColor),
      '"},'
    ));

    // moustache
    genes /= 10;
    x1 = genes % Constants.NUMBER_OF_MOUSTACHE;
    attributes = string(abi.encodePacked(attributes,
      '{"trait_type": "Moustache type", "value": "',
      x1.toString(),
      '"},'
    ));

    // mouth
    genes /= 10;
    x1 = genes % Constants.NUMBER_OF_MOUTHS;
    attributes = string(abi.encodePacked(attributes,
      '{"trait_type": "Mouth type", "value": "',
      x1.toString(),
      '"},'
    ));

    // hat
    attributes = string(abi.encodePacked(attributes,
      '{"trait_type": "Hat type", "value": "',
      getHatTrait(peep.hasHat),
      '"}'
    ));

    attributes = string(abi.encodePacked(attributes,
      ']'
    ));
  }

  /**
   * @dev rreturns the SVG image of a gravestone
   */
  function getGravestone(Peep calldata peep, address peepOwner) external pure returns (string memory svg) {
    uint256 genes = peep.genes;    
    // avoiding 'Stack too deep' error
    uint256 x1;
    uint256 x2;
    uint256 x3;

    // background
    x1 = genes % Constants.NUMBER_OF_BACKGROUNDS;
    genes /= 10; // changing the number
    x2 = genes % Constants.MAX_COLOR;
    genes /= 10;
    x3 = genes % Constants.MAX_COLOR;
    svg = getBackground(x1, uint24(x2), uint24(x3));

    // gravestone
    svg = string(abi.encodePacked(svg,
      '<rect width="250" height="15" x="80" y="350" fill="grey" stroke="black"/><path d="M80 350, 330 350, 310 340, 100 340 z" fill="grey" stroke="black"/><path d="M110 345, 300 345, 300 120, 270 120, 205 100, 140 120, 110 120 z" fill="grey" stroke="black"/><path d="M140 120 C210 40, 270 120, 270 120" fill="grey" stroke="black"/>'
    ));
    
    // traits style
    svg = string(abi.encodePacked(svg,
      '<style>.trait { fill: black; font-family: serif; font-size: 16px; }</style><style>.value { fill: black; font-family: serif; font-size: 13px; }</style>'
    ));

    svg = string(abi.encodePacked(svg,
      '<text x="125" y="160" class="trait">',
      'Name: </text><text x="185" y="160" class="value">',
      getFittingName(peep.peepName),
      '</text>'
    ));

    svg = string(abi.encodePacked(svg,
      '<text x="125" y="190" class="trait">',
      'Owner: </text><text x="190" y="190" class="value">',
      addressToString(peepOwner),
      '</text>'
    ));  

    svg = string(abi.encodePacked(svg,
      '<text x="125" y="220" class="trait">',
      'Lifetime: </text><text x="203" y="220" class="value">',
      '~ ',
      getLifetime(peep.birthTime, peep.oldTime).toString(),
      ' h',
      '</text>'
    )); 

    uint64[] memory arr = new uint64[](2);
    arr[0] = peep.parents[0];
    arr[1] = peep.parents[1];
    svg = string(abi.encodePacked(svg,
      '<text x="125" y="250" class="trait">',
      'Parents: </text><text x="198" y="250" class="value">',
      arrayToString(arr),
      '</text>'
    ));

    arr = peep.children;
    svg = string(abi.encodePacked(svg,
      '<text x="125" y="280" class="trait">',
      'Kids: </text><text x="175" y="280" class="value">',
      arrayToString(arr),
      '</text>'
    ));

    // hat
    svg = string(abi.encodePacked(svg,
      getGravestoneHat(peep.hasHat)
    ));
  }

  function getBackground(
    uint256 background,
    uint24 color1,
    uint24 color2
  ) public pure returns (string memory) {
    if (background == 0)
      return string(abi.encodePacked(
        '<path d="M 0 230, 400 180, 400 400, 0 400 z" fill="#',
        toColor(color1),
        '" stroke="black"/>',
        '<path d="M 0 230, 400 180, 400 0, 0 0 z" fill="#',
        toColor(color2),
        '" stroke="black"/>'
      ));
    else if (background == 1) 
      return string(abi.encodePacked(
        '<path d="M 0 60, 400 250, 400 400, 0 400 z" fill="#',
        toColor(color1),
        '" stroke="black"/>',
        '<path d="M 0 60, 400 250, 400 0, 0 0 z" fill="#',
        toColor(color2),
        '" stroke="black"/>'
      ));
    else if (background == 2)
      return string(abi.encodePacked(
        '<path d="M 0 260 C0 260, 100 112, 400 260 M 400 260, 400 400, 0 400 0 260" fill="#',
        toColor(color1),
        '" stroke="black"/>',
        '<path d="M 0 260 C0 260, 100 112, 400 260 M 400 260, 400 0, 0 0 0 260" fill="#',
        toColor(color2),
        '" stroke="black"/>'
      ));
    else
      return string(abi.encodePacked(
        '<path d="M400 200, 400 400, 0 400, 0 260 C100 112, 200 370, 400 200 " fill="#',
        toColor(color1),
        '" stroke="black"/>',
        '<path d="M400 200, 400 0, 0 0, 0 260 C100 112, 200 370, 400 200 " fill="#',
        toColor(color2),
        '" stroke="black"/>'
      ));
  }

  function getGravestoneHat(uint256 hat) internal pure returns (string memory) {
    if (hat == 0) return '';
    uint256 hatType = hat % Constants.NUMBER_OF_HATS;
    string memory color = toColor(uint24(hat));
    if (hatType == 0) return string(abi.encodePacked(
      '<ellipse cx="210" cy="85" rx="50" ry="10" fill="#',
      color,
      '" stroke="black"/><path d="M180 83 A120 900 0 0 1 240 83" fill="#',
      color,
      '" stroke="black"/>'));
    else if (hatType == 1) return string(abi.encodePacked(
      '<ellipse cx="210" cy="85" rx="20" ry="10" fill="#',
      color,
      '" stroke="black"/><path d="M200 83 200 50 210 70 220 50 220 83" fill="#',
      color,
      '" stroke="black"/>'));
    else return string(abi.encodePacked(
      '<path d="M175 93, 180 85, 185 77, 187 75, 190 73, 195 70, 200 70, 205 71, 210 72, 215 73, 240 83, 245 86, 253 95, 255 99, 257 110, 255 115, 250 115, 240 110, 235 105, 230 100, 225 97, 210 91, 200 90, 175 93" fill="#',
      color,
      '" stroke="black"/>'));
  }

  function getHatTrait(uint256 hat) internal pure returns (string memory attributes) {
    if (hat == 0) return 'None';
    else {
      return string(abi.encodePacked(  
      (hat % Constants.NUMBER_OF_HATS).toString(),
      '"},',
      '{"trait_type": "Hat color", "value": "#',
      toColor(uint24(hat))
      ));
    }
  }

  function getLifetime(uint256 birthTime, uint256 deathTime) internal pure returns (uint256) {
    return (deathTime - birthTime) / 1 hours;
  }

  function arrayToString(uint64[] memory arr) internal pure returns (string memory str) {
    uint256 len = arr.length;
    if (len == 0) return 'None';
    if (arr[0] == 0) return 'None';
    --len;
    for (uint256 i; i < len;) {
      str = string(abi.encodePacked(str,
      uint256(arr[i]).toString(),
      ', '
      ));  
      unchecked {++i;}
    }
    str = string(abi.encodePacked(str,
      uint256(arr[len]).toString()
    ));
  }

  function toColor(uint24 color) internal pure returns (string memory) {
    bytes3 value = bytes3(color);
    bytes memory buffer = new bytes(6);
    for (uint256 i; i < 3;) {
      buffer[i*2+1] = ALPHABET[uint8(value[i]) & 0xf];
      buffer[i*2] = ALPHABET[uint8(value[i]>>4) & 0xf];
      unchecked {++i;}
    }    
    return string(buffer);
  }

  function boolToString(uint256 _bool) internal pure returns (string memory) {
    if (_bool == 0) return 'No';
    else return 'Yes';
  }

  function addressToString(address x) internal pure returns (string memory addrStr) {
    addrStr = '0x';
    bytes memory s = new bytes(4);
    bytes1 b;
    bytes1 hi;
    bytes1 lo;
    for (uint256 i; i < 2;) {
      b = bytes1(uint8(uint256(uint160(x)) / (2**(8 * (19 - i)))));
      hi = bytes1(uint8(b) / 16);
      lo = bytes1(uint8(b) - 16 * uint8(hi));
      s[2 * i] = char(hi);
      s[2 * i + 1] = char(lo);
      unchecked {++i;}
    }
    addrStr = string(abi.encodePacked(addrStr,
      string(s),
      '...'
    ));

    s = new bytes(4);
    for (uint256 i = 18; i < 20;) {
      b = bytes1(uint8(uint256(uint160(x)) / (2**(8 * (19 - i)))));
      hi = bytes1(uint8(b) / 16);
      lo = bytes1(uint8(b) - 16 * uint8(hi));
      s[2 * (i - 18)] = char(hi);
      s[2 * (i - 18) + 1] = char(lo);
      unchecked {++i;}
    }

    addrStr = string(abi.encodePacked(addrStr,
      string(s)
    ));   
  }

  /**
   * @dev returns a short name if name.length > 11
   */
  function getFittingName(string calldata x) internal pure returns (string memory) {
    bytes memory y = bytes(x);
    if (y.length < 12) return x;

    bytes memory s;
    for (uint256 i; i < 11;) {
      s = abi.encodePacked(s, bytes1(y[i]));
      unchecked {++i;}
    }

    return string(abi.encodePacked(string(s),
      '...'
    ));
  }

  function char(bytes1 b) internal pure returns (bytes1 c) {
    if (uint8(b) < 10) return bytes1(uint8(b) + 0x30);
    else return bytes1(uint8(b) + 0x57);
  }
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

/**
 * @title SVGData
 * @dev returns parts of a peep's body
 */
library SVGData {
  bytes16 internal constant ALPHABET = '0123456789abcdef';
  uint256 constant NUMBER_OF_HATS = 3;

  function getAdultLegs() internal pure returns (string memory) {
    return string(abi.encodePacked(
      '<path d="M180 280, 180 360, 160 375" fill="none" stroke="black" stroke-width="5"/>',
      '<path d="M215 280, 215 360, 235 375" fill="none" stroke="black" stroke-width="5"/>'));
  }

  function getAdultHead() internal pure returns (string memory) {
    return 
      '<ellipse cx="200" cy="90" rx="30" ry="40" fill="white" stroke="black"/>';
  }

  function getAdultEyes(uint256 eyeColor) internal pure returns (string memory) {
    string memory color = toColor(uint24(eyeColor));
    return string(abi.encodePacked(
      '<circle cx="187" cy="80" r="5" fill="#',
      color,
      '" stroke="black"/>',
      '<circle cx="210" cy="80" r="5" fill="#',
      color,
      '" stroke="black"/>'
    ));
  }

  function getWrinkles() internal pure returns (string memory) {
    return 
      '<line x1="180" y1="77" x2="175" y2="75" stroke="black"/><line x1="180" y1="80" x2="175" y2="80" stroke="black"/><line x1="180" y1="83" x2="175" y2="85" stroke="black"/><line x1="217" y1="77" x2="222" y2="75" stroke="black"/><line x1="217" y1="80" x2="222" y2="80" stroke="black"/><line x1="217" y1="83" x2="222" y2="85" stroke="black"/>';
  }

  function getKidArms(
    uint256 isLeftAnimated,
    uint256 isRightAnimated,
    uint256 leftArm,
    uint256 rightArm
  ) internal pure returns (string memory arms) { 
    if (isLeftAnimated == 0) {
      if (leftArm == 0) arms = 
        '<line x1="181" y1="168" x2="155" y2="215" stroke="black" stroke-width="3"/>';
      else if (leftArm == 1) arms = 
        '<line x1="180" y1="168" x2="153" y2="127" stroke="black" stroke-width="3"/>';
      else if (leftArm == 2) arms = 
        '<path d="M181 168 L168 168 C148 150, 150 185, 125 168" fill="none" stroke="black" stroke-width="3"/>';
      else arms = 
        '<path d="M181 168 L168 168 C148 190, 150 145, 125 165" fill="none" stroke="black" stroke-width="3"/>';
    } else {
      if (leftArm < 2) arms = 
        '<line x1="181" y1="168" x2="155" y2="215" stroke="black" stroke-width="3"><animate attributeName="x2" attributeType="XML" values="155;125;155;125;155" dur="2s" repeatCount="indefinite"/><animate attributeName="y2" attributeType="XML" values="215;170;127;170;215" dur="2s" repeatCount="indefinite"/></line>';
      else arms = 
        '<path fill="none" stroke="black" stroke-width="3"><animate attributeName="d" attributeType="XML" values="M181 168 L168 168 C148 150, 150 185, 125 168; M181 168 L168 168 C148 190, 150 145, 125 165; M181 168 L168 168 C148 150, 150 185, 125 168" dur="2s" repeatCount="indefinite"/></path>';
    }
    if (isRightAnimated == 0) {
      if (rightArm == 0) arms = string(abi.encodePacked(arms,
        '<line x1="219" y1="168" x2="246" y2="215" stroke="black" stroke-width="3"/>'));
      else if (rightArm == 1) arms = string(abi.encodePacked(arms,
        '<line x1="220" y1="168" x2="248" y2="127" stroke="black" stroke-width="3"/>'));
      else if (rightArm == 2) arms = string(abi.encodePacked(arms,
        '<path d="M218 168 L231 168 C251 150, 249 185, 274 168" fill="none" stroke="black" stroke-width="3"/>'));
      else arms = string(abi.encodePacked(arms,
        '<path d="M218 168 L231 168 C251 190, 249 145, 274 165" fill="none" stroke="black" stroke-width="3"/>'));
    } else {
      if (rightArm < 2) arms = string(abi.encodePacked(arms,
        '<line x1="219" y1="168" x2="246" y2="215" stroke="black" stroke-width="3"><animate attributeName="x2" attributeType="XML" values="246;276;246;276;246" dur="2s" repeatCount="indefinite"/><animate attributeName="y2" attributeType="XML" values="215;170;127;170;215" dur="2s" repeatCount="indefinite" /></line>'));
      else arms = string(abi.encodePacked(arms,
        '<path fill="none" stroke="black" stroke-width="3"><animate attributeName="d" attributeType="XML" values="M218 168 L231 168 C251 150, 249 185, 274 168; M218 168 L231 168 C251 190, 249 145, 274 165; M218 168 L231 168 C251 150, 249 185, 274 168" dur="2s" repeatCount="indefinite"/></path>'));
    }    
  }

  function getAdultArms(
    uint256 isLeftAnimated,
    uint256 isRightAnimated,
    uint256 leftArm,
    uint256 rightArm,
    bool isOld
  ) internal pure returns (string memory arms) { 
    string memory dur;
    if (isOld) dur = "4s"; 
    else dur = "2s";

    if (isLeftAnimated == 0) {
      if (leftArm == 0) arms = 
        '<line x1="165" y1="130" x2="100" y2="240" stroke="black" stroke-width="5"/>';
      else if (leftArm == 1) arms = 
        '<line x1="165" y1="130" x2="100" y2="50" stroke="black" stroke-width="5"/>';
      else if (leftArm == 2) arms = 
        '<path d="M165 130 L145 130 C95 70, 85 190, 35 130" fill="none" stroke="black" stroke-width="5"/>';
      else arms = 
        '<path d="M165 130 L145 130 C95 190, 85 70, 35 125" fill="none" stroke="black" stroke-width="5"/>';
    } else {
      if (leftArm < 2) arms = string(abi.encodePacked(
        '<line x1="165" y1="130" x2="100" y2="240" stroke="black" stroke-width="5"><animate attributeName="x2" attributeType="XML" values="100;50;80;50;100" dur="',
        dur,
        '" repeatCount="indefinite"/><animate attributeName="y2" attributeType="XML" values="240;130;40;130;240" dur="',
        dur,
        '" repeatCount="indefinite"/></line>'));
      else arms = string(abi.encodePacked(
        '<path fill="none" stroke="black" stroke-width="5"><animate attributeName="d" attributeType="XML" values="M165 130 L145 130 C95 70, 85 190, 35 130; M165 130 L145 130 C95 190, 85 70, 35 125; M165 130 L145 130 C95 70, 85 190, 35 130" dur="',
        dur,
        '" repeatCount="indefinite"/></path>'));
    }
    if (isRightAnimated == 0) {
      if (rightArm == 0) arms = string(abi.encodePacked(arms,
        '<line x1="235" y1="130" x2="300" y2="240" stroke="black" stroke-width="5"/>'));
      else if (rightArm == 1) arms = string(abi.encodePacked(arms,
        '<line x1="235" y1="130" x2="300" y2="40" stroke="black" stroke-width="5"/>'));
      else if (rightArm == 2) arms = string(abi.encodePacked(arms,
        '<path d="M235 130 L255 130 C305 70, 315 190, 365 130" fill="none" stroke="black" stroke-width="5"/>'));
      else arms = string(abi.encodePacked(arms,
        '<path d="M235 130 L255 130 C305 190, 315 70, 365 125" fill="none" stroke="black" stroke-width="5"/>'));
    } else {
      if (rightArm < 2) arms = string(abi.encodePacked(arms,
        '<line x1="235" y1="130" x2="300" y2="240" stroke="black" stroke-width="5"><animate attributeName="x2" attributeType="XML" values="300;350;320;350;300" dur="',
        dur,
        '" repeatCount="indefinite"/>  <animate attributeName="y2" attributeType="XML" values="240;130;40;130;240" dur="',
        dur,
        '" repeatCount="indefinite"/></line>'));
      else arms = string(abi.encodePacked(arms,
        '<path fill="none" stroke="black" stroke-width="5"><animate attributeName="d" attributeType="XML" values="M235 130 L255 130 C305 70, 315 190, 365 130; M235 130 L255 130 C305 190, 315 70, 365 125; M235 130 L255 130 C305 70, 315 190, 365 130" dur="',
        dur,
        '" repeatCount="indefinite"/></path>'));
    }    
  }

  function getKidEyebrows(uint256 eyebrows) internal pure returns (string memory) {
    if (eyebrows == 0) return 
      '<path d="M190 136, 196 136" fill="none" stroke="black"/><path d="M201 136, 205 134, 209 136" fill="none" stroke="black"/>';
    else if (eyebrows == 1) return 
      '<path d="M190 136, 192 135, 194 135, 197 136" fill="none" stroke="black"/><path d="M202 136, 204 135, 206 135, 209 136" fill="none" stroke="black"/>';
    else return 
      '<path d="M190 136, 197 136" fill="none" stroke="black"/><path d="M202 136, 209 136" fill="none" stroke="black"/>';
  }

  function getAdultEyebrows(uint256 eyebrows) internal pure returns (string memory) {
    if (eyebrows == 0) return 
      '<path d="M180 71, 194 71" fill="none" stroke="black"/><path d="M203 71, 210 69, 217 71" fill="none" stroke="black"/>';
    else if (eyebrows == 1) return 
      '<path d="M180 73, 182 72, 185 71, 187 71, 189 71, 194 73" fill="none" stroke="black"/><path d="M203 73, 205 72, 208 71, 210 71, 212 71, 217 73" fill="none" stroke="black"/>';
    else return 
      '<path d="M180 71, 194 71" fill="none" stroke="black"/><path d="M203 71, 217 71" fill="none" stroke="black"/>';
  }

  function getMoustache(uint256 moustache) internal pure returns (string memory) {
    if (moustache == 0) return 
      '<path d="M 180 90, 178 91, 178 93, 180 95, 185 97, 195 94, 197 90" fill="none" stroke="black"/><path d="M202 90, 204 94, 214 97, 219 95, 221 93, 221 91, 219 90" fill="none" stroke="black"/>';
    else if (moustache == 1) return 
      '<line x1="187" y1="95" x2="195" y2="95" stroke="black"/><line x1="203" y1="95" x2="211" y2="95" stroke="black"/>';
    else if (moustache == 2) return
      '<path d="M188 96 Q 201 91 211 96" fill="none" stroke="black" stroke-width="2"/>';
    else if (moustache == 3) return
      '<path d="M185 97, 195 94, 197 90" fill="none" stroke="black"/><path d="M202 90, 204 94, 214 97" fill="none" stroke="black"/>';
    else return 
      '';
  }

  function getKidMouth(uint256 mouth) internal pure returns (string memory) {
    if (mouth == 0) return 
      '<path d="M191 153 C197 144, 203 162, 208 153" fill="none" stroke="black"/>';
    else if (mouth == 1) return 
      '<line x1="193" y1="153" x2="206" y2="153" stroke="black"/>';
    else if (mouth == 2) return 
      '<path d="M193 153 C198 157, 201 157, 206 153" fill="none" stroke="black"/>';
    else if (mouth == 3) return 
      '<path d="M193 155, 200 154, 206 151" fill="none" stroke="black"/>';
    else if (mouth == 4) return 
      '<path d="M194 156, 196 153, 197 152, 198 151, 200 150, 202 150, 204 151, 205 152, 206 156" fill="black" stroke="black"/><path d="M194 156 Q 206 147 206 156 z" fill="red" stroke="black"/>';
    else return 
      '<path d="M194 150, 195 153, 196 155, 197 156, 199 157, 200 157, 203 157, 200 157, 203 156, 205 154, 206 150 z" fill="black"/><path d="M196 154, 197 155, 198 156, 200 156, 200 156, 202 156, 204 155, 204 153, 204 153, 203 153, 202 153, 201 153, 200 153" fill="red"/>';
  }

  function getAdultMouth(uint256 mouth) internal pure returns (string memory) {
    if (mouth == 0) return 
      '<path d="M183 107 C193 92, 203 122, 213 107" fill="none" stroke="black"/>';
    else if (mouth == 1) return 
      '<line x1="187" y1="107" x2="210" y2="107" stroke="black"/>';
    else if (mouth == 2) return 
      '<path d="M185 104 C194 112, 202 112, 213 104" fill="none" stroke="black"/>';
    else if (mouth == 3) return 
      '<path d="M187 106, 205 104, 206 104, 207 103, 208 103, 209 102, 210 102, 211 101, 212 101, 213 100" fill="none" stroke="black"/>';
    else if (mouth == 4) return 
      '<path d="M190 110, 191 106, 192 104, 195 101, 198 99, 200 99, 202 99, 207 101, 209 104, 209 107, 210 110 z" fill="black" stroke="black"/><path d="M190 110 Q 210 95 210 110 z" fill="red" stroke="black"/>';
    else return 
      '<path d="M190 102, 191 106, 192 108, 195 112, 198 113, 200 113, 202 113, 207 111, 209 107, 210 102 z" fill="black" stroke="black"/><path d="M192 108, 195 112, 198 113, 200 113, 202 113, 205 112, 207 111, 209 107, 204 106, 203 106, 202 106, 201 106, 200 106" fill="red"/>';
  }

  function getKidHat(uint256 hat) internal pure returns (string memory) {
    if (hat == 0) return '';
    uint256 hatType = hat % NUMBER_OF_HATS;
    string memory color = toColor(uint24(hat));
    if (hatType == 0) return string(abi.encodePacked(
      '<ellipse cx="200" cy="127" rx="24" ry="5" fill="#',
      color,
      '" stroke="black"/><path d="M185 126 A80 800 0 0 1 215 126" fill="#',
      color,
      '" stroke="black"/>'));
    else if (hatType == 1) return string(abi.encodePacked(
      '<ellipse cx="200" cy="127" rx="10" ry="5" fill="#',
      color,
      '" stroke="black"/><path d="M195 127 195 112 200 120 205 112 205 127" fill="#',
      color,
      '" stroke="black"/>'));
    else return string(abi.encodePacked(
      '<path d="M187 131, 191 122, 196 117, 200 116, 203 116, 208 118, 215 121, 225 127, 228 135, 228 143, 226 143, 224 142, 220 139, 217 135, 210 130, 205 129, 197 128 187 131" fill="#',
      color,
      '" stroke="black"/>'));
  }

  function getAdultHat(uint256 hat) internal pure returns (string memory) {
    if (hat == 0) return '';
    uint256 hatType = hat % NUMBER_OF_HATS;
    string memory color = toColor(uint24(hat));
    if (hatType == 0) return string(abi.encodePacked(
      '<ellipse cx="200" cy="55" rx="50" ry="10" fill="#',
      color,
      '" stroke="black"/><path d="M170 53 A120 900 0 0 1 230 53" fill="#',
      color,
      '" stroke="black"/>'));
    else if (hatType == 1) return string(abi.encodePacked(
      '<ellipse cx="200" cy="55" rx="20" ry="10" fill="#',
      color,
      '" stroke="black"/><path d="M190 53 190 20 200 40 210 20 210 53" fill="#',
      color,
      '" stroke="black"/>'));
    else return string(abi.encodePacked(
      '<path d="M175 63, 180 55, 185 47, 187 45, 190 43, 195 40, 200 40, 205 41, 210 42, 215 43, 240 53, 245 56, 253 65, 255 69, 257 80, 255 85, 250 85, 240 80, 235 75, 230 70, 225 67, 210 61, 200 60, 175 63" fill="#',
      color,
      '" stroke="black"/>'));
  }

  function toColor(uint24 color) internal pure returns (string memory) {
    bytes3 value = bytes3(color);
    bytes memory buffer = new bytes(6);
    for (uint256 i; i < 3;) {
      buffer[i*2+1] = ALPHABET[uint8(value[i]) & 0xf];
      buffer[i*2] = ALPHABET[uint8(value[i]>>4) & 0xf];
      unchecked {++i;}
    }    
    return string(buffer);
  }
    
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

struct Peep {
  uint256 genes;
  bool isBuried;
  bool breedingAllowed;
  uint8 breedCount;
  uint24 hasHat;
  uint24 bodyColor1;
  uint24 bodyColor2;
  uint24 eyesColor;
  uint32 birthTime;
  uint32 kidTime;
  uint32 adultTime;
  uint32 oldTime;
  uint64[2] parents;
  uint64[] children;
  string peepName;
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.6.0;

/// @title Base64
/// @author Brecht Devos - <[email protected]>
/// @notice Provides functions for encoding/decoding base64
library Base64 {
  string internal constant TABLE_ENCODE = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';
  bytes  internal constant TABLE_DECODE = hex"0000000000000000000000000000000000000000000000000000000000000000"
  hex"00000000000000000000003e0000003f3435363738393a3b3c3d000000000000"
  hex"00000102030405060708090a0b0c0d0e0f101112131415161718190000000000"
  hex"001a1b1c1d1e1f202122232425262728292a2b2c2d2e2f303132330000000000";

  function encode(bytes memory data) internal pure returns (string memory) {
    if (data.length == 0) return '';

    // load the table into memory
    string memory table = TABLE_ENCODE;

    // multiply by 4/3 rounded up
    uint256 encodedLen = 4 * ((data.length + 2) / 3);

    // add some extra buffer at the end required for the writing
    string memory result = new string(encodedLen + 32);

    assembly {
      // set the actual output length
      mstore(result, encodedLen)

      // prepare the lookup table
      let tablePtr := add(table, 1)

      // input ptr
      let dataPtr := data
      let endPtr := add(dataPtr, mload(data))

      // result ptr, jump over length
      let resultPtr := add(result, 32)

      // run over the input, 3 bytes at a time
      for {} lt(dataPtr, endPtr) {}
      {
        // read 3 bytes
        dataPtr := add(dataPtr, 3)
        let input := mload(dataPtr)

        // write 4 characters
        mstore8(resultPtr, mload(add(tablePtr, and(shr(18, input), 0x3F))))
        resultPtr := add(resultPtr, 1)
        mstore8(resultPtr, mload(add(tablePtr, and(shr(12, input), 0x3F))))
        resultPtr := add(resultPtr, 1)
        mstore8(resultPtr, mload(add(tablePtr, and(shr( 6, input), 0x3F))))
        resultPtr := add(resultPtr, 1)
        mstore8(resultPtr, mload(add(tablePtr, and(        input,  0x3F))))
        resultPtr := add(resultPtr, 1)
      }

      // padding with '='
      switch mod(mload(data), 3)
      case 1 { mstore(sub(resultPtr, 2), shl(240, 0x3d3d)) }
      case 2 { mstore(sub(resultPtr, 1), shl(248, 0x3d)) }
    }

    return result;
  }

  function decode(string memory _data) internal pure returns (bytes memory) {
    bytes memory data = bytes(_data);

    if (data.length == 0) return new bytes(0);
    require(data.length % 4 == 0, "invalid base64 decoder input");

    // load the table into memory
    bytes memory table = TABLE_DECODE;

    // every 4 characters represent 3 bytes
    uint256 decodedLen = (data.length / 4) * 3;

    // add some extra buffer at the end required for the writing
    bytes memory result = new bytes(decodedLen + 32);

    assembly {
      // padding with '='
      let lastBytes := mload(add(data, mload(data)))
      if eq(and(lastBytes, 0xFF), 0x3d) {
        decodedLen := sub(decodedLen, 1)
        if eq(and(lastBytes, 0xFFFF), 0x3d3d) {
          decodedLen := sub(decodedLen, 1)
        }
      }

      // set the actual output length
      mstore(result, decodedLen)

      // prepare the lookup table
      let tablePtr := add(table, 1)

      // input ptr
      let dataPtr := data
      let endPtr := add(dataPtr, mload(data))

      // result ptr, jump over length
      let resultPtr := add(result, 32)

      // run over the input, 4 characters at a time
      for {} lt(dataPtr, endPtr) {}
      {
        // read 4 characters
        dataPtr := add(dataPtr, 4)
        let input := mload(dataPtr)

        // write 3 bytes
        let output := add(
          add(
            shl(18, and(mload(add(tablePtr, and(shr(24, input), 0xFF))), 0xFF)),
            shl(12, and(mload(add(tablePtr, and(shr(16, input), 0xFF))), 0xFF))),
            add(
              shl( 6, and(mload(add(tablePtr, and(shr( 8, input), 0xFF))), 0xFF)),
              and(mload(add(tablePtr, and(input, 0xFF))), 0xFF)
            )
        )
        mstore(resultPtr, shl(232, output))
        resultPtr := add(resultPtr, 3)
      }
    }

    return result;
  }
}