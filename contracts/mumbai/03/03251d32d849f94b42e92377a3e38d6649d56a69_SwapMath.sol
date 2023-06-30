// SPDX-License-Identifier: BSL-1.1
pragma solidity ^0.8.13;

// Types
import { Price, PriceImpl, MIN_PRICE, MAX_PRICE, MAX_SQRT_RATIO } from "Ticks/Tick.sol";
// Utils
import { X96, Q64X96 } from "Math/Ops.sol";
import { MathUtils } from "Math/Utils.sol";
import { FullMath } from "Math/FullMath.sol";
import { UnsafeMath } from "Math/UnsafeMath.sol";


library SwapMath {
    using PriceImpl for Price;

    /// @notice Calculate the new price resulting from additional X
    /// @dev We round up to minimize price impact of X.
    /// We should also be sure to clamp this result after, because it could be below MIN_PRICE.
    /// We want to compute L\sqrt(P) / (L + x\sqrt(P))
    /// If liq is 0, slippage is infinite, and we snap to the minimum valid price.
    /// @param x The amount of x being exchanged. If 0 this reverts.
    function calcNewPriceFromAddX(
        uint128 liq,
        Price oldSqrtPrice,
        uint256 x
    ) public pure returns (Price newSqrtPrice) {
        if (liq == 0) {
            return MIN_PRICE;
        }

        // We're adding x, pushing down the price, we need to round up the price.
        uint256 liqX96 = uint256(liq) << 96;
        uint160 rp = Price.unwrap(oldSqrtPrice);
        uint256 xrp;
        unchecked {
            xrp = x * rp;
        }
        if ((xrp / x) == rp) { // If we don't overflow
            uint256 denom;
            unchecked {
                denom = xrp + liqX96;
            }
            if (denom > liqX96) { // Check the denom hasn't overflowed
                // Will always fit since denom >= liqX96
                return Price.wrap(uint160(FullMath.mulDivRoundingUp(liqX96, rp, denom)));
            }
        }
        // This will also always fit since liqx96/rp is 64 bits.
        return Price.wrap(uint160(UnsafeMath.divRoundingUp(liqX96, (liqX96 / rp) + x)));
    }

    /// @notice Calculate the new price resulting from removing X
    /// @dev We round up to maximize price impact from removing X.
    /// We want to compute L\sqrt(P) / (L - x\sqrt(P))
    /// If liq is 0, slippage is infinite, and we snap to the maximum valid price.
    function calcNewPriceFromSubX(
        uint128 liq,
        Price oldSqrtPrice,
        uint256 x
    ) public pure returns (Price newSqrtPrice) {
        if (liq == 0) {
            return MAX_PRICE;
        }
        uint256 liqX96 = uint256(liq) << 96;

        // We're removing x, pushing up the price. They expect a certain amount of x out,
        // so we have to round up.
        uint160 rp = Price.unwrap(oldSqrtPrice);
        uint256 xrp;
        unchecked {
            xrp = x * rp;
        }
        if ((xrp / x) == rp) { // If we don't overflow
            uint256 shortDenom;
            unchecked {
                shortDenom = liqX96 - xrp;
            }
            if (shortDenom < liqX96) { // Check the denom hasn't underflowed
                // This might go over max price.
                uint256 newSP = FullMath.mulDivRoundingUp(liqX96, rp, shortDenom);
                // We don't need this check on the down side because swap clamps the result
                // afterwards anyways. But here we really use this check to make sure the result
                // fits in a uint160 which it won't in the extremes. If we're checking for that
                // we might as well just clamp here now, ergo compare to MAX_SQRT_RATIO.
                if (newSP > MAX_SQRT_RATIO) {
                    return MAX_PRICE;
                } else {
                    return Price.wrap(uint160(newSP));
                }
            }
        }

        // This tick doesn't have sufficient liquidity to support this move.
        // So we return MAX_PRICE hoping some other tick is sufficient.
        uint256 ratio = liqX96 / rp;
        if (ratio < x) {
            return MAX_PRICE;
        }
        uint256 denom;
        unchecked { // Already checked
            denom = ratio - x;
        }
        return Price.wrap(uint160(UnsafeMath.divRoundingUp(liqX96, denom)));
    }

    /// @notice Calculate the new price resulting from adding Y
    /// @dev We round down to minimize price impact of adding Y.
    /// We want to compute y / L + \sqrt(P).
    /// If liq is 0, slippage is infinite, and we snap to the maximum valid price.
    function calcNewPriceFromAddY(
        uint128 liq,
        Price oldSqrtPrice,
        uint256 y
    ) public pure returns (Price newSqrtPrice) {
        if (liq == 0) {
            return MAX_PRICE;
        }

        // We're adding y which buys x and pushes the price up. Round down to minimize x bought.
        uint256 rp = Price.unwrap(oldSqrtPrice); // 160, but used as 256 to save gas

        // If y is small enough, we don't have to resort to full division.
        uint256 delta = ((y <= type(uint160).max)
                         ? (y << 96) / liq
                         : FullMath.mulDiv(X96.SHIFT, y, liq));

        // If this ticks liquidity is insufficient and will send the price crazy high,
        // we return MAX_PRICE and hope some other tick's liquidity is sufficient.
        // That high price might not fit in a uint160 so we might as well compare to
        // MAX_SQRT_RATIO anyways, and return that if we're too high.
        uint256 newSP = delta + rp;
        if (newSP > MAX_SQRT_RATIO) {
            return MAX_PRICE;
        }
        return Price.wrap(uint160(newSP));
    }

    /// @notice Calculate the new price resulting from subtracing Y
    /// @dev We round down to maximize the price impact of removing Y.
    /// We want to compute \sqrt(P) - y / L.
    /// If liq is 0, slippage is infinite, and we snap to the minimum valid price.
    function calcNewPriceFromSubY(
        uint128 liq,
        Price oldSqrtPrice,
        uint256 y
    ) public pure returns (Price newSqrtPrice) {
        if (liq == 0) {
            return MIN_PRICE;
        }

        // We're adding y which buys x and pushes the price up. Round down to minimize x bought.
        uint256 rp = Price.unwrap(oldSqrtPrice); // 160, but used as 256 to save gas

        // If y is small enough, we don't have to resort to full division.
        uint256 delta = ((y <= type(uint160).max)
                         ? (y << 96) / liq
                         : FullMath.mulDiv(X96.SHIFT, y, liq));

        // This tick doesn't have sufficient liquidty to support this move.
        // But we return MIN_PRICE hoping another tick is sufficient.
        if (delta >= rp) {
            return MIN_PRICE;
        }
        unchecked {
            return Price.wrap(uint160(rp - delta));
        }
    }

    /// @notice Given a price change, determine the corresponding change in X in absolute terms.
    /// @dev We are computing L(\sqrt{p} - \sqrt{p'}) / \sqrt{pp'} where p > p'
    /// If this is called for a zero liquidity region, the returned delta is 0.
    function calcXFromPriceDelta(
        Price lowSP,
        Price highSP,
        uint128 liq,
        bool roundUp
    ) internal pure returns (uint256 deltaX) {
        if (liq == 0) {
            return 0;
        }

        uint160 pX96 = highSP.unwrap();
        uint160 ppX96 = lowSP.unwrap();
        if (pX96 < ppX96) {
            (pX96, ppX96) = (ppX96, pX96);
        }

        uint256 diffX96 = pX96 - ppX96;
        uint256 liqX96 = uint256(liq) << 96;
        if (roundUp) {
            return UnsafeMath.divRoundingUp(FullMath.mulDivRoundingUp(liqX96, diffX96, pX96), ppX96);
        } else {
            return FullMath.mulDiv(liqX96, diffX96, pX96) / ppX96;
        }
    }

    /// @notice Given a price change, determine the corresponding change in Y in absolute terms.
    /// @dev We are computing L(\sqrt{p'} - \sqrt{p}) where p' > p;
    /// If this is called for a zero liquidity region, the returned delta is 0.
    /// This differs slightly from the Uniswap version. It's cheaper and matches identically.
    function calcYFromPriceDelta(
        Price lowSP,
        Price highSP,
        uint128 liq,
        bool roundUp
    ) internal pure returns (uint256 deltaY) {
        if (liq == 0) {
            return 0;
        }

        uint160 pX96 = lowSP.unwrap();
        uint160 ppX96 = highSP.unwrap();
        if (ppX96 < pX96) {
            (pX96, ppX96) = (ppX96, pX96);
        }

        uint160 diffX96 = ppX96 - pX96;
        // We know this uses at most 128 bits and 160.
        return Q64X96.unsafeMul(diffX96, liq, roundUp);
    }
}

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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import { FullMath } from "Math/FullMath.sol";

library X32 {
    // Multiply two 256 bit numbers to a 512 number, but one of the 256's is X32.
    function mul512(uint256 a, uint256 b)
    internal pure returns (uint256 bot, uint256 top) {
        (uint256 rawB, uint256 rawT) = FullMath.mul512(a, b);
        bot = (rawB >> 32) + (rawT << 224);
        top = rawT >> 32;
    }
}

library X64 {
    // Multiply two 256 bit numbers to a 512 number, but one of the 256's is X32.
    function mul512(uint256 a, uint256 b)
    internal pure returns (uint256 bot, uint256 top) {
        (uint256 rawB, uint256 rawT) = FullMath.mul512(a, b);
        bot = (rawB >> 64) + (rawT << 192);
        top = rawT >> 64;
    }
}

/**
 * @notice Utility for Q64.96 operations
 **/
library Q64X96 {

    uint256 constant PRECISION = 96;

    uint256 constant SHIFT = 1 << 96;

    error Q64X96Overflow(uint160 a, uint256 b);

    /// Multiply an X96 precision number by an arbitrary uint256 number.
    /// Returns with the same precision as b.
    /// The result takes up 256 bits. Will error on overflow.
    function mul(uint160 a, uint256 b, bool roundUp) internal pure returns(uint256 res) {
        (uint256 bot, uint256 top) = FullMath.mul512(a, b);
        if ((top >> 96) > 0) {
            revert Q64X96Overflow(a, b);
        }
        assembly {
            res := add(shr(96, bot), shl(160, top))
        }
        if (roundUp && (bot % SHIFT > 0)) {
            res += 1;
        }
    }

    /// Same as the regular mul but without checking for overflow
    function unsafeMul(uint160 a, uint256 b, bool roundUp) internal pure returns(uint256 res) {
        (uint256 bot, uint256 top) = FullMath.mul512(a, b);
        assembly {
            res := add(shr(96, bot), shl(160, top))
        }
        if (roundUp) {
            uint256 modby = SHIFT;
            assembly {
                res := add(res, gt(mod(bot, modby), 0))
            }
        }
    }

    /// Divide a uint160 by a Q64X96 number.
    /// Returns with the same precision as num.
    /// @dev uint160 is chosen because once the 96 bits of precision are cancelled out,
    /// the result is at most 256 bits.
    function div(uint160 num, uint160 denom, bool roundUp)
    internal pure returns (uint256 res) {
        uint256 fullNum = uint256(num) << PRECISION;
        res = fullNum / denom;
        if (roundUp) {
            assembly {
                res := add(res, gt(fullNum, mul(res, denom)))
            }
        }
    }
}

library X96 {
    uint256 constant PRECISION = 96;
    uint256 constant SHIFT = 1 << 96;
}

library X128 {
    uint256 constant PRECISION = 128;

    uint256 constant SHIFT = 1 << 128;

    /// Multiply a 256 bit number by a 128 bit number. Either of which is X128.
    /// @dev This rounds results down.
    function mul256(uint128 a, uint256 b) internal pure returns (uint256) {
        (uint256 bot, uint256 top) = FullMath.mul512(a, b);
        return (bot >> 128) + (top << 128);
    }

    /// Multiply a 256 bit number by a 128 bit number. Either of which is X128.
    /// @dev This rounds results up.
    function mul256RoundUp(uint128 a, uint256 b) internal pure returns (uint256 res) {
        (uint256 bot, uint256 top) = FullMath.mul512(a, b);
        uint256 modmax = SHIFT;
        assembly {
            res := add(add(shr(128, bot), shl(128, top)), gt(mod(bot, modmax), 0))
        }
    }

    /// Multiply a 256 bit number by a 256 bit number, either of which is X128, to get 384 bits.
    /// @dev This rounds results down.
    /// @return bot The bottom 256 bits of the result.
    /// @return top The top 128 bits of the result.
    function mul512(uint256 a, uint256 b) internal pure returns (uint256 bot, uint256 top) {
        (uint256 _bot, uint256 _top) = FullMath.mul512(a, b);
        bot = (_bot >> 128) + (_top << 128);
        top = _top >> 128;
    }
}

/// Convenience library for interacting with Uint128s by other types.
library U128Ops {

    function add(uint128 self, int128 other) public pure returns (uint128) {
        if (other >= 0) {
            return self + uint128(other);
        } else {
            return self - uint128(-other);
        }
    }

    function sub(uint128 self, int128 other) public pure returns (uint128) {
        if (other >= 0) {
            return self - uint128(other);
        } else {
            return self + uint128(-other);
        }
    }
}

library U256Ops {
    function add(uint256 self, int256 other) public pure returns (uint256) {
        if (other >= 0) {
            return self + uint256(other);
        } else {
            return self - uint256(-other);
        }
    }

    function sub(uint256 self, uint256 other) public pure returns (int256) {
        if (other >= self) {
            uint256 temp = other - self;
            // Yes technically the max should be -type(int256).max but that's annoying to
            // get right and cheap for basically no benefit.
            require(temp <= uint256(type(int256).max));
            return -int256(temp);
        } else {
            uint256 temp = self - other;
            require(temp <= uint256(type(int256).max));
            return int256(temp);
        }
    }
}

// SPDX-License-Identifier: BSL-1.1
pragma solidity ^0.8.13;

library MathUtils {

    function abs(int256 self) internal pure returns (int256) {
        return self >= 0 ? self : -self;
    }

    /// @notice Calculates the square root of x using the Babylonian method.
    ///
    /// @dev See https://en.wikipedia.org/wiki/Methods_of_computing_square_roots#Babylonian_method.
    /// Copied from PRBMath: https://github.com/PaulRBerg/prb-math/blob/83b3a0dcd4aaca779d0632118772f00611340e79/src/Common.sol
    ///
    /// Notes:
    /// - If x is not a perfect square, the result is rounded down.
    /// - Credits to OpenZeppelin for the explanations in comments below.
    ///
    /// @param x The uint256 number for which to calculate the square root.
    /// @return result The result as a uint256.
    /// @custom:smtchecker abstract-function-nondet
    function sqrt(uint256 x) internal pure returns (uint256 result) {
        if (x == 0) {
            return 0;
        }

        // For our first guess, we calculate the biggest power of 2 which is smaller than the square root of x.
        //
        // We know that the "msb" (most significant bit) of x is a power of 2 such that we have:
        //
        // $$
        // msb(x) <= x <= 2*msb(x)$
        // $$
        //
        // We write $msb(x)$ as $2^k$, and we get:
        //
        // $$
        // k = log_2(x)
        // $$
        //
        // Thus, we can write the initial inequality as:
        //
        // $$
        // 2^{log_2(x)} <= x <= 2*2^{log_2(x)+1}
        // sqrt(2^k) <= sqrt(x) < sqrt(2^{k+1})
        // 2^{k/2} <= sqrt(x) < 2^{(k+1)/2} <= 2^{(k/2)+1}
        // $$
        //
        // Consequently, $2^{log_2(x) /2} is a good first approximation of sqrt(x) with at least one correct bit.
        uint256 xAux = uint256(x);
        result = 1;
        if (xAux >= 2 ** 128) {
            xAux >>= 128;
            result <<= 64;
        }
        if (xAux >= 2 ** 64) {
            xAux >>= 64;
            result <<= 32;
        }
        if (xAux >= 2 ** 32) {
            xAux >>= 32;
            result <<= 16;
        }
        if (xAux >= 2 ** 16) {
            xAux >>= 16;
            result <<= 8;
        }
        if (xAux >= 2 ** 8) {
            xAux >>= 8;
            result <<= 4;
        }
        if (xAux >= 2 ** 4) {
            xAux >>= 4;
            result <<= 2;
        }
        if (xAux >= 2 ** 2) {
            result <<= 1;
        }

        // At this point, `result` is an estimation with at least one bit of precision. We know the true value has at
        // most 128 bits, since it is the square root of a uint256. Newton's method converges quadratically (precision
        // doubles at every iteration). We thus need at most 7 iteration to turn our partial result with one bit of
        // precision into the expected uint128 result.
        unchecked {
            result = (result + x / result) >> 1;
            result = (result + x / result) >> 1;
            result = (result + x / result) >> 1;
            result = (result + x / result) >> 1;
            result = (result + x / result) >> 1;
            result = (result + x / result) >> 1;
            result = (result + x / result) >> 1;

            // If x is not a perfect square, round the result toward zero.
            uint256 roundedResult = x / result;
            if (result >= roundedResult) {
                result = roundedResult;
            }
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.4.0;

/// @title Contains 512-bit math functions
/// @author Uniswap Team
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
        uint256 twos = uint256(-int256(denominator)) & denominator;
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
        unchecked {
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
        }
        return result;
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
        result = mulDiv(a, b, denominator);
        if (mulmod(a, b, denominator) > 0) {
            require(result < type(uint256).max);
            result++;
        }
    }

    /// Calculates a 512 bit product of two 256 bit numbers.
    /// @return r0 The lower 256 bits of the result.
    /// @return r1 The higher 256 bits of the result.
    function mul512(uint256 a, uint256 b)
    internal pure returns(uint256 r0, uint256 r1) {
        assembly {
            let mm := mulmod(a, b, not(0))
            r0 := mul(a, b)
            r1 := sub(sub(mm, r0), lt(mm, r0))
        }
    }

    /// Short circuit mulDiv if the multiplicands don't overflow.
    /// Use this when you expect the input values to be small in most cases.
    /// @dev This charges an extra ~20 gas on top of the regular mulDiv if used, but otherwise costs 30 gas
    function shortMulDiv(
        uint256 m0,
        uint256 m1,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        uint256 num;
        unchecked {
            num = m0 * m1;
        }
        if (num / m0 == m1) {
            return num / denominator;
        } else {
            return mulDiv(m0, m1, denominator);
        }
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Math functions that do not check inputs or outputs
/// @notice Contains methods that perform common math functions but do not do any overflow or underflow checks
library UnsafeMath {
    /// @notice Returns ceil(x / y)
    /// @dev division by 0 returns 0
    /// @param x The dividend
    /// @param y The divisor
    /// @return z The quotient, ceil(x / y)
    function divRoundingUp(uint256 x, uint256 y) internal pure returns (uint256 z) {
        assembly {
            z := add(div(x, y), gt(mod(x, y), 0))
        }
    }
}