// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.13;

type TickIndex is int24;
type Price is uint160; // Price is a 64X96 value.

/// @dev The minimum tick that may be passed to #getSqrtRatioAtTick computed from log base 1.0001 of 2**-128.
/// Tick indices are inclusive of the min tick.
int24 constant MIN_TICK = -887272;
/// @dev The maximum tick that may be passed to #getSqrtRatioAtTick computed from log base 1.0001 of 2**128
/// Tick indices are inclusive of the max tick.
int24 constant MAX_TICK = -MIN_TICK;
int24 constant NUM_TICKS = MAX_TICK - MIN_TICK;

/// @dev The minimum sqrt price we can have. Equivalent to toSqrtPrice(MIN_TICK). Inclusive.
uint160 constant MIN_SQRT_RATIO = 4295128739;
/// @dev The maximum sqrt price we can have. Equivalent to toSqrtPrice(MAX_TICK). Inclusive.
uint160 constant MAX_SQRT_RATIO = 1461446703485210103287273052203988822378723970342;

/// @dev Price versions of the above.
Price constant MIN_PRICE = Price.wrap(MIN_SQRT_RATIO);
Price constant MAX_PRICE = Price.wrap(MAX_SQRT_RATIO);

library TickLib {
    /// How to create a TickIndex for user facing functions
    function newTickIndex(int24 num) public pure returns (TickIndex res) {
        res = TickIndex.wrap(num);
        TickIndexImpl.validate(res);
    }
}

/**
 * @title TickIndex utilities and primarily tick to price conversions
 * @author UniswapV3 (https://github.com/Uniswap/v3-core/blob/main/contracts/libraries/TickMath.sol)
 * @notice Converts between square root of price and TickIndex for prices in the range of 2^-128 to 2^128.
 * Essentially Uniswap's GPL implementation of TickMath with very minor edits.
 **/
library TickIndexImpl {
    error TickIndexOutOfBounds();

    /// Ensure the tick index is in range.
    function validate(TickIndex ti) internal pure {
        int24 num = TickIndex.unwrap(ti);
        if (num > MAX_TICK || num < MIN_TICK) {
            revert TickIndexOutOfBounds();
        }
    }

    /// @notice Returns if the TickIndex is within the given range
    /// @dev This is inclusive on the lower end, and exclusive on the upper end like all Tick operations.
    function inRange(TickIndex self, TickIndex lower, TickIndex upper) internal pure returns (bool) {
        int24 num = TickIndex.unwrap(self);
        return (TickIndex.unwrap(lower) <= num) && (num < TickIndex.unwrap(upper));
    }

    /// Clamp tick index to be within range.
    function clamp(TickIndex self) internal pure returns (TickIndex) {
        int24 ti = TickIndex.unwrap(self);
        if (ti < MIN_TICK)
            return TickIndex.wrap(MIN_TICK);
        else if (ti > MAX_TICK)
            return TickIndex.wrap(MAX_TICK);
        else
            return self;
    }

    /// Decrements the TickIndex by 1
    function dec(TickIndex ti) internal pure returns (TickIndex) {
        int24 num = TickIndex.unwrap(ti);
        require(num > MIN_TICK);
        unchecked { return TickIndex.wrap(num - 1); }
    }

    /// Increments the TickIndex by 1
    function inc(TickIndex ti) internal pure returns (TickIndex) {
        int24 num = TickIndex.unwrap(ti);
        require(num < MAX_TICK);
        unchecked { return TickIndex.wrap(num + 1); }
    }

    /* Comparisons */

    /// Returns if self is less than other.
    function isLT(TickIndex self, TickIndex other) internal pure returns (bool) {
        return TickIndex.unwrap(self) < TickIndex.unwrap(other);
    }

    function isEq(TickIndex self, TickIndex other) internal pure returns (bool) {
        return TickIndex.unwrap(self) == TickIndex.unwrap(other);
    }


    /**
     * @notice Calculates sqrt(1.0001^tick) * 2^96
     * @dev Throws if |tick| > max tick
     * @param ti TickIndex wrapping a tick representing the price as 1.0001^tick.
     * @return sqrtP A Q64.96 representation of the sqrt of the price represented by the given tick.
     **/
    function toSqrtPrice(TickIndex ti) internal pure returns (Price sqrtP) {
        uint160 sqrtPriceX96;
        int256 tick = int256(TickIndex.unwrap(ti));
        uint256 absTick = tick < 0 ? uint256(-tick) : uint256(tick);
        require(absTick <= uint256(int256(MAX_TICK)), "TickIndexImpl:SqrtMax");

        // We first handle it as if it were a negative index to allow a later trick for the reciprocal.
        // Iteratively multiply by the precomputed Q128.128 of 1.0001 to various negative powers
        uint256 ratio = absTick & 0x1 != 0 ? 0xfffcb933bd6fad37aa2d162d1a594001 : 0x100000000000000000000000000000000;
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

        // Get the reciprocal if the index was positive.
        if (tick > 0) ratio = type(uint256).max / ratio;

        // This divides by 1<<32 rounding up to go from a Q128.128 to a Q128.96.
        // we then downcast because we know the result always fits within 160 bits due to our tick input constraint
        // we round up in the division so getTickAtSqrtRatio of the output price is always consistent
        unchecked { sqrtPriceX96 = uint160((ratio >> 32) + (uint32(ratio) == 0 ? 0 : 1)); }
        sqrtP = Price.wrap(sqrtPriceX96);
    }

    /**
     * @notice Calculates sqrt(1.0001^-tick) * 2^96
     * @dev Calls into toSqrtPrice. Not currently used.
     **/
    function toRecipSqrtPrice(TickIndex ti) internal pure returns (Price sqrtRecip) {
        TickIndex inv = TickIndex.wrap(-TickIndex.unwrap(ti));
        sqrtRecip = toSqrtPrice(inv);
        // This is surprisingly equally accurate afaik.
        // sqrtPriceX96 = uint160((1<< 192) / uint256(toSqrtPrice(ti)));
    }
}

library PriceImpl {
    function unwrap(Price self) internal pure returns (uint160) {
        return Price.unwrap(self);
    }

    /* Comparison functions */
    function eq(Price self, Price other) internal pure returns (bool) {
        return Price.unwrap(self) == Price.unwrap(other);
    }

    function gt(Price self, Price other) internal pure returns (bool) {
        return Price.unwrap(self) > Price.unwrap(other);
    }

    function gteq(Price self, Price other) internal pure returns (bool) {
        return Price.unwrap(self) >= Price.unwrap(other);
    }

    function lt(Price self, Price other) internal pure returns (bool) {
        return Price.unwrap(self) < Price.unwrap(other);
    }

    function lteq(Price self, Price other) internal pure returns (bool) {
        return Price.unwrap(self) <= Price.unwrap(other);
    }

    function max(Price self, Price other) internal pure returns (Price) {
        return unwrap(self) > unwrap(other) ? self : other;
    }
}

library SqrtPriceLib {
    error PriceOutOfBounds(uint160 sqrtPX96);

    function make(uint160 sqrtPX96) internal pure returns (Price sqrtP) {
        if (sqrtPX96 < MIN_SQRT_RATIO || MAX_SQRT_RATIO < sqrtPX96) {
            revert PriceOutOfBounds(sqrtPX96);
        }
        return Price.wrap(sqrtPX96);
    }

    /// @notice Calculates the greatest tick value such that getRatioAtTick(tick) <= ratio
    /// @dev Throws in case sqrtPriceX96 < MIN_SQRT_RATIO, as MIN_SQRT_RATIO is the lowest value getRatioAtTick may
    /// ever return.
    /// @param sqrtP A Q64.96 value representing the sqrt of the tick's price.
    /// @return ti The greatest tick whose price is less than or equal to the input price.
    function toTick(Price sqrtP) internal pure returns (TickIndex ti) {
        uint160 sqrtPriceX96 = Price.unwrap(sqrtP);
        // I believe the Uni requirement that sqrtPriceX96 < MAX_SQRT_RATIO is incorrect.
        // The toSqrtPrice function clearly goes to MAX_SQRT_RATIO.
        require(sqrtPriceX96 >= MIN_SQRT_RATIO && sqrtPriceX96 <= MAX_SQRT_RATIO, 'R');
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

        unchecked {
        int256 log_sqrt10001 = log_2 * 255738958999603826347141; // 128.128 number

        int24 tickLow = int24((log_sqrt10001 - 3402992956809132418596140100660247210) >> 128);
        int24 tickHi = int24((log_sqrt10001 + 291339464771989622907027621153398088495) >> 128);

        int24 tick = (tickLow == tickHi ?
                      tickLow :
                      (Price.unwrap(TickIndexImpl.toSqrtPrice(TickIndex.wrap(tickHi))) <= sqrtPriceX96 ?
                       tickHi : tickLow));
        ti = TickIndex.wrap(tick);
        TickIndexImpl.validate(ti);
        }
    }

    /// Determine if a price is within the range we operate the AMM in.
    function isValid(Price self) internal pure returns (bool) {
        uint160 num = Price.unwrap(self);
        return  MIN_SQRT_RATIO <= num && num < MAX_SQRT_RATIO;
    }
}