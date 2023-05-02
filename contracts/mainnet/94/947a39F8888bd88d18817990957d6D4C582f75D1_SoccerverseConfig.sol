// SPDX-License-Identifier: MIT
// Copyright (C) 2023 Soccerverse Ltd

pragma solidity ^0.8.19;

import "@xaya/democrit-evm/contracts/IDemocritConfig.sol";
import "@xaya/democrit-evm/contracts/JsonUtils.sol";

import "@openzeppelin/contracts/utils/Strings.sol";

/**
 * @dev The Democrit config for Soccerverse.  The tradable asset is just
 * the SMC coin.
 */
contract SoccerverseConfig is IDemocritConfig
{

  string public constant gameId = "smc";

  uint64 public constant feeDenominator = 10**18;
  uint64 public constant maxRelPoolFee = 10**17;

  bytes32 private constant HASH_SMC = keccak256 ("smc");

  function isTradableAsset (string memory asset)
      public pure returns (bool)
  {
    bytes32 hash = keccak256 (abi.encodePacked (asset));
    return hash == HASH_SMC;
  }

  function createVaultMove (string memory, uint vaultId,
                            string memory founder,
                            string memory, uint amount)
      public pure returns (string memory)
  {
    return string (abi.encodePacked (
        "{\"tv\":{\"c\":{",
        "\"id\":", Strings.toString (vaultId), ",",
        "\"f\":", JsonUtils.escapeString (founder), ",",
        "\"a\":", Strings.toString (amount),
        "}}}"
    ));
  }

  function checkpointMove (string memory, uint num, bytes32 hash)
      public pure returns (string memory)
  {
    return string (abi.encodePacked (
        "{\"tv\":{\"cp\":{",
        "\"n\":", Strings.toString (num), ",",
        "\"h\":\"", Strings.toHexString (uint256 (hash)), "\"",
        "}}}"
    ));
  }

  function sendFromVaultMove (string memory, uint vaultId,
                              string memory recipient,
                              string memory, uint amount)
      public pure returns (string memory)
  {
    return string (abi.encodePacked (
        "{\"tv\":{\"s\":{",
        "\"id\":", Strings.toString (vaultId), ",",
        "\"r\":", JsonUtils.escapeString (recipient), ",",
        "\"a\":", Strings.toString (amount),
        "}}}"
    ));
  }

  function fundVaultMove (string memory controller, uint vaultId,
                          string memory, string memory, uint)
      public pure returns (string[] memory path, string memory mv)
  {
    mv = string (abi.encodePacked (
        "{",
        "\"id\":", Strings.toString (vaultId), ",",
        "\"c\":", JsonUtils.escapeString (controller),
        "}"
    ));

    path = new string[] (2);
    path[0] = "tv";
    path[1] = "f";
  }

}

// SPDX-License-Identifier: MIT
// Copyright (C) 2021-2022 Autonomous Worlds Ltd

pragma solidity ^0.8.4;

/**
 * @dev A Solidity library for validating UTF-8 from strings / bytes.
 * This is based on the definition of UTF-8 in RFC 3629.
 */
library Utf8
{

  /**
   * @dev Decodes the next codepoint from a byte array of UTF-8 encoded
   * data.  The input is expected in the byte(s) following the offset
   * into the array, and the return value is the decoded codepoint as well
   * as the offset of the following bytes (if any).  If the input bytes
   * are invalid, this method throws.
   */
  function decodeCodepoint (bytes memory data, uint offset)
      internal pure returns (uint32 cp, uint newOffset)
  {
    require (offset < data.length, "no more input bytes available");

    uint8 cur = uint8 (data[offset]);

    /* Special case for ASCII characters.  */
    if (cur < 0x80)
      return (cur, offset + 1);

    if (cur < 0xC0)
      revert ("mid-sequence character at start of sequence");

    /* Process the sequence-start character.  */
    uint8 numBytes;
    uint8 state;
    if (cur < 0xE0)
      {
        numBytes = 2;
        cp = uint32 (cur & 0x1F) << 6;
        state = 6;
      }
    else if (cur < 0xF0)
      {
        numBytes = 3;
        cp = uint32 (cur & 0x0F) << 12;
        state = 12;
      }
    else if (cur < 0xF8)
      {
        numBytes = 4;
        cp = uint32 (cur & 0x07) << 18;
        state = 18;
      }
    else
      revert ("invalid sequence start byte");
    newOffset = offset + 1;

    /* Process the following bytes of this sequence.  */
    while (state > 0)
      {
        require (newOffset < data.length, "eof in the middle of a sequence");

        cur = uint8 (data[newOffset]);
        newOffset += 1;

        require (cur & 0xC0 == 0x80, "expected sequence continuation");

        state -= 6;
        cp |= uint32 (cur & 0x3F) << state;
      }

    /* Verify that the character we decoded matches the number of bytes
       we had, to prevent overlong sequences.  */
    if (numBytes == 2)
      require (cp >= 0x80 && cp < 0x800, "overlong sequence");
    else if (numBytes == 3)
      require (cp >= 0x800 && cp < 0x10000, "overlong sequence");
    else
      {
        assert (numBytes == 4);
        require (cp >= 0x10000 && cp < 0x110000, "overlong sequence");
      }

    /* Prevent characters reserved for UTF-16 surrogate pairs.  */
    require (cp < 0xD800 || cp > 0xDFFF, "surrogate-pair character decoded");
  }

  /**
   * @dev Validates that the given sequence of bytes is valid UTF-8
   * as per the definition in RFC 3629.  Throws if not.
   */
  function validate (bytes memory data) internal pure
  {
    uint offset = 0;
    while (offset < data.length)
      (, offset) = decodeCodepoint (data, offset);
    assert (offset == data.length);
  }

}

// SPDX-License-Identifier: MIT
// Copyright (C) 2021 Autonomous Worlds Ltd

pragma solidity ^0.8.4;

/**
 * @dev Utility library for building up strings in Solidity bit-by-bit,
 * without the need to re-allocate the string for each bit.
 */
library StringBuilder
{

  /**
   * @dev A string being built.  This is just a bytes array of a given
   * allocated size, and the current length (which might be smaller than
   * the allocated size).
   */
  struct Type
  {

    /**
     * @dev The allocated data array.  The size (stored in the first slot)
     * is set to the actual (current) length, rather than the allocated one.
     */
    bytes data;

    /** @dev The maximum / allocated size of the data array.  */
    uint maxLen;

  }

  /**
   * @dev Constructs a new builder that is empty initially but has space
   * for the given number of bytes.
   */
  function create (uint maxLen) internal pure returns (Type memory res)
  {
    bytes memory data = new bytes (maxLen);

    assembly {
      mstore (data, 0)
    }

    res.data = data;
    res.maxLen = maxLen;
  }

  /**
   * @dev Extracts the current data from a builder instance as string.
   */
  function extract (Type memory b) internal pure returns (string memory)
  {
    return string (b.data);
  }

  /**
   * @dev Adds the given string to the content of the builder.  This must
   * not exceed the allocated maximum size.
   */
  function append (Type memory b, string memory str) internal pure
  {
    bytes memory buf = b.data;
    bytes memory added = bytes (str);

    uint256 oldLen = buf.length;
    uint256 newLen = oldLen + added.length;
    require (newLen <= b.maxLen, "StringBuilder maxLen exceeded");
    assembly {
      mstore (buf, newLen)
    }

    for (uint i = 0; i < added.length; ++i)
      buf[i + oldLen] = added[i];
  }

}

// SPDX-License-Identifier: MIT
// Copyright (C) 2021 Autonomous Worlds Ltd

pragma solidity ^0.8.4;

import "./StringBuilder.sol";

/**
 * @dev A Solidity library for escaping UTF-8 characters into
 * hex sequences, e.g. for JSON string literals.
 */
library HexEscapes
{

  /** @dev Hex characters used.  */
  bytes internal constant HEX = bytes ("0123456789ABCDEF");

  /**
   * @dev Converts a single uint16 number into a \uXXXX JSON escape
   * string.  This does not do any UTF-16 surrogate pair conversion.
   */
  function jsonUint16 (uint16 val) private pure returns (string memory)
  {
    bytes memory res = bytes ("\\uXXXX");

    for (uint i = 0; i < 4; ++i)
      {
        res[5 - i] = HEX[val & 0xF];
        val >>= 4;
      }

    return string (res);
  }

  /**
   * @dev Converts a given Unicode codepoint into a corresponding
   * escape sequence inside a JSON literal.  This takes care of encoding
   * it into either one or two \uXXXX sequences based on UTF-16.
   */
  function jsonCodepoint (uint32 val) internal pure returns (string memory)
  {
    if (val < 0xD800 || (val >= 0xE000 && val < 0x10000))
      return jsonUint16 (uint16 (val));

    require (val >= 0x10000 && val < 0x110000, "invalid codepoint");

    val -= 0x10000;
    return string (abi.encodePacked (
      jsonUint16 (0xD800 | uint16 (val >> 10)),
      jsonUint16 (0xDC00 | uint16 (val & 0x3FF))
    ));
  }

  /**
   * @dev Converts a given Unicode codepoint into an XML escape sequence.
   */
  function xmlCodepoint (uint32 val) internal pure returns (string memory)
  {
    bytes memory res = bytes ("&#x000000;");

    for (uint i = 0; val > 0; ++i)
      {
        require (i < 6, "codepoint does not fit into 24 bits");

        res[8 - i] = HEX[val & 0xF];
        val >>= 4;
      }

    return string (res);
  }

  /**
   * @dev Converts a binary string into all-hex characters.
   */
  function hexlify (string memory str) internal pure returns (string memory)
  {
    bytes memory data = bytes (str);
    StringBuilder.Type memory builder = StringBuilder.create (2 * data.length);

    for (uint i = 0; i < data.length; ++i)
      {
        bytes memory cur = bytes ("xx");

        uint8 val = uint8 (data[i]);
        cur[1] = HEX[val & 0xF];
        val >>= 4;
        cur[0] = HEX[val & 0xF];

        StringBuilder.append (builder, string (cur));
      }

    return StringBuilder.extract (builder);
  }

}

// SPDX-License-Identifier: MIT
// Copyright (C) 2023 Autonomous Worlds Ltd

pragma solidity ^0.8.19;

import "@openzeppelin/contracts/utils/Strings.sol";
import "@xaya/eth-account-registry/contracts/HexEscapes.sol";
import "@xaya/eth-account-registry/contracts/Utf8.sol";

/**
 * @dev A basic utility library for dealing with JSON (which we need for
 * handling moves).  In particular, it supports escaping user-provided
 * account names into JSON literals, so we can use them in moves to send
 * assets to those accounts.
 */
library JsonUtils
{

  /**
   * @dev Escapes a raw string into a JSON literal representing the same
   * string (including the surrounding quotes).  If the provided string is
   * invalid UTF-8, then this method will revert.
   */
  function escapeString (string memory input)
      internal pure returns (string memory)
  {
    bytes memory data = bytes (input);

    /* ASCII characters get translated literally (i.e. just copied over).
       We escape " and \ by placing a backslash before them, and change
       control characters as well as non-ASCII Unicode codepoints to \uXXXX.
       So worst case, if all are Unicode codepoints that need a
       UTF-16 surrogate pair, we 12x the length of the data, plus
       two quotes.  */
    bytes memory out = new bytes (2 + 12 * data.length);

    uint len = 0;
    out[len++] = '"';

    /* Note that one could in theory ignore the UTF-8 parsing here, and just
       literally copy over bytes 0x80 and above.  This would also produce a
       valid JSON result (or invalid JSON if the input is invalid), but it
       fails the XayaPolicy move validation, which requires all non-ASCII
       characters to be escaped in moves.  */

    uint offset = 0;
    while (offset < data.length)
      {
        uint32 cp;
        (cp, offset) = Utf8.decodeCodepoint (data, offset);
        if (cp == 0x22 || cp == 0x5C)
          {
            out[len++] = '\\';
            out[len++] = bytes1 (uint8 (cp));
          }
        else if (cp >= 0x20 && cp < 0x7F)
          out[len++] = bytes1 (uint8 (cp));
        else
          {
            bytes memory escape = bytes (HexEscapes.jsonCodepoint (cp));
            for (uint i = 0; i < escape.length; ++i)
              out[len++] = escape[i];
          }
      }
    assert (offset == data.length);

    out[len++] = '"';

    assembly {
      mstore (out, len)
    }

    return string (out);
  }

}

// SPDX-License-Identifier: MIT
// Copyright (C) 2023 Autonomous Worlds Ltd

pragma solidity ^0.8.19;

/**
 * @dev This interface defines the methods, that concrete applications
 * need to provide to configure Democrit.  It defines what assets
 * are tradable and how the move formats for creating, funding and
 * sending from vaults are.
 *
 * Vaults need to be implemented in the GSP with behaviour as described
 * in the design doc:
 *
 * https://docs.google.com/document/d/16B-vPKtpjbiCl6XCQaO2-7p8xN-2o5JveYJDHVCIxAw/edit?usp=sharing
 */
interface IDemocritConfig
{

  /**
   * @dev Returns the game ID of the application this is for.
   * The game ID is automatically added to all moves generated
   * by the other functions.
   */
  function gameId () external view returns (string memory);

  /**
   * @dev The denominator amount used for specifying the pool fee fraction.
   */
  function feeDenominator () external view returns (uint64);

  /**
   * @dev The maximum allowed relative fee for a trading pool.  This is
   * enforced on chain to prevent scams with very abusive fees.  The value
   * is relative to feeDenominator.
   */
  function maxRelPoolFee () external view returns (uint64);

  /**
   * @dev Checks if the given asset is tradable.
   */
  function isTradableAsset (string memory asset) external view returns (bool);

  /**
   * @dev Returns the move for creating a vault with the given data.
   * The move should be returned as formatted JSON string, and will be
   * wrapped into {"g":{"game id": ... }} by the caller.
   */
  function createVaultMove (string memory controller, uint vaultId,
                            string memory founder,
                            string memory asset, uint amount)
      external view returns (string memory);

  /**
   * @dev Returns the move for sending assets from a vault.  The move returned
   * must be a formatted JSON string, and will be wrapped into
   * {"g":{"game id": ... }} by the caller.
   */
  function sendFromVaultMove (string memory controller, uint vaultId,
                              string memory recipient,
                              string memory asset, uint amount)
      external view returns (string memory);

  /**
   * @dev Returns the move for requesting a checkpoint.  The returned move
   * should be a JSON string.  The caller will wrap it into
   * {"g":{"game id": ... }}.
   */
  function checkpointMove (string memory controller, uint num, bytes32 hash)
      external view returns (string memory);

  /**
   * @dev Returns the move for funding a vault, which is sent from the
   * founding user (not the controller) after a vault has been created.
   * This is sent through the delegation contract, so it should return
   * both the actual move and a hierarchical path for it.  The path
   * will be extended by ["g", "game id", ...] by the caller.
   */
  function fundVaultMove (string memory controller, uint vaultId,
                          string memory founder,
                          string memory asset, uint amount)
      external view returns (string[] memory, string memory);

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