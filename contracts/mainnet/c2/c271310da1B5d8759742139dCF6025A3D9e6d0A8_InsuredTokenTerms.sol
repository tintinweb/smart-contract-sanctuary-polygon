/**
 *Submitted for verification at polygonscan.com on 2022-08-24
*/

// File: abdk-libraries-solidity/ABDKMathQuad.sol

/*
 * ABDK Math Quad Smart Contract Library.  Copyright © 2019 by ABDK Consulting.
 * Author: Mikhail Vladimirov <[email protected]>
 */
pragma solidity ^0.8.0;

/**
 * Smart contract library of mathematical functions operating with IEEE 754
 * quadruple-precision binary floating-point numbers (quadruple precision
 * numbers).  As long as quadruple precision numbers are 16-bytes long, they are
 * represented by bytes16 type.
 */
library ABDKMathQuad {
  /*
   * 0.
   */
  bytes16 private constant POSITIVE_ZERO = 0x00000000000000000000000000000000;

  /*
   * -0.
   */
  bytes16 private constant NEGATIVE_ZERO = 0x80000000000000000000000000000000;

  /*
   * +Infinity.
   */
  bytes16 private constant POSITIVE_INFINITY = 0x7FFF0000000000000000000000000000;

  /*
   * -Infinity.
   */
  bytes16 private constant NEGATIVE_INFINITY = 0xFFFF0000000000000000000000000000;

  /*
   * Canonical NaN value.
   */
  bytes16 private constant NaN = 0x7FFF8000000000000000000000000000;

  /**
   * Convert signed 256-bit integer number into quadruple precision number.
   *
   * @param x signed 256-bit integer number
   * @return quadruple precision number
   */
  function fromInt (int256 x) internal pure returns (bytes16) {
    unchecked {
      if (x == 0) return bytes16 (0);
      else {
        // We rely on overflow behavior here
        uint256 result = uint256 (x > 0 ? x : -x);

        uint256 msb = mostSignificantBit (result);
        if (msb < 112) result <<= 112 - msb;
        else if (msb > 112) result >>= msb - 112;

        result = result & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFF | 16383 + msb << 112;
        if (x < 0) result |= 0x80000000000000000000000000000000;

        return bytes16 (uint128 (result));
      }
    }
  }

  /**
   * Convert quadruple precision number into signed 256-bit integer number
   * rounding towards zero.  Revert on overflow.
   *
   * @param x quadruple precision number
   * @return signed 256-bit integer number
   */
  function toInt (bytes16 x) internal pure returns (int256) {
    unchecked {
      uint256 exponent = uint128 (x) >> 112 & 0x7FFF;

      require (exponent <= 16638); // Overflow
      if (exponent < 16383) return 0; // Underflow

      uint256 result = uint256 (uint128 (x)) & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFF |
        0x10000000000000000000000000000;

      if (exponent < 16495) result >>= 16495 - exponent;
      else if (exponent > 16495) result <<= exponent - 16495;

      if (uint128 (x) >= 0x80000000000000000000000000000000) { // Negative
        require (result <= 0x8000000000000000000000000000000000000000000000000000000000000000);
        return -int256 (result); // We rely on overflow behavior here
      } else {
        require (result <= 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF);
        return int256 (result);
      }
    }
  }

  /**
   * Convert unsigned 256-bit integer number into quadruple precision number.
   *
   * @param x unsigned 256-bit integer number
   * @return quadruple precision number
   */
  function fromUInt (uint256 x) internal pure returns (bytes16) {
    unchecked {
      if (x == 0) return bytes16 (0);
      else {
        uint256 result = x;

        uint256 msb = mostSignificantBit (result);
        if (msb < 112) result <<= 112 - msb;
        else if (msb > 112) result >>= msb - 112;

        result = result & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFF | 16383 + msb << 112;

        return bytes16 (uint128 (result));
      }
    }
  }

  /**
   * Convert quadruple precision number into unsigned 256-bit integer number
   * rounding towards zero.  Revert on underflow.  Note, that negative floating
   * point numbers in range (-1.0 .. 0.0) may be converted to unsigned integer
   * without error, because they are rounded to zero.
   *
   * @param x quadruple precision number
   * @return unsigned 256-bit integer number
   */
  function toUInt (bytes16 x) internal pure returns (uint256) {
    unchecked {
      uint256 exponent = uint128 (x) >> 112 & 0x7FFF;

      if (exponent < 16383) return 0; // Underflow

      require (uint128 (x) < 0x80000000000000000000000000000000); // Negative

      require (exponent <= 16638); // Overflow
      uint256 result = uint256 (uint128 (x)) & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFF |
        0x10000000000000000000000000000;

      if (exponent < 16495) result >>= 16495 - exponent;
      else if (exponent > 16495) result <<= exponent - 16495;

      return result;
    }
  }

  /**
   * Convert signed 128.128 bit fixed point number into quadruple precision
   * number.
   *
   * @param x signed 128.128 bit fixed point number
   * @return quadruple precision number
   */
  function from128x128 (int256 x) internal pure returns (bytes16) {
    unchecked {
      if (x == 0) return bytes16 (0);
      else {
        // We rely on overflow behavior here
        uint256 result = uint256 (x > 0 ? x : -x);

        uint256 msb = mostSignificantBit (result);
        if (msb < 112) result <<= 112 - msb;
        else if (msb > 112) result >>= msb - 112;

        result = result & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFF | 16255 + msb << 112;
        if (x < 0) result |= 0x80000000000000000000000000000000;

        return bytes16 (uint128 (result));
      }
    }
  }

  /**
   * Convert quadruple precision number into signed 128.128 bit fixed point
   * number.  Revert on overflow.
   *
   * @param x quadruple precision number
   * @return signed 128.128 bit fixed point number
   */
  function to128x128 (bytes16 x) internal pure returns (int256) {
    unchecked {
      uint256 exponent = uint128 (x) >> 112 & 0x7FFF;

      require (exponent <= 16510); // Overflow
      if (exponent < 16255) return 0; // Underflow

      uint256 result = uint256 (uint128 (x)) & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFF |
        0x10000000000000000000000000000;

      if (exponent < 16367) result >>= 16367 - exponent;
      else if (exponent > 16367) result <<= exponent - 16367;

      if (uint128 (x) >= 0x80000000000000000000000000000000) { // Negative
        require (result <= 0x8000000000000000000000000000000000000000000000000000000000000000);
        return -int256 (result); // We rely on overflow behavior here
      } else {
        require (result <= 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF);
        return int256 (result);
      }
    }
  }

  /**
   * Convert signed 64.64 bit fixed point number into quadruple precision
   * number.
   *
   * @param x signed 64.64 bit fixed point number
   * @return quadruple precision number
   */
  function from64x64 (int128 x) internal pure returns (bytes16) {
    unchecked {
      if (x == 0) return bytes16 (0);
      else {
        // We rely on overflow behavior here
        uint256 result = uint128 (x > 0 ? x : -x);

        uint256 msb = mostSignificantBit (result);
        if (msb < 112) result <<= 112 - msb;
        else if (msb > 112) result >>= msb - 112;

        result = result & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFF | 16319 + msb << 112;
        if (x < 0) result |= 0x80000000000000000000000000000000;

        return bytes16 (uint128 (result));
      }
    }
  }

  /**
   * Convert quadruple precision number into signed 64.64 bit fixed point
   * number.  Revert on overflow.
   *
   * @param x quadruple precision number
   * @return signed 64.64 bit fixed point number
   */
  function to64x64 (bytes16 x) internal pure returns (int128) {
    unchecked {
      uint256 exponent = uint128 (x) >> 112 & 0x7FFF;

      require (exponent <= 16446); // Overflow
      if (exponent < 16319) return 0; // Underflow

      uint256 result = uint256 (uint128 (x)) & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFF |
        0x10000000000000000000000000000;

      if (exponent < 16431) result >>= 16431 - exponent;
      else if (exponent > 16431) result <<= exponent - 16431;

      if (uint128 (x) >= 0x80000000000000000000000000000000) { // Negative
        require (result <= 0x80000000000000000000000000000000);
        return -int128 (int256 (result)); // We rely on overflow behavior here
      } else {
        require (result <= 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF);
        return int128 (int256 (result));
      }
    }
  }

  /**
   * Convert octuple precision number into quadruple precision number.
   *
   * @param x octuple precision number
   * @return quadruple precision number
   */
  function fromOctuple (bytes32 x) internal pure returns (bytes16) {
    unchecked {
      bool negative = x & 0x8000000000000000000000000000000000000000000000000000000000000000 > 0;

      uint256 exponent = uint256 (x) >> 236 & 0x7FFFF;
      uint256 significand = uint256 (x) & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;

      if (exponent == 0x7FFFF) {
        if (significand > 0) return NaN;
        else return negative ? NEGATIVE_INFINITY : POSITIVE_INFINITY;
      }

      if (exponent > 278526)
        return negative ? NEGATIVE_INFINITY : POSITIVE_INFINITY;
      else if (exponent < 245649)
        return negative ? NEGATIVE_ZERO : POSITIVE_ZERO;
      else if (exponent < 245761) {
        significand = (significand | 0x100000000000000000000000000000000000000000000000000000000000) >> 245885 - exponent;
        exponent = 0;
      } else {
        significand >>= 124;
        exponent -= 245760;
      }

      uint128 result = uint128 (significand | exponent << 112);
      if (negative) result |= 0x80000000000000000000000000000000;

      return bytes16 (result);
    }
  }

  /**
   * Convert quadruple precision number into octuple precision number.
   *
   * @param x quadruple precision number
   * @return octuple precision number
   */
  function toOctuple (bytes16 x) internal pure returns (bytes32) {
    unchecked {
      uint256 exponent = uint128 (x) >> 112 & 0x7FFF;

      uint256 result = uint128 (x) & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFF;

      if (exponent == 0x7FFF) exponent = 0x7FFFF; // Infinity or NaN
      else if (exponent == 0) {
        if (result > 0) {
          uint256 msb = mostSignificantBit (result);
          result = result << 236 - msb & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
          exponent = 245649 + msb;
        }
      } else {
        result <<= 124;
        exponent += 245760;
      }

      result |= exponent << 236;
      if (uint128 (x) >= 0x80000000000000000000000000000000)
        result |= 0x8000000000000000000000000000000000000000000000000000000000000000;

      return bytes32 (result);
    }
  }

  /**
   * Convert double precision number into quadruple precision number.
   *
   * @param x double precision number
   * @return quadruple precision number
   */
  function fromDouble (bytes8 x) internal pure returns (bytes16) {
    unchecked {
      uint256 exponent = uint64 (x) >> 52 & 0x7FF;

      uint256 result = uint64 (x) & 0xFFFFFFFFFFFFF;

      if (exponent == 0x7FF) exponent = 0x7FFF; // Infinity or NaN
      else if (exponent == 0) {
        if (result > 0) {
          uint256 msb = mostSignificantBit (result);
          result = result << 112 - msb & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
          exponent = 15309 + msb;
        }
      } else {
        result <<= 60;
        exponent += 15360;
      }

      result |= exponent << 112;
      if (x & 0x8000000000000000 > 0)
        result |= 0x80000000000000000000000000000000;

      return bytes16 (uint128 (result));
    }
  }

  /**
   * Convert quadruple precision number into double precision number.
   *
   * @param x quadruple precision number
   * @return double precision number
   */
  function toDouble (bytes16 x) internal pure returns (bytes8) {
    unchecked {
      bool negative = uint128 (x) >= 0x80000000000000000000000000000000;

      uint256 exponent = uint128 (x) >> 112 & 0x7FFF;
      uint256 significand = uint128 (x) & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFF;

      if (exponent == 0x7FFF) {
        if (significand > 0) return 0x7FF8000000000000; // NaN
        else return negative ?
            bytes8 (0xFFF0000000000000) : // -Infinity
            bytes8 (0x7FF0000000000000); // Infinity
      }

      if (exponent > 17406)
        return negative ?
            bytes8 (0xFFF0000000000000) : // -Infinity
            bytes8 (0x7FF0000000000000); // Infinity
      else if (exponent < 15309)
        return negative ?
            bytes8 (0x8000000000000000) : // -0
            bytes8 (0x0000000000000000); // 0
      else if (exponent < 15361) {
        significand = (significand | 0x10000000000000000000000000000) >> 15421 - exponent;
        exponent = 0;
      } else {
        significand >>= 60;
        exponent -= 15360;
      }

      uint64 result = uint64 (significand | exponent << 52);
      if (negative) result |= 0x8000000000000000;

      return bytes8 (result);
    }
  }

  /**
   * Test whether given quadruple precision number is NaN.
   *
   * @param x quadruple precision number
   * @return true if x is NaN, false otherwise
   */
  function isNaN (bytes16 x) internal pure returns (bool) {
    unchecked {
      return uint128 (x) & 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF >
        0x7FFF0000000000000000000000000000;
    }
  }

  /**
   * Test whether given quadruple precision number is positive or negative
   * infinity.
   *
   * @param x quadruple precision number
   * @return true if x is positive or negative infinity, false otherwise
   */
  function isInfinity (bytes16 x) internal pure returns (bool) {
    unchecked {
      return uint128 (x) & 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF ==
        0x7FFF0000000000000000000000000000;
    }
  }

  /**
   * Calculate sign of x, i.e. -1 if x is negative, 0 if x if zero, and 1 if x
   * is positive.  Note that sign (-0) is zero.  Revert if x is NaN. 
   *
   * @param x quadruple precision number
   * @return sign of x
   */
  function sign (bytes16 x) internal pure returns (int8) {
    unchecked {
      uint128 absoluteX = uint128 (x) & 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;

      require (absoluteX <= 0x7FFF0000000000000000000000000000); // Not NaN

      if (absoluteX == 0) return 0;
      else if (uint128 (x) >= 0x80000000000000000000000000000000) return -1;
      else return 1;
    }
  }

  /**
   * Calculate sign (x - y).  Revert if either argument is NaN, or both
   * arguments are infinities of the same sign. 
   *
   * @param x quadruple precision number
   * @param y quadruple precision number
   * @return sign (x - y)
   */
  function cmp (bytes16 x, bytes16 y) internal pure returns (int8) {
    unchecked {
      uint128 absoluteX = uint128 (x) & 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;

      require (absoluteX <= 0x7FFF0000000000000000000000000000); // Not NaN

      uint128 absoluteY = uint128 (y) & 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;

      require (absoluteY <= 0x7FFF0000000000000000000000000000); // Not NaN

      // Not infinities of the same sign
      require (x != y || absoluteX < 0x7FFF0000000000000000000000000000);

      if (x == y) return 0;
      else {
        bool negativeX = uint128 (x) >= 0x80000000000000000000000000000000;
        bool negativeY = uint128 (y) >= 0x80000000000000000000000000000000;

        if (negativeX) {
          if (negativeY) return absoluteX > absoluteY ? -1 : int8 (1);
          else return -1; 
        } else {
          if (negativeY) return 1;
          else return absoluteX > absoluteY ? int8 (1) : -1;
        }
      }
    }
  }

  /**
   * Test whether x equals y.  NaN, infinity, and -infinity are not equal to
   * anything. 
   *
   * @param x quadruple precision number
   * @param y quadruple precision number
   * @return true if x equals to y, false otherwise
   */
  function eq (bytes16 x, bytes16 y) internal pure returns (bool) {
    unchecked {
      if (x == y) {
        return uint128 (x) & 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF <
          0x7FFF0000000000000000000000000000;
      } else return false;
    }
  }

  /**
   * Calculate x + y.  Special values behave in the following way:
   *
   * NaN + x = NaN for any x.
   * Infinity + x = Infinity for any finite x.
   * -Infinity + x = -Infinity for any finite x.
   * Infinity + Infinity = Infinity.
   * -Infinity + -Infinity = -Infinity.
   * Infinity + -Infinity = -Infinity + Infinity = NaN.
   *
   * @param x quadruple precision number
   * @param y quadruple precision number
   * @return quadruple precision number
   */
  function add (bytes16 x, bytes16 y) internal pure returns (bytes16) {
    unchecked {
      uint256 xExponent = uint128 (x) >> 112 & 0x7FFF;
      uint256 yExponent = uint128 (y) >> 112 & 0x7FFF;

      if (xExponent == 0x7FFF) {
        if (yExponent == 0x7FFF) { 
          if (x == y) return x;
          else return NaN;
        } else return x; 
      } else if (yExponent == 0x7FFF) return y;
      else {
        bool xSign = uint128 (x) >= 0x80000000000000000000000000000000;
        uint256 xSignifier = uint128 (x) & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
        if (xExponent == 0) xExponent = 1;
        else xSignifier |= 0x10000000000000000000000000000;

        bool ySign = uint128 (y) >= 0x80000000000000000000000000000000;
        uint256 ySignifier = uint128 (y) & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
        if (yExponent == 0) yExponent = 1;
        else ySignifier |= 0x10000000000000000000000000000;

        if (xSignifier == 0) return y == NEGATIVE_ZERO ? POSITIVE_ZERO : y;
        else if (ySignifier == 0) return x == NEGATIVE_ZERO ? POSITIVE_ZERO : x;
        else {
          int256 delta = int256 (xExponent) - int256 (yExponent);
  
          if (xSign == ySign) {
            if (delta > 112) return x;
            else if (delta > 0) ySignifier >>= uint256 (delta);
            else if (delta < -112) return y;
            else if (delta < 0) {
              xSignifier >>= uint256 (-delta);
              xExponent = yExponent;
            }
  
            xSignifier += ySignifier;
  
            if (xSignifier >= 0x20000000000000000000000000000) {
              xSignifier >>= 1;
              xExponent += 1;
            }
  
            if (xExponent == 0x7FFF)
              return xSign ? NEGATIVE_INFINITY : POSITIVE_INFINITY;
            else {
              if (xSignifier < 0x10000000000000000000000000000) xExponent = 0;
              else xSignifier &= 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
  
              return bytes16 (uint128 (
                  (xSign ? 0x80000000000000000000000000000000 : 0) |
                  (xExponent << 112) |
                  xSignifier)); 
            }
          } else {
            if (delta > 0) {
              xSignifier <<= 1;
              xExponent -= 1;
            } else if (delta < 0) {
              ySignifier <<= 1;
              xExponent = yExponent - 1;
            }

            if (delta > 112) ySignifier = 1;
            else if (delta > 1) ySignifier = (ySignifier - 1 >> uint256 (delta - 1)) + 1;
            else if (delta < -112) xSignifier = 1;
            else if (delta < -1) xSignifier = (xSignifier - 1 >> uint256 (-delta - 1)) + 1;

            if (xSignifier >= ySignifier) xSignifier -= ySignifier;
            else {
              xSignifier = ySignifier - xSignifier;
              xSign = ySign;
            }

            if (xSignifier == 0)
              return POSITIVE_ZERO;

            uint256 msb = mostSignificantBit (xSignifier);

            if (msb == 113) {
              xSignifier = xSignifier >> 1 & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
              xExponent += 1;
            } else if (msb < 112) {
              uint256 shift = 112 - msb;
              if (xExponent > shift) {
                xSignifier = xSignifier << shift & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
                xExponent -= shift;
              } else {
                xSignifier <<= xExponent - 1;
                xExponent = 0;
              }
            } else xSignifier &= 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFF;

            if (xExponent == 0x7FFF)
              return xSign ? NEGATIVE_INFINITY : POSITIVE_INFINITY;
            else return bytes16 (uint128 (
                (xSign ? 0x80000000000000000000000000000000 : 0) |
                (xExponent << 112) |
                xSignifier));
          }
        }
      }
    }
  }

  /**
   * Calculate x - y.  Special values behave in the following way:
   *
   * NaN - x = NaN for any x.
   * Infinity - x = Infinity for any finite x.
   * -Infinity - x = -Infinity for any finite x.
   * Infinity - -Infinity = Infinity.
   * -Infinity - Infinity = -Infinity.
   * Infinity - Infinity = -Infinity - -Infinity = NaN.
   *
   * @param x quadruple precision number
   * @param y quadruple precision number
   * @return quadruple precision number
   */
  function sub (bytes16 x, bytes16 y) internal pure returns (bytes16) {
    unchecked {
      return add (x, y ^ 0x80000000000000000000000000000000);
    }
  }

  /**
   * Calculate x * y.  Special values behave in the following way:
   *
   * NaN * x = NaN for any x.
   * Infinity * x = Infinity for any finite positive x.
   * Infinity * x = -Infinity for any finite negative x.
   * -Infinity * x = -Infinity for any finite positive x.
   * -Infinity * x = Infinity for any finite negative x.
   * Infinity * 0 = NaN.
   * -Infinity * 0 = NaN.
   * Infinity * Infinity = Infinity.
   * Infinity * -Infinity = -Infinity.
   * -Infinity * Infinity = -Infinity.
   * -Infinity * -Infinity = Infinity.
   *
   * @param x quadruple precision number
   * @param y quadruple precision number
   * @return quadruple precision number
   */
  function mul (bytes16 x, bytes16 y) internal pure returns (bytes16) {
    unchecked {
      uint256 xExponent = uint128 (x) >> 112 & 0x7FFF;
      uint256 yExponent = uint128 (y) >> 112 & 0x7FFF;

      if (xExponent == 0x7FFF) {
        if (yExponent == 0x7FFF) {
          if (x == y) return x ^ y & 0x80000000000000000000000000000000;
          else if (x ^ y == 0x80000000000000000000000000000000) return x | y;
          else return NaN;
        } else {
          if (y & 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF == 0) return NaN;
          else return x ^ y & 0x80000000000000000000000000000000;
        }
      } else if (yExponent == 0x7FFF) {
          if (x & 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF == 0) return NaN;
          else return y ^ x & 0x80000000000000000000000000000000;
      } else {
        uint256 xSignifier = uint128 (x) & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
        if (xExponent == 0) xExponent = 1;
        else xSignifier |= 0x10000000000000000000000000000;

        uint256 ySignifier = uint128 (y) & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
        if (yExponent == 0) yExponent = 1;
        else ySignifier |= 0x10000000000000000000000000000;

        xSignifier *= ySignifier;
        if (xSignifier == 0)
          return (x ^ y) & 0x80000000000000000000000000000000 > 0 ?
              NEGATIVE_ZERO : POSITIVE_ZERO;

        xExponent += yExponent;

        uint256 msb =
          xSignifier >= 0x200000000000000000000000000000000000000000000000000000000 ? 225 :
          xSignifier >= 0x100000000000000000000000000000000000000000000000000000000 ? 224 :
          mostSignificantBit (xSignifier);

        if (xExponent + msb < 16496) { // Underflow
          xExponent = 0;
          xSignifier = 0;
        } else if (xExponent + msb < 16608) { // Subnormal
          if (xExponent < 16496)
            xSignifier >>= 16496 - xExponent;
          else if (xExponent > 16496)
            xSignifier <<= xExponent - 16496;
          xExponent = 0;
        } else if (xExponent + msb > 49373) {
          xExponent = 0x7FFF;
          xSignifier = 0;
        } else {
          if (msb > 112)
            xSignifier >>= msb - 112;
          else if (msb < 112)
            xSignifier <<= 112 - msb;

          xSignifier &= 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFF;

          xExponent = xExponent + msb - 16607;
        }

        return bytes16 (uint128 (uint128 ((x ^ y) & 0x80000000000000000000000000000000) |
            xExponent << 112 | xSignifier));
      }
    }
  }

  /**
   * Calculate x / y.  Special values behave in the following way:
   *
   * NaN / x = NaN for any x.
   * x / NaN = NaN for any x.
   * Infinity / x = Infinity for any finite non-negative x.
   * Infinity / x = -Infinity for any finite negative x including -0.
   * -Infinity / x = -Infinity for any finite non-negative x.
   * -Infinity / x = Infinity for any finite negative x including -0.
   * x / Infinity = 0 for any finite non-negative x.
   * x / -Infinity = -0 for any finite non-negative x.
   * x / Infinity = -0 for any finite non-negative x including -0.
   * x / -Infinity = 0 for any finite non-negative x including -0.
   * 
   * Infinity / Infinity = NaN.
   * Infinity / -Infinity = -NaN.
   * -Infinity / Infinity = -NaN.
   * -Infinity / -Infinity = NaN.
   *
   * Division by zero behaves in the following way:
   *
   * x / 0 = Infinity for any finite positive x.
   * x / -0 = -Infinity for any finite positive x.
   * x / 0 = -Infinity for any finite negative x.
   * x / -0 = Infinity for any finite negative x.
   * 0 / 0 = NaN.
   * 0 / -0 = NaN.
   * -0 / 0 = NaN.
   * -0 / -0 = NaN.
   *
   * @param x quadruple precision number
   * @param y quadruple precision number
   * @return quadruple precision number
   */
  function div (bytes16 x, bytes16 y) internal pure returns (bytes16) {
    unchecked {
      uint256 xExponent = uint128 (x) >> 112 & 0x7FFF;
      uint256 yExponent = uint128 (y) >> 112 & 0x7FFF;

      if (xExponent == 0x7FFF) {
        if (yExponent == 0x7FFF) return NaN;
        else return x ^ y & 0x80000000000000000000000000000000;
      } else if (yExponent == 0x7FFF) {
        if (y & 0x0000FFFFFFFFFFFFFFFFFFFFFFFFFFFF != 0) return NaN;
        else return POSITIVE_ZERO | (x ^ y) & 0x80000000000000000000000000000000;
      } else if (y & 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF == 0) {
        if (x & 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF == 0) return NaN;
        else return POSITIVE_INFINITY | (x ^ y) & 0x80000000000000000000000000000000;
      } else {
        uint256 ySignifier = uint128 (y) & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
        if (yExponent == 0) yExponent = 1;
        else ySignifier |= 0x10000000000000000000000000000;

        uint256 xSignifier = uint128 (x) & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
        if (xExponent == 0) {
          if (xSignifier != 0) {
            uint shift = 226 - mostSignificantBit (xSignifier);

            xSignifier <<= shift;

            xExponent = 1;
            yExponent += shift - 114;
          }
        }
        else {
          xSignifier = (xSignifier | 0x10000000000000000000000000000) << 114;
        }

        xSignifier = xSignifier / ySignifier;
        if (xSignifier == 0)
          return (x ^ y) & 0x80000000000000000000000000000000 > 0 ?
              NEGATIVE_ZERO : POSITIVE_ZERO;

        assert (xSignifier >= 0x1000000000000000000000000000);

        uint256 msb =
          xSignifier >= 0x80000000000000000000000000000 ? mostSignificantBit (xSignifier) :
          xSignifier >= 0x40000000000000000000000000000 ? 114 :
          xSignifier >= 0x20000000000000000000000000000 ? 113 : 112;

        if (xExponent + msb > yExponent + 16497) { // Overflow
          xExponent = 0x7FFF;
          xSignifier = 0;
        } else if (xExponent + msb + 16380  < yExponent) { // Underflow
          xExponent = 0;
          xSignifier = 0;
        } else if (xExponent + msb + 16268  < yExponent) { // Subnormal
          if (xExponent + 16380 > yExponent)
            xSignifier <<= xExponent + 16380 - yExponent;
          else if (xExponent + 16380 < yExponent)
            xSignifier >>= yExponent - xExponent - 16380;

          xExponent = 0;
        } else { // Normal
          if (msb > 112)
            xSignifier >>= msb - 112;

          xSignifier &= 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFF;

          xExponent = xExponent + msb + 16269 - yExponent;
        }

        return bytes16 (uint128 (uint128 ((x ^ y) & 0x80000000000000000000000000000000) |
            xExponent << 112 | xSignifier));
      }
    }
  }

  /**
   * Calculate -x.
   *
   * @param x quadruple precision number
   * @return quadruple precision number
   */
  function neg (bytes16 x) internal pure returns (bytes16) {
    unchecked {
      return x ^ 0x80000000000000000000000000000000;
    }
  }

  /**
   * Calculate |x|.
   *
   * @param x quadruple precision number
   * @return quadruple precision number
   */
  function abs (bytes16 x) internal pure returns (bytes16) {
    unchecked {
      return x & 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
    }
  }

  /**
   * Calculate square root of x.  Return NaN on negative x excluding -0.
   *
   * @param x quadruple precision number
   * @return quadruple precision number
   */
  function sqrt (bytes16 x) internal pure returns (bytes16) {
    unchecked {
      if (uint128 (x) >  0x80000000000000000000000000000000) return NaN;
      else {
        uint256 xExponent = uint128 (x) >> 112 & 0x7FFF;
        if (xExponent == 0x7FFF) return x;
        else {
          uint256 xSignifier = uint128 (x) & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
          if (xExponent == 0) xExponent = 1;
          else xSignifier |= 0x10000000000000000000000000000;

          if (xSignifier == 0) return POSITIVE_ZERO;

          bool oddExponent = xExponent & 0x1 == 0;
          xExponent = xExponent + 16383 >> 1;

          if (oddExponent) {
            if (xSignifier >= 0x10000000000000000000000000000)
              xSignifier <<= 113;
            else {
              uint256 msb = mostSignificantBit (xSignifier);
              uint256 shift = (226 - msb) & 0xFE;
              xSignifier <<= shift;
              xExponent -= shift - 112 >> 1;
            }
          } else {
            if (xSignifier >= 0x10000000000000000000000000000)
              xSignifier <<= 112;
            else {
              uint256 msb = mostSignificantBit (xSignifier);
              uint256 shift = (225 - msb) & 0xFE;
              xSignifier <<= shift;
              xExponent -= shift - 112 >> 1;
            }
          }

          uint256 r = 0x10000000000000000000000000000;
          r = (r + xSignifier / r) >> 1;
          r = (r + xSignifier / r) >> 1;
          r = (r + xSignifier / r) >> 1;
          r = (r + xSignifier / r) >> 1;
          r = (r + xSignifier / r) >> 1;
          r = (r + xSignifier / r) >> 1;
          r = (r + xSignifier / r) >> 1; // Seven iterations should be enough
          uint256 r1 = xSignifier / r;
          if (r1 < r) r = r1;

          return bytes16 (uint128 (xExponent << 112 | r & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFF));
        }
      }
    }
  }

  /**
   * Calculate binary logarithm of x.  Return NaN on negative x excluding -0.
   *
   * @param x quadruple precision number
   * @return quadruple precision number
   */
  function log_2 (bytes16 x) internal pure returns (bytes16) {
    unchecked {
      if (uint128 (x) > 0x80000000000000000000000000000000) return NaN;
      else if (x == 0x3FFF0000000000000000000000000000) return POSITIVE_ZERO; 
      else {
        uint256 xExponent = uint128 (x) >> 112 & 0x7FFF;
        if (xExponent == 0x7FFF) return x;
        else {
          uint256 xSignifier = uint128 (x) & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
          if (xExponent == 0) xExponent = 1;
          else xSignifier |= 0x10000000000000000000000000000;

          if (xSignifier == 0) return NEGATIVE_INFINITY;

          bool resultNegative;
          uint256 resultExponent = 16495;
          uint256 resultSignifier;

          if (xExponent >= 0x3FFF) {
            resultNegative = false;
            resultSignifier = xExponent - 0x3FFF;
            xSignifier <<= 15;
          } else {
            resultNegative = true;
            if (xSignifier >= 0x10000000000000000000000000000) {
              resultSignifier = 0x3FFE - xExponent;
              xSignifier <<= 15;
            } else {
              uint256 msb = mostSignificantBit (xSignifier);
              resultSignifier = 16493 - msb;
              xSignifier <<= 127 - msb;
            }
          }

          if (xSignifier == 0x80000000000000000000000000000000) {
            if (resultNegative) resultSignifier += 1;
            uint256 shift = 112 - mostSignificantBit (resultSignifier);
            resultSignifier <<= shift;
            resultExponent -= shift;
          } else {
            uint256 bb = resultNegative ? 1 : 0;
            while (resultSignifier < 0x10000000000000000000000000000) {
              resultSignifier <<= 1;
              resultExponent -= 1;
  
              xSignifier *= xSignifier;
              uint256 b = xSignifier >> 255;
              resultSignifier += b ^ bb;
              xSignifier >>= 127 + b;
            }
          }

          return bytes16 (uint128 ((resultNegative ? 0x80000000000000000000000000000000 : 0) |
              resultExponent << 112 | resultSignifier & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFF));
        }
      }
    }
  }

  /**
   * Calculate natural logarithm of x.  Return NaN on negative x excluding -0.
   *
   * @param x quadruple precision number
   * @return quadruple precision number
   */
  function ln (bytes16 x) internal pure returns (bytes16) {
    unchecked {
      return mul (log_2 (x), 0x3FFE62E42FEFA39EF35793C7673007E5);
    }
  }

  /**
   * Calculate 2^x.
   *
   * @param x quadruple precision number
   * @return quadruple precision number
   */
  function pow_2 (bytes16 x) internal pure returns (bytes16) {
    unchecked {
      bool xNegative = uint128 (x) > 0x80000000000000000000000000000000;
      uint256 xExponent = uint128 (x) >> 112 & 0x7FFF;
      uint256 xSignifier = uint128 (x) & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFF;

      if (xExponent == 0x7FFF && xSignifier != 0) return NaN;
      else if (xExponent > 16397)
        return xNegative ? POSITIVE_ZERO : POSITIVE_INFINITY;
      else if (xExponent < 16255)
        return 0x3FFF0000000000000000000000000000;
      else {
        if (xExponent == 0) xExponent = 1;
        else xSignifier |= 0x10000000000000000000000000000;

        if (xExponent > 16367)
          xSignifier <<= xExponent - 16367;
        else if (xExponent < 16367)
          xSignifier >>= 16367 - xExponent;

        if (xNegative && xSignifier > 0x406E00000000000000000000000000000000)
          return POSITIVE_ZERO;

        if (!xNegative && xSignifier > 0x3FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF)
          return POSITIVE_INFINITY;

        uint256 resultExponent = xSignifier >> 128;
        xSignifier &= 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
        if (xNegative && xSignifier != 0) {
          xSignifier = ~xSignifier;
          resultExponent += 1;
        }

        uint256 resultSignifier = 0x80000000000000000000000000000000;
        if (xSignifier & 0x80000000000000000000000000000000 > 0) resultSignifier = resultSignifier * 0x16A09E667F3BCC908B2FB1366EA957D3E >> 128;
        if (xSignifier & 0x40000000000000000000000000000000 > 0) resultSignifier = resultSignifier * 0x1306FE0A31B7152DE8D5A46305C85EDEC >> 128;
        if (xSignifier & 0x20000000000000000000000000000000 > 0) resultSignifier = resultSignifier * 0x1172B83C7D517ADCDF7C8C50EB14A791F >> 128;
        if (xSignifier & 0x10000000000000000000000000000000 > 0) resultSignifier = resultSignifier * 0x10B5586CF9890F6298B92B71842A98363 >> 128;
        if (xSignifier & 0x8000000000000000000000000000000 > 0) resultSignifier = resultSignifier * 0x1059B0D31585743AE7C548EB68CA417FD >> 128;
        if (xSignifier & 0x4000000000000000000000000000000 > 0) resultSignifier = resultSignifier * 0x102C9A3E778060EE6F7CACA4F7A29BDE8 >> 128;
        if (xSignifier & 0x2000000000000000000000000000000 > 0) resultSignifier = resultSignifier * 0x10163DA9FB33356D84A66AE336DCDFA3F >> 128;
        if (xSignifier & 0x1000000000000000000000000000000 > 0) resultSignifier = resultSignifier * 0x100B1AFA5ABCBED6129AB13EC11DC9543 >> 128;
        if (xSignifier & 0x800000000000000000000000000000 > 0) resultSignifier = resultSignifier * 0x10058C86DA1C09EA1FF19D294CF2F679B >> 128;
        if (xSignifier & 0x400000000000000000000000000000 > 0) resultSignifier = resultSignifier * 0x1002C605E2E8CEC506D21BFC89A23A00F >> 128;
        if (xSignifier & 0x200000000000000000000000000000 > 0) resultSignifier = resultSignifier * 0x100162F3904051FA128BCA9C55C31E5DF >> 128;
        if (xSignifier & 0x100000000000000000000000000000 > 0) resultSignifier = resultSignifier * 0x1000B175EFFDC76BA38E31671CA939725 >> 128;
        if (xSignifier & 0x80000000000000000000000000000 > 0) resultSignifier = resultSignifier * 0x100058BA01FB9F96D6CACD4B180917C3D >> 128;
        if (xSignifier & 0x40000000000000000000000000000 > 0) resultSignifier = resultSignifier * 0x10002C5CC37DA9491D0985C348C68E7B3 >> 128;
        if (xSignifier & 0x20000000000000000000000000000 > 0) resultSignifier = resultSignifier * 0x1000162E525EE054754457D5995292026 >> 128;
        if (xSignifier & 0x10000000000000000000000000000 > 0) resultSignifier = resultSignifier * 0x10000B17255775C040618BF4A4ADE83FC >> 128;
        if (xSignifier & 0x8000000000000000000000000000 > 0) resultSignifier = resultSignifier * 0x1000058B91B5BC9AE2EED81E9B7D4CFAB >> 128;
        if (xSignifier & 0x4000000000000000000000000000 > 0) resultSignifier = resultSignifier * 0x100002C5C89D5EC6CA4D7C8ACC017B7C9 >> 128;
        if (xSignifier & 0x2000000000000000000000000000 > 0) resultSignifier = resultSignifier * 0x10000162E43F4F831060E02D839A9D16D >> 128;
        if (xSignifier & 0x1000000000000000000000000000 > 0) resultSignifier = resultSignifier * 0x100000B1721BCFC99D9F890EA06911763 >> 128;
        if (xSignifier & 0x800000000000000000000000000 > 0) resultSignifier = resultSignifier * 0x10000058B90CF1E6D97F9CA14DBCC1628 >> 128;
        if (xSignifier & 0x400000000000000000000000000 > 0) resultSignifier = resultSignifier * 0x1000002C5C863B73F016468F6BAC5CA2B >> 128;
        if (xSignifier & 0x200000000000000000000000000 > 0) resultSignifier = resultSignifier * 0x100000162E430E5A18F6119E3C02282A5 >> 128;
        if (xSignifier & 0x100000000000000000000000000 > 0) resultSignifier = resultSignifier * 0x1000000B1721835514B86E6D96EFD1BFE >> 128;
        if (xSignifier & 0x80000000000000000000000000 > 0) resultSignifier = resultSignifier * 0x100000058B90C0B48C6BE5DF846C5B2EF >> 128;
        if (xSignifier & 0x40000000000000000000000000 > 0) resultSignifier = resultSignifier * 0x10000002C5C8601CC6B9E94213C72737A >> 128;
        if (xSignifier & 0x20000000000000000000000000 > 0) resultSignifier = resultSignifier * 0x1000000162E42FFF037DF38AA2B219F06 >> 128;
        if (xSignifier & 0x10000000000000000000000000 > 0) resultSignifier = resultSignifier * 0x10000000B17217FBA9C739AA5819F44F9 >> 128;
        if (xSignifier & 0x8000000000000000000000000 > 0) resultSignifier = resultSignifier * 0x1000000058B90BFCDEE5ACD3C1CEDC823 >> 128;
        if (xSignifier & 0x4000000000000000000000000 > 0) resultSignifier = resultSignifier * 0x100000002C5C85FE31F35A6A30DA1BE50 >> 128;
        if (xSignifier & 0x2000000000000000000000000 > 0) resultSignifier = resultSignifier * 0x10000000162E42FF0999CE3541B9FFFCF >> 128;
        if (xSignifier & 0x1000000000000000000000000 > 0) resultSignifier = resultSignifier * 0x100000000B17217F80F4EF5AADDA45554 >> 128;
        if (xSignifier & 0x800000000000000000000000 > 0) resultSignifier = resultSignifier * 0x10000000058B90BFBF8479BD5A81B51AD >> 128;
        if (xSignifier & 0x400000000000000000000000 > 0) resultSignifier = resultSignifier * 0x1000000002C5C85FDF84BD62AE30A74CC >> 128;
        if (xSignifier & 0x200000000000000000000000 > 0) resultSignifier = resultSignifier * 0x100000000162E42FEFB2FED257559BDAA >> 128;
        if (xSignifier & 0x100000000000000000000000 > 0) resultSignifier = resultSignifier * 0x1000000000B17217F7D5A7716BBA4A9AE >> 128;
        if (xSignifier & 0x80000000000000000000000 > 0) resultSignifier = resultSignifier * 0x100000000058B90BFBE9DDBAC5E109CCE >> 128;
        if (xSignifier & 0x40000000000000000000000 > 0) resultSignifier = resultSignifier * 0x10000000002C5C85FDF4B15DE6F17EB0D >> 128;
        if (xSignifier & 0x20000000000000000000000 > 0) resultSignifier = resultSignifier * 0x1000000000162E42FEFA494F1478FDE05 >> 128;
        if (xSignifier & 0x10000000000000000000000 > 0) resultSignifier = resultSignifier * 0x10000000000B17217F7D20CF927C8E94C >> 128;
        if (xSignifier & 0x8000000000000000000000 > 0) resultSignifier = resultSignifier * 0x1000000000058B90BFBE8F71CB4E4B33D >> 128;
        if (xSignifier & 0x4000000000000000000000 > 0) resultSignifier = resultSignifier * 0x100000000002C5C85FDF477B662B26945 >> 128;
        if (xSignifier & 0x2000000000000000000000 > 0) resultSignifier = resultSignifier * 0x10000000000162E42FEFA3AE53369388C >> 128;
        if (xSignifier & 0x1000000000000000000000 > 0) resultSignifier = resultSignifier * 0x100000000000B17217F7D1D351A389D40 >> 128;
        if (xSignifier & 0x800000000000000000000 > 0) resultSignifier = resultSignifier * 0x10000000000058B90BFBE8E8B2D3D4EDE >> 128;
        if (xSignifier & 0x400000000000000000000 > 0) resultSignifier = resultSignifier * 0x1000000000002C5C85FDF4741BEA6E77E >> 128;
        if (xSignifier & 0x200000000000000000000 > 0) resultSignifier = resultSignifier * 0x100000000000162E42FEFA39FE95583C2 >> 128;
        if (xSignifier & 0x100000000000000000000 > 0) resultSignifier = resultSignifier * 0x1000000000000B17217F7D1CFB72B45E1 >> 128;
        if (xSignifier & 0x80000000000000000000 > 0) resultSignifier = resultSignifier * 0x100000000000058B90BFBE8E7CC35C3F0 >> 128;
        if (xSignifier & 0x40000000000000000000 > 0) resultSignifier = resultSignifier * 0x10000000000002C5C85FDF473E242EA38 >> 128;
        if (xSignifier & 0x20000000000000000000 > 0) resultSignifier = resultSignifier * 0x1000000000000162E42FEFA39F02B772C >> 128;
        if (xSignifier & 0x10000000000000000000 > 0) resultSignifier = resultSignifier * 0x10000000000000B17217F7D1CF7D83C1A >> 128;
        if (xSignifier & 0x8000000000000000000 > 0) resultSignifier = resultSignifier * 0x1000000000000058B90BFBE8E7BDCBE2E >> 128;
        if (xSignifier & 0x4000000000000000000 > 0) resultSignifier = resultSignifier * 0x100000000000002C5C85FDF473DEA871F >> 128;
        if (xSignifier & 0x2000000000000000000 > 0) resultSignifier = resultSignifier * 0x10000000000000162E42FEFA39EF44D91 >> 128;
        if (xSignifier & 0x1000000000000000000 > 0) resultSignifier = resultSignifier * 0x100000000000000B17217F7D1CF79E949 >> 128;
        if (xSignifier & 0x800000000000000000 > 0) resultSignifier = resultSignifier * 0x10000000000000058B90BFBE8E7BCE544 >> 128;
        if (xSignifier & 0x400000000000000000 > 0) resultSignifier = resultSignifier * 0x1000000000000002C5C85FDF473DE6ECA >> 128;
        if (xSignifier & 0x200000000000000000 > 0) resultSignifier = resultSignifier * 0x100000000000000162E42FEFA39EF366F >> 128;
        if (xSignifier & 0x100000000000000000 > 0) resultSignifier = resultSignifier * 0x1000000000000000B17217F7D1CF79AFA >> 128;
        if (xSignifier & 0x80000000000000000 > 0) resultSignifier = resultSignifier * 0x100000000000000058B90BFBE8E7BCD6D >> 128;
        if (xSignifier & 0x40000000000000000 > 0) resultSignifier = resultSignifier * 0x10000000000000002C5C85FDF473DE6B2 >> 128;
        if (xSignifier & 0x20000000000000000 > 0) resultSignifier = resultSignifier * 0x1000000000000000162E42FEFA39EF358 >> 128;
        if (xSignifier & 0x10000000000000000 > 0) resultSignifier = resultSignifier * 0x10000000000000000B17217F7D1CF79AB >> 128;
        if (xSignifier & 0x8000000000000000 > 0) resultSignifier = resultSignifier * 0x1000000000000000058B90BFBE8E7BCD5 >> 128;
        if (xSignifier & 0x4000000000000000 > 0) resultSignifier = resultSignifier * 0x100000000000000002C5C85FDF473DE6A >> 128;
        if (xSignifier & 0x2000000000000000 > 0) resultSignifier = resultSignifier * 0x10000000000000000162E42FEFA39EF34 >> 128;
        if (xSignifier & 0x1000000000000000 > 0) resultSignifier = resultSignifier * 0x100000000000000000B17217F7D1CF799 >> 128;
        if (xSignifier & 0x800000000000000 > 0) resultSignifier = resultSignifier * 0x10000000000000000058B90BFBE8E7BCC >> 128;
        if (xSignifier & 0x400000000000000 > 0) resultSignifier = resultSignifier * 0x1000000000000000002C5C85FDF473DE5 >> 128;
        if (xSignifier & 0x200000000000000 > 0) resultSignifier = resultSignifier * 0x100000000000000000162E42FEFA39EF2 >> 128;
        if (xSignifier & 0x100000000000000 > 0) resultSignifier = resultSignifier * 0x1000000000000000000B17217F7D1CF78 >> 128;
        if (xSignifier & 0x80000000000000 > 0) resultSignifier = resultSignifier * 0x100000000000000000058B90BFBE8E7BB >> 128;
        if (xSignifier & 0x40000000000000 > 0) resultSignifier = resultSignifier * 0x10000000000000000002C5C85FDF473DD >> 128;
        if (xSignifier & 0x20000000000000 > 0) resultSignifier = resultSignifier * 0x1000000000000000000162E42FEFA39EE >> 128;
        if (xSignifier & 0x10000000000000 > 0) resultSignifier = resultSignifier * 0x10000000000000000000B17217F7D1CF6 >> 128;
        if (xSignifier & 0x8000000000000 > 0) resultSignifier = resultSignifier * 0x1000000000000000000058B90BFBE8E7A >> 128;
        if (xSignifier & 0x4000000000000 > 0) resultSignifier = resultSignifier * 0x100000000000000000002C5C85FDF473C >> 128;
        if (xSignifier & 0x2000000000000 > 0) resultSignifier = resultSignifier * 0x10000000000000000000162E42FEFA39D >> 128;
        if (xSignifier & 0x1000000000000 > 0) resultSignifier = resultSignifier * 0x100000000000000000000B17217F7D1CE >> 128;
        if (xSignifier & 0x800000000000 > 0) resultSignifier = resultSignifier * 0x10000000000000000000058B90BFBE8E6 >> 128;
        if (xSignifier & 0x400000000000 > 0) resultSignifier = resultSignifier * 0x1000000000000000000002C5C85FDF472 >> 128;
        if (xSignifier & 0x200000000000 > 0) resultSignifier = resultSignifier * 0x100000000000000000000162E42FEFA38 >> 128;
        if (xSignifier & 0x100000000000 > 0) resultSignifier = resultSignifier * 0x1000000000000000000000B17217F7D1B >> 128;
        if (xSignifier & 0x80000000000 > 0) resultSignifier = resultSignifier * 0x100000000000000000000058B90BFBE8D >> 128;
        if (xSignifier & 0x40000000000 > 0) resultSignifier = resultSignifier * 0x10000000000000000000002C5C85FDF46 >> 128;
        if (xSignifier & 0x20000000000 > 0) resultSignifier = resultSignifier * 0x1000000000000000000000162E42FEFA2 >> 128;
        if (xSignifier & 0x10000000000 > 0) resultSignifier = resultSignifier * 0x10000000000000000000000B17217F7D0 >> 128;
        if (xSignifier & 0x8000000000 > 0) resultSignifier = resultSignifier * 0x1000000000000000000000058B90BFBE7 >> 128;
        if (xSignifier & 0x4000000000 > 0) resultSignifier = resultSignifier * 0x100000000000000000000002C5C85FDF3 >> 128;
        if (xSignifier & 0x2000000000 > 0) resultSignifier = resultSignifier * 0x10000000000000000000000162E42FEF9 >> 128;
        if (xSignifier & 0x1000000000 > 0) resultSignifier = resultSignifier * 0x100000000000000000000000B17217F7C >> 128;
        if (xSignifier & 0x800000000 > 0) resultSignifier = resultSignifier * 0x10000000000000000000000058B90BFBD >> 128;
        if (xSignifier & 0x400000000 > 0) resultSignifier = resultSignifier * 0x1000000000000000000000002C5C85FDE >> 128;
        if (xSignifier & 0x200000000 > 0) resultSignifier = resultSignifier * 0x100000000000000000000000162E42FEE >> 128;
        if (xSignifier & 0x100000000 > 0) resultSignifier = resultSignifier * 0x1000000000000000000000000B17217F6 >> 128;
        if (xSignifier & 0x80000000 > 0) resultSignifier = resultSignifier * 0x100000000000000000000000058B90BFA >> 128;
        if (xSignifier & 0x40000000 > 0) resultSignifier = resultSignifier * 0x10000000000000000000000002C5C85FC >> 128;
        if (xSignifier & 0x20000000 > 0) resultSignifier = resultSignifier * 0x1000000000000000000000000162E42FD >> 128;
        if (xSignifier & 0x10000000 > 0) resultSignifier = resultSignifier * 0x10000000000000000000000000B17217E >> 128;
        if (xSignifier & 0x8000000 > 0) resultSignifier = resultSignifier * 0x1000000000000000000000000058B90BE >> 128;
        if (xSignifier & 0x4000000 > 0) resultSignifier = resultSignifier * 0x100000000000000000000000002C5C85E >> 128;
        if (xSignifier & 0x2000000 > 0) resultSignifier = resultSignifier * 0x10000000000000000000000000162E42E >> 128;
        if (xSignifier & 0x1000000 > 0) resultSignifier = resultSignifier * 0x100000000000000000000000000B17216 >> 128;
        if (xSignifier & 0x800000 > 0) resultSignifier = resultSignifier * 0x10000000000000000000000000058B90A >> 128;
        if (xSignifier & 0x400000 > 0) resultSignifier = resultSignifier * 0x1000000000000000000000000002C5C84 >> 128;
        if (xSignifier & 0x200000 > 0) resultSignifier = resultSignifier * 0x100000000000000000000000000162E41 >> 128;
        if (xSignifier & 0x100000 > 0) resultSignifier = resultSignifier * 0x1000000000000000000000000000B1720 >> 128;
        if (xSignifier & 0x80000 > 0) resultSignifier = resultSignifier * 0x100000000000000000000000000058B8F >> 128;
        if (xSignifier & 0x40000 > 0) resultSignifier = resultSignifier * 0x10000000000000000000000000002C5C7 >> 128;
        if (xSignifier & 0x20000 > 0) resultSignifier = resultSignifier * 0x1000000000000000000000000000162E3 >> 128;
        if (xSignifier & 0x10000 > 0) resultSignifier = resultSignifier * 0x10000000000000000000000000000B171 >> 128;
        if (xSignifier & 0x8000 > 0) resultSignifier = resultSignifier * 0x1000000000000000000000000000058B8 >> 128;
        if (xSignifier & 0x4000 > 0) resultSignifier = resultSignifier * 0x100000000000000000000000000002C5B >> 128;
        if (xSignifier & 0x2000 > 0) resultSignifier = resultSignifier * 0x10000000000000000000000000000162D >> 128;
        if (xSignifier & 0x1000 > 0) resultSignifier = resultSignifier * 0x100000000000000000000000000000B16 >> 128;
        if (xSignifier & 0x800 > 0) resultSignifier = resultSignifier * 0x10000000000000000000000000000058A >> 128;
        if (xSignifier & 0x400 > 0) resultSignifier = resultSignifier * 0x1000000000000000000000000000002C4 >> 128;
        if (xSignifier & 0x200 > 0) resultSignifier = resultSignifier * 0x100000000000000000000000000000161 >> 128;
        if (xSignifier & 0x100 > 0) resultSignifier = resultSignifier * 0x1000000000000000000000000000000B0 >> 128;
        if (xSignifier & 0x80 > 0) resultSignifier = resultSignifier * 0x100000000000000000000000000000057 >> 128;
        if (xSignifier & 0x40 > 0) resultSignifier = resultSignifier * 0x10000000000000000000000000000002B >> 128;
        if (xSignifier & 0x20 > 0) resultSignifier = resultSignifier * 0x100000000000000000000000000000015 >> 128;
        if (xSignifier & 0x10 > 0) resultSignifier = resultSignifier * 0x10000000000000000000000000000000A >> 128;
        if (xSignifier & 0x8 > 0) resultSignifier = resultSignifier * 0x100000000000000000000000000000004 >> 128;
        if (xSignifier & 0x4 > 0) resultSignifier = resultSignifier * 0x100000000000000000000000000000001 >> 128;

        if (!xNegative) {
          resultSignifier = resultSignifier >> 15 & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
          resultExponent += 0x3FFF;
        } else if (resultExponent <= 0x3FFE) {
          resultSignifier = resultSignifier >> 15 & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
          resultExponent = 0x3FFF - resultExponent;
        } else {
          resultSignifier = resultSignifier >> resultExponent - 16367;
          resultExponent = 0;
        }

        return bytes16 (uint128 (resultExponent << 112 | resultSignifier));
      }
    }
  }

  /**
   * Calculate e^x.
   *
   * @param x quadruple precision number
   * @return quadruple precision number
   */
  function exp (bytes16 x) internal pure returns (bytes16) {
    unchecked {
      return pow_2 (mul (x, 0x3FFF71547652B82FE1777D0FFDA0D23A));
    }
  }

  /**
   * Get index of the most significant non-zero bit in binary representation of
   * x.  Reverts if x is zero.
   *
   * @return index of the most significant non-zero bit in binary representation
   *         of x
   */
  function mostSignificantBit (uint256 x) private pure returns (uint256) {
    unchecked {
      require (x > 0);

      uint256 result = 0;

      if (x >= 0x100000000000000000000000000000000) { x >>= 128; result += 128; }
      if (x >= 0x10000000000000000) { x >>= 64; result += 64; }
      if (x >= 0x100000000) { x >>= 32; result += 32; }
      if (x >= 0x10000) { x >>= 16; result += 16; }
      if (x >= 0x100) { x >>= 8; result += 8; }
      if (x >= 0x10) { x >>= 4; result += 4; }
      if (x >= 0x4) { x >>= 2; result += 2; }
      if (x >= 0x2) result += 1; // No need to shift x anymore

      return result;
    }
  }
}

// File: contracts/math/NumLib.sol


pragma solidity ^0.8.0;

library NumLib {
  uint8 public constant STANDARD_DECIMALS = 18;
  uint8 public constant BONE_DECIMALS = 26;
  uint256 public constant BONE = 10**BONE_DECIMALS;
  int256 public constant iBONE = int256(BONE);

  function add(uint256 a, uint256 b) public pure returns (uint256 c) {
    c = a + b;
    require(c >= a, "ADD_OVERFLOW");
  }

  function sub(uint256 a, uint256 b) public pure returns (uint256 c) {
    bool flag;
    (c, flag) = subSign(a, b);
    require(!flag, "SUB_UNDERFLOW");
  }

  function subSign(uint256 a, uint256 b) public pure returns (uint256, bool) {
    if (a >= b) {
      return (a - b, false);
    } else {
      return (b - a, true);
    }
  }

  function mul(uint256 a, uint256 b) public pure returns (uint256 c) {
    uint256 c0 = a * b;
    require(a == 0 || c0 / a == b, "MUL_OVERFLOW");
    uint256 c1 = c0 + (BONE / 2);
    require(c1 >= c0, "MUL_OVERFLOW");
    c = c1 / BONE;
  }

  function div(uint256 a, uint256 b) public pure returns (uint256 c) {
    require(b != 0, "DIV_ZERO");
    uint256 c0 = a * BONE;
    require(a == 0 || c0 / a == BONE, "DIV_public"); // mul overflow
    uint256 c1 = c0 + (b / 2);
    require(c1 >= c0, "DIV_public"); //  add require
    c = c1 / b;
  }

  function min(uint256 first, uint256 second) public pure returns (uint256) {
    if (first < second) {
      return first;
    }
    return second;
  }
}

// File: contracts/math/ABDKMathQuadExtra.sol


pragma solidity ^0.8.0;


library ABDKMathQuadExtra {
  using ABDKMathQuad for bytes16;

  bytes16 private constant ZERO = 0x00000000000000000000000000000000; // 0
  bytes16 private constant BONE16 = 0x40554adf4b7320334b90000000000000; // 10^26

  function pow2(bytes16 _a) public pure returns (bytes16) {
    return _a.mul(_a);
  }

  function pown(bytes16 _a, uint256 _n) public pure returns (bytes16) {
    bytes16 z = _n % 2 != 0 ? _a : ABDKMathQuad.fromInt(1);

    for (_n /= 2; _n != 0; _n /= 2) {
      _a = ABDKMathQuad.mul(_a, _a);

      if (_n % 2 != 0) {
        z = ABDKMathQuad.mul(z, _a);
      }
    }
    return z;
  }

  function boundary(
    bytes16 _a,
    bytes16 _min,
    bytes16 _max
  ) public pure returns (bytes16) {
    if (lt(_a, _min)) {
      return _min;
    }

    if (gt(_a, _max)) {
      return _max;
    }

    return _a;
  }

  function max(bytes16 _a, bytes16 _b) public pure returns (bytes16) {
    if (_a.cmp(_b) == int8(1)) {
      return _a;
    } else {
      return _b;
    }
  }

  function min(bytes16 _a, bytes16 _b) public pure returns (bytes16) {
    if (_a.cmp(_b) == int8(1)) {
      return _b;
    } else {
      return _a;
    }
  }

  function gt(bytes16 _a, bytes16 _b) public pure returns (bool) {
    return _a.cmp(_b) == int8(1);
  }

  function gte(bytes16 _a, bytes16 _b) public pure returns (bool) {
    return gt(_a, _b) || _a.eq(_b);
  }

  function lt(bytes16 _a, bytes16 _b) public pure returns (bool) {
    return _a.cmp(_b) == int8(-1);
  }

  function lte(bytes16 _a, bytes16 _b) public pure returns (bool) {
    return lt(_a, _b) || _a.eq(_b);
  }

  function zerofyWrongNumber(bytes16 _a) public pure returns (bytes16) {
    if (_a.isNaN() || _a.isInfinity()) {
      return ZERO;
    } else {
      return _a;
    }
  }

  function toUIntBoned(bytes16 _value) public pure returns (uint256) {
    return ABDKMathQuad.toUInt(ABDKMathQuad.mul(_value, BONE16));
  }

  function fromUIntBoned(uint256 _value) public pure returns (bytes16) {
    return ABDKMathQuad.div(ABDKMathQuad.fromUInt(_value), BONE16);
  }

  function toIntBoned(bytes16 _value) public pure returns (int256) {
    return ABDKMathQuad.toInt(ABDKMathQuad.mul(_value, BONE16));
  }

  function fromIntBoned(int256 _value) public pure returns (bytes16) {
    return ABDKMathQuad.div(ABDKMathQuad.fromInt(_value), BONE16);
  }
}

// File: contracts/Const.sol


pragma solidity ^0.8.0;

contract Const {
  uint8 public constant STANDARD_DECIMALS = 18;
  uint8 public constant BONE_DECIMALS = 26;
  uint256 public constant BONE = 10**BONE_DECIMALS;
  int256 public constant iBONE = int256(BONE);
}

// File: contracts/specification/IDerivativeSpecification.sol


pragma solidity ^0.8.0;

/// @title Derivative Specification interface
/// @notice Immutable collection of derivative attributes
/// @dev Created by the derivative's author and published to the DerivativeSpecificationRegistry
interface IDerivativeSpecification {
  /// @notice Proof of a derivative specification
  /// @dev Verifies that contract is a derivative specification
  /// @return true if contract is a derivative specification
  function isDerivativeSpecification() external pure returns (bool);

  /// @notice Set of oracles that are relied upon to measure changes in the state of the world
  /// between the start and the end of the Live period
  /// @dev Should be resolved through OracleRegistry contract
  /// @return oracle symbols
  function underlyingOracleSymbols() external view returns (bytes32[] memory);

  /// @notice Algorithm that, for the type of oracle used by the derivative,
  /// finds the value closest to a given timestamp
  /// @dev Should be resolved through OracleIteratorRegistry contract
  /// @return oracle iterator symbols
  function underlyingOracleIteratorSymbols() external view returns (bytes32[] memory);

  /// @notice Type of collateral that users submit to mint the derivative
  /// @dev Should be resolved through CollateralTokenRegistry contract
  /// @return collateral token symbol
  function collateralTokenSymbol() external view returns (bytes32);

  /// @notice Mapping from the change in the underlying variable (as defined by the oracle)
  /// and the initial collateral split to the final collateral split
  /// @dev Should be resolved through CollateralSplitRegistry contract
  /// @return collateral split symbol
  function collateralSplitSymbol() external view returns (bytes32);

  function denomination(uint256 _settlement, uint256 _referencePrice)
    external
    view
    returns (uint256);

  function referencePrice(uint256 _price, uint256 _position) external view returns (uint256);
}

// File: contracts/collateralSplits/ICollateralSplit.sol



pragma solidity ^0.8.0;

/// @title Collateral Split interface
/// @notice Contains mathematical functions used to calculate relative claim
/// on collateral of primary and complement assets after settlement.
/// @dev Created independently from specification and published to the CollateralSplitRegistry
interface ICollateralSplit {
  /// @notice Proof of collateral split contract
  /// @dev Verifies that contract is a collateral split contract
  /// @return true if contract is a collateral split contract
  function isCollateralSplit() external pure returns (bool);

  /// @notice Symbol of the collateral split
  /// @dev Should be resolved through CollateralSplitRegistry contract
  /// @return collateral split specification symbol
  function symbol() external pure returns (string memory);

  /// @notice Calcs primary asset class' share of collateral at settlement.
  /// @dev Returns ranged value between 0 and 1 multiplied by 10 ^ 12
  /// @param _underlyingStarts underlying values in the start of Live period
  /// @param _underlyingEndRoundHints specify for each oracle round of the end of Live period
  /// @return _split primary asset class' share of collateral at settlement
  /// @return _underlyingEnds underlying values in the end of Live period
  function split(
    address[] calldata _oracles,
    address[] calldata _oracleIterators,
    int256[] calldata _underlyingStarts,
    uint256 _settleTime,
    uint256[] calldata _underlyingEndRoundHints
  ) external view returns (uint256 _split, int256[] memory _underlyingEnds);
}

// File: contracts/volatility/IVolatilitySurface.sol


pragma solidity ^0.8.0;

interface IVolatilitySurface {
  function calcSigmaATM(bytes16 _omega, bytes16 _ttm) external view returns (bytes16);

  function calcSigmaATMReverted(bytes16 _sigmaTTM, bytes16 _ttm) external view returns (bytes16);

  function calcSigma(
    bytes16 _sigmaATM,
    bytes16 _mu,
    bytes16 _ttm
  ) external view returns (bytes16);

  function calcSigmaReverted(
    bytes16 _sigma,
    bytes16 _mu,
    bytes16 _ttm
  ) external view returns (bytes16);
}

// File: @chainlink/contracts/src/v0.8/interfaces/AggregatorInterface.sol


pragma solidity ^0.8.0;

interface AggregatorInterface {
  function latestAnswer() external view returns (int256);

  function latestTimestamp() external view returns (uint256);

  function latestRound() external view returns (uint256);

  function getAnswer(uint256 roundId) external view returns (int256);

  function getTimestamp(uint256 roundId) external view returns (uint256);

  event AnswerUpdated(int256 indexed current, uint256 indexed roundId, uint256 updatedAt);

  event NewRound(uint256 indexed roundId, address indexed startedBy, uint256 startedAt);
}

// File: @chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol


pragma solidity ^0.8.0;

interface AggregatorV3Interface {
  function decimals() external view returns (uint8);

  function description() external view returns (string memory);

  function version() external view returns (uint256);

  // getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.
  function getRoundData(uint80 _roundId)
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );
}

// File: @chainlink/contracts/src/v0.8/interfaces/AggregatorV2V3Interface.sol


pragma solidity ^0.8.0;


interface AggregatorV2V3Interface is AggregatorInterface, AggregatorV3Interface {}

// File: contracts/utility/ISettableFeed.sol


pragma solidity ^0.8.0;

interface ISettableFeed is AggregatorV2V3Interface {
  function setLatestRoundData(int256 _answer, uint256 _timestamp) external;
}

// File: contracts/oracleIterators/IOracleIterator.sol


pragma solidity ^0.8.0;

interface IOracleIterator {
  /// @notice Proof of oracle iterator contract
  /// @dev Verifies that contract is a oracle iterator contract
  /// @return true if contract is a oracle iterator contract
  function isOracleIterator() external pure returns (bool);

  /// @notice Symbol of the oracle iterator
  /// @dev Should be resolved through OracleIteratorRegistry contract
  /// @return oracle iterator symbol
  function symbol() external pure returns (string memory);

  /// @notice Algorithm that, for the type of oracle used by the derivative,
  //  finds the value closest to a given timestamp
  /// @param _oracle iteratable oracle through
  /// @param _timestamp a given timestamp
  /// @param _roundHint specified a round for a given timestamp
  /// @return roundId the roundId closest to a given timestamp
  /// @return value the value closest to a given timestamp
  /// @return timestamp the timestamp closest to a given timestamp
  function getRound(
    address _oracle,
    uint256 _timestamp,
    uint256 _roundHint
  )
    external
    view
    returns (
      uint80 roundId,
      int256 value,
      uint256 timestamp
    );
}

// File: contracts/volatility/IVolatilityEvolution.sol


pragma solidity ^0.8.0;



interface IVolatilityEvolution {
  struct UnderlyingParams {
    IVolatilitySurface surface;
    ISettableFeed feed;
    IOracleIterator feedIterator;
    bytes16 omegaTarget;
    bytes16 omegaMin;
    bytes16 omegaMax;
    bytes16 deltaOmegaMin;
    bytes16 deltaOmegaMax;
    bytes16 sigmaMin;
    bytes16 sigmaMax;
    bytes16 thetaConv;
  }

  struct VolatilityParams {
    bytes16 ttm;
    bytes16 mu;
    bytes16 sigma;
    bytes16 omegaCurrent;
  }

  function calculateVolatility(
    uint256 _pointInTime,
    address _underlying,
    bytes16 _ttm,
    bytes16 _mu,
    uint256 omegaRoundHint
  ) external view returns (bytes16 sigma, bytes16 omega);

  function updateVolatility(
    uint256 _pointInTime,
    VolatilityParams memory _volParams,
    address _underlying,
    bytes16 _underlyingPrice,
    bytes16 _strike,
    bytes16 _priceNorm,
    bool _buyPrimary
  ) external;
}

// File: contracts/IUnderlyingLiquidityValuer.sol


pragma solidity ^0.8.0;

interface IUnderlyingLiquidityValuer {
  function getUnderlyingLiquidityValue(address underlying) external returns (uint256 liquidityValue);
}

// File: contracts/poolBlocks/IPoolTypes.sol


pragma solidity ^0.8.0;




interface IPoolTypes {
  enum PriceType {
    mid,
    ask,
    bid
  }

  enum Side {
    Primary,
    Complement,
    Empty,
    Both
  }

  enum Mode {
    Temp,
    Reinvest
  }

  struct Sequence {
    Mode mode;
    Side side;
    uint256 settlementDelta;
    uint256 strikePosition;
  }

  struct DerivativeConfig {
    IDerivativeSpecification specification;
    address[] underlyingOracles;
    address[] underlyingOracleIterators;
    address collateralToken;
    ICollateralSplit collateralSplit;
  }

  struct Derivative {
    DerivativeConfig config;
    address terms;
    Sequence sequence;
    DerivativeParams params;
  }

  struct DerivativeParams {
    uint256 priceReference;
    uint256 settlement;
    uint256 denomination;
  }

  struct Vintage {
    Pair rollRate;
    Pair releaseRate;
    uint256 priceReference;
  }

  struct Pair {
    uint256 primary;
    uint256 complement;
  }

  struct PoolSnapshot {
    Derivative[] derivatives;
    address exposureAddress;
    uint256 collateralLocked;
    uint256 collateralFree;
    Pair[] derivativePositions;
    IVolatilityEvolution volatilityEvolution;
    IUnderlyingLiquidityValuer underlyingLiquidityValuer;
  }

  struct PricePair {
    int256 primary;
    int256 complement;
  }

  struct OtherPrices {
    int256 collateral;
    int256 underlying;
    uint256 volatilityRoundHint;
  }

  struct SettlementValues {
    Pair value;
    uint256 underlyingPrice;
  }

  struct RolloverTrade {
    Pair inward;
    Pair outward;
  }

  struct DerivativeSettlement {
    uint256 settlement;
    Pair value;
    Pair position;
  }

  struct PoolSharePriceHints {
    bool hintLess;
    uint256 collateralPrice;
    uint256[] underlyingRoundHintsIndexed;
    uint256 volatilityRoundHint;
  }

  struct PoolBalance {
    uint256 collateralLocked;
    uint256 collateralFree;
    uint256 releasedWinnings;
    uint256 releasedLiquidityTotal;
  }

  struct RolloverHints {
    uint256 derivativeIndex;
    uint256 collateralRoundHint;
    uint256[] underlyingRoundHintsIndexed;
    uint256 volatilityRoundHint;
  }
}

// File: contracts/exposure/IExposure.sol


pragma solidity ^0.8.0;

interface IExposure is IPoolTypes {
  function calcExposure(
    Derivative[] memory derivatives,
    Pair[] memory positions,
    uint256 collateralAmount
  ) external view returns (uint256);

  function calcCollateralExposureLimit(
    Derivative[] memory derivatives,
    Pair[] memory positions
  ) external view returns (uint256);

  function calcInputPercent(
    uint256 derivativeIndex,
    Derivative[] memory derivatives,
    Pair[] memory positions,
    uint256 collateralFreeAmount,
    uint256 inDerivativeAmountNew,
    uint256 outDerivativeAmountNew,
    uint256 collateralAmountNew
  ) external view returns (bytes16 percent);

  function getCoefficients(
    address[] memory _underlyings
  ) external view returns(uint256[4][] memory coefficients);

  function getWeight(
    uint256 _derivativeIndex
  ) external view returns(uint256);
}

// File: @openzeppelin/contracts/access/IAccessControl.sol


// OpenZeppelin Contracts v4.4.1 (access/IAccessControl.sol)

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControl {
    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {AccessControl-_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) external view returns (bool);

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {AccessControl-_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) external;
}

// File: @openzeppelin/contracts/utils/Context.sol


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

// File: @openzeppelin/contracts/utils/Strings.sol


// OpenZeppelin Contracts (last updated v4.7.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
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

// File: @openzeppelin/contracts/utils/introspection/IERC165.sol


// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// File: @openzeppelin/contracts/utils/introspection/ERC165.sol


// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// File: @openzeppelin/contracts/access/AccessControl.sol


// OpenZeppelin Contracts (last updated v4.7.0) (access/AccessControl.sol)

pragma solidity ^0.8.0;




/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms. This is a lightweight version that doesn't allow enumerating role
 * members except through off-chain means by accessing the contract event logs. Some
 * applications may benefit from on-chain enumerability, for those cases see
 * {AccessControlEnumerable}.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it.
 */
abstract contract AccessControl is Context, IAccessControl, ERC165 {
    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
    }

    mapping(bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with a standardized message including the required role.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     *
     * _Available since v4.1._
     */
    modifier onlyRole(bytes32 role) {
        _checkRole(role);
        _;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControl).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view virtual override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `_msgSender()` is missing `role`.
     * Overriding this function changes the behavior of the {onlyRole} modifier.
     *
     * Format of the revert message is described in {_checkRole}.
     *
     * _Available since v4.6._
     */
    function _checkRole(bytes32 role) internal view virtual {
        _checkRole(role, _msgSender());
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function _checkRole(bytes32 role, address account) internal view virtual {
        if (!hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        Strings.toHexString(uint160(account), 20),
                        " is missing role ",
                        Strings.toHexString(uint256(role), 32)
                    )
                )
            );
        }
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view virtual override returns (bytes32) {
        return _roles[role].adminRole;
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     *
     * May emit a {RoleGranted} event.
     */
    function grantRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     *
     * May emit a {RoleRevoked} event.
     */
    function revokeRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been revoked `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     *
     * May emit a {RoleRevoked} event.
     */
    function renounceRole(bytes32 role, address account) public virtual override {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * May emit a {RoleGranted} event.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     *
     * NOTE: This function is deprecated in favor of {_grantRole}.
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        bytes32 previousAdminRole = getRoleAdmin(role);
        _roles[role].adminRole = adminRole;
        emit RoleAdminChanged(role, previousAdminRole, adminRole);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * Internal function without access restriction.
     *
     * May emit a {RoleGranted} event.
     */
    function _grantRole(bytes32 role, address account) internal virtual {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * Internal function without access restriction.
     *
     * May emit a {RoleRevoked} event.
     */
    function _revokeRole(bytes32 role, address account) internal virtual {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }
}

// File: contracts/math/NormalDist.sol


pragma solidity ^0.8.0;


contract NormalDist {
  using ABDKMathQuad for bytes16;
  using ABDKMathQuadExtra for bytes16;

  bytes16 private constant PI = 0x4000921fb54442d18469898cc516fc9e; //fromIntMultiplied(3141592653589793238462643383279, 10**30)

  bytes16 private constant ZERO = 0x00000000000000000000000000000000; // 0
  bytes16 private constant ONE = 0x3fff0000000000000000000000000000; // 1
  bytes16 private constant TWO = 0x40000000000000000000000000000000; // 2
  bytes16 private constant THREE = 0x40008000000000000000000000000000; // 3
  bytes16 private constant FOUR = 0x40010000000000000000000000000000; // 4
  bytes16 private constant THIRTEEN = 0x4002a000000000000000000000000000; // 13
  bytes16 private constant TWENTY = 0x40034000000000000000000000000000; // 20

  bytes16 private constant THIRTY_SEVEN = 0x40042800000000000000000000000000; // 37
  bytes16 private constant SPLIT = 0x4001c48c6001f0ab9cd3274c66eef06e; // fromIntMultiplied(707106781186547, 10**14)
  bytes16 private constant RT2PI = 0x400040d931ff61e38a7f7b85645ce6aa; // fromIntMultiplied(250662827463, 10**11) == sqrt(4.0*acos(0.0))

  bytes16 private constant N0 = 0x4006b869ea974c7e514091f224d31ad3; // 220.206867912376;
  bytes16 private constant N1 = 0x4006ba6d5c7a28cf1b17c104954fd0f8; // 221.213596169931;
  bytes16 private constant N2 = 0x4005c05131ca58d3c304ec2134f725a5; // 112.079291497871;
  bytes16 private constant N3 = 0x40040f4d8cbb024316659889b54a916d; // 33.912866078383;
  bytes16 private constant N4 = 0x400197eeff2a86f23217cff3c38ba52b; // 6.37396220353165;
  bytes16 private constant N5 = 0x3ffe66989be8ea71eb9ee99cdf2a6444; // 0.700383064443688;
  bytes16 private constant N6 = 0x3ffa20ded0b57fbde15a25a9bb09ea24; // 3.52624965998911e-02;

  bytes16 private constant M0 = 0x4007b869ea974c7e514091f224d31ad3; // 440.413735824752;
  bytes16 private constant M1 = 0x40088ce9cb298974a27389304c88bc0c; // 793.826512519948;
  bytes16 private constant M2 = 0x40083eaab47fa177709906e1cd401126; // 637.333633378831;
  bytes16 private constant M3 = 0x40072890729ba781fb37f5a54d8e35f9; // 296.564248779674;
  bytes16 private constant M4 = 0x40055b1f78433a59a29ad6ea709d5b6c; // 86.7807322029461;
  bytes16 private constant M5 = 0x40030106df11bd49c9b1325f6a6b4863; // 16.064177579207;
  bytes16 private constant M6 = 0x3fffc173673887d114c5497f3fbc4d89; // 1.75566716318264;
  bytes16 private constant M7 = 0x3ffb6a09e667f3bc9a486ba1c47c161d; // 8.83883476483184e-02;

  // https://stackoverflow.com/questions/2328258/cumulative-normal-distribution-function-in-c-c/23119456#23119456
  function ncdf(bytes16 x) public pure returns (bytes16) {
    bytes16 z = ABDKMathQuad.abs(x);
    bytes16 c = ZERO;

    if (z.lte(THIRTY_SEVEN)) {
      bytes16 e = ABDKMathQuad.exp(
        ABDKMathQuad.div(ABDKMathQuad.mul(ABDKMathQuad.neg(z), z), TWO)
      );

      if (z.lt(SPLIT)) {
        c = calcLessSplit(z, e);
      } else {
        c = calcMoreSplit(z, e);
      }
    }
    c = x.lte(0) ? c : ONE.sub(c);
    return c;
  }

  function calcLessSplit(bytes16 z, bytes16 e) internal pure returns (bytes16) {
    bytes16 n = addm(addm(addm(addm(addm(addm(N6, z, N5), z, N4), z, N3), z, N2), z, N1), z, N0);

    bytes16 d = addm(
      addm(addm(addm(addm(addm(addm(M7, z, M6), z, M5), z, M4), z, M3), z, M2), z, M1),
      z,
      M0
    );

    return ABDKMathQuad.div(ABDKMathQuad.mul(e, n), d);
  }

  function calcMoreSplit(bytes16 z, bytes16 e) internal pure returns (bytes16) {
    bytes16 f = addr(z, THIRTEEN, TWENTY);
    f = addr(z, FOUR, f);
    f = addr(z, THREE, f);
    f = addr(z, TWO, f);
    f = addr(z, ONE, f);

    return ABDKMathQuad.div(e, ABDKMathQuad.mul(RT2PI, f));
  }

  function addm(
    bytes16 a,
    bytes16 b,
    bytes16 c
  ) internal pure returns (bytes16) {
    return a.mul(b).add(c);
  }

  function addr(
    bytes16 a,
    bytes16 b,
    bytes16 c
  ) internal pure returns (bytes16) {
    return b.div(c).add(a);
  }
}

// File: contracts/math/Volatility.sol


pragma solidity ^0.8.0;



//import "hardhat/console.sol";

//TODO: change to Library
contract Volatility is NormalDist {
  using ABDKMathQuad for bytes16;
  using ABDKMathQuad for uint256;
  using ABDKMathQuadExtra for bytes16;

  bytes16 private constant PI = 0x4000921fb54442d18469898cc516fc9e; //fromIntMultiplied(3141592653589793238462643383279, 10**30)

  bytes16 private constant ZERO = 0x00000000000000000000000000000000; // 0
  bytes16 private constant ONE = 0x3fff0000000000000000000000000000; // 1
  bytes16 private constant TWO = 0x40000000000000000000000000000000; // 2

  //    bytes16 private constant EPSILON = 0x3feb0c6f7a0b5ed8d36b4c7f34938583; // 0.000001
  bytes16 private constant EPSILON = 0x3ff50624dd2f1a9fbe76c8b439581062; // 0.001

  uint256 IMPLIED_VOLATILITY_ITERATION_MAX = 5;

  function calcD1(
    bytes16 _spotPrice,
    bytes16 _volatility,
    bytes16 _ttm,
    bytes16 _strike
  ) public pure returns (bytes16 d1, bytes16 volatilityBySqrtTtm) {
    volatilityBySqrtTtm = _volatility.mul(_ttm.sqrt());
    bytes16 volatilityByTtm = _volatility.mul(_volatility).mul(_ttm).div(TWO);
    d1 = ONE.div(volatilityBySqrtTtm).mul(_spotPrice.div(_strike).ln().add(volatilityByTtm));
  }

  function calcOption(
    bytes16 _spotPrice,
    bytes16 _strike,
    bytes16 _d1,
    bytes16 _volatilityBySqrtTtm
  ) public pure returns (bytes16) {
    return ncdf(_d1).mul(_spotPrice).sub(ncdf(_d1.sub(_volatilityBySqrtTtm)).mul(_strike));
  }

  function pdf(bytes16 x) public pure returns (bytes16) {
    return ONE.div(PI.mul(TWO).sqrt()).mul(x.mul(x).div(TWO).neg().exp());
  }

  function calcVega(
    bytes16 F, //_spotPrice,
    bytes16 T, // TTM option maturity
    bytes16 d1
  ) public pure returns (bytes16) {
    return F.mul(pdf(d1)).mul(T.sqrt()); //S * N'(d_{1}){\sqrt {T-t}}\,
  }

  function calcVolatility(
    bytes16 sigmaCurrent,
    bytes16 sigmaMin,
    bytes16 optionPrice, //option market price
    bytes16 underlyingPrice, //spot price,
    bytes16 strike,
    bytes16 ttm,
    bytes16 r // constant interest rates
  ) public view returns (bytes16 sigma) {
    sigma = sigmaCurrent;

    //        log("sigmaCurrent", sigmaCurrent);
    //        log("optionPrice", optionPrice);
    //        log("underlyingPrice", underlyingPrice);
    //        log("strike", strike);
    //        log("ttm", ttm);
    //        log("r", r);

    (bytes16 d1, bytes16 volatilityBySqrtTtm) = calcD1(underlyingPrice, sigma, ttm, strike);
    bytes16 optionPriceNew = calcOption(underlyingPrice, strike, d1, volatilityBySqrtTtm);
    //        log("optionPriceNew", optionPriceNew);

    bytes16 optionPriceDiff = optionPriceNew.sub(optionPrice);
    //        log("optionPriceDiff", optionPriceDiff);
    bytes16 vega;

    uint256 i;
    while (optionPriceDiff.abs().gt(EPSILON)) {
      vega = calcVega(underlyingPrice, ttm, d1);

      //            log("vega", vega);
      sigma = sigma.sub(optionPriceDiff.div(vega)).max(sigmaMin);
      //            log("vol", sigma);

      (d1, volatilityBySqrtTtm) = calcD1(underlyingPrice, sigma, ttm, strike);
      optionPriceNew = calcOption(underlyingPrice, strike, d1, volatilityBySqrtTtm);
      if (optionPriceNew.lte(ZERO)) {
        return ZERO;
      }
      //            log("optionPriceNew", optionPriceNew);

      optionPriceDiff = optionPriceNew.sub(optionPrice);
      //            log("optionPriceDiff", optionPriceDiff);

      i += 1;
      if (i > IMPLIED_VOLATILITY_ITERATION_MAX) {
        return ZERO;
      }
    }
  }

  //    function log(string memory name, bytes16 value) internal view {
  //        console.log(name);
  //        console.logBytes16(value);
  //        console.logInt(ABDKMathQuadExtra.toIntBoned(value));
  //        console.log("");
  //    }
}

// File: contracts/volatility/VolatilityEvolution.sol


pragma solidity ^0.8.0;










//import "hardhat/console.sol";

contract VolatilityEvolution is IVolatilityEvolution, AccessControl, Volatility, Const {
  using ABDKMathQuad for bytes16;
  using ABDKMathQuad for uint256;
  using ABDKMathQuad for int256;
  using ABDKMathQuadExtra for bytes16;
  using ABDKMathQuadExtra for uint256;
  using ABDKMathQuadExtra for int256;

  bytes32 public constant FEED_UPDATER_ROLE = keccak256("FEED_UPDATER_ROLE");

  bytes16 private constant ZERO = 0x00000000000000000000000000000000; // 0
  bytes16 private constant ONE = 0x3fff0000000000000000000000000000; // 1
  bytes16 internal constant RefTTM = 0x3ffb50a8542a150a8542a150a8542a15; // 30/365

  event SetUnderlyingParams(address indexed underlying, UnderlyingParams params);

  event UpdatedVolatility(
    uint256 updatedAt,
    uint256 omegaNew,
    uint256 omegaAdjusted,
    uint256 sigmaEst,
    uint256 sigmaPrice,
    uint256 ttm,
    int256 mu,
    uint256 underlyingPrice,
    uint256 strike,
    uint256 priceNorm,
    bool buyPrimary
  );

  mapping(address => UnderlyingParams) internal _underlyingParams;

  constructor() {
    _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
  }

  function setUnderlyingParams(
    address _underlying,
    address _surface,
    address _feed,
    address _feedIterator,
    uint256 _omegaTarget,
    uint256 _omegaMin,
    uint256 _omegaMax,
    uint256 _deltaOmegaMin,
    uint256 _deltaOmegaMax,
    uint256 _sigmaMin,
    uint256 _sigmaMax,
    uint256 _thetaConv
  ) external {
    _checkRole(DEFAULT_ADMIN_ROLE, _msgSender());

    UnderlyingParams memory params = UnderlyingParams(
      IVolatilitySurface(_surface),
      ISettableFeed(_feed),
      IOracleIterator(_feedIterator),
      _omegaTarget.fromUIntBoned(),
      _omegaMin.fromUIntBoned(),
      _omegaMax.fromUIntBoned(),
      _deltaOmegaMin.fromUIntBoned(),
      _deltaOmegaMax.fromUIntBoned(),
      _sigmaMin.fromUIntBoned(),
      _sigmaMax.fromUIntBoned(),
      _thetaConv.fromUIntBoned()
    );

    _underlyingParams[_underlying] = params;

    emit SetUnderlyingParams(_underlying, params);
  }

  function getUnderlyingParams(address _underlying)
    external
    view
    returns (
      IVolatilitySurface surface,
      ISettableFeed feed,
      IOracleIterator feedIterator,
      uint256 omegaTarget,
      uint256 omegaMin,
      uint256 omegaMax,
      uint256 deltaOmegaMin,
      uint256 deltaOmegaMax,
      uint256 sigmaMin,
      uint256 sigmaMax,
      uint256 thetaConv
    )
  {
    UnderlyingParams memory params = _underlyingParams[_underlying];

    surface = params.surface;
    feed = params.feed;
    feedIterator = params.feedIterator;
    omegaTarget = params.omegaTarget.toUIntBoned();
    omegaMin = params.omegaMin.toUIntBoned();
    omegaMax = params.omegaMax.toUIntBoned();
    deltaOmegaMin = params.deltaOmegaMin.toUIntBoned();
    deltaOmegaMax = params.deltaOmegaMax.toUIntBoned();
    sigmaMin = params.sigmaMin.toUIntBoned();
    sigmaMax = params.sigmaMax.toUIntBoned();
    thetaConv = params.thetaConv.toUIntBoned();
  }

  function calculateVolatility(
    uint256 _pointInTime,
    address _underlying,
    bytes16 _ttm,
    bytes16 _mu,
    uint256 _omegaRoundHint
  ) external view override returns (bytes16 sigma, bytes16 omega) {
    UnderlyingParams memory params = _underlyingParams[_underlying];

    (, int256 omegaAnswer, uint256 omegaTimestamp) = params.feedIterator.getRound(
      address(params.feed),
      _pointInTime,
      _omegaRoundHint
    );

    omega = updateOmegaToTime(_pointInTime, params, omegaAnswer, omegaTimestamp);

    if (omega.lte(params.omegaMin) || omega.gte(params.omegaMax)) {
      omega = params.omegaTarget;
    }

    sigma = params.surface.calcSigmaATM(omega, _ttm);

    sigma = params.surface.calcSigma(sigma, _mu, _ttm);

    sigma = sigma.boundary(params.sigmaMin, params.sigmaMax);
  }

  function updateOmegaToTime(
    uint256 _pointInTime,
    UnderlyingParams memory _params,
    int256 _omegaAnswerRaw,
    uint256 _omegaTimestamp
  ) internal pure returns (bytes16) {
    bytes16 omegaAnswer = _omegaAnswerRaw.fromIntBoned();

    return
      omegaAnswer.add(
        _params.omegaTarget.sub(omegaAnswer).mul(
          (_pointInTime - _omegaTimestamp).fromUInt().div(_params.thetaConv).min(ONE)
        )
      );
  }

  function updateVolatility(
    uint256 _pointInTime,
    VolatilityParams memory _volParams,
    address _underlying,
    bytes16 _underlyingPrice,
    bytes16 _strike,
    bytes16 _priceNorm,
    bool _buyPrimary
  ) external override onlyRole(FEED_UPDATER_ROLE) {
    UnderlyingParams memory params = _underlyingParams[_underlying];

    bytes16 sigmaEst = calcVolatility(
      _volParams.sigma,
      params.sigmaMin,
      _priceNorm,
      _underlyingPrice,
      _strike,
      _volParams.ttm,
      ZERO
    );

    sigmaEst = sigmaEst.boundary(params.sigmaMin, params.sigmaMax);

    sigmaEst = params.surface.calcSigmaReverted(sigmaEst, _volParams.mu, _volParams.ttm);
    bytes16 omegaEst = params.surface.calcSigmaATMReverted(sigmaEst, _volParams.ttm);

    if (_buyPrimary) {
      if (omegaEst.lt(_volParams.omegaCurrent)) {
        omegaEst = _volParams.omegaCurrent;
      }
    } else {
      if (omegaEst.gt(_volParams.omegaCurrent)) {
        omegaEst = _volParams.omegaCurrent;
      }
    }

    omegaEst = omegaEst.boundary(
      _volParams.omegaCurrent.sub(params.deltaOmegaMax),
      _volParams.omegaCurrent.add(params.deltaOmegaMax)
    );
    omegaEst = omegaEst.boundary(params.omegaMin, params.omegaMax);

    bool updating = omegaEst.gte(_volParams.omegaCurrent.add(params.deltaOmegaMin)) ||
      omegaEst.lte(_volParams.omegaCurrent.sub(params.deltaOmegaMin));
    if (updating) {
      params.feed.setLatestRoundData(omegaEst.toIntBoned(), _pointInTime);
      emitUpdatedVolatilityParams(
        _pointInTime,
        omegaEst,
        _volParams,
        sigmaEst,
        _underlyingPrice,
        _strike,
        _priceNorm,
        _buyPrimary
      );
    }
  }

  function emitUpdatedVolatilityParams(
    uint256 _pointInTime,
    bytes16 _omegaEst,
    VolatilityParams memory _volParams,
    bytes16 _sigmaEst,
    bytes16 _underlyingPrice,
    bytes16 _strike,
    bytes16 _priceNorm,
    bool _buyPrimary
  ) internal {
    emit UpdatedVolatility(
      _pointInTime,
      _omegaEst.toUIntBoned(),
      _volParams.omegaCurrent.toUIntBoned(),
      _sigmaEst.toUIntBoned(),
      _volParams.sigma.toUIntBoned(),
      _volParams.ttm.toUIntBoned(),
      _volParams.mu.toIntBoned(),
      _underlyingPrice.toUIntBoned(),
      _strike.toUIntBoned(),
      _priceNorm.toUIntBoned(),
      _buyPrimary
    );
  }

  //    function log(string memory name, bytes16 value) internal view {
  //        console.log(name);
  //        console.logBytes16(value);
  //        console.logInt(ABDKMathQuadExtra.toIntBoned(value));
  //        console.log("");
  //    }
}

// File: contracts/terms/IRepricerTypes.sol


pragma solidity ^0.8.0;

interface IRepricerTypes {
  struct PairBytes16 {
    bytes16 primary;
    bytes16 complement;
  }
}

// File: contracts/terms/ITermsTypes.sol


pragma solidity ^0.8.0;


interface ITermsTypes is IPoolTypes, IRepricerTypes {
  struct VolatilityInputs {
    bytes16 ttm;
    bytes16 mu;
  }

  struct TradePrices {
    bytes16 derivative;
    bytes16 inward;
    bytes16 outward;
    DerivativePricesBytes16 derivativePrices;
  }

  struct TradeAmounts {
    bytes16 inward;
    bytes16 outward;
  }

  struct RolloverInputs {
    PairBytes16 price;
    PairBytes16 amount;
    PairBytes16 valueAllowed;
    bytes16 collateralAmount;
    bytes16 percentLiq;
  }

  struct FeeParams {
    uint256 baseFee;
    uint256 maxFee;
    uint256 rollFee;
    uint256 feeAmpPrimary;
    uint256 feeAmpComplement;
  }

  struct DerivativePricesBytes16 {
    PairBytes16 pair;
    VolatilityInputs inputs;
    bytes16 sigma;
    bytes16 omega;
  }

  struct OtherPricesBytes16 {
    bytes16 collateral;
    bytes16 underlying;
    uint256 volatilityRoundHint;
  }

  struct DerivativeSettlementBytes16 {
    uint256 settlement;
    PairBytes16 value;
    PairBytes16 position;
  }

  struct RolloverTradeBytes16 {
    PairBytes16 inward;
    PairBytes16 outward;
    bytes16 percentExp;
  }
}

// File: contracts/terms/ITerms.sol


pragma solidity ^0.8.0;

interface ITerms is ITermsTypes {

  function version() external returns (uint256);

  function instrumentType() external returns (string memory);

  function calculatePrice(
    uint256 _pointInTime,
    Derivative memory _derivative,
    Side _side,
    PriceType _price,
    OtherPrices memory otherPrices,
    IVolatilityEvolution _volatilityEvolution
  ) external returns (PricePair memory);

  function calculateRolloverTrade(
    PoolSnapshot memory snapshot,
    uint256 derivativeIndex,
    IPoolTypes.DerivativeSettlement memory derivativeSettlement,
    OtherPrices memory otherPrices
  ) external returns (RolloverTrade memory positions);

  function calculateOutAmount(
    PoolSnapshot memory snapshot,
    uint256 inAmount,
    uint256 derivativeIndex,
    Side _side,
    bool _poolReceivesCollateral,
    OtherPrices memory otherPrices
  ) external returns (uint256 outAmount);
}

// File: contracts/terms/IRepricer.sol


pragma solidity ^0.8.0;

interface IRepricer is IRepricerTypes {
  function isRepricer() external pure returns (bool);

  function symbol() external pure returns (string memory);

  function reprice(
    bytes16 _underlyingPrice,
    bytes16 _collateralPrice, // doesn't used
    bytes16 _ttm,
    bytes16 _repricerParam1,
    bytes16 _repricerParam2,
    bytes16 _strike, // doesn't used
    bytes16 _denomination
  ) external view returns (PairBytes16 memory);
}

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol


// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

// File: @openzeppelin/contracts/token/ERC721/IERC721.sol


// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

// File: contracts/portfolio/ITraderPortfolio.sol


pragma solidity ^0.8.0;

interface ITraderPortfolio is IERC721 {
  function getPortfolioBy(address _user) external view returns (uint256);
  function getOrCreatePortfolioBy(address _user) external returns (uint256);
}

// File: contracts/share/IERC20MintedBurnable.sol


pragma solidity ^0.8.0;

interface IERC20MintedBurnable is IERC20 {
  function mint(address to, uint256 amount) external;

  function burn(uint256 amount) external;
}

// File: contracts/poolBlocks/IPoolConfigTypes.sol


pragma solidity ^0.8.0;







interface IPoolConfigTypes {
  struct PoolConfig {
    uint256 minExitAmount; //100USD in collateral
    uint256 protocolFee;
    address feeWallet;
    IERC20 collateralToken;
    address collateralOracle;
    IOracleIterator collateralOracleIterator;
    IVolatilityEvolution volatilityEvolution;
    IUnderlyingLiquidityValuer underlyingLiquidityValuer;
    IExposure exposure;
    IERC20MintedBurnable poolShare;
    ITraderPortfolio traderPortfolio;
    uint8 collateralDecimals;
  }
}

// File: contracts/poolBlocks/RedemptionQueue.sol


pragma solidity ^0.8.0;

library RedemptionQueue {
  struct Request {
    address owner;
    uint256 amount;
    uint256 time;
  }

  struct Queue {
    mapping(uint256 => Request) _internal;
    uint256 _first;
    uint256 _last;
  }

  function init(Queue storage _queue) public {
    _queue._first = 1;
  }

  function empty(Queue storage _queue) public view returns (bool) {
    return (_queue._last < _queue._first);
  }

  function get(Queue storage _queue) public view returns (Request storage data) {
    return _queue._internal[_queue._first];
  }

  function getBy(Queue storage _queue, uint256 _index) public view returns (Request storage data) {
    return _queue._internal[_index];
  }

  function enqueue(Queue storage _queue, Request memory _data) public {
    _queue._last += 1;
    _queue._internal[_queue._last] = _data;
  }

  function dequeue(Queue storage _queue) public returns (Request memory data) {
    require(_queue._last >= _queue._first); // non-empty queue

    data = _queue._internal[_queue._first];

    delete _queue._internal[_queue._first];
    _queue._first += 1;
  }

  function getAll(Queue storage _queue) public view returns (Request[] memory requests) {
    if (_queue._first > _queue._last) return new Request[](0);
    uint256 length = _queue._last - _queue._first + 1;
    requests = new Request[](length);
    for (uint256 i = 0; i < length; i++) {
      requests[i] = getBy(_queue, _queue._first + i);
    }
  }
}

// File: contracts/IPool.sol


pragma solidity ^0.8.0;



interface IPool is IPoolTypes {
  function addDerivative(
    DerivativeConfig memory derivativeImplementation,
    address _termsOfTrade,
    Sequence memory sequence,
    uint256 pRef,
    uint256 settlement
  ) external returns (uint256 derivativeIndex);

  // pool config
  function changeProtocolFee(uint256 _protocolFee) external;

  function changeMinExitAmount(uint256 _minExitAmount) external;

  function changeFeeWallet(address _feeWallet) external;

  function changeVolatilityEvolution(address _volatilityEvolution) external;

  function changeExposure(address _exposure) external;

  function changeCollateralOracleIterator(address _collateralOracleIterator) external;

  function changeUnderlyingLiquidityValuer(address _underlyingLiquidityValuer) external;

  // derivative params
  function changeDerivativeMode(uint256 derivativeIndex, Mode mode) external;

  function changeDerivativeSide(uint256 derivativeIndex, Side side) external;

  function changeDerivativeTerms(uint256 derivativeIndex, address terms) external;

  function changeDerivativeSettlementDelta(uint256 _derivativeIndex, uint256 _settlementDelta) external;

  function getCollateralValue() external view returns (uint256);

  //READ
  function getPoolSharePrice() external view returns (uint256);

  function getDerivativePrice(uint256 _derivativeIndex) external view returns (PricePair memory);

  function getCollateralExposureLimit() external view returns (uint256);

  function getPortfolioBy(address user) external view returns (uint256);

  function checkPortfolioOf(address user) external view returns (bool);

  function derivativeBalanceOf(uint256 portfolioId, uint256 derivativeIndex)
    external
    view
    returns (Pair memory);

  function derivativeVintageIndexOf(uint256 portfolioId, uint256 derivativeIndex)
    external
    view
    returns (uint256);

  function getDerivatives() external view returns (Derivative[] memory);

  function getDerivativeIndex() external view returns (uint256);

  function getDerivative(uint256 derivativeIndex) external view returns (Derivative memory);

  function getDerivativeVintages(uint256 derivativeIndex) external view returns (Vintage[] memory);

  function getDerivativeVintageIndex(uint256 derivativeIndex) external view returns (uint256);

  function getDerivativeVintage(uint256 derivativeIndex, uint256 vintageIndex)
    external
    view
    returns (Vintage memory);

  function getBalance() external view returns (PoolBalance memory);

  function getConfig() external view returns (IPoolConfigTypes.PoolConfig memory);

  function releasedLiquidityOf(address owner) external view returns (uint256);

  function getAllRedemptionRequests() external view returns (RedemptionQueue.Request[] memory);

  function paused() external view returns (bool);
}

// File: contracts/terms/insured/InsuredTokenTermsLib.sol


pragma solidity ^0.8.0;









//import "hardhat/console.sol";

library InsuredTokenTermsLib {
  using ABDKMathQuad for bytes16;
  using ABDKMathQuad for uint256;
  using ABDKMathQuad for int256;
  using ABDKMathQuadExtra for uint256;
  using ABDKMathQuadExtra for int256;
  using ABDKMathQuadExtra for bytes16;

  bytes16 public constant ZERO = 0x00000000000000000000000000000000; // 0
  bytes16 public constant ONE = 0x3fff0000000000000000000000000000; // 1
  bytes16 public constant THREE = 0x40008000000000000000000000000000; // 3
  bytes16 public constant FOUR = 0x40010000000000000000000000000000; // 4

  bytes16 public constant TEN_POW_MINUS_NINE = 0x3fe112e0be826d694b2e62d01511f12a; // 10^-9
  bytes16 public constant TEN_POW_MINUS_TWO = 0x3ff847ae147ae147ae147ae147ae147a; // 10^-2

  bytes16 public constant ZERO_POINT_ZERO_TWENTY_FIVE = 0x3ff99999999999999999999999999999; // 0.025
  bytes16 public constant ZERO_POINT_THREE = 0x3ffd3333333333333333333333333333; // 0.3

  bytes16 public constant MinDeltaTTM = 0x00000000000000000000000000000000; // 0%
  bytes16 public constant MaxDeltaTTM = 0x3ffb9999999999999999999999999999; // 10% = 0.1
  bytes16 public constant MinDeltaMoney = 0x00000000000000000000000000000000; // 0%
  //    bytes16 public constant MaxDeltaMoney = 0x40000000000000000000000000000000; // 200% = 2
  bytes16 public constant MaxDeltaMoney = 0x3ffe0000000000000000000000000000; // 50% = 0.5

  bytes16 public constant SafeTTM = 0x3ff1decd44801decd44801decd44801d; // 1/(24*365)
  bytes16 public constant SecondsInYear = 0x4017e133800000000000000000000000; // 31536000; // 365 * 24 * 3600
  bytes16 public constant RefTTM = 0x3ffb50a8542a150a8542a150a8542a15; // 30/365

  event LogTradingFee(uint256 tradingFee, uint256 expStart, uint256 expEnd, uint256 feeAmp);

  struct Config {
    bytes16 baseFee;
    bytes16 maxFee;
    bytes16 rollFee;
    bytes16 feeAmpPrimary;
    bytes16 feeAmpComplement;
    bytes16 pMin;
    bytes16 qMin;
    bytes16 alphaTrade;
    bytes16 alphaRoll;
    bytes16 rollCap;
    bytes16 thetaDiv;
    IRepricer repricer;
  }

  function init(
    Config storage _config,
    address _repricer,
    ITermsTypes.FeeParams memory _feeParams,
    uint256 _pMin,
    uint256 _qMin,
    uint256 _alphaTrade,
    uint256 _alphaRoll,
    uint256 _rollCap,
    uint256 _thetaDiv
  ) public {
    _config.baseFee = _feeParams.baseFee.fromUIntBoned();
    _config.maxFee = _feeParams.maxFee.fromUIntBoned();
    _config.rollFee = _feeParams.rollFee.fromUIntBoned();
    _config.feeAmpPrimary = _feeParams.feeAmpPrimary.fromUIntBoned();
    _config.feeAmpComplement = _feeParams.feeAmpComplement.fromUIntBoned();

    _config.pMin = _pMin.fromUIntBoned();
    _config.qMin = _qMin.fromUIntBoned();

    _config.alphaTrade = _alphaTrade.fromUIntBoned();
    _config.alphaRoll = _alphaRoll.fromUIntBoned();

    _config.rollCap = _rollCap.fromUIntBoned();
    _config.thetaDiv = _thetaDiv.fromUIntBoned();

    require(_repricer != address(0), "REPR");
    _config.repricer = IRepricer(_repricer);
  }

  function getSide(ITermsTypes.PairBytes16 memory _pair, IPoolTypes.Side _side)
    public
    pure
    returns (bytes16)
  {
    return _side == IPoolTypes.Side.Primary ? _pair.primary : _pair.complement;
  }

  function calcInvariant(
    IPoolTypes.PoolSnapshot memory _snapshot,
    bytes16 _denomination,
    bytes16 _inAmount,
    ITermsTypes.TradePrices memory _prices,
    bytes16 _tradingFee,
    bytes16 _alpha
  ) public pure returns (bytes16 outAmount) {
    if (_inAmount.eq(ZERO)) return ZERO;
    bytes16 poolTotalCollateral = _snapshot.collateralLocked.fromUIntBoned().add(
      _snapshot.collateralFree.fromUIntBoned()
    );

    bytes16 leveragedPricesRatioSqrt = _alpha.mul(_prices.inward).div(_prices.outward).sqrt();
    bytes16 leveragedRevertedPricesRatioSqrt = _alpha
      .mul(_prices.outward)
      .div(_prices.inward)
      .sqrt();
    bytes16 inAmountFeeLess = _inAmount.mul(ONE.sub(_tradingFee));

    outAmount = leveragedPricesRatioSqrt.mul(poolTotalCollateral).mul(inAmountFeeLess).div(
      leveragedRevertedPricesRatioSqrt.mul(poolTotalCollateral).add(
        _denomination.mul(inAmountFeeLess)
      )
    );
  }

  function calcDeltas(
    bytes16 _sigma,
    bytes16 _ttm,
    bytes16 _mu
  ) public pure returns (bytes16 deltaTTM, bytes16 deltaMoney) {
    bytes16 minTTM = _ttm.min(RefTTM);

    deltaTTM = TEN_POW_MINUS_NINE.div(minTTM.add(TEN_POW_MINUS_TWO).pown(4));
    deltaTTM = deltaTTM.boundary(MinDeltaTTM, MaxDeltaTTM);

    bytes16 multiplicator = _mu.lt(ZERO) ? ZERO_POINT_ZERO_TWENTY_FIVE : ZERO_POINT_THREE;

    deltaMoney = _mu.mul(_mu).mul(multiplicator).div(minTTM).boundary(
      MinDeltaMoney,
      MaxDeltaMoney
    );
  }

  function convertPairToBytes16(IPoolTypes.Pair memory _pair)
    public
    pure
    returns (IRepricerTypes.PairBytes16 memory)
  {
    return
      IRepricerTypes.PairBytes16(_pair.primary.fromUIntBoned(), _pair.complement.fromUIntBoned());
  }

  function convertDerivativeSettlementToBytes16(IPoolTypes.DerivativeSettlement memory _settlement)
    public
    pure
    returns (ITermsTypes.DerivativeSettlementBytes16 memory)
  {
    return
      ITermsTypes.DerivativeSettlementBytes16(
        _settlement.settlement,
        convertPairToBytes16(_settlement.value),
        convertPairToBytes16(_settlement.position)
      );
  }

  function convertOtherPricesToBytes16(IPoolTypes.OtherPrices memory _otherPrices)
    public
    pure
    returns (ITermsTypes.OtherPricesBytes16 memory)
  {
    return
      ITermsTypes.OtherPricesBytes16(
        _otherPrices.collateral.fromIntBoned(),
        _otherPrices.underlying.fromIntBoned(),
        _otherPrices.volatilityRoundHint
      );
  }

  function calcTradingFee(
    Config memory _config,
    bytes16 _expStart,
    bytes16 _expEnd,
    bytes16 _feeAmp
  ) public returns (bytes16 tradingFee) {
    //TODO: pure
    if (_expStart.lt(_expEnd)) {
      tradingFee = _expEnd
        .pown(3)
        .sub(_expStart.pown(3))
        .mul(_feeAmp)
        .div(_expEnd.sub(_expStart).mul(THREE))
        .add(_config.baseFee);
    } else {
      tradingFee = _config.baseFee;
    }
    tradingFee = tradingFee.boundary(_config.baseFee, _config.maxFee);

    logTradingFeeParams(tradingFee, _expStart, _expEnd, _feeAmp);
  }

  function logTradingFeeParams(
    bytes16 tradingFee,
    bytes16 expStart,
    bytes16 expEnd,
    bytes16 feeAmp
  ) internal {
    emit LogTradingFee(
      tradingFee.toUIntBoned(),
      expStart.toUIntBoned(),
      expEnd.toUIntBoned(),
      feeAmp.toUIntBoned()
    );
  }

  function calcVolAsk(
    bytes16 _sigma,
    bytes16 _ttm,
    bytes16 _mu
  ) public pure returns (bytes16) {
    (bytes16 deltaTTM, bytes16 deltaMoney) = calcDeltas(_sigma, _ttm, _mu);
    return _sigma.mul((ONE.add(deltaTTM)).mul(ONE.add(deltaMoney)));
  }

  function calcVolBid(
    bytes16 _sigma,
    bytes16 _ttm,
    bytes16 _mu
  ) public pure returns (bytes16) {
    (bytes16 deltaTTM, bytes16 deltaMoney) = calcDeltas(_sigma, _ttm, _mu);
    return _sigma.div((ONE.add(deltaTTM)).mul(ONE.add(deltaMoney)));
  }

  function calcTTM(uint256 _current, uint256 _settlement) public pure returns (bytes16) {
    return _settlement.fromUInt().sub(_current.fromUInt()).div(SecondsInYear);
  }

  function calcMu(bytes16 _currentPrice, bytes16 _strike) public pure returns (bytes16) {
    return _strike.sub(_currentPrice).div(_currentPrice);
  }

  function calcExposure(
    IPoolTypes.PoolSnapshot memory _snapshot,
    uint256 _derivativeIndex,
    IPoolTypes.Pair memory _poolPositionNew,
    uint256 _collateralAmount
  ) public view returns (bytes16 exposure) {
    //save initial position
    IPoolTypes.Pair memory poolPositionOriginal = _snapshot.derivativePositions[_derivativeIndex];

    //set new position
    _snapshot.derivativePositions[_derivativeIndex] = _poolPositionNew;

    exposure = IExposure(_snapshot.exposureAddress)
      .calcExposure(_snapshot.derivatives, _snapshot.derivativePositions, _collateralAmount)
      .fromUIntBoned();

    //restore initial position
    _snapshot.derivativePositions[_derivativeIndex] = poolPositionOriginal;
  }

  //    function log(string memory name, bytes16 value) internal view {
  //        console.log(name);
  //        //console.logBytes16(value);
  //        console.logInt(ABDKMathQuadExtra.toIntBoned(value));
  //        console.log("");
  //    }
}

// File: contracts/terms/insured/InsuredTokenTermsTradeLib.sol


pragma solidity ^0.8.0;





//import "hardhat/console.sol";

library InsuredTokenTermsTradeLib {
  using ABDKMathQuad for bytes16;
  using ABDKMathQuad for uint256;
  using ABDKMathQuad for int256;
  using ABDKMathQuadExtra for uint256;
  using ABDKMathQuadExtra for int256;
  using ABDKMathQuadExtra for bytes16;

  bytes16 public constant ZERO = 0x00000000000000000000000000000000; // 0
  bytes16 public constant ONE = 0x3fff0000000000000000000000000000; // 1
  bytes16 public constant THREE = 0x40008000000000000000000000000000; // 3
  bytes16 public constant FOUR = 0x40010000000000000000000000000000; // 4

  bytes16 public constant RefTTM = 0x3ffb50a8542a150a8542a150a8542a15; // 30/365

  function calcTradingExposureEnd(
    IPoolTypes.PoolSnapshot memory _snapshot,
    uint256 _derivativeIndex,
    IPoolTypes.Side _side,
    bytes16 _denomination,
    ITermsTypes.TradeAmounts memory _tradeAmounts,
    bool _poolReceivesCollateral
  ) public view returns (bytes16) {
    (IPoolTypes.Pair memory position, bytes16 collateralAmountExp) = prepareExposureEndPosition(
      _snapshot,
      _derivativeIndex,
      _side,
      _denomination,
      _tradeAmounts,
      _poolReceivesCollateral
    );

    return
      InsuredTokenTermsLib.calcExposure(
        _snapshot,
        _derivativeIndex,
        position,
        collateralAmountExp.toUIntBoned()
      );
  }

  function prepareExposureEndPosition(
    IPoolTypes.PoolSnapshot memory _snapshot,
    uint256 _derivativeIndex,
    IPoolTypes.Side _side,
    bytes16 _denomination,
    ITermsTypes.TradeAmounts memory _tradeAmounts,
    bool _poolReceivesCollateral
  ) internal pure returns (IPoolTypes.Pair memory position, bytes16 collateralAmountExp) {
    IPoolTypes.Pair memory derivativePosition = _snapshot.derivativePositions[_derivativeIndex];
    uint256 inward = _tradeAmounts.inward.toUIntBoned();
    uint256 outward = _tradeAmounts.outward.toUIntBoned();
    if (_poolReceivesCollateral) {
      if (_side == IPoolTypes.Side.Primary) {
        position = IPoolTypes.Pair(
          derivativePosition.primary,
          derivativePosition.complement + outward
        );
      } else {
        position = IPoolTypes.Pair(
          derivativePosition.primary + outward,
          derivativePosition.complement
        );
      }
      collateralAmountExp = _tradeAmounts
        .inward
        .add(_snapshot.collateralFree.fromUIntBoned())
        .sub(_denomination.mul(_tradeAmounts.outward))
        .max(ZERO);
    } else {
      if (_side == IPoolTypes.Side.Primary) {
        position = IPoolTypes.Pair(
          derivativePosition.primary,
          derivativePosition.complement - inward
        );
      } else {
        position = IPoolTypes.Pair(
          derivativePosition.primary - inward,
          derivativePosition.complement
        );
      }
      collateralAmountExp = _snapshot
        .collateralFree
        .fromUIntBoned()
        .add(_denomination.mul(_tradeAmounts.inward))
        .sub(_tradeAmounts.outward)
        .max(ZERO);
    }
  }

  function checkTradeResults(
    IPoolTypes.PoolSnapshot memory _snapshot,
    uint256 _derivativeIndex,
    IPoolTypes.Side _side,
    bytes16 _denomination,
    ITermsTypes.TradePrices memory _tradePrices,
    ITermsTypes.TradeAmounts memory _tradeAmounts,
    bool _poolReceivesCollateral
  ) public view {
    require(
      _tradeAmounts.inward.div(_tradeAmounts.outward).gt(
        _tradePrices.outward.div(_tradePrices.inward)
      ),
      "PVALDOWN"
    );
    require(_tradeAmounts.outward.gte(ZERO), "NEGOUT");
    if (_poolReceivesCollateral) {
      require(
        _tradeAmounts.outward.mul(_denomination).lte(
          _snapshot.collateralFree.fromUIntBoned().add(_tradeAmounts.inward)
        ),
        "OUT MORE THAN FREE AND IN"
      );

      require(
        ONE.gte(
          InsuredTokenTermsLib.calcExposure(
            _snapshot,
            _derivativeIndex,
            prepareExposureCheckPosition(
              _snapshot.derivativePositions[_derivativeIndex],
              _side,
              _tradeAmounts
            ),
            calcFreeCollateralForTradeExposure(_snapshot, _tradeAmounts, _denomination)
          )
        ),
        "EL"
      );
    } else {
      require(_tradeAmounts.inward.mul(_denomination).gt(_tradeAmounts.outward), "IN LESS OUT");
    }
  }

  function prepareExposureCheckPosition(
    IPoolTypes.Pair memory _derivativePosition,
    IPoolTypes.Side _side,
    ITermsTypes.TradeAmounts memory _tradeAmounts
  ) internal pure returns (IPoolTypes.Pair memory) {
    uint256 outward = _tradeAmounts.outward.toUIntBoned();
    if (_side == IPoolTypes.Side.Primary) {
      return
        IPoolTypes.Pair(_derivativePosition.primary, _derivativePosition.complement + outward);
    } else {
      return
        IPoolTypes.Pair(_derivativePosition.primary + outward, _derivativePosition.complement);
    }
  }

  function calcFreeCollateralForTradeExposure(
    IPoolTypes.PoolSnapshot memory _snapshot,
    ITermsTypes.TradeAmounts memory _tradeAmounts,
    bytes16 _denomination
  ) internal pure returns (uint256) {
    return
      _snapshot
        .collateralFree
        .fromUIntBoned()
        .add(_tradeAmounts.inward)
        .sub(_denomination.mul(_tradeAmounts.outward))
        .toUIntBoned();
  }

  function normalizePrice(
    ITermsTypes.Derivative memory _derivative,
    ITermsTypes.Side _side,
    ITermsTypes.TradeAmounts memory _tradeAmounts,
    bytes16 _collateralPrices,
    bool _poolReceivesCollateral,
    ITermsTypes.DerivativePricesBytes16 memory _derivativePrices,
    bytes16 _allPoolsCollateralValue,
    bytes16 _thetaDiv
  ) internal pure returns (bytes16) {
    bytes16 lambda = calcLambda(_derivativePrices.inputs.ttm, _derivativePrices.inputs.mu);

    if (lambda.lt(ZERO) || lambda.gt(ONE)) return ZERO;

    bytes16 midPrice = InsuredTokenTermsLib.getSide(_derivativePrices.pair, _side);

    bytes16 collateralValue = (
      _poolReceivesCollateral ? _tradeAmounts.inward : _tradeAmounts.outward
    ).mul(_collateralPrices);
    bytes16 derivativeValue = (
      _poolReceivesCollateral ? _tradeAmounts.outward : _tradeAmounts.inward
    ).mul(midPrice);

    return
      calcNormPriceByFormula(
        _thetaDiv,
        derivativeValue,
        collateralValue,
        lambda,
        _allPoolsCollateralValue,
        midPrice
      );
  }

  function calcLambda(bytes16 _ttm, bytes16 _mu) internal pure returns (bytes16) {
    bytes16 expPow = FOUR
      .neg()
      .mul(ONE.div((_ttm <= InsuredTokenTermsLib.RefTTM ? _ttm : InsuredTokenTermsLib.RefTTM).sqrt()))
      .mul(_mu.div(ONE.sub(_mu)).pown(2))
      .exp();
    return
      _ttm <= InsuredTokenTermsLib.RefTTM
        ? _ttm.sqrt().div(InsuredTokenTermsLib.RefTTM.sqrt()).mul(expPow)
        : expPow;
  }

  function calcNormPriceByFormula(
    bytes16 _thetaDiv,
    bytes16 _derivativeValue,
    bytes16 _collateralValue,
    bytes16 _lambda,
    bytes16 _allPoolsCollateralValue,
    bytes16 _midPrice
  ) internal pure returns (bytes16 normPrice) {
    bytes16 difference = _collateralValue.sub(_derivativeValue);

    bytes16 part1 = difference.abs().mul(_lambda).mul(_thetaDiv).div(_allPoolsCollateralValue).min(
      ONE
    );

    bytes16 part2 = difference.div(_derivativeValue);

    normPrice = part1.mul(part2).add(ONE).mul(_midPrice);
  }

  function calcNormPriceAndUpdateVolatility(
    IPoolTypes.PoolSnapshot memory _snapshot,
    uint256 _pointInTime,
    IPoolTypes.Derivative memory _derivative,
    IPoolTypes.Side _side,
    ITermsTypes.TradeAmounts memory _tradeAmounts,
    ITermsTypes.DerivativePricesBytes16 memory _derivativePrices,
    ITermsTypes.OtherPricesBytes16 memory _otherPrices,
    bool _poolReceivesCollateral,
    bytes16 _thetaDiv
  ) public {
    bytes16 allPoolsCollateralValue = _snapshot.underlyingLiquidityValuer.getUnderlyingLiquidityValue(_derivative.config.underlyingOracles[0]).fromUIntBoned();

    if (allPoolsCollateralValue.lte(ZERO)) return;

    bytes16 normPrice = normalizePrice(
      _derivative,
      _side,
      _tradeAmounts,
      _otherPrices.collateral,
      _poolReceivesCollateral,
      _derivativePrices,
      allPoolsCollateralValue,
      _thetaDiv
    );

    if (normPrice.eq(ZERO)) return;

    updateVolatility(
      _pointInTime,
      _snapshot.volatilityEvolution,
      _derivative,
      _side,
      _derivativePrices,
      _otherPrices.underlying,
      normPrice
    );
  }

  function updateVolatility(
    uint256 _pointInTime,
    IVolatilityEvolution _volatilityEvolution,
    IPoolTypes.Derivative memory _derivative,
    IPoolTypes.Side _side,
    ITermsTypes.DerivativePricesBytes16 memory _derivativePrices,
    bytes16 _underlyingPrice,
    bytes16 _normPrice
  ) internal {
    _volatilityEvolution.updateVolatility(
      _pointInTime,
      IVolatilityEvolution.VolatilityParams(
        _derivativePrices.inputs.ttm,
        _derivativePrices.inputs.mu,
        _derivativePrices.sigma,
        _derivativePrices.omega
      ),
      _derivative.config.underlyingOracles[0],
      _underlyingPrice,
      _derivative.params.priceReference.fromUIntBoned(),
      _normPrice,
      _side == IPoolTypes.Side.Primary
    );
  }

  //    function log(string memory name, bytes16 value) internal view {
  //        console.log(name);
  //        //console.logBytes16(value);
  //        console.logInt(ABDKMathQuadExtra.toIntBoned(value));
  //        console.log("");
  //    }
}

// File: contracts/terms/insured/InsuredTokenTermsRolloverLib.sol


pragma solidity ^0.8.0;




//import "hardhat/console.sol";

library InsuredTokenTermsRolloverLib {
  using ABDKMathQuad for bytes16;
  using ABDKMathQuad for uint256;
  using ABDKMathQuad for int256;
  using ABDKMathQuadExtra for uint256;
  using ABDKMathQuadExtra for int256;
  using ABDKMathQuadExtra for bytes16;

  bytes16 public constant ZERO = 0x00000000000000000000000000000000; // 0
  bytes16 public constant ONE = 0x3fff0000000000000000000000000000; // 1

  function calcRolloverInputs(
    InsuredTokenTermsLib.Config memory _config,
    uint256 _collateralFree,
    ITermsTypes.DerivativeSettlementBytes16 memory _derivativeSettlement,
    ITermsTypes.PairBytes16 memory _derivativeAskPrice,
    bytes16 _denomination,
    ITermsTypes.OtherPricesBytes16 memory _otherPrices
  ) public pure returns (ITermsTypes.RolloverInputs memory rolloverInputs) {
    rolloverInputs.price = _derivativeAskPrice;

    //4 Calculate portion of V that pool allows to roll over
    rolloverInputs.valueAllowed = IRepricerTypes.PairBytes16(
      _derivativeSettlement.value.primary,
      _derivativeSettlement.value.complement
    );

    //5 Estimate biggest possible Pool positions (full inputs, baseFee only, no-slippage)
    bytes16 oneMinusRollFee = ONE.sub(_config.rollFee);

    if (_derivativeSettlement.position.primary.gt(ZERO)) {
      rolloverInputs.amount.primary = rolloverInputs
        .valueAllowed
        .complement
        .mul(_derivativeSettlement.position.primary)
        .mul(oneMinusRollFee)
        .div(rolloverInputs.price.complement);
    }

    if (_derivativeSettlement.position.complement.gt(ZERO)) {
      rolloverInputs.amount.complement = rolloverInputs
        .valueAllowed
        .primary
        .mul(_derivativeSettlement.position.complement)
        .mul(oneMinusRollFee)
        .div(rolloverInputs.price.primary);
    }

    rolloverInputs.collateralAmount = rolloverInputs
      .valueAllowed
      .complement
      .mul(_derivativeSettlement.position.primary)
      .add(rolloverInputs.valueAllowed.primary.mul(_derivativeSettlement.position.complement))
      .div(_otherPrices.collateral);

    bytes16 denominatorPercentLiq = rolloverInputs
      .amount
      .primary
      .add(rolloverInputs.amount.complement)
      .mul(_denomination)
      .sub(rolloverInputs.collateralAmount);

    rolloverInputs.percentLiq = denominatorPercentLiq.eq(ZERO)
      ? ZERO
      : _collateralFree.fromUIntBoned().div(denominatorPercentLiq).boundary(ZERO, ONE);

    rolloverInputs.amount.primary = rolloverInputs.amount.primary.mul(rolloverInputs.percentLiq);
    rolloverInputs.amount.complement = rolloverInputs.amount.complement.mul(
      rolloverInputs.percentLiq
    );
    rolloverInputs.collateralAmount = rolloverInputs.collateralAmount.mul(
      rolloverInputs.percentLiq
    );
  }

  function calcRolloverTrade(
    IPoolTypes.PoolSnapshot memory _snapshot,
    InsuredTokenTermsLib.Config memory _config,
    ITermsTypes.DerivativeSettlementBytes16 memory _derivativeSettlement,
    uint256 _derivativeIndex,
    ITermsTypes.RolloverInputs memory _rolloverInputs,
    bytes16 _denomination,
    ITermsTypes.OtherPricesBytes16 memory _otherPrices,
    bytes16 _alpha
  ) public view returns (ITermsTypes.RolloverTradeBytes16 memory rolloverTrade) {
    // 7
    rolloverTrade.percentExp = calcPercentExp(
      _snapshot,
      _derivativeIndex,
      _denomination,
      _rolloverInputs
    );

    // 8
    rolloverTrade.inward.primary = calcRolloverTradeInward(
      _rolloverInputs.valueAllowed.primary,
      _derivativeSettlement.position.complement,
      rolloverTrade.percentExp,
      _rolloverInputs.percentLiq,
      _otherPrices.collateral
    );

    rolloverTrade.outward.primary = calcRolloverTradeOutward(
      _snapshot,
      _config,
      _denomination,
      rolloverTrade.inward.primary,
      _rolloverInputs.price.primary,
      _derivativeSettlement.value.primary,
      _otherPrices.collateral,
      _alpha
    );

    // 9
    rolloverTrade.inward.complement = calcRolloverTradeInward(
      _rolloverInputs.valueAllowed.complement,
      _derivativeSettlement.position.primary,
      rolloverTrade.percentExp,
      _rolloverInputs.percentLiq,
      _otherPrices.collateral
    );

    rolloverTrade.outward.complement = calcRolloverTradeOutward(
      _snapshot,
      _config,
      _denomination,
      rolloverTrade.inward.complement,
      _rolloverInputs.price.complement,
      _derivativeSettlement.value.complement,
      _otherPrices.collateral,
      _alpha
    );
  }

  function calcRolloverTradeInward(
    bytes16 _derivativeSideValue,
    bytes16 _derivativeSidePosition,
    bytes16 _percentExp,
    bytes16 _percentLiq,
    bytes16 _collateralPrice
  ) internal pure returns (bytes16) {
    bytes16 dividend = _derivativeSideValue.mul(_derivativeSidePosition).mul(_percentExp).mul(
      _percentLiq
    );

    return !dividend.eq(ZERO) ? dividend.div(_collateralPrice) : ZERO;
  }

  function calcRolloverTradeOutward(
    IPoolTypes.PoolSnapshot memory _snapshot,
    InsuredTokenTermsLib.Config memory _config,
    bytes16 _denomination,
    bytes16 _tradeInwardAmount, // rolloverTrade.inward
    bytes16 _derivativeSidePrice, // _rolloverInputs.price
    bytes16 _derivativeSideValue, //  _derivativeSettlement.value
    bytes16 _collateralPrice,
    bytes16 _alpha
  ) internal pure returns (bytes16) {
    return
      _tradeInwardAmount.eq(ZERO)
        ? ZERO
        : InsuredTokenTermsLib.calcInvariant(
          _snapshot,
          _denomination,
          _tradeInwardAmount,
          ITermsTypes.TradePrices(
            ZERO,
            _collateralPrice,
            _derivativeSidePrice,
            ITermsTypes.DerivativePricesBytes16(
              IRepricerTypes.PairBytes16(ZERO, ZERO),
              ITermsTypes.VolatilityInputs(ZERO, ZERO),
              ZERO,
              ZERO
            )
          ),
          _config.rollFee,
          _alpha
        );
  }

  function calcPercentExp(
    IPoolTypes.PoolSnapshot memory _snapshot,
    uint256 _derivativeIndex,
    bytes16 _denomination,
    ITermsTypes.RolloverInputs memory _rolloverInputs
  ) internal view returns (bytes16 percentExp) {
    bytes16 exposureMax = InsuredTokenTermsLib.calcExposure(
      _snapshot,
      _derivativeIndex,
      IPoolTypes.Pair(
        _rolloverInputs.amount.primary.toUIntBoned(),
        _rolloverInputs.amount.complement.toUIntBoned()
      ),
      calcReducedFreeCollateralForPercentExp(_snapshot, _rolloverInputs, _denomination)
    );

    IPoolTypes.Pair memory current = _snapshot.derivativePositions[_derivativeIndex];
    _snapshot.derivativePositions[_derivativeIndex] = IPoolTypes.Pair(0, 0);

    percentExp = exposureMax.lte(ONE)
      ? ONE
      : IExposure(_snapshot.exposureAddress).calcInputPercent(
        _derivativeIndex,
        _snapshot.derivatives,
        _snapshot.derivativePositions,
        _snapshot.collateralFree,
        _rolloverInputs.amount.primary.toUIntBoned(),
        _rolloverInputs.amount.complement.toUIntBoned(),
        _rolloverInputs.collateralAmount.toUIntBoned()
      );

    _snapshot.derivativePositions[_derivativeIndex] = current;
  }

  function calcReducedFreeCollateralForPercentExp(
    IPoolTypes.PoolSnapshot memory _snapshot,
    ITermsTypes.RolloverInputs memory _rolloverInputs,
    bytes16 _denomination
  ) internal pure returns (uint256) {
    return
      _snapshot
        .collateralFree
        .fromUIntBoned()
        .add(_rolloverInputs.collateralAmount)
        .sub(
          _rolloverInputs.amount.primary.add(_rolloverInputs.amount.complement).mul(_denomination)
        )
        .max(ZERO)
        .toUIntBoned();
  }

  function calcReducedFreeCollateralForExposureEnd(
    IPoolTypes.PoolSnapshot memory _snapshot,
    ITermsTypes.RolloverTradeBytes16 memory _rolloverTrade,
    bytes16 _denomination
  ) internal pure returns (uint256) {
    return
      _snapshot
        .collateralFree
        .fromUIntBoned()
        .add(_rolloverTrade.inward.primary)
        .add(_rolloverTrade.inward.complement)
        .sub(
          _rolloverTrade.outward.complement.add(_rolloverTrade.outward.primary).mul(_denomination)
        )
        .toUIntBoned();
  }

  function calcFreeCollateralForRolloverExposure(
    IPoolTypes.PoolSnapshot memory _snapshot,
    ITermsTypes.RolloverTradeBytes16 memory _rolloverTrade,
    bytes16 _denomination
  ) public pure returns (uint256) {
    return
      _snapshot
        .collateralFree
        .fromUIntBoned()
        .add(_rolloverTrade.inward.primary)
        .add(_rolloverTrade.inward.complement)
        .sub(
          _rolloverTrade.outward.complement.add(_rolloverTrade.outward.primary).mul(_denomination)
        )
        .toUIntBoned();
  }

//  function log(string memory name, bytes16 value) internal view {
//      console.log(name);
//      console.logBytes16(value);
//      console.logInt(ABDKMathQuadExtra.toIntBoned(value));
//      console.log("");
//  }
}

// File: contracts/terms/insured/InsuredTokenTermsBase.sol


pragma solidity ^0.8.0;









//import "hardhat/console.sol";

abstract contract InsuredTokenTermsBase is ITerms, Const {
  using InsuredTokenTermsLib for InsuredTokenTermsLib.Config;
  using InsuredTokenTermsLib for IPoolTypes.PoolSnapshot;
  using InsuredTokenTermsTradeLib for InsuredTokenTermsLib.Config;
  using InsuredTokenTermsTradeLib for IPoolTypes.PoolSnapshot;
  using InsuredTokenTermsRolloverLib for InsuredTokenTermsLib.Config;
  using InsuredTokenTermsRolloverLib for IPoolTypes.PoolSnapshot;

  using ABDKMathQuad for bytes16;
  using ABDKMathQuad for uint256;
  using ABDKMathQuad for int256;
  using ABDKMathQuadExtra for uint256;
  using ABDKMathQuadExtra for int256;
  using ABDKMathQuadExtra for bytes16;

  bytes16 internal constant ZERO = 0x00000000000000000000000000000000; // 0
  bytes16 internal constant ONE = 0x3fff0000000000000000000000000000; // 1
  bytes16 internal constant THREE = 0x40008000000000000000000000000000; // 3

  InsuredTokenTermsLib.Config internal _config;

  bool public updatingVolatility;

  event LogOutAmount(
    uint256 inAmount,
    uint256 outAmountFeeFree,
    uint256 inPrice,
    uint256 outAmount,
    uint256 outPrice,
    uint256 tradingFee,
    uint256 alphaTrade,
    uint256 ttm,
    int256 mu
  );

  event LogRolloverTrade(Pair valueAllowed, uint256 percentLiq, uint256 percentExp);

  event LogTradingFee(uint256 tradingFee, uint256 expStart, uint256 expEnd, uint256 feeAmp);

  constructor(
    address _repricer,
    FeeParams memory _feeParams,
    uint256 _pMin,
    uint256 _qMin,
    uint256 _alphaTrade,
    uint256 _alphaRoll,
    uint256 _rollCap,
    uint256 _thetaDiv,
    bool _updatingVolatility
  ) {
    _config.init(
      _repricer,
      _feeParams,
      _pMin,
      _qMin,
      _alphaTrade,
      _alphaRoll,
      _rollCap,
      _thetaDiv
    );

    _updatingVolatility = updatingVolatility;
  }

  function getConfig()
    external
    view
    returns (
      uint256 baseFee,
      uint256 maxFee,
      uint256 rollFee,
      uint256 feeAmpPrimary,
      uint256 feeAmpComplement,
      uint256 pMin,
      uint256 qMin,
      uint256 alphaTrade,
      uint256 alphaRoll,
      uint256 rollCap,
      uint256 thetaDiv,
      address repricer
    )
  {
    baseFee = _config.baseFee.toUIntBoned();
    maxFee = _config.maxFee.toUIntBoned();
    rollFee = _config.rollFee.toUIntBoned();
    feeAmpPrimary = _config.feeAmpPrimary.toUIntBoned();
    feeAmpComplement = _config.feeAmpComplement.toUIntBoned();
    pMin = _config.pMin.toUIntBoned();
    qMin = _config.qMin.toUIntBoned();
    alphaTrade = _config.alphaTrade.toUIntBoned();
    alphaRoll = _config.alphaRoll.toUIntBoned();
    rollCap = _config.rollCap.toUIntBoned();
    thetaDiv = _config.thetaDiv.toUIntBoned();
    repricer = address(_config.repricer);
  }

  function calculatePrice(
    uint256 _pointInTime,
    Derivative memory _derivative,
    Side _side,
    PriceType _price,
    OtherPrices memory _otherPrices,
    IVolatilityEvolution _volatilityEvolution
  ) external view override returns (PricePair memory) {
    DerivativePricesBytes16 memory prices = calculatePriceInternal(
      _pointInTime,
      _derivative,
      _side,
      _price,
      OtherPricesBytes16(
        _otherPrices.collateral.fromIntBoned(),
        _otherPrices.underlying.fromIntBoned(),
        _otherPrices.volatilityRoundHint
      ),
      _volatilityEvolution
    );

    return PricePair(prices.pair.primary.toIntBoned(), prices.pair.complement.toIntBoned());
  }

  function calculatePriceInternal(
    uint256 _pointInTime,
    Derivative memory _derivative,
    Side _side,
    PriceType _price,
    OtherPricesBytes16 memory _otherPrices,
    IVolatilityEvolution _volatilityEvolution
  ) internal view virtual returns (DerivativePricesBytes16 memory);

  function repriceDerivative(
    Derivative memory _derivative,
    bytes16 _underlying,
    bytes16 _collateral,
    bytes16 _ttm,
    bytes16 _sigma1,
    bytes16 _sigma2
  ) internal view returns (PairBytes16 memory) {
    return
      _config.repricer.reprice(
        _underlying,
        _collateral,
        _ttm,
        _sigma1,
        _sigma2,
        _derivative.params.priceReference.fromUIntBoned(),
        _derivative.params.denomination.fromUIntBoned()
      );
  }

  struct VarsRolloverPrice {
    Derivative derivative;
    bytes16 denomination;
    OtherPricesBytes16 otherPrices;
    DerivativeSettlementBytes16 derivativeSettlement;
    RolloverInputs rolloverInputs;
    bytes16 percentExp;
    PairBytes16 tradingFee;
  }

  function calculateRolloverTrade(
    PoolSnapshot memory _snapshot,
    uint256 _derivativeIndex,
    IPoolTypes.DerivativeSettlement memory _derivativeSettlement,
    OtherPrices memory _otherPrices //TODO: view
  ) external override returns (RolloverTrade memory rolloverTrade) {
    VarsRolloverPrice memory vars;

    vars.derivative = _snapshot.derivatives[_derivativeIndex];
    vars.denomination = vars.derivative.params.denomination.fromUIntBoned();
    vars.otherPrices = InsuredTokenTermsLib.convertOtherPricesToBytes16(_otherPrices);
    vars.derivativeSettlement = InsuredTokenTermsLib.convertDerivativeSettlementToBytes16(
      _derivativeSettlement
    );

    vars.rolloverInputs = _config.calcRolloverInputs(
      _snapshot.collateralFree,
      vars.derivativeSettlement,
      calcAskDerivativePriceBySide(
        _derivativeSettlement,
        vars.derivative,
        vars.denomination,
        vars.otherPrices,
        _snapshot.volatilityEvolution
      ),
      vars.denomination,
      vars.otherPrices
    );

    RolloverTradeBytes16 memory rolloverTradeBytes16 = _snapshot.calcRolloverTrade(
      _config,
      vars.derivativeSettlement,
      _derivativeIndex,
      vars.rolloverInputs,
      vars.denomination,
      vars.otherPrices,
      _config.alphaRoll
    );

    logRolloverTrade(
      vars.rolloverInputs.valueAllowed,
      vars.rolloverInputs.percentLiq,
      rolloverTradeBytes16.percentExp
    );

    if (
      ONE.lt(
        InsuredTokenTermsLib.calcExposure(
          _snapshot,
          _derivativeIndex,
          Pair(rolloverTrade.outward.complement, rolloverTrade.outward.primary),
          _snapshot.calcFreeCollateralForRolloverExposure(rolloverTradeBytes16, vars.denomination)
        )
      )
    ) {
      return RolloverTrade(Pair(0, 0), Pair(0, 0));
    }

    return
      RolloverTrade(
        Pair(
          rolloverTradeBytes16.inward.primary.toUIntBoned(),
          rolloverTradeBytes16.inward.complement.toUIntBoned()
        ),
        Pair(
          rolloverTradeBytes16.outward.primary.toUIntBoned(),
          rolloverTradeBytes16.outward.complement.toUIntBoned()
        )
      );
  }

  function logRolloverTrade(
    PairBytes16 memory valueAllowed,
    bytes16 percentLiq,
    bytes16 percentExp
  ) internal {
    emit LogRolloverTrade(
      Pair(valueAllowed.primary.toUIntBoned(), valueAllowed.complement.toUIntBoned()),
      percentLiq.toUIntBoned(),
      percentExp.toUIntBoned()
    );
  }

  function calcAskDerivativePriceBySide(
    IPoolTypes.DerivativeSettlement memory _derivativeSettlement,
    Derivative memory _derivative,
    bytes16 _denomination,
    OtherPricesBytes16 memory _otherPrices,
    IVolatilityEvolution _volatilityEvolution
  ) internal view returns (PairBytes16 memory price) {
    // 2 & 3
    if (_derivativeSettlement.position.complement > 0) {
      price.primary = calcAskDerivativePrice(
        _derivativeSettlement.settlement,
        _derivative,
        Side.Primary,
        _denomination,
        _otherPrices,
        _volatilityEvolution,
        _config.pMin.add(_otherPrices.underlying)
      );
    }

    if (_derivativeSettlement.position.primary > 0) {
      price.complement = calcAskDerivativePrice(
        _derivativeSettlement.settlement,
        _derivative,
        Side.Complement,
        _denomination,
        _otherPrices,
        _volatilityEvolution,
        _config.pMin
      );
    }
  }

  function calcAskDerivativePrice(
    uint256 _pointInTime,
    Derivative memory _derivative,
    Side _side,
    bytes16 _denomination,
    OtherPricesBytes16 memory _otherPrices,
    IVolatilityEvolution _volatilityEvolution,
    bytes16 _maxPriceBoundary
  ) internal view returns (bytes16) {
    DerivativePricesBytes16 memory derivativePrices = calculatePriceInternal(
      _pointInTime,
      _derivative,
      _side,
      PriceType.ask,
      _otherPrices,
      _volatilityEvolution
    );

    return
      InsuredTokenTermsLib
        .getSide(derivativePrices.pair, _side)
        .min(_denomination.mul(_otherPrices.collateral))
        .max(_maxPriceBoundary);
  }

  struct VarsOutAmount {
    uint256 pointInTime;
    bytes16 inAmount;
    Derivative derivative;
    bytes16 denomination;
    OtherPricesBytes16 otherPrices;
    DerivativePricesBytes16 derivativePrices;
    TradePrices tradePrices;
    bytes16 adjustedAlphaTrade;
    bytes16 outAmountFeeFree;
    bytes16 tradingFee;
    bytes16 outAmount;
  }

  function calculateOutAmount(
    PoolSnapshot memory _snapshot,
    uint256 _inAmountBoned,
    uint256 _derivativeIndex,
    Side _side,
    bool _poolReceivesCollateral,
    OtherPrices memory _otherPrices
  ) external override returns (uint256) {
    VarsOutAmount memory vars;

    vars.inAmount = _inAmountBoned.fromUIntBoned();
    require(vars.inAmount.gte(_config.qMin), "Q MIN");

    vars.pointInTime = block.timestamp;
    vars.derivative = _snapshot.derivatives[_derivativeIndex];

    vars.denomination = vars.derivative.params.denomination.fromUIntBoned();

    vars.otherPrices = InsuredTokenTermsLib.convertOtherPricesToBytes16(_otherPrices);

    vars.tradePrices = calcTradePrices(
      vars.pointInTime,
      vars.derivative,
      vars.denomination,
      _side,
      vars.otherPrices,
      _poolReceivesCollateral,
      _snapshot.volatilityEvolution
    );

    vars.outAmountFeeFree = InsuredTokenTermsLib.calcInvariant(
      _snapshot,
      vars.denomination,
      vars.inAmount,
      vars.tradePrices,
      ZERO,
      _config.alphaTrade
    );

    vars.tradingFee = calcTradeTradingFee(
      _snapshot,
      _derivativeIndex,
      _side,
      vars.denomination,
      TradeAmounts(vars.inAmount, vars.outAmountFeeFree),
      vars.tradePrices.derivative,
      vars.otherPrices,
      _poolReceivesCollateral
    );

    vars.outAmount = InsuredTokenTermsLib.calcInvariant(
      _snapshot,
      vars.denomination,
      vars.inAmount,
      vars.tradePrices,
      vars.tradingFee,
      vars.adjustedAlphaTrade
    );

    if (_poolReceivesCollateral) {
      vars.outAmount = vars.outAmount.max(vars.inAmount.div(vars.denomination));
    }

    _snapshot.checkTradeResults(
      _derivativeIndex,
      _side,
      vars.denomination,
      vars.tradePrices,
      TradeAmounts(vars.inAmount, vars.outAmount),
      _poolReceivesCollateral
    );

    vars.derivativePrices = calculatePriceInternal(
      vars.pointInTime,
      vars.derivative,
      _side,
      IPoolTypes.PriceType.mid,
      vars.otherPrices,
      _snapshot.volatilityEvolution
    );

    logOutAmount(vars);

//    if (updatingVolatility && vars.derivativePrices.inputs.ttm.gt(InsuredTokenTermsLib.SafeTTM)) {
//      _snapshot.calcNormPriceAndUpdateVolatility(
//        vars.pointInTime,
//        vars.derivative,
//        _side,
//        TradeAmounts(vars.inAmount, vars.outAmount),
//        vars.derivativePrices,
//        vars.otherPrices,
//        _poolReceivesCollateral,
//        _config.thetaDiv
//      );
//    }

    return vars.outAmount.toUIntBoned();
  }

  function logOutAmount(VarsOutAmount memory vars) internal {
    emit LogOutAmount(
      vars.inAmount.toUIntBoned(),
      vars.outAmountFeeFree.toUIntBoned(),
      vars.tradePrices.inward.toUIntBoned(),
      vars.outAmount.toUIntBoned(),
      vars.tradePrices.outward.toUIntBoned(),
      vars.tradingFee.toUIntBoned(),
      vars.adjustedAlphaTrade.toUIntBoned(),
      vars.tradePrices.derivativePrices.inputs.ttm.toUIntBoned(),
      vars.tradePrices.derivativePrices.inputs.mu.toIntBoned()
    );
  }

  function calcTradePrices(
    uint256 _pointInTime,
    Derivative memory _derivative,
    bytes16 _denomination,
    Side _side,
    OtherPricesBytes16 memory _otherPrices,
    bool _poolReceivesCollateral,
    IVolatilityEvolution _volatilityEvolution
  ) internal view returns (TradePrices memory prices) {
    DerivativePricesBytes16 memory derivativePrices = calculatePriceInternal(
      _pointInTime,
      _derivative,
      _side,
      _poolReceivesCollateral ? PriceType.ask : PriceType.bid,
      _otherPrices,
      _volatilityEvolution
    );

    prices.derivativePrices = derivativePrices;

    prices.derivative = InsuredTokenTermsLib.getSide(derivativePrices.pair, _side);

    if (_poolReceivesCollateral) {
      prices.derivative = prices.derivative.min(_denomination.mul(_otherPrices.collateral)).max(
        _config.pMin
      );

      prices.inward = _otherPrices.collateral;
      prices.outward = prices.derivative;
    } else {
      prices.derivative = prices
        .derivative
        .min(_config.pMin)
        .max(_denomination.mul(_otherPrices.collateral).sub(_config.pMin))
        .min(prices.derivative);

      prices.inward = prices.derivative;
      prices.outward = _otherPrices.collateral;
    }
  }

  function calcTradeTradingFee(
    PoolSnapshot memory _snapshot,
    uint256 _derivativeIndex,
    Side _side,
    bytes16 _denomination,
    TradeAmounts memory _tradeAmounts,
    bytes16 _derivativePrice,
    OtherPricesBytes16 memory _otherPrices,
    bool _poolReceivesCollateral
  ) internal returns (bytes16 tradingFee) {
    bytes16 expStart = InsuredTokenTermsLib.calcExposure(
      _snapshot,
      _derivativeIndex,
      _snapshot.derivativePositions[_derivativeIndex],
      _snapshot.collateralFree
    );

    bytes16 expEnd = _snapshot.calcTradingExposureEnd(
      _derivativeIndex,
      _side,
      _denomination,
      _tradeAmounts,
      _poolReceivesCollateral
    );

    tradingFee = _config.calcTradingFee(expStart, expEnd, getFeeAmpMultiplier(_side));
  }

  function getFeeAmpMultiplier(Side _side) internal view returns (bytes16) {
    return _side == Side.Primary ? _config.feeAmpPrimary : _config.feeAmpComplement;
  }

//      function log(string memory name, bytes16 value) internal view {
//          console.log(name);
//          console.logBytes16(value);
//          console.logInt(ABDKMathQuadExtra.toIntBoned(value));
//          console.log("");
//      }
}

// File: contracts/terms/insured/InsuredTokenTerms.sol
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract InsuredTokenTerms is InsuredTokenTermsBase {
  using ABDKMathQuad for bytes16;
  using ABDKMathQuad for uint256;
  using ABDKMathQuadExtra for uint256;
  using ABDKMathQuadExtra for bytes16;

  bytes16 internal constant SIX = 0x40018000000000000000000000000000; // 6

  bytes16 public constant ZERO_POINT_EIGHT = 0x3ffe9999999999999999999999999999; // 0.8

  constructor(
    address _repricer,
    FeeParams memory _feeParams,
    uint256 _pMin,
    uint256 _qMin,
    uint256 _alphaTrade,
    uint256 _alphaRoll,
    uint256 _rollCap,
    uint256 _thetaDiv,
    bool _updatingVolatility
  )
    InsuredTokenTermsBase(
      _repricer,
      _feeParams,
      _pMin,
      _qMin,
      _alphaTrade,
      _alphaRoll,
      _rollCap,
      _thetaDiv,
      _updatingVolatility
    )
  {}

  function instrumentType() public pure returns (string memory) {
    return "InsuredTokendToken";
  }

  function version() public pure returns (uint256) {
    return 2;
  }

  struct VarsPriceCalculation {
    bytes16 strikeLong;
    bytes16 strikeShort;
    bytes16 ttm;
    bytes16 muLong;
    bytes16 muShort;
    PairBytes16 pricePair;
  }

  function calculatePriceInternal(
    uint256 _pointInTime,
    Derivative memory _derivative,
    Side _side,
    PriceType _price,
    OtherPricesBytes16 memory _otherPrices,
    IVolatilityEvolution _volatilityEvolution
  ) internal view override returns (DerivativePricesBytes16 memory) {
    VarsPriceCalculation memory vars;

    vars.strikeLong = _derivative.params.priceReference.fromUIntBoned();
    vars.strikeShort = vars.strikeLong.mul(ZERO_POINT_EIGHT);

    vars.ttm = InsuredTokenTermsLib.calcTTM(_pointInTime, _derivative.params.settlement).max(
      InsuredTokenTermsLib.SafeTTM
    );
    vars.muLong = InsuredTokenTermsLib.calcMu(_otherPrices.underlying, vars.strikeLong);
    vars.muShort = InsuredTokenTermsLib.calcMu(_otherPrices.underlying, vars.strikeShort);

    (bytes16 sigmaLong, bytes16 omega) = _volatilityEvolution.calculateVolatility(
      _pointInTime,
      _derivative.config.underlyingOracles[0],
      vars.ttm,
      vars.muLong,
      _otherPrices.volatilityRoundHint
    );

    (bytes16 sigmaShort, ) = _volatilityEvolution.calculateVolatility(
      _pointInTime,
      _derivative.config.underlyingOracles[0],
      vars.ttm,
      vars.muShort,
      _otherPrices.volatilityRoundHint
    );

    if (_price == PriceType.bid) {
      sigmaLong = InsuredTokenTermsLib.calcVolBid(sigmaLong, vars.ttm, vars.muLong);
      sigmaShort = InsuredTokenTermsLib.calcVolAsk(sigmaShort, vars.ttm, vars.muShort);
    }

    if (_price == PriceType.ask) {
      sigmaLong = InsuredTokenTermsLib.calcVolAsk(sigmaLong, vars.ttm, vars.muLong);
      sigmaShort = InsuredTokenTermsLib.calcVolBid(sigmaShort, vars.ttm, vars.muShort);
    }

    vars.pricePair = repriceDerivative(
      _derivative,
      _otherPrices.underlying,
      _otherPrices.collateral,
      vars.ttm,
      sigmaLong,
      sigmaShort
    );

    return
      DerivativePricesBytes16(vars.pricePair, VolatilityInputs(vars.ttm, vars.muLong), sigmaLong, omega);
  }
}