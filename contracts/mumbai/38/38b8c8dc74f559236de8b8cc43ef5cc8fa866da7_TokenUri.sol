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

// SPDX-License-Identifier: BSD-3-Clause
pragma solidity ^0.8.8;

import {ISVGRaffle} from './interfaces/ISVGRaffle.sol';
import {NumberUtils} from './libs/NumberUtils.sol';

import 'openzeppelin-contracts/contracts/utils/Base64.sol';
import 'openzeppelin-contracts/contracts/utils/Strings.sol';
import {RaffleConfig, ITokenUri} from './interfaces/ITokenUri.sol';

contract TokenUri is ITokenUri {
  address public immutable RAFFLE_SVG_COMPOSER;

  /**
   * @param raffleSVGComposer address that generates the raffle NFT SVG string for use in tokenUri
   */
  constructor(address raffleSVGComposer) {
    RAFFLE_SVG_COMPOSER = raffleSVGComposer;
  }

  function toJson(
    RaffleConfig.RaffleConfiguration memory raffleConfig,
    RaffleConfig.RaffleStates state,
    uint256 precision,
    string memory symbol
  ) external view returns (string memory) {
    string memory json = Base64.encode(
      abi.encodePacked(
        '{"name": " Raffle #',
        Strings.toString(raffleConfig.raffleId),
        '", "description": "", "image": "data:image/svg+xml;base64,',
        Base64.encode(
          bytes(
            ISVGRaffle(RAFFLE_SVG_COMPOSER).getSvg(
              Strings.toString(raffleConfig.raffleId),
              string(
                abi.encodePacked(
                  NumberUtils.numToFixedLengthStr(
                    precision,
                    raffleConfig.maxTickets // TODO: number of tickets instead of price
                  ),
                  ' ',
                  symbol
                )
              ),
              string(
                abi.encodePacked(
                  NumberUtils.numToFixedLengthStr(
                    precision,
                    raffleConfig.minTickets // TODO: number of tickets instead of price
                  ),
                  ' ',
                  symbol
                )
              ),
              Strings.toString(raffleConfig.maxTickets),
              raffleConfig.expirationDate,
              state
            )
          )
        ),
        '"}'
      )
    );
    return string(abi.encodePacked('data:application/json;base64,', json));
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

pragma solidity ^0.8.0;

import {RaffleConfig} from '../libs/RaffleConfig.sol';

interface ITokenUri {
  function RAFFLE_SVG_COMPOSER() external view returns (address);

  function toJson(
    RaffleConfig.RaffleConfiguration memory raffleConfig,
    RaffleConfig.RaffleStates state,
    uint256 precision,
    string memory symbol
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