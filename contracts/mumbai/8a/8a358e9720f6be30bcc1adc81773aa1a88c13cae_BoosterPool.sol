/**
 *Submitted for verification at polygonscan.com on 2023-05-03
*/

// File: @uniswap/v3-core/contracts/libraries/FixedPoint96.sol


pragma solidity >=0.4.0;

/// @title FixedPoint96
/// @notice A library for handling binary fixed point numbers, see https://en.wikipedia.org/wiki/Q_(number_format)
/// @dev Used in SqrtPriceMath.sol
library FixedPoint96 {
    uint8 internal constant RESOLUTION = 96;
    uint256 internal constant Q96 = 0x1000000000000000000000000;
}

// File: github.com/Uniswap/v3-core/blob/0.8/contracts/libraries/FullMath.sol


pragma solidity ^0.8.0;

/// @title Contains 512-bit math functions
/// @notice Facilitates multiplication and division that can have overflow of an intermediate value without any loss of precision
/// @dev Handles "phantom overflow" i.e., allows multiplication and division where an intermediate value overflows 256 bits
library FullMath {
    /// @notice Calculates floor(a×b÷denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
    /// @param a The multiplicand
    /// @param b The multiplier
    /// @param denominator The divisor
    /// @return result The 256-bit result
    /// @dev Credit to Remco Bloemen under MIT license https://xn--2-umb.com/21/muldiv
    function mulDiv(
        uint256 a,
        uint256 b,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        unchecked {
            // 512-bit multiply [prod1 prod0] = a * b
            // Compute the product mod 2**256 and mod 2**256 - 1
            // then use the Chinese Remainder Theorem to reconstruct
            // the 512 bit result. The result is stored in two 256
            // variables such that product = prod1 * 2**256 + prod0
            uint256 prod0; // Least significant 256 bits of the product
            uint256 prod1; // Most significant 256 bits of the product
            assembly {
                let mm := mulmod(a, b, not(0))
                prod0 := mul(a, b)
                prod1 := sub(sub(mm, prod0), lt(mm, prod0))
            }

            // Handle non-overflow cases, 256 by 256 division
            if (prod1 == 0) {
                require(denominator > 0);
                assembly {
                    result := div(prod0, denominator)
                }
                return result;
            }

            // Make sure the result is less than 2**256.
            // Also prevents denominator == 0
            require(denominator > prod1);

            ///////////////////////////////////////////////
            // 512 by 256 division.
            ///////////////////////////////////////////////

            // Make division exact by subtracting the remainder from [prod1 prod0]
            // Compute remainder using mulmod
            uint256 remainder;
            assembly {
                remainder := mulmod(a, b, denominator)
            }
            // Subtract 256 bit number from 512 bit number
            assembly {
                prod1 := sub(prod1, gt(remainder, prod0))
                prod0 := sub(prod0, remainder)
            }

            // Factor powers of two out of denominator
            // Compute largest power of two divisor of denominator.
            // Always >= 1.
            uint256 twos = (0 - denominator) & denominator;
            // Divide denominator by power of two
            assembly {
                denominator := div(denominator, twos)
            }

            // Divide [prod1 prod0] by the factors of two
            assembly {
                prod0 := div(prod0, twos)
            }
            // Shift in bits from prod1 into prod0. For this we need
            // to flip `twos` such that it is 2**256 / twos.
            // If twos is zero, then it becomes one
            assembly {
                twos := add(div(sub(0, twos), twos), 1)
            }
            prod0 |= prod1 * twos;

            // Invert denominator mod 2**256
            // Now that denominator is an odd number, it has an inverse
            // modulo 2**256 such that denominator * inv = 1 mod 2**256.
            // Compute the inverse by starting with a seed that is correct
            // correct for four bits. That is, denominator * inv = 1 mod 2**4
            uint256 inv = (3 * denominator) ^ 2;
            // Now use Newton-Raphson iteration to improve the precision.
            // Thanks to Hensel's lifting lemma, this also works in modular
            // arithmetic, doubling the correct bits in each step.
            inv *= 2 - denominator * inv; // inverse mod 2**8
            inv *= 2 - denominator * inv; // inverse mod 2**16
            inv *= 2 - denominator * inv; // inverse mod 2**32
            inv *= 2 - denominator * inv; // inverse mod 2**64
            inv *= 2 - denominator * inv; // inverse mod 2**128
            inv *= 2 - denominator * inv; // inverse mod 2**256

            // Because the division is now exact we can divide by multiplying
            // with the modular inverse of denominator. This will give us the
            // correct result modulo 2**256. Since the precoditions guarantee
            // that the outcome is less than 2**256, this is the final result.
            // We don't need to compute the high bits of the result and prod1
            // is no longer required.
            result = prod0 * inv;
            return result;
        }
    }

    /// @notice Calculates ceil(a×b÷denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
    /// @param a The multiplicand
    /// @param b The multiplier
    /// @param denominator The divisor
    /// @return result The 256-bit result
    function mulDivRoundingUp(
        uint256 a,
        uint256 b,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        unchecked {
            result = mulDiv(a, b, denominator);
            if (mulmod(a, b, denominator) > 0) {
                require(result < type(uint256).max);
                result++;
            }
        }
    }
}

// File: contracts/libraries/LiquidityAmounts.sol


pragma solidity >=0.5.0;



/// @title Liquidity amount functions
/// @notice Provides functions for computing liquidity amounts from token amounts and prices
library LiquidityAmounts {
    /// @notice Downcasts uint256 to uint128
    /// @param x The uint258 to be downcasted
    /// @return y The passed value, downcasted to uint128
    function toUint128(uint256 x) private pure returns (uint128 y) {
        require((y = uint128(x)) == x);
    }

    /// @notice Computes the amount of liquidity received for a given amount of token0 and price range
    /// @dev Calculates amount0 * (sqrt(upper) * sqrt(lower)) / (sqrt(upper) - sqrt(lower))
    /// @param sqrtRatioAX96 A sqrt price representing the first tick boundary
    /// @param sqrtRatioBX96 A sqrt price representing the second tick boundary
    /// @param amount0 The amount0 being sent in
    /// @return liquidity The amount of returned liquidity
    function getLiquidityForAmount0(
        uint160 sqrtRatioAX96,
        uint160 sqrtRatioBX96,
        uint256 amount0
    ) internal pure returns (uint128 liquidity) {
        if (sqrtRatioAX96 > sqrtRatioBX96) (sqrtRatioAX96, sqrtRatioBX96) = (sqrtRatioBX96, sqrtRatioAX96);
        uint256 intermediate = FullMath.mulDiv(sqrtRatioAX96, sqrtRatioBX96, FixedPoint96.Q96);
        unchecked {
            return toUint128(FullMath.mulDiv(amount0, intermediate, sqrtRatioBX96 - sqrtRatioAX96));
        }
    }

    /// @notice Computes the amount of liquidity received for a given amount of token1 and price range
    /// @dev Calculates amount1 / (sqrt(upper) - sqrt(lower)).
    /// @param sqrtRatioAX96 A sqrt price representing the first tick boundary
    /// @param sqrtRatioBX96 A sqrt price representing the second tick boundary
    /// @param amount1 The amount1 being sent in
    /// @return liquidity The amount of returned liquidity
    function getLiquidityForAmount1(
        uint160 sqrtRatioAX96,
        uint160 sqrtRatioBX96,
        uint256 amount1
    ) internal pure returns (uint128 liquidity) {
        if (sqrtRatioAX96 > sqrtRatioBX96) (sqrtRatioAX96, sqrtRatioBX96) = (sqrtRatioBX96, sqrtRatioAX96);
        unchecked {
            return toUint128(FullMath.mulDiv(amount1, FixedPoint96.Q96, sqrtRatioBX96 - sqrtRatioAX96));
        }
    }

    /// @notice Computes the maximum amount of liquidity received for a given amount of token0, token1, the current
    /// pool prices and the prices at the tick boundaries
    /// @param sqrtRatioX96 A sqrt price representing the current pool prices
    /// @param sqrtRatioAX96 A sqrt price representing the first tick boundary
    /// @param sqrtRatioBX96 A sqrt price representing the second tick boundary
    /// @param amount0 The amount of token0 being sent in
    /// @param amount1 The amount of token1 being sent in
    /// @return liquidity The maximum amount of liquidity received
    function getLiquidityForAmounts(
        uint160 sqrtRatioX96,
        uint160 sqrtRatioAX96,
        uint160 sqrtRatioBX96,
        uint256 amount0,
        uint256 amount1
    ) internal pure returns (uint128 liquidity) {
        if (sqrtRatioAX96 > sqrtRatioBX96) (sqrtRatioAX96, sqrtRatioBX96) = (sqrtRatioBX96, sqrtRatioAX96);

        if (sqrtRatioX96 <= sqrtRatioAX96) {
            liquidity = getLiquidityForAmount0(sqrtRatioAX96, sqrtRatioBX96, amount0);
        } else if (sqrtRatioX96 < sqrtRatioBX96) {
            uint128 liquidity0 = getLiquidityForAmount0(sqrtRatioX96, sqrtRatioBX96, amount0);
            uint128 liquidity1 = getLiquidityForAmount1(sqrtRatioAX96, sqrtRatioX96, amount1);

            liquidity = liquidity0 < liquidity1 ? liquidity0 : liquidity1;
        } else {
            liquidity = getLiquidityForAmount1(sqrtRatioAX96, sqrtRatioBX96, amount1);
        }
    }

    /// @notice Computes the amount of token0 for a given amount of liquidity and a price range
    /// @param sqrtRatioAX96 A sqrt price representing the first tick boundary
    /// @param sqrtRatioBX96 A sqrt price representing the second tick boundary
    /// @param liquidity The liquidity being valued
    /// @return amount0 The amount of token0
    function getAmount0ForLiquidity(
        uint160 sqrtRatioAX96,
        uint160 sqrtRatioBX96,
        uint128 liquidity
    ) internal pure returns (uint256 amount0) {
        unchecked {
            if (sqrtRatioAX96 > sqrtRatioBX96) (sqrtRatioAX96, sqrtRatioBX96) = (sqrtRatioBX96, sqrtRatioAX96);

            return
                FullMath.mulDiv(
                    uint256(liquidity) << FixedPoint96.RESOLUTION,
                    sqrtRatioBX96 - sqrtRatioAX96,
                    sqrtRatioBX96
                ) / sqrtRatioAX96;
        }
    }

    /// @notice Computes the amount of token1 for a given amount of liquidity and a price range
    /// @param sqrtRatioAX96 A sqrt price representing the first tick boundary
    /// @param sqrtRatioBX96 A sqrt price representing the second tick boundary
    /// @param liquidity The liquidity being valued
    /// @return amount1 The amount of token1
    function getAmount1ForLiquidity(
        uint160 sqrtRatioAX96,
        uint160 sqrtRatioBX96,
        uint128 liquidity
    ) internal pure returns (uint256 amount1) {
        if (sqrtRatioAX96 > sqrtRatioBX96) (sqrtRatioAX96, sqrtRatioBX96) = (sqrtRatioBX96, sqrtRatioAX96);

        unchecked {
            return FullMath.mulDiv(liquidity, sqrtRatioBX96 - sqrtRatioAX96, FixedPoint96.Q96);
        }
    }

    /// @notice Computes the token0 and token1 value for a given amount of liquidity, the current
    /// pool prices and the prices at the tick boundaries
    /// @param sqrtRatioX96 A sqrt price representing the current pool prices
    /// @param sqrtRatioAX96 A sqrt price representing the first tick boundary
    /// @param sqrtRatioBX96 A sqrt price representing the second tick boundary
    /// @param liquidity The liquidity being valued
    /// @return amount0 The amount of token0
    /// @return amount1 The amount of token1
    function getAmountsForLiquidity(
        uint160 sqrtRatioX96,
        uint160 sqrtRatioAX96,
        uint160 sqrtRatioBX96,
        uint128 liquidity
    ) internal pure returns (uint256 amount0, uint256 amount1) {
        if (sqrtRatioAX96 > sqrtRatioBX96) (sqrtRatioAX96, sqrtRatioBX96) = (sqrtRatioBX96, sqrtRatioAX96);

        if (sqrtRatioX96 <= sqrtRatioAX96) {
            amount0 = getAmount0ForLiquidity(sqrtRatioAX96, sqrtRatioBX96, liquidity);
        } else if (sqrtRatioX96 < sqrtRatioBX96) {
            amount0 = getAmount0ForLiquidity(sqrtRatioX96, sqrtRatioBX96, liquidity);
            amount1 = getAmount1ForLiquidity(sqrtRatioAX96, sqrtRatioX96, liquidity);
        } else {
            amount1 = getAmount1ForLiquidity(sqrtRatioAX96, sqrtRatioBX96, liquidity);
        }
    }
}
// File: contracts/libraries/TickMath.sol


pragma solidity ^0.8.0;

/// @title Math library for computing sqrt prices from ticks and vice versa
/// @notice Computes sqrt price for ticks of size 1.0001, i.e. sqrt(1.0001^tick) as fixed point Q64.96 numbers. Supports
/// prices between 2**-128 and 2**128
library TickMath {
    error T();
    error R();

    /// @dev The minimum tick that may be passed to #getSqrtRatioAtTick computed from log base 1.0001 of 2**-128
    int24 internal constant MIN_TICK = -887272;
    /// @dev The maximum tick that may be passed to #getSqrtRatioAtTick computed from log base 1.0001 of 2**128
    int24 internal constant MAX_TICK = -MIN_TICK;

    /// @dev The minimum value that can be returned from #getSqrtRatioAtTick. Equivalent to getSqrtRatioAtTick(MIN_TICK)
    uint160 internal constant MIN_SQRT_RATIO = 4295128739;
    /// @dev The maximum value that can be returned from #getSqrtRatioAtTick. Equivalent to getSqrtRatioAtTick(MAX_TICK)
    uint160 internal constant MAX_SQRT_RATIO = 1461446703485210103287273052203988822378723970342;

    /// @notice Calculates sqrt(1.0001^tick) * 2^96
    /// @dev Throws if |tick| > max tick
    /// @param tick The input tick for the above formula
    /// @return sqrtPriceX96 A Fixed point Q64.96 number representing the sqrt of the ratio of the two assets (token1/token0)
    /// at the given tick
    function getSqrtRatioAtTick(int24 tick) internal pure returns (uint160 sqrtPriceX96) {
        unchecked {
            uint256 absTick = tick < 0 ? uint256(-int256(tick)) : uint256(int256(tick));
            if (absTick > uint256(int256(MAX_TICK))) revert T();

            uint256 ratio = absTick & 0x1 != 0
                ? 0xfffcb933bd6fad37aa2d162d1a594001
                : 0x100000000000000000000000000000000;
            if (absTick & 0x2 != 0) ratio = (ratio * 0xfff97272373d413259a46990580e213a) >> 128;
            if (absTick & 0x4 != 0) ratio = (ratio * 0xfff2e50f5f656932ef12357cf3c7fdcc) >> 128;
            if (absTick & 0x8 != 0) ratio = (ratio * 0xffe5caca7e10e4e61c3624eaa0941cd0) >> 128;
            if (absTick & 0x10 != 0) ratio = (ratio * 0xffcb9843d60f6159c9db58835c926644) >> 128;
            if (absTick & 0x20 != 0) ratio = (ratio * 0xff973b41fa98c081472e6896dfb254c0) >> 128;
            if (absTick & 0x40 != 0) ratio = (ratio * 0xff2ea16466c96a3843ec78b326b52861) >> 128;
            if (absTick & 0x80 != 0) ratio = (ratio * 0xfe5dee046a99a2a811c461f1969c3053) >> 128;
            if (absTick & 0x100 != 0) ratio = (ratio * 0xfcbe86c7900a88aedcffc83b479aa3a4) >> 128;
            if (absTick & 0x200 != 0) ratio = (ratio * 0xf987a7253ac413176f2b074cf7815e54) >> 128;
            if (absTick & 0x400 != 0) ratio = (ratio * 0xf3392b0822b70005940c7a398e4b70f3) >> 128;
            if (absTick & 0x800 != 0) ratio = (ratio * 0xe7159475a2c29b7443b29c7fa6e889d9) >> 128;
            if (absTick & 0x1000 != 0) ratio = (ratio * 0xd097f3bdfd2022b8845ad8f792aa5825) >> 128;
            if (absTick & 0x2000 != 0) ratio = (ratio * 0xa9f746462d870fdf8a65dc1f90e061e5) >> 128;
            if (absTick & 0x4000 != 0) ratio = (ratio * 0x70d869a156d2a1b890bb3df62baf32f7) >> 128;
            if (absTick & 0x8000 != 0) ratio = (ratio * 0x31be135f97d08fd981231505542fcfa6) >> 128;
            if (absTick & 0x10000 != 0) ratio = (ratio * 0x9aa508b5b7a84e1c677de54f3e99bc9) >> 128;
            if (absTick & 0x20000 != 0) ratio = (ratio * 0x5d6af8dedb81196699c329225ee604) >> 128;
            if (absTick & 0x40000 != 0) ratio = (ratio * 0x2216e584f5fa1ea926041bedfe98) >> 128;
            if (absTick & 0x80000 != 0) ratio = (ratio * 0x48a170391f7dc42444e8fa2) >> 128;

            if (tick > 0) ratio = type(uint256).max / ratio;

            // this divides by 1<<32 rounding up to go from a Q128.128 to a Q128.96.
            // we then downcast because we know the result always fits within 160 bits due to our tick input constraint
            // we round up in the division so getTickAtSqrtRatio of the output price is always consistent
            sqrtPriceX96 = uint160((ratio >> 32) + (ratio % (1 << 32) == 0 ? 0 : 1));
        }
    }

    /// @notice Calculates the greatest tick value such that getRatioAtTick(tick) <= ratio
    /// @dev Throws in case sqrtPriceX96 < MIN_SQRT_RATIO, as MIN_SQRT_RATIO is the lowest value getRatioAtTick may
    /// ever return.
    /// @param sqrtPriceX96 The sqrt ratio for which to compute the tick as a Q64.96
    /// @return tick The greatest tick for which the ratio is less than or equal to the input ratio
    function getTickAtSqrtRatio(uint160 sqrtPriceX96) internal pure returns (int24 tick) {
        unchecked {
            // second inequality must be < because the price can never reach the price at the max tick
            if (!(sqrtPriceX96 >= MIN_SQRT_RATIO && sqrtPriceX96 < MAX_SQRT_RATIO)) revert R();
            uint256 ratio = uint256(sqrtPriceX96) << 32;

            uint256 r = ratio;
            uint256 msb = 0;

            assembly {
                let f := shl(7, gt(r, 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF))
                msb := or(msb, f)
                r := shr(f, r)
            }
            assembly {
                let f := shl(6, gt(r, 0xFFFFFFFFFFFFFFFF))
                msb := or(msb, f)
                r := shr(f, r)
            }
            assembly {
                let f := shl(5, gt(r, 0xFFFFFFFF))
                msb := or(msb, f)
                r := shr(f, r)
            }
            assembly {
                let f := shl(4, gt(r, 0xFFFF))
                msb := or(msb, f)
                r := shr(f, r)
            }
            assembly {
                let f := shl(3, gt(r, 0xFF))
                msb := or(msb, f)
                r := shr(f, r)
            }
            assembly {
                let f := shl(2, gt(r, 0xF))
                msb := or(msb, f)
                r := shr(f, r)
            }
            assembly {
                let f := shl(1, gt(r, 0x3))
                msb := or(msb, f)
                r := shr(f, r)
            }
            assembly {
                let f := gt(r, 0x1)
                msb := or(msb, f)
            }

            if (msb >= 128) r = ratio >> (msb - 127);
            else r = ratio << (127 - msb);

            int256 log_2 = (int256(msb) - 128) << 64;

            assembly {
                r := shr(127, mul(r, r))
                let f := shr(128, r)
                log_2 := or(log_2, shl(63, f))
                r := shr(f, r)
            }
            assembly {
                r := shr(127, mul(r, r))
                let f := shr(128, r)
                log_2 := or(log_2, shl(62, f))
                r := shr(f, r)
            }
            assembly {
                r := shr(127, mul(r, r))
                let f := shr(128, r)
                log_2 := or(log_2, shl(61, f))
                r := shr(f, r)
            }
            assembly {
                r := shr(127, mul(r, r))
                let f := shr(128, r)
                log_2 := or(log_2, shl(60, f))
                r := shr(f, r)
            }
            assembly {
                r := shr(127, mul(r, r))
                let f := shr(128, r)
                log_2 := or(log_2, shl(59, f))
                r := shr(f, r)
            }
            assembly {
                r := shr(127, mul(r, r))
                let f := shr(128, r)
                log_2 := or(log_2, shl(58, f))
                r := shr(f, r)
            }
            assembly {
                r := shr(127, mul(r, r))
                let f := shr(128, r)
                log_2 := or(log_2, shl(57, f))
                r := shr(f, r)
            }
            assembly {
                r := shr(127, mul(r, r))
                let f := shr(128, r)
                log_2 := or(log_2, shl(56, f))
                r := shr(f, r)
            }
            assembly {
                r := shr(127, mul(r, r))
                let f := shr(128, r)
                log_2 := or(log_2, shl(55, f))
                r := shr(f, r)
            }
            assembly {
                r := shr(127, mul(r, r))
                let f := shr(128, r)
                log_2 := or(log_2, shl(54, f))
                r := shr(f, r)
            }
            assembly {
                r := shr(127, mul(r, r))
                let f := shr(128, r)
                log_2 := or(log_2, shl(53, f))
                r := shr(f, r)
            }
            assembly {
                r := shr(127, mul(r, r))
                let f := shr(128, r)
                log_2 := or(log_2, shl(52, f))
                r := shr(f, r)
            }
            assembly {
                r := shr(127, mul(r, r))
                let f := shr(128, r)
                log_2 := or(log_2, shl(51, f))
                r := shr(f, r)
            }
            assembly {
                r := shr(127, mul(r, r))
                let f := shr(128, r)
                log_2 := or(log_2, shl(50, f))
            }

            int256 log_sqrt10001 = log_2 * 255738958999603826347141; // 128.128 number

            int24 tickLow = int24((log_sqrt10001 - 3402992956809132418596140100660247210) >> 128);
            int24 tickHi = int24((log_sqrt10001 + 291339464771989622907027621153398088495) >> 128);

            tick = tickLow == tickHi ? tickLow : getSqrtRatioAtTick(tickHi) <= sqrtPriceX96 ? tickHi : tickLow;
        }
    }
}
// File: @uniswap/v3-periphery/contracts/libraries/PositionKey.sol


pragma solidity >=0.5.0;

library PositionKey {
    /// @dev Returns the key of the position in the core library
    function compute(
        address owner,
        int24 tickLower,
        int24 tickUpper
    ) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(owner, tickLower, tickUpper));
    }
}

// File: contracts/Algebra/interfaces/pool/IAlgebraPoolEvents.sol


pragma solidity >=0.5.0;

/// @title Events emitted by a pool
/// @dev Credit to Uniswap Labs under GPL-2.0-or-later license:
/// https://github.com/Uniswap/v3-core/tree/main/contracts/interfaces
interface IAlgebraPoolEvents {
  /**
   * @notice Emitted exactly once by a pool when #initialize is first called on the pool
   * @dev Mint/Burn/Swap cannot be emitted by the pool before Initialize
   * @param price The initial sqrt price of the pool, as a Q64.96
   * @param tick The initial tick of the pool, i.e. log base 1.0001 of the starting price of the pool
   */
  event Initialize(uint160 price, int24 tick);

  /**
   * @notice Emitted when liquidity is minted for a given position
   * @param sender The address that minted the liquidity
   * @param owner The owner of the position and recipient of any minted liquidity
   * @param bottomTick The lower tick of the position
   * @param topTick The upper tick of the position
   * @param liquidityAmount The amount of liquidity minted to the position range
   * @param amount0 How much token0 was required for the minted liquidity
   * @param amount1 How much token1 was required for the minted liquidity
   */
  event Mint(
    address sender,
    address indexed owner,
    int24 indexed bottomTick,
    int24 indexed topTick,
    uint128 liquidityAmount,
    uint256 amount0,
    uint256 amount1
  );

  /**
   * @notice Emitted when fees are collected by the owner of a position
   * @dev Collect events may be emitted with zero amount0 and amount1 when the caller chooses not to collect fees
   * @param owner The owner of the position for which fees are collected
   * @param recipient The address that received fees
   * @param bottomTick The lower tick of the position
   * @param topTick The upper tick of the position
   * @param amount0 The amount of token0 fees collected
   * @param amount1 The amount of token1 fees collected
   */
  event Collect(address indexed owner, address recipient, int24 indexed bottomTick, int24 indexed topTick, uint128 amount0, uint128 amount1);

  /**
   * @notice Emitted when a position's liquidity is removed
   * @dev Does not withdraw any fees earned by the liquidity position, which must be withdrawn via #collect
   * @param owner The owner of the position for which liquidity is removed
   * @param bottomTick The lower tick of the position
   * @param topTick The upper tick of the position
   * @param liquidityAmount The amount of liquidity to remove
   * @param amount0 The amount of token0 withdrawn
   * @param amount1 The amount of token1 withdrawn
   */
  event Burn(address indexed owner, int24 indexed bottomTick, int24 indexed topTick, uint128 liquidityAmount, uint256 amount0, uint256 amount1);

  /**
   * @notice Emitted by the pool for any swaps between token0 and token1
   * @param sender The address that initiated the swap call, and that received the callback
   * @param recipient The address that received the output of the swap
   * @param amount0 The delta of the token0 balance of the pool
   * @param amount1 The delta of the token1 balance of the pool
   * @param price The sqrt(price) of the pool after the swap, as a Q64.96
   * @param liquidity The liquidity of the pool after the swap
   * @param tick The log base 1.0001 of price of the pool after the swap
   */
  event Swap(address indexed sender, address indexed recipient, int256 amount0, int256 amount1, uint160 price, uint128 liquidity, int24 tick);

  /**
   * @notice Emitted by the pool for any flashes of token0/token1
   * @param sender The address that initiated the swap call, and that received the callback
   * @param recipient The address that received the tokens from flash
   * @param amount0 The amount of token0 that was flashed
   * @param amount1 The amount of token1 that was flashed
   * @param paid0 The amount of token0 paid for the flash, which can exceed the amount0 plus the fee
   * @param paid1 The amount of token1 paid for the flash, which can exceed the amount1 plus the fee
   */
  event Flash(address indexed sender, address indexed recipient, uint256 amount0, uint256 amount1, uint256 paid0, uint256 paid1);

  /**
   * @notice Emitted when the community fee is changed by the pool
   * @param communityFee0New The updated value of the token0 community fee percent
   * @param communityFee1New The updated value of the token1 community fee percent
   */
  event CommunityFee(uint8 communityFee0New, uint8 communityFee1New);

  /**
   * @notice Emitted when new activeIncentive is set
   * @param virtualPoolAddress The address of a virtual pool associated with the current active incentive
   */
  event Incentive(address indexed virtualPoolAddress);

  /**
   * @notice Emitted when the fee changes
   * @param fee The value of the token fee
   */
  event Fee(uint16 fee);

  /**
   * @notice Emitted when the LiquidityCooldown changes
   * @param liquidityCooldown The value of locktime for added liquidity
   */
  event LiquidityCooldown(uint32 liquidityCooldown);
}

// File: contracts/Algebra/interfaces/pool/IAlgebraPoolPermissionedActions.sol


pragma solidity >=0.5.0;

/**
 * @title Permissioned pool actions
 * @notice Contains pool methods that may only be called by the factory owner or tokenomics
 * @dev Credit to Uniswap Labs under GPL-2.0-or-later license:
 * https://github.com/Uniswap/v3-core/tree/main/contracts/interfaces
 */
interface IAlgebraPoolPermissionedActions {
  /**
   * @notice Set the community's % share of the fees. Cannot exceed 25% (250)
   * @param communityFee0 new community fee percent for token0 of the pool in thousandths (1e-3)
   * @param communityFee1 new community fee percent for token1 of the pool in thousandths (1e-3)
   */
  function setCommunityFee(uint8 communityFee0, uint8 communityFee1) external;

  /**
   * @notice Sets an active incentive
   * @param virtualPoolAddress The address of a virtual pool associated with the incentive
   */
  function setIncentive(address virtualPoolAddress) external;

  /**
   * @notice Sets new lock time for added liquidity
   * @param newLiquidityCooldown The time in seconds
   */
  function setLiquidityCooldown(uint32 newLiquidityCooldown) external;
}

// File: contracts/Algebra/interfaces/pool/IAlgebraPoolActions.sol


pragma solidity >=0.5.0;

/// @title Permissionless pool actions
/// @dev Credit to Uniswap Labs under GPL-2.0-or-later license:
/// https://github.com/Uniswap/v3-core/tree/main/contracts/interfaces
interface IAlgebraPoolActions {
  /**
   * @notice Sets the initial price for the pool
   * @dev Price is represented as a sqrt(amountToken1/amountToken0) Q64.96 value
   * @param price the initial sqrt price of the pool as a Q64.96
   */
  function initialize(uint160 price) external;

  /**
   * @notice Adds liquidity for the given recipient/bottomTick/topTick position
   * @dev The caller of this method receives a callback in the form of IAlgebraMintCallback# AlgebraMintCallback
   * in which they must pay any token0 or token1 owed for the liquidity. The amount of token0/token1 due depends
   * on bottomTick, topTick, the amount of liquidity, and the current price.
   * @param sender The address which will receive potential surplus of paid tokens
   * @param recipient The address for which the liquidity will be created
   * @param bottomTick The lower tick of the position in which to add liquidity
   * @param topTick The upper tick of the position in which to add liquidity
   * @param amount The desired amount of liquidity to mint
   * @param data Any data that should be passed through to the callback
   * @return amount0 The amount of token0 that was paid to mint the given amount of liquidity. Matches the value in the callback
   * @return amount1 The amount of token1 that was paid to mint the given amount of liquidity. Matches the value in the callback
   * @return liquidityActual The actual minted amount of liquidity
   */
  function mint(
    address sender,
    address recipient,
    int24 bottomTick,
    int24 topTick,
    uint128 amount,
    bytes calldata data
  )
    external
    returns (
      uint256 amount0,
      uint256 amount1,
      uint128 liquidityActual
    );

  /**
   * @notice Collects tokens owed to a position
   * @dev Does not recompute fees earned, which must be done either via mint or burn of any amount of liquidity.
   * Collect must be called by the position owner. To withdraw only token0 or only token1, amount0Requested or
   * amount1Requested may be set to zero. To withdraw all tokens owed, caller may pass any value greater than the
   * actual tokens owed, e.g. type(uint128).max. Tokens owed may be from accumulated swap fees or burned liquidity.
   * @param recipient The address which should receive the fees collected
   * @param bottomTick The lower tick of the position for which to collect fees
   * @param topTick The upper tick of the position for which to collect fees
   * @param amount0Requested How much token0 should be withdrawn from the fees owed
   * @param amount1Requested How much token1 should be withdrawn from the fees owed
   * @return amount0 The amount of fees collected in token0
   * @return amount1 The amount of fees collected in token1
   */
  function collect(
    address recipient,
    int24 bottomTick,
    int24 topTick,
    uint128 amount0Requested,
    uint128 amount1Requested
  ) external returns (uint128 amount0, uint128 amount1);

  /**
   * @notice Burn liquidity from the sender and account tokens owed for the liquidity to the position
   * @dev Can be used to trigger a recalculation of fees owed to a position by calling with an amount of 0
   * @dev Fees must be collected separately via a call to #collect
   * @param bottomTick The lower tick of the position for which to burn liquidity
   * @param topTick The upper tick of the position for which to burn liquidity
   * @param amount How much liquidity to burn
   * @return amount0 The amount of token0 sent to the recipient
   * @return amount1 The amount of token1 sent to the recipient
   */
  function burn(
    int24 bottomTick,
    int24 topTick,
    uint128 amount
  ) external returns (uint256 amount0, uint256 amount1);

  /**
   * @notice Swap token0 for token1, or token1 for token0
   * @dev The caller of this method receives a callback in the form of IAlgebraSwapCallback# AlgebraSwapCallback
   * @param recipient The address to receive the output of the swap
   * @param zeroToOne The direction of the swap, true for token0 to token1, false for token1 to token0
   * @param amountSpecified The amount of the swap, which implicitly configures the swap as exact input (positive), or exact output (negative)
   * @param limitSqrtPrice The Q64.96 sqrt price limit. If zero for one, the price cannot be less than this
   * value after the swap. If one for zero, the price cannot be greater than this value after the swap
   * @param data Any data to be passed through to the callback. If using the Router it should contain
   * SwapRouter#SwapCallbackData
   * @return amount0 The delta of the balance of token0 of the pool, exact when negative, minimum when positive
   * @return amount1 The delta of the balance of token1 of the pool, exact when negative, minimum when positive
   */
  function swap(
    address recipient,
    bool zeroToOne,
    int256 amountSpecified,
    uint160 limitSqrtPrice,
    bytes calldata data
  ) external returns (int256 amount0, int256 amount1);

  /**
   * @notice Swap token0 for token1, or token1 for token0 (tokens that have fee on transfer)
   * @dev The caller of this method receives a callback in the form of I AlgebraSwapCallback# AlgebraSwapCallback
   * @param sender The address called this function (Comes from the Router)
   * @param recipient The address to receive the output of the swap
   * @param zeroToOne The direction of the swap, true for token0 to token1, false for token1 to token0
   * @param amountSpecified The amount of the swap, which implicitly configures the swap as exact input (positive), or exact output (negative)
   * @param limitSqrtPrice The Q64.96 sqrt price limit. If zero for one, the price cannot be less than this
   * value after the swap. If one for zero, the price cannot be greater than this value after the swap
   * @param data Any data to be passed through to the callback. If using the Router it should contain
   * SwapRouter#SwapCallbackData
   * @return amount0 The delta of the balance of token0 of the pool, exact when negative, minimum when positive
   * @return amount1 The delta of the balance of token1 of the pool, exact when negative, minimum when positive
   */
  function swapSupportingFeeOnInputTokens(
    address sender,
    address recipient,
    bool zeroToOne,
    int256 amountSpecified,
    uint160 limitSqrtPrice,
    bytes calldata data
  ) external returns (int256 amount0, int256 amount1);

  /**
   * @notice Receive token0 and/or token1 and pay it back, plus a fee, in the callback
   * @dev The caller of this method receives a callback in the form of IAlgebraFlashCallback# AlgebraFlashCallback
   * @dev All excess tokens paid in the callback are distributed to liquidity providers as an additional fee. So this method can be used
   * to donate underlying tokens to currently in-range liquidity providers by calling with 0 amount{0,1} and sending
   * the donation amount(s) from the callback
   * @param recipient The address which will receive the token0 and token1 amounts
   * @param amount0 The amount of token0 to send
   * @param amount1 The amount of token1 to send
   * @param data Any data to be passed through to the callback
   */
  function flash(
    address recipient,
    uint256 amount0,
    uint256 amount1,
    bytes calldata data
  ) external;
}

// File: contracts/Algebra/interfaces/pool/IAlgebraPoolDerivedState.sol


pragma solidity >=0.5.0;

/**
 * @title Pool state that is not stored
 * @notice Contains view functions to provide information about the pool that is computed rather than stored on the
 * blockchain. The functions here may have variable gas costs.
 * @dev Credit to Uniswap Labs under GPL-2.0-or-later license:
 * https://github.com/Uniswap/v3-core/tree/main/contracts/interfaces
 */
interface IAlgebraPoolDerivedState {
  /**
   * @notice Returns the cumulative tick and liquidity as of each timestamp `secondsAgo` from the current block timestamp
   * @dev To get a time weighted average tick or liquidity-in-range, you must call this with two values, one representing
   * the beginning of the period and another for the end of the period. E.g., to get the last hour time-weighted average tick,
   * you must call it with secondsAgos = [3600, 0].
   * @dev The time weighted average tick represents the geometric time weighted average price of the pool, in
   * log base sqrt(1.0001) of token1 / token0. The TickMath library can be used to go from a tick value to a ratio.
   * @param secondsAgos From how long ago each cumulative tick and liquidity value should be returned
   * @return tickCumulatives Cumulative tick values as of each `secondsAgos` from the current block timestamp
   * @return secondsPerLiquidityCumulatives Cumulative seconds per liquidity-in-range value as of each `secondsAgos`
   * from the current block timestamp
   * @return volatilityCumulatives Cumulative standard deviation as of each `secondsAgos`
   * @return volumePerAvgLiquiditys Cumulative swap volume per liquidity as of each `secondsAgos`
   */
  function getTimepoints(uint32[] calldata secondsAgos)
    external
    view
    returns (
      int56[] memory tickCumulatives,
      uint160[] memory secondsPerLiquidityCumulatives,
      uint112[] memory volatilityCumulatives,
      uint256[] memory volumePerAvgLiquiditys
    );

  /**
   * @notice Returns a snapshot of the tick cumulative, seconds per liquidity and seconds inside a tick range
   * @dev Snapshots must only be compared to other snapshots, taken over a period for which a position existed.
   * I.e., snapshots cannot be compared if a position is not held for the entire period between when the first
   * snapshot is taken and the second snapshot is taken.
   * @param bottomTick The lower tick of the range
   * @param topTick The upper tick of the range
   * @return innerTickCumulative The snapshot of the tick accumulator for the range
   * @return innerSecondsSpentPerLiquidity The snapshot of seconds per liquidity for the range
   * @return innerSecondsSpent The snapshot of the number of seconds during which the price was in this range
   */
  function getInnerCumulatives(int24 bottomTick, int24 topTick)
    external
    view
    returns (
      int56 innerTickCumulative,
      uint160 innerSecondsSpentPerLiquidity,
      uint32 innerSecondsSpent
    );
}

// File: contracts/Algebra/interfaces/pool/IAlgebraPoolState.sol


pragma solidity >=0.5.0;

/// @title Pool state that can change
/// @dev Credit to Uniswap Labs under GPL-2.0-or-later license:
/// https://github.com/Uniswap/v3-core/tree/main/contracts/interfaces
interface IAlgebraPoolState {
  /**
   * @notice The globalState structure in the pool stores many values but requires only one slot
   * and is exposed as a single method to save gas when accessed externally.
   * @return price The current price of the pool as a sqrt(token1/token0) Q64.96 value;
   * Returns tick The current tick of the pool, i.e. according to the last tick transition that was run;
   * Returns This value may not always be equal to SqrtTickMath.getTickAtSqrtRatio(price) if the price is on a tick
   * boundary;
   * Returns fee The last pool fee value in hundredths of a bip, i.e. 1e-6;
   * Returns timepointIndex The index of the last written timepoint;
   * Returns communityFeeToken0 The community fee percentage of the swap fee in thousandths (1e-3) for token0;
   * Returns communityFeeToken1 The community fee percentage of the swap fee in thousandths (1e-3) for token1;
   * Returns unlocked Whether the pool is currently locked to reentrancy;
   */
  function globalState()
    external
    view
    returns (
      uint160 price,
      int24 tick,
      uint16 fee,
      uint16 timepointIndex,
      uint8 communityFeeToken0,
      uint8 communityFeeToken1,
      bool unlocked
    );

  /**
   * @notice The fee growth as a Q128.128 fees of token0 collected per unit of liquidity for the entire life of the pool
   * @dev This value can overflow the uint256
   */
  function totalFeeGrowth0Token() external view returns (uint256);

  /**
   * @notice The fee growth as a Q128.128 fees of token1 collected per unit of liquidity for the entire life of the pool
   * @dev This value can overflow the uint256
   */
  function totalFeeGrowth1Token() external view returns (uint256);

  /**
   * @notice The currently in range liquidity available to the pool
   * @dev This value has no relationship to the total liquidity across all ticks.
   * Returned value cannot exceed type(uint128).max
   */
  function liquidity() external view returns (uint128);

  /**
   * @notice Look up information about a specific tick in the pool
   * @dev This is a public structure, so the `return` natspec tags are omitted.
   * @param tick The tick to look up
   * @return liquidityTotal the total amount of position liquidity that uses the pool either as tick lower or
   * tick upper;
   * Returns liquidityDelta how much liquidity changes when the pool price crosses the tick;
   * Returns outerFeeGrowth0Token the fee growth on the other side of the tick from the current tick in token0;
   * Returns outerFeeGrowth1Token the fee growth on the other side of the tick from the current tick in token1;
   * Returns outerTickCumulative the cumulative tick value on the other side of the tick from the current tick;
   * Returns outerSecondsPerLiquidity the seconds spent per liquidity on the other side of the tick from the current tick;
   * Returns outerSecondsSpent the seconds spent on the other side of the tick from the current tick;
   * Returns initialized Set to true if the tick is initialized, i.e. liquidityTotal is greater than 0
   * otherwise equal to false. Outside values can only be used if the tick is initialized.
   * In addition, these values are only relative and must be used only in comparison to previous snapshots for
   * a specific position.
   */
  function ticks(int24 tick)
    external
    view
    returns (
      uint128 liquidityTotal,
      int128 liquidityDelta,
      uint256 outerFeeGrowth0Token,
      uint256 outerFeeGrowth1Token,
      int56 outerTickCumulative,
      uint160 outerSecondsPerLiquidity,
      uint32 outerSecondsSpent,
      bool initialized
    );

  /** @notice Returns 256 packed tick initialized boolean values. See TickTable for more information */
  function tickTable(int16 wordPosition) external view returns (uint256);

  /**
   * @notice Returns the information about a position by the position's key
   * @dev This is a public mapping of structures, so the `return` natspec tags are omitted.
   * @param key The position's key is a hash of a preimage composed by the owner, bottomTick and topTick
   * @return liquidityAmount The amount of liquidity in the position;
   * Returns lastLiquidityAddTimestamp Timestamp of last adding of liquidity;
   * Returns innerFeeGrowth0Token Fee growth of token0 inside the tick range as of the last mint/burn/poke;
   * Returns innerFeeGrowth1Token Fee growth of token1 inside the tick range as of the last mint/burn/poke;
   * Returns fees0 The computed amount of token0 owed to the position as of the last mint/burn/poke;
   * Returns fees1 The computed amount of token1 owed to the position as of the last mint/burn/poke
   */
  function positions(bytes32 key)
    external
    view
    returns (
      uint128 liquidityAmount,
      uint32 lastLiquidityAddTimestamp,
      uint256 innerFeeGrowth0Token,
      uint256 innerFeeGrowth1Token,
      uint128 fees0,
      uint128 fees1
    );

  /**
   * @notice Returns data about a specific timepoint index
   * @param index The element of the timepoints array to fetch
   * @dev You most likely want to use #getTimepoints() instead of this method to get an timepoint as of some amount of time
   * ago, rather than at a specific index in the array.
   * This is a public mapping of structures, so the `return` natspec tags are omitted.
   * @return initialized whether the timepoint has been initialized and the values are safe to use;
   * Returns blockTimestamp The timestamp of the timepoint;
   * Returns tickCumulative the tick multiplied by seconds elapsed for the life of the pool as of the timepoint timestamp;
   * Returns secondsPerLiquidityCumulative the seconds per in range liquidity for the life of the pool as of the timepoint timestamp;
   * Returns volatilityCumulative Cumulative standard deviation for the life of the pool as of the timepoint timestamp;
   * Returns averageTick Time-weighted average tick;
   * Returns volumePerLiquidityCumulative Cumulative swap volume per liquidity for the life of the pool as of the timepoint timestamp;
   */
  function timepoints(uint256 index)
    external
    view
    returns (
      bool initialized,
      uint32 blockTimestamp,
      int56 tickCumulative,
      uint160 secondsPerLiquidityCumulative,
      uint88 volatilityCumulative,
      int24 averageTick,
      uint144 volumePerLiquidityCumulative
    );

  /**
   * @notice Returns the information about active incentive
   * @dev if there is no active incentive at the moment, virtualPool,endTimestamp,startTimestamp would be equal to 0
   * @return virtualPool The address of a virtual pool associated with the current active incentive
   */
  function activeIncentive() external view returns (address virtualPool);

  /**
   * @notice Returns the lock time for added liquidity
   */
  function liquidityCooldown() external view returns (uint32 cooldownInSeconds);
}

// File: contracts/Algebra/libraries/Constants.sol


pragma solidity >=0.7.6;

library Constants {
  uint8 internal constant RESOLUTION = 96;
  uint256 internal constant Q96 = 0x1000000000000000000000000;
  uint256 internal constant Q128 = 0x100000000000000000000000000000000;
  // fee value in hundredths of a bip, i.e. 1e-6
  uint16 internal constant BASE_FEE = 100;
  int24 internal constant TICK_SPACING = 60;

  // max(uint128) / ( (MAX_TICK - MIN_TICK) / TICK_SPACING )
  uint128 internal constant MAX_LIQUIDITY_PER_TICK = 11505743598341114571880798222544994;

  uint32 internal constant MAX_LIQUIDITY_COOLDOWN = 1 days;
  uint8 internal constant MAX_COMMUNITY_FEE = 250;
  uint256 internal constant COMMUNITY_FEE_DENOMINATOR = 1000;
}

// File: contracts/Algebra/libraries/AdaptiveFee.sol


pragma solidity >=0.7.6;


/// @title AdaptiveFee
/// @notice Calculates fee based on combination of sigmoids
library AdaptiveFee {
  // alpha1 + alpha2 + baseFee must be <= type(uint16).max
  struct Configuration {
    uint16 alpha1; // max value of the first sigmoid
    uint16 alpha2; // max value of the second sigmoid
    uint32 beta1; // shift along the x-axis for the first sigmoid
    uint32 beta2; // shift along the x-axis for the second sigmoid
    uint16 gamma1; // horizontal stretch factor for the first sigmoid
    uint16 gamma2; // horizontal stretch factor for the second sigmoid
    uint32 volumeBeta; // shift along the x-axis for the outer volume-sigmoid
    uint16 volumeGamma; // horizontal stretch factor the outer volume-sigmoid
    uint16 baseFee; // minimum possible fee
  }

  /// @notice Calculates fee based on formula:
  /// baseFee + sigmoidVolume(sigmoid1(volatility, volumePerLiquidity) + sigmoid2(volatility, volumePerLiquidity))
  /// maximum value capped by baseFee + alpha1 + alpha2
  function getFee(
    uint88 volatility,
    uint256 volumePerLiquidity,
    Configuration memory config
  ) internal pure returns (uint16 fee) {
    uint256 sumOfSigmoids = sigmoid(volatility, config.gamma1, config.alpha1, config.beta1) +
      sigmoid(volatility, config.gamma2, config.alpha2, config.beta2);

    if (sumOfSigmoids > type(uint16).max) {
      // should be impossible, just in case
      sumOfSigmoids = type(uint16).max;
    }

    return uint16(config.baseFee + sigmoid(volumePerLiquidity, config.volumeGamma, uint16(sumOfSigmoids), config.volumeBeta)); // safe since alpha1 + alpha2 + baseFee _must_ be <= type(uint16).max
  }

  /// @notice calculates α / (1 + e^( (β-x) / γ))
  /// that is a sigmoid with a maximum value of α, x-shifted by β, and stretched by γ
  /// @dev returns uint256 for fuzzy testing. Guaranteed that the result is not greater than alpha
  function sigmoid(
    uint256 x,
    uint16 g,
    uint16 alpha,
    uint256 beta
  ) internal pure returns (uint256 res) {
    if (x > beta) {
      x = x - beta;
      if (x >= 6 * uint256(g)) return alpha; // so x < 19 bits
      uint256 g8 = uint256(g)**8; // < 128 bits (8*16)
      uint256 ex = exp(x, g, g8); // < 155 bits
      res = (alpha * ex) / (g8 + ex); // in worst case: (16 + 155 bits) / 155 bits
      // so res <= alpha
    } else {
      x = beta - x;
      if (x >= 6 * uint256(g)) return 0; // so x < 19 bits
      uint256 g8 = uint256(g)**8; // < 128 bits (8*16)
      uint256 ex = g8 + exp(x, g, g8); // < 156 bits
      res = (alpha * g8) / ex; // in worst case: (16 + 128 bits) / 156 bits
      // g8 <= ex, so res <= alpha
    }
  }

  /// @notice calculates e^(x/g) * g^8 in a series, since (around zero):
  /// e^x = 1 + x + x^2/2 + ... + x^n/n! + ...
  /// e^(x/g) = 1 + x/g + x^2/(2*g^2) + ... + x^(n)/(g^n * n!) + ...
  function exp(
    uint256 x,
    uint16 g,
    uint256 gHighestDegree
  ) internal pure returns (uint256 res) {
    // calculating:
    // g**8 + x * g**7 + (x**2 * g**6) / 2 + (x**3 * g**5) / 6 + (x**4 * g**4) / 24 + (x**5 * g**3) / 120 + (x**6 * g^2) / 720 + x**7 * g / 5040 + x**8 / 40320

    // x**8 < 152 bits (19*8) and g**8 < 128 bits (8*16)
    // so each summand < 152 bits and res < 155 bits
    uint256 xLowestDegree = x;
    res = gHighestDegree; // g**8

    gHighestDegree /= g; // g**7
    res += xLowestDegree * gHighestDegree;

    gHighestDegree /= g; // g**6
    xLowestDegree *= x; // x**2
    res += (xLowestDegree * gHighestDegree) / 2;

    gHighestDegree /= g; // g**5
    xLowestDegree *= x; // x**3
    res += (xLowestDegree * gHighestDegree) / 6;

    gHighestDegree /= g; // g**4
    xLowestDegree *= x; // x**4
    res += (xLowestDegree * gHighestDegree) / 24;

    gHighestDegree /= g; // g**3
    xLowestDegree *= x; // x**5
    res += (xLowestDegree * gHighestDegree) / 120;

    gHighestDegree /= g; // g**2
    xLowestDegree *= x; // x**6
    res += (xLowestDegree * gHighestDegree) / 720;

    xLowestDegree *= x; // x**7
    res += (xLowestDegree * g) / 5040 + (xLowestDegree * x) / (40320);
  }
}

// File: contracts/Algebra/interfaces/IDataStorageOperator.sol


pragma solidity >=0.5.0;
pragma abicoder v2;


interface IDataStorageOperator {
  event FeeConfiguration(AdaptiveFee.Configuration feeConfig);

  /**
   * @notice Returns data belonging to a certain timepoint
   * @param index The index of timepoint in the array
   * @dev There is more convenient function to fetch a timepoint: observe(). Which requires not an index but seconds
   * @return initialized Whether the timepoint has been initialized and the values are safe to use,
   * blockTimestamp The timestamp of the observation,
   * tickCumulative The tick multiplied by seconds elapsed for the life of the pool as of the timepoint timestamp,
   * secondsPerLiquidityCumulative The seconds per in range liquidity for the life of the pool as of the timepoint timestamp,
   * volatilityCumulative Cumulative standard deviation for the life of the pool as of the timepoint timestamp,
   * averageTick Time-weighted average tick,
   * volumePerLiquidityCumulative Cumulative swap volume per liquidity for the life of the pool as of the timepoint timestamp
   */
  function timepoints(uint256 index)
    external
    view
    returns (
      bool initialized,
      uint32 blockTimestamp,
      int56 tickCumulative,
      uint160 secondsPerLiquidityCumulative,
      uint88 volatilityCumulative,
      int24 averageTick,
      uint144 volumePerLiquidityCumulative
    );

  /// @notice Initialize the dataStorage array by writing the first slot. Called once for the lifecycle of the timepoints array
  /// @param time The time of the dataStorage initialization, via block.timestamp truncated to uint32
  /// @param tick Initial tick
  function initialize(uint32 time, int24 tick) external;

  /// @dev Reverts if an timepoint at or before the desired timepoint timestamp does not exist.
  /// 0 may be passed as `secondsAgo' to return the current cumulative values.
  /// If called with a timestamp falling between two timepoints, returns the counterfactual accumulator values
  /// at exactly the timestamp between the two timepoints.
  /// @param time The current block timestamp
  /// @param secondsAgo The amount of time to look back, in seconds, at which point to return an timepoint
  /// @param tick The current tick
  /// @param index The index of the timepoint that was most recently written to the timepoints array
  /// @param liquidity The current in-range pool liquidity
  /// @return tickCumulative The cumulative tick since the pool was first initialized, as of `secondsAgo`
  /// @return secondsPerLiquidityCumulative The cumulative seconds / max(1, liquidity) since the pool was first initialized, as of `secondsAgo`
  /// @return volatilityCumulative The cumulative volatility value since the pool was first initialized, as of `secondsAgo`
  /// @return volumePerAvgLiquidity The cumulative volume per liquidity value since the pool was first initialized, as of `secondsAgo`
  function getSingleTimepoint(
    uint32 time,
    uint32 secondsAgo,
    int24 tick,
    uint16 index,
    uint128 liquidity
  )
    external
    view
    returns (
      int56 tickCumulative,
      uint160 secondsPerLiquidityCumulative,
      uint112 volatilityCumulative,
      uint256 volumePerAvgLiquidity
    );

  /// @notice Returns the accumulator values as of each time seconds ago from the given time in the array of `secondsAgos`
  /// @dev Reverts if `secondsAgos` > oldest timepoint
  /// @param time The current block.timestamp
  /// @param secondsAgos Each amount of time to look back, in seconds, at which point to return an timepoint
  /// @param tick The current tick
  /// @param index The index of the timepoint that was most recently written to the timepoints array
  /// @param liquidity The current in-range pool liquidity
  /// @return tickCumulatives The cumulative tick since the pool was first initialized, as of each `secondsAgo`
  /// @return secondsPerLiquidityCumulatives The cumulative seconds / max(1, liquidity) since the pool was first initialized, as of each `secondsAgo`
  /// @return volatilityCumulatives The cumulative volatility values since the pool was first initialized, as of each `secondsAgo`
  /// @return volumePerAvgLiquiditys The cumulative volume per liquidity values since the pool was first initialized, as of each `secondsAgo`
  function getTimepoints(
    uint32 time,
    uint32[] memory secondsAgos,
    int24 tick,
    uint16 index,
    uint128 liquidity
  )
    external
    view
    returns (
      int56[] memory tickCumulatives,
      uint160[] memory secondsPerLiquidityCumulatives,
      uint112[] memory volatilityCumulatives,
      uint256[] memory volumePerAvgLiquiditys
    );

  /// @notice Returns average volatility in the range from time-WINDOW to time
  /// @param time The current block.timestamp
  /// @param tick The current tick
  /// @param index The index of the timepoint that was most recently written to the timepoints array
  /// @param liquidity The current in-range pool liquidity
  /// @return TWVolatilityAverage The average volatility in the recent range
  /// @return TWVolumePerLiqAverage The average volume per liquidity in the recent range
  function getAverages(
    uint32 time,
    int24 tick,
    uint16 index,
    uint128 liquidity
  ) external view returns (uint112 TWVolatilityAverage, uint256 TWVolumePerLiqAverage);

  /// @notice Writes an dataStorage timepoint to the array
  /// @dev Writable at most once per block. Index represents the most recently written element. index must be tracked externally.
  /// @param index The index of the timepoint that was most recently written to the timepoints array
  /// @param blockTimestamp The timestamp of the new timepoint
  /// @param tick The active tick at the time of the new timepoint
  /// @param liquidity The total in-range liquidity at the time of the new timepoint
  /// @param volumePerLiquidity The gmean(volumes)/liquidity at the time of the new timepoint
  /// @return indexUpdated The new index of the most recently written element in the dataStorage array
  function write(
    uint16 index,
    uint32 blockTimestamp,
    int24 tick,
    uint128 liquidity,
    uint128 volumePerLiquidity
  ) external returns (uint16 indexUpdated);

  /// @notice Changes fee configuration for the pool
  function changeFeeConfiguration(AdaptiveFee.Configuration calldata feeConfig) external;

  /// @notice Calculates gmean(volume/liquidity) for block
  /// @param liquidity The current in-range pool liquidity
  /// @param amount0 Total amount of swapped token0
  /// @param amount1 Total amount of swapped token1
  /// @return volumePerLiquidity gmean(volume/liquidity) capped by 100000 << 64
  function calculateVolumePerLiquidity(
    uint128 liquidity,
    int256 amount0,
    int256 amount1
  ) external pure returns (uint128 volumePerLiquidity);

  /// @return windowLength Length of window used to calculate averages
  function window() external view returns (uint32 windowLength);

  /// @notice Calculates fee based on combination of sigmoids
  /// @param time The current block.timestamp
  /// @param tick The current tick
  /// @param index The index of the timepoint that was most recently written to the timepoints array
  /// @param liquidity The current in-range pool liquidity
  /// @return fee The fee in hundredths of a bip, i.e. 1e-6
  function getFee(
    uint32 time,
    int24 tick,
    uint16 index,
    uint128 liquidity
  ) external view returns (uint16 fee);
}

// File: contracts/Algebra/interfaces/pool/IAlgebraPoolImmutables.sol


pragma solidity >=0.5.0;


/// @title Pool state that never changes
/// @dev Credit to Uniswap Labs under GPL-2.0-or-later license:
/// https://github.com/Uniswap/v3-core/tree/main/contracts/interfaces
interface IAlgebraPoolImmutables {
  /**
   * @notice The contract that stores all the timepoints and can perform actions with them
   * @return The operator address
   */
  function dataStorageOperator() external view returns (address);

  /**
   * @notice The contract that deployed the pool, which must adhere to the IAlgebraFactory interface
   * @return The contract address
   */
  function factory() external view returns (address);

  /**
   * @notice The first of the two tokens of the pool, sorted by address
   * @return The token contract address
   */
  function token0() external view returns (address);

  /**
   * @notice The second of the two tokens of the pool, sorted by address
   * @return The token contract address
   */
  function token1() external view returns (address);

  /**
   * @notice The pool tick spacing
   * @dev Ticks can only be used at multiples of this value
   * e.g.: a tickSpacing of 60 means ticks can be initialized every 60th tick, i.e., ..., -120, -60, 0, 60, 120, ...
   * This value is an int24 to avoid casting even though it is always positive.
   * @return The tick spacing
   */
  function tickSpacing() external view returns (int24);

  /**
   * @notice The maximum amount of position liquidity that can use any tick in the range
   * @dev This parameter is enforced per tick to prevent liquidity from overflowing a uint128 at any point, and
   * also prevents out-of-range liquidity from being used to prevent adding in-range liquidity to a pool
   * @return The max amount of liquidity per tick
   */
  function maxLiquidityPerTick() external view returns (uint128);
}

// File: contracts/Algebra/interfaces/IAlgebraPool.sol


pragma solidity >=0.5.0;







/**
 * @title The interface for a Algebra Pool
 * @dev The pool interface is broken up into many smaller pieces.
 * Credit to Uniswap Labs under GPL-2.0-or-later license:
 * https://github.com/Uniswap/v3-core/tree/main/contracts/interfaces
 */
interface IAlgebraPool is
  IAlgebraPoolImmutables,
  IAlgebraPoolState,
  IAlgebraPoolDerivedState,
  IAlgebraPoolActions,
  IAlgebraPoolPermissionedActions,
  IAlgebraPoolEvents
{
  // used only for combining interfaces
}

// File: @uniswap/v3-core/contracts/interfaces/callback/IUniswapV3SwapCallback.sol


pragma solidity >=0.5.0;

/// @title Callback for IUniswapV3PoolActions#swap
/// @notice Any contract that calls IUniswapV3PoolActions#swap must implement this interface
interface IUniswapV3SwapCallback {
    /// @notice Called to `msg.sender` after executing a swap via IUniswapV3Pool#swap.
    /// @dev In the implementation you must pay the pool tokens owed for the swap.
    /// The caller of this method must be checked to be a UniswapV3Pool deployed by the canonical UniswapV3Factory.
    /// amount0Delta and amount1Delta can both be 0 if no tokens were swapped.
    /// @param amount0Delta The amount of token0 that was sent (negative) or must be received (positive) by the pool by
    /// the end of the swap. If positive, the callback must send that amount of token0 to the pool.
    /// @param amount1Delta The amount of token1 that was sent (negative) or must be received (positive) by the pool by
    /// the end of the swap. If positive, the callback must send that amount of token1 to the pool.
    /// @param data Any data passed through by the caller via the IUniswapV3PoolActions#swap call
    function uniswapV3SwapCallback(
        int256 amount0Delta,
        int256 amount1Delta,
        bytes calldata data
    ) external;
}

// File: @uniswap/v3-core/contracts/interfaces/callback/IUniswapV3MintCallback.sol


pragma solidity >=0.5.0;

/// @title Callback for IUniswapV3PoolActions#mint
/// @notice Any contract that calls IUniswapV3PoolActions#mint must implement this interface
interface IUniswapV3MintCallback {
    /// @notice Called to `msg.sender` after minting liquidity to a position from IUniswapV3Pool#mint.
    /// @dev In the implementation you must pay the pool tokens owed for the minted liquidity.
    /// The caller of this method must be checked to be a UniswapV3Pool deployed by the canonical UniswapV3Factory.
    /// @param amount0Owed The amount of token0 due to the pool for the minted liquidity
    /// @param amount1Owed The amount of token1 due to the pool for the minted liquidity
    /// @param data Any data passed through by the caller via the IUniswapV3PoolActions#mint call
    function uniswapV3MintCallback(
        uint256 amount0Owed,
        uint256 amount1Owed,
        bytes calldata data
    ) external;
}

// File: @openzeppelin/contracts/utils/math/Math.sol


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

// File: @openzeppelin/contracts/utils/Address.sol


// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly
                /// @solidity memory-safe-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// File: @openzeppelin/contracts/token/ERC20/extensions/draft-IERC20Permit.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/draft-IERC20Permit.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
interface IERC20Permit {
    /**
     * @dev Sets `value` as the allowance of `spender` over ``owner``'s tokens,
     * given ``owner``'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `deadline` must be a timestamp in the future.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments.
     * - the signature must use ``owner``'s current nonce (see {nonces}).
     *
     * For more information on the signature format, see the
     * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
     * section].
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @dev Returns the current nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases ``owner``'s nonce by one. This
     * prevents a signature from being used multiple times.
     */
    function nonces(address owner) external view returns (uint256);

    /**
     * @dev Returns the domain separator used in the encoding of the signature for {permit}, as defined by {EIP712}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);
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

// File: @openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol


// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;




/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    function safePermit(
        IERC20Permit token,
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal {
        uint256 nonceBefore = token.nonces(owner);
        token.permit(owner, spender, value, deadline, v, r, s);
        uint256 nonceAfter = token.nonces(owner);
        require(nonceAfter == nonceBefore + 1, "SafeERC20: permit did not succeed");
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// File: @openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;


/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

// File: @openzeppelin/contracts/token/ERC20/ERC20.sol


// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;




/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * NOTE: If `amount` is the maximum `uint256`, the allowance is not updated on
     * `transferFrom`. This is semantically equivalent to an infinite approval.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * NOTE: Does not update the allowance if the current allowance
     * is the maximum `uint256`.
     *
     * Requirements:
     *
     * - `from` and `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     * - the caller must have allowance for ``from``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, allowance(owner, spender) + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = allowance(owner, spender);
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `from` to `to`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     */
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
        }
        _balances[to] += amount;

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Updates `owner` s allowance for `spender` based on spent `amount`.
     *
     * Does not update the allowance amount in case of infinite allowance.
     * Revert if not enough allowance is available.
     *
     * Might emit an {Approval} event.
     */
    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}

// File: @openzeppelin/contracts/security/ReentrancyGuard.sol


// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// File: contracts/Booster03_Algebra.sol


// Copyright (c) 2021 TrinityLabDAO

// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:

// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.

// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.
pragma solidity 0.8.7;







//import "@uniswap/v3-core/contracts/interfaces/IUniswapV3Pool.sol";






/**
 * @title   Booster pool
 * @notice  A pool that provides liquidity on Uniswap V3.
 */
contract BoosterPool is
    IUniswapV3MintCallback,
    IUniswapV3SwapCallback,
    ERC20,
    ReentrancyGuard
{
    using SafeERC20 for IERC20;

    event OneAsset(
        address indexed token,
        uint256 amount
    );

    event Deposit(
        address indexed sender,
        address indexed to,
        uint256 shares,
        uint256 amount0,
        uint256 amount1
    );

    event Withdraw(
        address indexed sender,
        address indexed to,
        uint256 shares,
        uint256 amount0,
        uint256 amount1
    );

    /**
     * @notice The event is called when there is a collection of fees from a uniswap.
     * @param feesToPool0 users reward received in token 0
     * @param feesToPool1 users reward received in token 1
     * @param feesToTreasuryA0 protocol 'A' commission from earned reward received in token 0, will be stored in the 'Treasury A'
     * @param feesToTreasuryA1 protocol 'A' commission from earned reward received in token 1, will be stored in the 'Treasury A'
     * @param feesToTreasuryB0 protocol 'B' commission from earned reward received in token 0, will be stored in the 'Treasury B'
     * @param feesToTreasuryB1 protocol 'B' commission from earned reward received in token 1, will be stored in the 'Treasury B'
     */
    event CollectFees(
        uint256 feesToPool0,
        uint256 feesToPool1,
        uint256 feesToTreasuryA0,
        uint256 feesToTreasuryA1,
        uint256 feesToTreasuryB0,
        uint256 feesToTreasuryB1
    );
    
    //event Snapshot(int24 tick, uint256 totalAmount0, uint256 totalAmount1, uint256 totalSupply);

    /**
     * @notice Events that change key protocol variables
     */
    event AddressA(address oldAddress, address newAddress);
    event AddressB(address oldAddress, address newAddress);
    event ProtocolFeeA(uint256 oldProtocolFee, uint256 newProtocolFee);
    event ProtocolFeeB(uint256 oldProtocolFee, uint256 newProtocolFee);
    event PendingGovernance(address candidate);
    event Governance(address oldGovernance, address newGovernance);
    event Strategy(address oldStrategy, address newStrategy);
    /**
     * @notice Protocol deactivation event, after that only withdrawals work
     */
    event Deactivate();

    IAlgebraPool public immutable pool;
    IERC20 public immutable token0;
    IERC20 public immutable token1;
    int24 public immutable tickSpacing;

    address public governance;
    address public pendingGovernance;
    address public strategy;
    
    int24 public baseLower;
    int24 public baseUpper;

    address public addressA;
    address public addressB;
    uint256 public protocolFeeA;
    uint256 public protocolFeeB;

    uint256 public treasuryA0;
    uint256 public treasuryA1;

    uint256 public treasuryB0;
    uint256 public treasuryB1;

    bool public isDeactivated;

    /**
     * @param _pool Underlying Uniswap V3 pool
     * @param _addressB Address with access to Treasury A
     * @param _addressB Address with access to Treasury B
     * @param _protocolFeeA Protocol fee expressed as multiple of 1e-6, accumulates in the treasuryA
     * @param _protocolFeeB Protocol fee expressed as multiple of 1e-6, accumulates in the treasuryB
     * _protocolFeeA and _protocolFeeB in total must not exceed 1e-6
     * @param tokenName Token name
     * @param tokenSymbol Token symbol
     * @param _strategy Address that can rebalance 
     * @param _tickLower Position tick lower
     * @param _tickUpper Position tick upper
     */
    constructor(
        address _pool,
        address _addressA,
        address _addressB,
        uint256 _protocolFeeA,
        uint256 _protocolFeeB,
        string memory tokenName,
        string memory tokenSymbol,
        address _strategy,
        int24 _tickLower,
        int24 _tickUpper
    ) ERC20(tokenName, tokenSymbol) {
        pool = IAlgebraPool(_pool);
        token0 = IERC20(IAlgebraPool(_pool).token0());
        token1 = IERC20(IAlgebraPool(_pool).token1());
        int24 _tickSpacing = IAlgebraPool(_pool).tickSpacing();
        tickSpacing = _tickSpacing;

        governance = msg.sender;
        require(_strategy != address(0) && _strategy != address(this), "_strategy");
        strategy = _strategy;
        isDeactivated = false;
        require(_addressA != address(0) && _addressA != address(this), "_addressA");
        addressA = _addressA;
        require(_addressB != address(0) && _addressB != address(this), "_addressBto");
        addressB = _addressB;
        protocolFeeA = _protocolFeeA;
        protocolFeeB = _protocolFeeB; 
        require((_protocolFeeA + _protocolFeeB) < 1e6, "protocolFee");

         _checkRange(_tickLower, _tickUpper, _tickSpacing);
        baseLower = _tickLower;
        baseUpper = _tickUpper; 
    }

    //
    // EXTERNAL NON-VIEW
    //

    /**
     * @notice Deposit in one of two assets.
     * Part of the assets is exchanged in the Uniswap pool to obtain the required proportion.
     * Surplus will be returned to the user.
     * @dev The calculation uses the current price in the pool and
     * calculates the proportion for the deposit in a certain uniswap range at the initial moment.
     * The impact on the price and the proportion of the deposit is not taken into account, it only affects the size of the refund.
     * @param token Deposit token address
     * @param amount Max amount of token to deposit
     * @param to Recipient of shares
     * @return shares Number of shares minted
     * @return amount0 Amount of token0 deposited
     * @return amount1 Amount of token1 deposited
     */
    function depositOneAsset(
        address token,
        uint256 amount,
        address to
    ) external nonReentrant returns (uint256 shares, uint256 amount0, uint256 amount1){
        require(!isDeactivated, "deactivated"); 
        require(amount > 0 , "amount");
        require(token != address(0) && token != address(this), "token");
        require((address(token0) == token) || (address(token1) == token), "incorrect token");

        // Poke positions so vault's current holdings are up-to-date
        _poke(baseLower, baseUpper);

        //оценка
        (uint256 estimatedAmount0, uint256 estimatedAmount1) = estimatedAmountsForOneAsset(token, amount);

        uint256 startAmount0 = getBalance0();
        uint256 startAmount1 = getBalance1();

        //Transfer desired amount to contract
        IERC20(token).safeTransferFrom(msg.sender, address(this), amount);
        emit OneAsset(token, amount);

        if(address(token0) == token){
            if(estimatedAmount0 < estimatedAmount1)
                _sellExact(token, amount - estimatedAmount0, 0);
            else
                _buyExact(token, estimatedAmount1, 0);
        }else{
            if(amount0 < estimatedAmount1)
                _buyExact(token, estimatedAmount0, 0);
            else
                _sellExact(token, amount - estimatedAmount1, 0);
        }
        //calculation of the desired deposit amount after the swap
        //the deposit amount is the current balance of the contract minus the starting balance of the contract
        uint256 desiredAmount0 = getBalance0() - startAmount0;
        uint256 desiredAmount1 = getBalance1() - startAmount1;

        (shares, amount0, amount1) = _calcSharesAndAmounts(desiredAmount0, desiredAmount1, startAmount0, startAmount1);
        require(shares > 0, "shares to low");
        //the amount of assets that was not placed in the pool and will be returned to the sender
        uint256 refund0 = getBalance0() - startAmount0 - amount0;
        uint256 refund1 = getBalance1() - startAmount1 - amount1;

        if(refund0 > 0)
            token0.safeTransfer(msg.sender, refund0);
        if(refund1 > 0)
            token1.safeTransfer(msg.sender, refund1);
        // Mint shares to recipient
        _mint(to, shares);
        emit Deposit(msg.sender, to, shares, amount0, amount1);
        _reinvest(0, 0);
    }

    /**
     * @notice Deposits tokens in the current proportion of the uniswap pool in the set range.
     * @dev The user's tokens are immediately placed in the uniswap pool.
     * Also, along with this, there is a reinvestment of previously earned fees.
     * @param amount0Desired Max amount of token0 to deposit
     * @param amount1Desired Max amount of token1 to deposit
     * @param amount0Min Revert if resulting `amount0` is less than this
     * @param amount1Min Revert if resulting `amount1` is less than this
     * @param to Recipient of shares
     * @return shares Number of shares minted
     * @return amount0 Amount of token0 deposited
     * @return amount1 Amount of token1 deposited
     */
    function deposit(
        uint256 amount0Desired,
        uint256 amount1Desired,
        uint256 amount0Min,
        uint256 amount1Min,
        address to
    ) external nonReentrant returns (uint256 shares, uint256 amount0, uint256 amount1){
        require(!isDeactivated, "deactivated"); 
        require(amount0Desired > 0 || amount1Desired > 0, "amount0Desired or amount1Desired");
        require(to != address(0) && to != address(this), "to");

        // Poke positions so vault's current holdings are up-to-date
        _poke(baseLower, baseUpper);

        // Calculate amounts proportional to vault's holdings
        (shares, amount0, amount1) = _calcSharesAndAmounts(amount0Desired, amount1Desired, getBalance0(), getBalance1());
        require(shares > 0, "shares");
        require(amount0 >= amount0Min, "amount0Min");
        require(amount1 >= amount1Min, "amount1Min");

        // Pull in tokens from sender
        if (amount0 > 0) token0.safeTransferFrom(msg.sender, address(this), amount0);
        if (amount1 > 0) token1.safeTransferFrom(msg.sender, address(this), amount1);

        //Mint shares to recipient
        _mint(to, shares);
        emit Deposit(msg.sender, to, shares, amount0, amount1);
        _reinvest(0, 0);
    }

    function calcSharesAndAmounts(uint256 amount0Desired, uint256 amount1Desired)
        external
        returns (
            uint256 shares,
            uint256 amount0,
            uint256 amount1
        )
    {
        _poke(baseLower, baseUpper);
        (shares, amount0, amount1) = _calcSharesAndAmounts(amount0Desired, amount1Desired, getBalance0(), getBalance1());
    }

    /**
     * @notice Withdraws tokens in proportion to the position in Uniswap.
     * @dev The dust that remains when reinvesting fees is not used in the calculations.
     * The bot monitors the accumulation of dust and, if necessary, reinvests with a swap
     * @param shares Shares burned by sender
     * @param amount0Min Revert if resulting `amount0` is smaller than this
     * @param amount1Min Revert if resulting `amount1` is smaller than this
     * @param to Recipient of tokens
     * @return amount0 Amount of token0 sent to recipient
     * @return amount1 Amount of token1 sent to recipient
     */
    function withdraw(
        uint256 shares,
        uint256 amount0Min,
        uint256 amount1Min,
        address to
    ) external nonReentrant returns (uint256 amount0, uint256 amount1) {
        require(shares > 0, "shares");
        require(to != address(0) && to != address(this), "to");
        uint256 BPtotalSupply = totalSupply();

        // Burn shares
        _burn(msg.sender, shares);

        //if the pool is deactivated, then the assets are taken from the contract storage, in proportion to the boosterPool tokens
        if(isDeactivated){
            // Calculate token amounts proportional to unused balances
            amount0 = getBalance0() * shares / BPtotalSupply;
            amount1 = getBalance1() * shares / BPtotalSupply;
        } else {
            // Withdraw proportion of liquidity from Uniswap pool
            (amount0, amount1) = _burnLiquidityShare(baseLower, baseUpper, shares, BPtotalSupply);
        }

        require(amount0 >= amount0Min, "amount0Min");
        require(amount1 >= amount1Min, "amount1Min");

        // Push tokens to recipient
        if (amount0 > 0) token0.safeTransfer(to, amount0);
        if (amount1 > 0) token1.safeTransfer(to, amount1);

        emit Withdraw(msg.sender, to, shares, amount0, amount1);
    }

    /**
     * @notice The fees earned are withdrawn from Uniswap V3 
     * and the maximum possible liquidity is deposited into the position.
     * @param swapAmount the number of tokens to be exchanged. 
     * A positive or negative value indicates the direction of the swap 
     * (zeroForOne - The direction of the swap, true for token0 to token1, false for token1 to token0)
     * @param sqrtPriceLimitX96 - The Q64.96 sqrt price limit. If zero for one, the price cannot be less than this value after the swap. If one for zero, the price cannot be greater than this value after the swap
     */
    function reinvest(
        int256 swapAmount,
        uint160 sqrtPriceLimitX96
    ) external nonReentrant {
        require(!isDeactivated, "deactivated"); 
        require(msg.sender == strategy, "strategy");
        _poke(baseLower, baseUpper);
        _reinvest(swapAmount, sqrtPriceLimitX96);
    }

    /**
     * @notice Updates positions. Can only be called by the strategy.
     * @param swapAmount the number of tokens to be exchanged. 
     * A positive or negative value indicates the direction of the swap 
     * (zeroForOne - The direction of the swap, true for token0 to token1, false for token1 to token0)
     * @param sqrtPriceLimitX96 - The Q64.96 sqrt price limit. If zero for one, the price cannot be less than this value after the swap. If one for zero, the price cannot be greater than this value after the swap
     * @param tickLower new tick lower
     * @param tickUpper new tick upper
     */
    function rebalance(
        int256 swapAmount,
        uint160 sqrtPriceLimitX96,
        int24 tickLower,
        int24 tickUpper
    ) external nonReentrant {
        require(!isDeactivated, "deactivated"); 
        require(msg.sender == strategy, "strategy");   
        _checkRange(tickLower, tickUpper, tickSpacing);

        // Withdraw all current liquidity from Uniswap pool
        (uint128 baseLiquidity, , , , , ) = _position(baseLower, baseUpper);
        _burnAndCollect(baseLower, baseUpper, baseLiquidity);
        
        // swap and mint liquidity to position
        _swapAndMint(swapAmount, sqrtPriceLimitX96, tickLower, tickUpper);
        (baseLower, baseUpper) = (tickLower, tickUpper);
    }

    /**
     * @notice calculates how many assets token0 and token1 can be obtained for BP tokens
     * @dev used with static call in frontend
     * @param amountBP Amount of BP tokens for whom the calculation
     * @return amount0 computed value of token0
     * @return amount1 computed value of token1
     */
    function getTotalAmounts(uint256 amountBP)
        external
        returns(uint256 amount0, uint256 amount1)
    {
        uint256 BPtotalSupply = totalSupply();
        if(BPtotalSupply > 0){
            _poke(baseLower, baseUpper);
            (amount0,  amount1) = _getPositionAmounts();
            (amount0,  amount1) = ((amount0 * amountBP / BPtotalSupply), (amount1 * amountBP / BPtotalSupply));
        } else {
            (amount0,  amount1) = (0,0);
        }
    }

    /**
     * @notice Amounts of token0 and token1 in the Uniswap V3 pool to be collected
     * @return collect0 amount of accrued fees in token0
     * @return collect1 amount of accrued fees in token1
     */
    function collectPositionFees()
        external
        returns(uint256 collect0, uint256 collect1)
    {
        _poke(baseLower, baseUpper);
        (,,collect0, collect1) = _burnAndCollect(baseLower, baseUpper, 0);
    }

    /**
     * @notice Used to collect accumulated protocol fees from the treasury A.
     * @param amount0 amount token0 to the collect
     * @param amount1 amount token1 to the collect
     * @param to Recipient of tokens
     */
    function collectTreasuryA(
        uint256 amount0,
        uint256 amount1,
        address to
    ) external onlyAddressA {
        treasuryA0 = treasuryA0 - amount0;
        treasuryA1 = treasuryA1 - amount1;
        if (amount0 > 0) token0.safeTransfer(to, amount0);
        if (amount1 > 0) token1.safeTransfer(to, amount1);
    }

    /**
     * @notice Used to collect accumulated protocol fees from the treasury B.
     * @param amount0 amount token0 to the collect
     * @param amount1 amount token1 to the collect
     * @param to Recipient of tokens
     */
    function collectTreasuryB(
        uint256 amount0,
        uint256 amount1,
        address to
    ) external onlyAddressB {
        treasuryB0 = treasuryB0 - amount0;
        treasuryB1 = treasuryB1 - amount1;
        if (amount0 > 0) token0.safeTransfer(to, amount0);
        if (amount1 > 0) token1.safeTransfer(to, amount1);
    }

    /**
     * @notice Removes tokens accidentally sent to this vault.
     * @param token token to the sweep
     * @param amount amount to the sweep
     * @param to Recipient of tokens
     */
    function sweep(
        IERC20 token,
        uint256 amount,
        address to
    ) external onlyGovernance {
        require(token != token0 && token != token1, "token");
        token.safeTransfer(to, amount);
    }

    /**
     * @notice Used to set the strategy contract that determines the position
     * ranges and calls rebalance(). Must be called after this vault is
     * deployed.
     */
    function setStrategy(address newStrategy) external onlyGovernance {
        require(newStrategy != address(0) && newStrategy != address(this), "strategy");
        emit Strategy(strategy, newStrategy);
        strategy = newStrategy;
    }

    /**
     * @notice Setting a new address that will have access to Treasure A
     * @param newAddressA new address to use Treasury A
     */
    function setAddressA(address newAddressA) external onlyGovernance {
        require(newAddressA != address(0) && newAddressA != address(this), "addressA");
        emit AddressA(addressA, newAddressA);
        addressA = newAddressA;       
    }

    /**
     * @notice Setting a new address that will have access to Treasure B
     * @param newAddressB new address to use Treasury B
     */
    function setAddressB(address newAddressB) external onlyGovernance {
        require(newAddressB != address(0) && newAddressB != address(this), "addressB");
        emit AddressB(addressB, newAddressB);
        addressB = newAddressB;
    }

    /**
     * @notice Used to change the protocol fee charged on pool fees earned from
     * Uniswap, expressed as multiple of 1e-6.
     * @param newProtocolFeeA new fee value
     */
    function setProtocolFeeA(uint256 newProtocolFeeA) external onlyGovernance {
        require((newProtocolFeeA + protocolFeeB) < 1e6, "protocolFeeA");
        emit ProtocolFeeA(protocolFeeA, newProtocolFeeA);
        protocolFeeA = newProtocolFeeA;
    }

    /**
     * @notice Used to change the protocol fee charged on pool fees earned from
     * Uniswap, expressed as multiple of 1e-6.
     * @param newProtocolFeeB new fee value
     */
    function setProtocolFeeB(uint256 newProtocolFeeB) external onlyGovernance {
        require((newProtocolFeeB + protocolFeeA) < 1e6, "protocolFeeB");
        emit ProtocolFeeB(protocolFeeB, newProtocolFeeB);
        protocolFeeB = newProtocolFeeB;
    }

    /**
     * @notice The method disables the protocol, only the withdrawal of funds by users remains available.
     */
    function deactivateMode() external onlyGovernance {
        require(!isDeactivated, "deactivated"); 
        isDeactivated = true;
        (uint128 baseLiquidity, , , , , ) = _position(baseLower, baseUpper);
        _burnAndCollect(baseLower, baseUpper, baseLiquidity);
        emit Deactivate();
    }

    /**
     * @notice Governance address is not updated until the new governance
     * address has called `acceptGovernance()` to accept this responsibility.
     * @param newGovernance new governance address
     */
    function setGovernance(address newGovernance) external onlyGovernance {
        require(newGovernance != address(0) && newGovernance != address(this), "governance");
        pendingGovernance = newGovernance;
        emit PendingGovernance(pendingGovernance);
    }

    /**
     * @notice `setGovernance()` should be called by the existing governance
     * address prior to calling this function.
     */
    function acceptGovernance() external {
        require(msg.sender == pendingGovernance, "pendingGovernance");
        emit Governance(governance, msg.sender);
        governance = msg.sender;    
    }

    //
    // EXTERNAL VIEW
    //

    /**
     * @notice Calculates the estimated amounts to deposit in a uniswap V3 from one of asset.
     * @dev the calculation has assumptions in the values ​​of priceRatio and poolRatio,
     * does not take into account the impact of the swap on the price and proportion in the uniswap pool
     * x - deposit expressed in token0 
     * y - deposit expressed in token1 
     * pool_x, pool_y - proportion of assets in the pool
     * 
     *               x 
     * price_ratio = ―         - proportion of assets at the current price
     *               y
     *
     *              pool_x 
     * pool_ratio = ――――――     - proportion of assets in the pool
     *              pool_y
     *
     *                    x 
     * deposit_x = ―――――――――――――――
     *                 price_ratio 
     *             1 + ―――――――――――
     *                 pool_ratio
     *
     *             x - deposit_x
     * deposit_y = ―――――――――――――
     *              price_ratio
     *
     * @param token deposit token address
     * @param amount desired deposit amount
     * @return amount0 estimated Amount of token0
     * @return amount1 estimated Amount of token1
     */
    function estimatedAmountsForOneAsset(
        address token,
        uint256 amount
    ) public view returns (uint256 amount0, uint256 amount1){

        (uint160 sqrtPriceX96, , , , , , ) = pool.globalState();
        uint160 sqrtRatioAX96 = TickMath.getSqrtRatioAtTick(baseLower);
        uint160 sqrtRatioBX96 = TickMath.getSqrtRatioAtTick(baseUpper);
        uint256 calc_amount0;
        uint256 calc_amount1;
        if(address(token0) == token){
            calc_amount0 = amount;
            calc_amount1 = FullMath.mulDiv(amount, uint256(sqrtPriceX96) * uint256(sqrtPriceX96), 1 << 192);
        }else{
            calc_amount0 = FullMath.mulDiv(amount, 1 << 192, uint256(sqrtPriceX96) * uint256(sqrtPriceX96));
            calc_amount1 = amount;
        }

        require(calc_amount0 > 0 , "LA 0");
        require(calc_amount1 > 0 , "LA 1");

        (amount0, amount1) = LiquidityAmounts.getAmountsForLiquidity(
            sqrtPriceX96,
            sqrtRatioAX96,
            sqrtRatioBX96,
            1e18
        );

        amount0 = FullMath.mulDiv(calc_amount0 * amount0,
                            amount1 * calc_amount1,
                            amount1 * (calc_amount1 * amount0 + amount1 * calc_amount0));

        amount1 = FullMath.mulDiv(calc_amount0 - amount0,
                                calc_amount1,
                                calc_amount0);
    }

    /**
     * @notice Balance of token0 in vault not used in any position.
     */
    function getBalance0() public view returns (uint256) {
        return token0.balanceOf(address(this)) - treasuryA0 - treasuryB0;
    }

    /**
     * @notice Balance of token1 in vault not used in any position.
     */
    function getBalance1() public view returns (uint256) {
        return token1.balanceOf(address(this)) - treasuryA1 - treasuryB1;
    }

    //
    // UNISWAP V3 CALLBACKS
    //
    
    /// @dev Callback for Uniswap V3 pool.
    function uniswapV3MintCallback(
        uint256 amount0,
        uint256 amount1,
        bytes calldata data
    ) external override {
        require(msg.sender == address(pool));
        if (amount0 > 0) token0.safeTransfer(msg.sender, amount0);
        if (amount1 > 0) token1.safeTransfer(msg.sender, amount1);
    }

    /// @dev Callback for Uniswap V3 pool.
    function uniswapV3SwapCallback(
        int256 amount0Delta,
        int256 amount1Delta,
        bytes calldata data
    ) external override {
        require(msg.sender == address(pool));
        if (amount0Delta > 0) token0.safeTransfer(msg.sender, uint256(amount0Delta));
        if (amount1Delta > 0) token1.safeTransfer(msg.sender, uint256(amount1Delta));
    }

    //
    // INTERNAL
    //

    /// @dev Do zero-burns to poke a position on Uniswap so earned fees are
    /// updated. Should be called if total amounts needs to include up-to-date
    /// fees.
    function _poke(int24 tickLower, int24 tickUpper) internal {
        (uint128 liquidity, , , , , ) = _position(tickLower, tickUpper);
        if (liquidity > 0) {
            pool.burn(tickLower, tickUpper, 0);
        }
    }
    
    function _buyExact(
        address token,
        uint256 amountOut,
        uint160 sqrtPriceLimitX96
    ) internal returns (uint256 amountIn){
        bool zeroForOne = token == address(token0);
        (int256 amount0Delta, int256 amount1Delta) = pool.swap(
            address(this),
            zeroForOne,
            -int256(amountOut),
            sqrtPriceLimitX96 == 0
            ? (zeroForOne ? TickMath.MIN_SQRT_RATIO + 1 : TickMath.MAX_SQRT_RATIO - 1)
            : sqrtPriceLimitX96,
            ""
        );
        uint256 amountOutReceived;
        (amountIn, amountOutReceived) = zeroForOne
        ? (uint256(amount0Delta), uint256(-amount1Delta))
        : (uint256(amount1Delta), uint256(-amount0Delta));
        // it's technically possible to not receive the full output amount,
        // so if no price limit has been specified, require this possibility away
        if (sqrtPriceLimitX96 == 0) require(amountOutReceived == amountOut);
    }

    function _sellExact(
        address token,
        uint256 amountIn,
        uint160 sqrtPriceLimitX96
    ) internal returns (uint256 amountOut){
        bool zeroForOne = token == address(token0);
        (int256 amount0, int256 amount1) = pool.swap(
            address(this),
            zeroForOne,
            int256(amountIn),
            sqrtPriceLimitX96 == 0
            ? (zeroForOne ? TickMath.MIN_SQRT_RATIO + 1 : TickMath.MAX_SQRT_RATIO - 1)
            : sqrtPriceLimitX96,
            ""
        );
        return uint256(-(zeroForOne ? amount1 : amount0));
    }
    
    function _reinvest(
        int256 swapAmount,
        uint160 sqrtPriceLimitX96
    ) internal {
        _burnAndCollect(baseLower, baseUpper, 0);
        // swap and mint liquidity (fees) to position
        _swapAndMint(swapAmount, sqrtPriceLimitX96, baseLower, baseUpper);
    }

    function _swapAndMint(
        int256 swapAmount,
        uint160 sqrtPriceLimitX96,
        int24 _baseLower,
        int24 _baseUpper
    ) internal {
        if (swapAmount != 0) {
            pool.swap(
                address(this),
                swapAmount > 0,
                swapAmount > 0 ? swapAmount : -swapAmount,
                sqrtPriceLimitX96,
                ""
            );
        }
        // Place base order on Uniswap
        uint128 liquidity = _liquidityForAmounts(_baseLower, _baseUpper, getBalance0(), getBalance1());
        if (liquidity > 0) {
            pool.mint(address(this), address(this), _baseLower, _baseUpper, liquidity, "");
        }
    }

    /// @dev Withdraws share of liquidity in a range from Uniswap pool.
    function _burnLiquidityShare(
        int24 tickLower,
        int24 tickUpper,
        uint256 shares,
        uint256 BPtotalSupply
    ) internal returns (uint256 amount0, uint256 amount1) {
        (uint128 totalLiquidity, , , , , ) = _position(tickLower, tickUpper);
        uint256 liquidity = uint256(totalLiquidity) * shares / BPtotalSupply;

        if (liquidity > 0) {
            (uint256 burned0, uint256 burned1, uint256 fees0, uint256 fees1) =
                _burnAndCollect(tickLower, tickUpper, _toUint128(liquidity));

            // Add share of fees
            amount0 = burned0 + (fees0 * shares / BPtotalSupply);
            amount1 = burned1 + (fees1 * shares / BPtotalSupply);
        }
    }

    /// @dev Calculates the largest possible `amount0` and `amount1` such that
    /// they're in the same proportion as total amounts, but not greater than
    /// `desiredAmount0` and `desiredAmount1` respectively.
    function _calcSharesAndAmounts(uint256 desiredAmount0, uint256 desiredAmount1, uint256 contractBalance0, uint256 contractBalance1)
        internal view
        returns (
            uint256 shares,
            uint256 amount0,
            uint256 amount1
        )
    {
        uint128 liquidityUser = _liquidityForAmounts(baseLower, baseUpper, desiredAmount0, desiredAmount1);
        uint256 BPtotalSupply = totalSupply();

        uint128 liquidityTotal = _getTotalLiquidity(contractBalance0, contractBalance1);

        // If total supply > 0, vault can't be empty
        assert(BPtotalSupply == 0 || liquidityTotal > 0 );

        (amount0, amount1) = _amountsForLiquidity(baseLower, baseUpper, liquidityUser);
        //adding one penny due to loss during conversion 
        (amount0, amount1) = ((amount0 + 1), (amount1 + 1));
        if (BPtotalSupply == 0) {
            // For first deposit, just use the liquidity desired      
            shares = liquidityUser;
        } else {
            shares = uint256(liquidityUser) * BPtotalSupply / liquidityTotal;        
        }
    }

    function _checkRange(int24 tickLower, int24 tickUpper,  int24 _tickSpacing) internal pure {
        require(tickLower < tickUpper, "tickLower < tickUpper");
        require(tickLower >= TickMath.MIN_TICK, "tickLower too low");
        require(tickUpper <= TickMath.MAX_TICK, "tickUpper too high");
        require(tickLower % _tickSpacing == 0, "tickLower % tickSpacing");
        require(tickUpper % _tickSpacing == 0, "tickUpper % tickSpacing");
    }

    /// @dev Withdraws liquidity from a range and collects all fees in the
    /// process.
    function _burnAndCollect(
        int24 tickLower,
        int24 tickUpper,
        uint128 liquidity
    )
        internal
        returns (
            uint256 burned0,
            uint256 burned1,
            uint256 feesToPool0,
            uint256 feesToPool1
        )
    {
        if (liquidity > 0) {
            (burned0, burned1) = pool.burn(tickLower, tickUpper, liquidity);
        }

        // Collect all owed tokens including earned fees
        (uint256 collect0, uint256 collect1) =
            pool.collect(
                address(this),
                tickLower,
                tickUpper,
                type(uint128).max,
                type(uint128).max
            );

        feesToPool0 = collect0 - burned0;
        feesToPool1 = collect1 - burned1;

        uint256 feesToTreasuryA0 = 0;
        uint256 feesToTreasuryA1 = 0;
        uint256 feesToTreasuryB0 = 0;
        uint256 feesToTreasuryB1 = 0;

        if ((protocolFeeA + protocolFeeB) > 0) {        
            feesToTreasuryA0 = feesToPool0 * protocolFeeA / 1e6;
            feesToTreasuryA1 = feesToPool1 * protocolFeeA / 1e6;
            feesToTreasuryB0 = feesToPool0 * protocolFeeB / 1e6;
            feesToTreasuryB1 = feesToPool1 * protocolFeeB / 1e6;

            treasuryA0 = treasuryA0 + feesToTreasuryA0;
            treasuryA1 = treasuryA1 + feesToTreasuryA1;
            treasuryB0 = treasuryB0 + feesToTreasuryB0;
            treasuryB1 = treasuryB1 + feesToTreasuryB1;

            feesToPool0 = feesToPool0 - feesToTreasuryA0 - feesToTreasuryB0;
            feesToPool1 = feesToPool1 - feesToTreasuryA1 - feesToTreasuryB1;
        }
        emit CollectFees(feesToPool0, feesToPool1, feesToTreasuryA0, feesToTreasuryA1, feesToTreasuryB0, feesToTreasuryB1);
    }

    /**
    * @notice calculates the liquidity value in the Uniswap V3 pool, taking into account the accrued fee minus the protocol commission
    * @return liquidity Total liquidity in pool and booster contract
    */
    function _getTotalLiquidity(uint256 contractBalance0, uint256 contractBalance1) 
        internal view returns (uint128 liquidity) {

        (uint128 liquidityInPosition, , , , uint128 tokensOwed0, uint128 tokensOwed1) =
            _position(baseLower, baseUpper);
        uint256 oneMinusFee = uint256(1e6) - (protocolFeeA + protocolFeeB);

        uint256 fees0 = uint256(tokensOwed0) * oneMinusFee / 1e6;
        uint256 fees1 = uint256(tokensOwed1) * oneMinusFee / 1e6;
        uint256 amount0 = contractBalance0 + fees0;
        uint256 amount1 = contractBalance1 + fees1;

        uint128 liquidityToReinvest = _liquidityForAmounts(baseLower, baseUpper, amount0, amount1);
        //liquidity in position add liquidity from fees and contract balance
        liquidity = liquidityInPosition + liquidityToReinvest;
    }

    /**
     * @notice Amounts of token0 and token1 held in vault's position. Includes
     * owed fees but excludes the proportion of fees that will be paid to the
     * protocol. Doesn't include fees accrued since last poke.
     */
    function _getPositionAmounts()
        internal
        view
        returns (uint256 amount0, uint256 amount1)
    {
        (uint128 liquidity, , , , uint128 tokensOwed0, uint128 tokensOwed1) =
            _position(baseLower, baseUpper);
        (amount0, amount1) = _amountsForLiquidity(baseLower, baseUpper, liquidity);

        // Subtract protocol fees
        uint256 oneMinusFee = uint256(1e6) - (protocolFeeA + protocolFeeB);
        amount0 = amount0 + (uint256(tokensOwed0) * oneMinusFee / 1e6);
        amount1 = amount1 + (uint256(tokensOwed1) * oneMinusFee / 1e6);
    }

    /// @dev Wrapper around `IUniswapV3Pool.positions()`.
    function _position(int24 tickLower, int24 tickUpper)
        internal
        view
        returns (
            uint128,
            uint32, 
            uint256,
            uint256,
            uint128,
            uint128
        )
    {
        bytes32 positionKey = PositionKey.compute(address(this), tickLower, tickUpper);
        return pool.positions(positionKey);
    }

    /// @dev Wrapper around `LiquidityAmounts.getAmountsForLiquidity()`.
    function _amountsForLiquidity(
        int24 tickLower,
        int24 tickUpper,
        uint128 liquidity
    ) public view returns (uint256, uint256) {
        (uint160 sqrtRatioX96, , , , , , ) = pool.globalState();
        return
            LiquidityAmounts.getAmountsForLiquidity(
                sqrtRatioX96,
                TickMath.getSqrtRatioAtTick(tickLower),
                TickMath.getSqrtRatioAtTick(tickUpper),
                liquidity
            );
    }

    /// @dev Wrapper around `LiquidityAmounts.getLiquidityForAmounts()`.
    function _liquidityForAmounts(
        int24 tickLower,
        int24 tickUpper,
        uint256 amount0,
        uint256 amount1
    ) public view returns (uint128) {
        (uint160 sqrtRatioX96, , , , , , ) = pool.globalState();
        return
            LiquidityAmounts.getLiquidityForAmounts(
                sqrtRatioX96,
                TickMath.getSqrtRatioAtTick(tickLower),
                TickMath.getSqrtRatioAtTick(tickUpper),
                amount0,
                amount1
            );
    }

    /// @dev Casts uint256 to uint128 with overflow check.
    function _toUint128(uint256 x) internal pure returns (uint128) {
        assert(x <= type(uint128).max);
        return uint128(x);
    }

    //
    // MODIFIERS
    //

    modifier onlyGovernance {
        require(msg.sender == governance, "governance");
        _;
    }

    modifier onlyAddressA {
        require(msg.sender == addressA, "addressA");
        _;
    }

    modifier onlyAddressB {
        require(msg.sender == addressB, "addressB");
        _;
    }
}