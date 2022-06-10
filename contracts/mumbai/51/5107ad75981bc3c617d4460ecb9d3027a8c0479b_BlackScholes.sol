//SPDX-License-Identifier: ISC
pragma solidity >=0.5.0 <=0.8.0;
pragma experimental ABIEncoderV2;

// Libraries
import "../synthetix/SignedSafeDecimalMath.sol";
import "../synthetix/SafeDecimalMath.sol";
import "./IBlackScholes.sol";

/**
 * @title BlackScholes
 * References Lyra for the black scholes implementation
 * https://github.com/lyra-finance/lyra-protocol/blob/master/contracts/BlackScholes.sol
 * @author SirenMarkets
 * @dev Contract to compute the black scholes price of options. Where the unit is unspecified, it should be treated as a
 * PRECISE_DECIMAL, which has 1e27 units of precision. The default decimal matches the ethereum standard of 1e18 units
 * of precision.
 */
contract BlackScholes is IBlackScholes {
    using SafeMath for uint256;
    using SafeDecimalMath for uint256;
    using SignedSafeMath for int256;
    using SignedSafeDecimalMath for int256;

    uint256 private constant SECONDS_PER_YEAR = 31536000;
    /// @dev Internally this library uses 27 decimals of precision
    uint256 private constant PRECISE_UNIT = 1e27;
    uint256 private constant LN_2_PRECISE = 693147180559945309417232122;
    uint256 private constant SQRT_TWOPI = 2506628274631000502415765285;
    /// @dev Below this value, return 0
    int256 private constant MIN_CDF_STD_DIST_INPUT =
        (int256(PRECISE_UNIT) * -45) / 10; // -4.5
    /// @dev Above this value, return 1
    int256 private constant MAX_CDF_STD_DIST_INPUT = int256(PRECISE_UNIT) * 10;
    /// @dev Below this value, the result is always 0
    int256 private constant MIN_EXP = -63 * int256(PRECISE_UNIT);
    /// @dev Above this value the a lot of precision is lost, and uint256s come close to not being able to handle the size
    uint256 private constant MAX_EXP = 100 * PRECISE_UNIT;
    /// @dev Value to use to avoid any division by 0 or values near 0
    uint256 private constant MIN_T_ANNUALISED = PRECISE_UNIT / SECONDS_PER_YEAR; // 1 second
    uint256 private constant MIN_VOLATILITY = PRECISE_UNIT / 10000; // 0.001%
    uint256 private constant VEGA_STANDARDISATION_MIN_DAYS = 7 days;

    /*
     * Math Operations
     */

    /**
     * @dev Returns absolute value of an int as a uint.
     */
    function abs(int256 x) public pure override returns (uint256) {
        return uint256(x < 0 ? -x : x);
    }

    /**
     * @dev Returns the floor of a PRECISE_UNIT (x - (x % 1e27))
     */
    function floor(uint256 x) internal pure returns (uint256) {
        return x - (x % PRECISE_UNIT);
    }

    /**
     * @dev Returns the natural log of the value using Halley's method.
     */
    function ln(uint256 x) internal pure returns (int256) {
        int256 res;
        int256 next;

        for (uint256 i = 0; i < 8; i++) {
            int256 e = int256(exp(res));
            next = res.add(
                (int256(x).sub(e).mul(2)).divideDecimalRoundPrecise(
                    int256(x).add(e)
                )
            );
            if (next == res) {
                break;
            }
            res = next;
        }

        return res;
    }

    /**
     * @dev Returns the exponent of the value using taylor expansion with range reduction.
     */
    function exp(uint256 x) public pure override returns (uint256) {
        if (x == 0) {
            return PRECISE_UNIT;
        }
        require(x <= MAX_EXP, "cannot handle exponents greater than 100");

        uint256 k = floor(x.divideDecimalRoundPrecise(LN_2_PRECISE)) /
            PRECISE_UNIT;
        uint256 p = 2**k;
        uint256 r = x.sub(k.mul(LN_2_PRECISE));

        uint256 _T = PRECISE_UNIT;

        uint256 lastT;
        for (uint8 i = 16; i > 0; i--) {
            _T = _T.multiplyDecimalRoundPrecise(r / i).add(PRECISE_UNIT);
            if (_T == lastT) {
                break;
            }
            lastT = _T;
        }

        return p.mul(_T);
    }

    /**
     * @dev Returns the exponent of the value using taylor expansion with range reduction, with support for negative
     * numbers.
     */
    function exp(int256 x) public pure override returns (uint256) {
        if (0 <= x) {
            return exp(uint256(x));
        } else if (x < MIN_EXP) {
            // exp(-63) < 1e-27, so we just return 0
            return 0;
        } else {
            return PRECISE_UNIT.divideDecimalRoundPrecise(exp(uint256(-x)));
        }
    }

    /**
     * @dev Returns the square root of the value using Newton's method. This ignores the unit, so numbers should be
     * multiplied by their unit before being passed in.
     */
    function sqrt(uint256 x) public pure override returns (uint256 y) {
        uint256 z = (x.add(1)) / 2;
        y = x;
        while (z < y) {
            y = z;
            z = (x / z + z) / 2;
        }
    }

    /**
     * @dev Returns the square root of the value using Newton's method.
     */
    function sqrtPrecise(uint256 x) internal pure returns (uint256) {
        // Add in an extra unit factor for the square root to gobble;
        // otherwise, sqrt(x * UNIT) = sqrt(x) * sqrt(UNIT)
        return sqrt(x.mul(PRECISE_UNIT));
    }

    /**
     * @dev The standard normal distribution of the value.
     */
    function stdNormal(int256 x) internal pure returns (uint256) {
        return
            exp(-x.multiplyDecimalRoundPrecise(x / 2))
                .divideDecimalRoundPrecise(SQRT_TWOPI);
    }

    /*
     * @dev The standard normal cumulative distribution of the value. Only has to operate precisely between -1 and 1 for
     * the calculation of option prices, but handles up to -4 with good accuracy.
     */
    function stdNormalCDF(int256 x) internal pure returns (uint256) {
        // Based on testing, errors are ~0.1% at -4, which is still acceptable; and around 0.3% at -4.5.
        // This function seems to become increasingly inaccurate past -5 ( >%5 inaccuracy)
        // At that range, the values are so low at that we will return 0, as it won't affect any usage of this value.
        if (x < MIN_CDF_STD_DIST_INPUT) {
            return 0;
        }

        // Past 10, this will always return 1 at the level of precision we are using
        if (x > MAX_CDF_STD_DIST_INPUT) {
            return PRECISE_UNIT;
        }

        int256 t1 = int256(1e7 + int256((2315419 * abs(x)) / PRECISE_UNIT));
        uint256 exponent = uint256(x.multiplyDecimalRoundPrecise(x / 2));
        int256 d = int256((3989423 * PRECISE_UNIT) / exp(exponent));
        uint256 prob = uint256(
            (d *
                (3193815 +
                    ((-3565638 +
                        ((17814780 +
                            ((-18212560 + (13302740 * 1e7) / t1) * 1e7) /
                            t1) * 1e7) /
                        t1) * 1e7) /
                    t1) *
                1e7) / t1
        );
        if (x > 0) prob = 1e14 - prob;
        return (PRECISE_UNIT * prob) / 1e14;
    }

    /**
     * @dev Converts an integer number of seconds to a fractional number of years.
     */
    function annualise(uint256 secs)
        internal
        pure
        returns (uint256 yearFraction)
    {
        return secs.divideDecimalRoundPrecise(SECONDS_PER_YEAR);
    }

    /*
     * Black Scholes and option prices
     */

    /**
     * @dev Returns internal coefficients of the Black-Scholes call price formula, d1 and d2.
     * @param tAnnualised Number of years to expiry
     * @param volatility Implied volatility over the period til expiry as a percentage
     * @param spot The current price of the base asset
     * @param strike The strike price of the option
     * @param rate The percentage risk free rate + carry cost
     */
    function d1d2(
        uint256 tAnnualised,
        uint256 volatility,
        uint256 spot,
        uint256 strike,
        int256 rate
    ) internal pure returns (int256 d1, int256 d2) {
        // Set minimum values for tAnnualised and volatility to not break computation in extreme scenarios
        // These values will result in option prices reflecting only the difference in stock/strike, which is expected.
        // This should be caught before calling this function, however the function shouldn't break if the values are 0.
        tAnnualised = tAnnualised < MIN_T_ANNUALISED
            ? MIN_T_ANNUALISED
            : tAnnualised;
        volatility = volatility < MIN_VOLATILITY ? MIN_VOLATILITY : volatility;

        int256 vtSqrt = int256(
            volatility.multiplyDecimalRoundPrecise(sqrtPrecise(tAnnualised))
        );
        int256 log = ln(spot.divideDecimalRoundPrecise(strike));
        int256 v2t = int256(
            volatility.multiplyDecimalRoundPrecise(volatility) / 2
        ).add(rate).multiplyDecimalRoundPrecise(int256(tAnnualised));
        d1 = log.add(v2t).divideDecimalRoundPrecise(vtSqrt);
        d2 = d1.sub(vtSqrt);
    }

    /**
     * @dev Internal coefficients of the Black-Scholes call price formula.
     * @param tAnnualised Number of years to expiry
     * @param spot The current price of the base asset
     * @param strike The strike price of the option
     * @param rate The percentage risk free rate + carry cost
     * @param d1 Internal coefficient of Black-Scholes
     * @param d2 Internal coefficient of Black-Scholes
     */
    function _optionPrices(
        uint256 tAnnualised,
        uint256 spot,
        uint256 strike,
        int256 rate,
        int256 d1,
        int256 d2
    ) internal pure returns (uint256 call, uint256 put) {
        uint256 strikePV = strike.multiplyDecimalRoundPrecise(
            exp(-rate.multiplyDecimalRoundPrecise(int256(tAnnualised)))
        );
        uint256 spotNd1 = spot.multiplyDecimalRoundPrecise(stdNormalCDF(d1));
        uint256 strikeNd2 = strikePV.multiplyDecimalRoundPrecise(
            stdNormalCDF(d2)
        );

        // We clamp to zero if the minuend is less than the subtrahend
        // In some scenarios it may be better to compute put price instead and derive call from it depending on which way
        // around is more precise.
        call = strikeNd2 <= spotNd1 ? spotNd1.sub(strikeNd2) : 0;
        put = call.add(strikePV);
        put = spot <= put ? put.sub(spot) : 0;
    }

    /**
     * @dev Returns call and put prices for options with given parameters.
     * @param timeToExpirySec Number of seconds to the expiry of the option
     * @param volatilityDecimal Implied volatility over the period til expiry as a percentage( we calculate our volatilty and it is returned with 8
     *                          decimals so we need to update it to be the correct format for blackscholes
     * @param spotDecimal The current price of the base asset
     * @param strikeDecimal The strike price of the option
     * @param rateDecimal The percentage risk free rate + carry cost
     */
    function optionPrices(
        uint256 timeToExpirySec,
        uint256 volatilityDecimal,
        uint256 spotDecimal,
        uint256 strikeDecimal,
        int256 rateDecimal
    ) external view override returns (uint256 call, uint256 put) {
        uint256 tAnnualised = annualise(timeToExpirySec);
        uint256 spotPrecise = spotDecimal.decimalToPreciseDecimal();
        uint256 strikePrecise = strikeDecimal.decimalToPreciseDecimal();
        int256 ratePrecise = rateDecimal.decimalToPreciseDecimal();
        (int256 d1, int256 d2) = d1d2(
            tAnnualised,
            volatilityDecimal.decimalToPreciseDecimal(),
            spotPrecise,
            strikePrecise,
            ratePrecise
        );

        (call, put) = _optionPrices(
            tAnnualised,
            spotPrecise,
            strikePrecise,
            ratePrecise,
            d1,
            d2
        );
        return (call.preciseDecimalToDecimal(), put.preciseDecimalToDecimal());
    }

    /**
     * @dev Returns call and put prices for options with given parameters.
     * @param timeToExpirySec Number of seconds to the expiry of the option
     * @param volatilityDecimal Implied volatility over the period til expiry as a percentage( we calculate our volatilty and it is returned with 8
     *                          decimals so we need to update it to be the correct format for blackscholes
     * @param spotDecimal The current price of the base asset
     * @param strikeDecimal The strike price of the option
     * @param rateDecimal The percentage risk free rate + carry cost
     */
    function optionPricesInUnderlying(
        uint256 timeToExpirySec,
        uint256 volatilityDecimal,
        uint256 spotDecimal,
        uint256 strikeDecimal,
        int256 rateDecimal
    ) external view override returns (uint256 call, uint256 put) {
        uint256 tAnnualised = annualise(timeToExpirySec);
        uint256 spotPrecise = spotDecimal.decimalToPreciseDecimal();
        uint256 strikePrecise = strikeDecimal.decimalToPreciseDecimal();
        int256 ratePrecise = rateDecimal.decimalToPreciseDecimal();
        (int256 d1, int256 d2) = d1d2(
            tAnnualised,
            volatilityDecimal.decimalToPreciseDecimal(),
            spotPrecise,
            strikePrecise,
            ratePrecise
        );

        (call, put) = _optionPrices(
            tAnnualised,
            spotPrecise,
            strikePrecise,
            ratePrecise,
            d1,
            d2
        );
        call = call.divideDecimalRoundPrecise(spotPrecise);
        put = put.divideDecimalRoundPrecise(spotPrecise);

        return (call.preciseDecimalToDecimal(), put.preciseDecimalToDecimal());
    }

    /*.000246212471428571
     * Greeks
     */

    /**
     * @dev Returns the option's delta value
     * @param d1 Internal coefficient of Black-Scholes
     */
    function _delta(int256 d1)
        internal
        pure
        returns (int256 callDelta, int256 putDelta)
    {
        callDelta = int256(stdNormalCDF(d1));
        putDelta = callDelta - int256(PRECISE_UNIT);
    }

    /**
     * @dev Returns the option's vega value based on d1
     *
     * @param d1 Internal coefficient of Black-Scholes
     * @param tAnnualised Number of years to expiry
     * @param spot The current price of the base asset
     */
    function _vega(
        uint256 tAnnualised,
        uint256 spot,
        int256 d1
    ) internal pure returns (uint256 vega) {
        return
            sqrtPrecise(tAnnualised).multiplyDecimalRoundPrecise(
                stdNormal(d1).multiplyDecimalRoundPrecise(spot)
            );
    }

    /**
     * @dev Returns the option's vega value with expiry modified to be at least VEGA_STANDARDISATION_MIN_DAYS
     * @param d1 Internal coefficient of Black-Scholes
     * @param spot The current price of the base asset
     * @param timeToExpirySec Number of seconds to expiry
     */
    function _standardVega(
        int256 d1,
        uint256 spot,
        uint256 timeToExpirySec
    ) internal pure returns (uint256) {
        uint256 tAnnualised = annualise(timeToExpirySec);

        timeToExpirySec = timeToExpirySec < VEGA_STANDARDISATION_MIN_DAYS
            ? VEGA_STANDARDISATION_MIN_DAYS
            : timeToExpirySec;
        uint256 daysToExpiry = (timeToExpirySec.mul(PRECISE_UNIT)) / 1 days;
        uint256 thirty = 30 * PRECISE_UNIT;
        uint256 normalisationFactor = sqrtPrecise(
            thirty.divideDecimalRoundPrecise(daysToExpiry)
        ).div(100);
        return
            _vega(tAnnualised, spot, d1)
                .multiplyDecimalRoundPrecise(normalisationFactor)
                .preciseDecimalToDecimal();
    }

    /**
     * @dev Returns call/put prices and delta/stdVega for options with given parameters.
     * @param timeToExpirySec Number of seconds to the expiry of the option
     * @param volatilityDecimal Implied volatility over the period til expiry as a percentage
     * @param spotDecimal The current price of the base asset
     * @param strikeDecimal The strike price of the option
     * @param rateDecimal The percentage risk free rate + carry cost
     */
    function pricesDeltaStdVega(
        uint256 timeToExpirySec,
        uint256 volatilityDecimal,
        uint256 spotDecimal,
        uint256 strikeDecimal,
        int256 rateDecimal
    ) external pure override returns (IBlackScholes.PricesDeltaStdVega memory) {
        uint256 tAnnualised = annualise(timeToExpirySec);
        uint256 spotPrecise = spotDecimal.decimalToPreciseDecimal();

        (int256 d1, int256 d2) = d1d2(
            tAnnualised,
            volatilityDecimal.decimalToPreciseDecimal(),
            spotPrecise,
            strikeDecimal.decimalToPreciseDecimal(),
            rateDecimal.decimalToPreciseDecimal()
        );
        (uint256 callPrice, uint256 putPrice) = _optionPrices(
            tAnnualised,
            spotPrecise,
            strikeDecimal.decimalToPreciseDecimal(),
            rateDecimal.decimalToPreciseDecimal(),
            d1,
            d2
        );
        uint256 v = _standardVega(d1, spotPrecise, timeToExpirySec);
        (int256 callDelta, int256 putDelta) = _delta(d1);

        return
            IBlackScholes.PricesDeltaStdVega(
                callPrice.preciseDecimalToDecimal(),
                putPrice.preciseDecimalToDecimal(),
                callDelta.preciseDecimalToDecimal(),
                putDelta.preciseDecimalToDecimal(),
                v
            );
    }

    /**
     * @dev Returns call/put prices for options with given parameters.
     * @param timeToExpirySec Number of seconds to the expiry of the option
     * @param volatilityDecimal Implied volatility over the period til expiry as a percentage
     * @param spotDecimal The current price of the base asset
     * @param strikeDecimal The strike price of the option
     * @param rateDecimal The percentage risk free rate + carry cost
     * @param isPut is the call a put or a call
     */
    function pricesStdVegaInUnderlying(
        uint256 timeToExpirySec,
        uint256 volatilityDecimal,
        uint256 spotDecimal,
        uint256 strikeDecimal,
        int256 rateDecimal,
        bool isPut
    ) external pure override returns (IBlackScholes.PricesStdVega memory) {
        uint256 tAnnualised = annualise(timeToExpirySec);
        uint256 spotPrecise = spotDecimal.decimalToPreciseDecimal();

        (int256 d1, int256 d2) = d1d2(
            tAnnualised,
            volatilityDecimal.decimalToPreciseDecimal(),
            spotPrecise,
            strikeDecimal.decimalToPreciseDecimal(),
            rateDecimal.decimalToPreciseDecimal()
        );

        //uint256 v = _standardVega(d1, spotPrecise, timeToExpirySec);
        uint256 v = _vega(tAnnualised, spotPrecise, d1)
            .divideDecimalRoundPrecise(spotPrecise);

        uint256 price;
        {
            (uint256 call, uint256 put) = _optionPrices(
                tAnnualised,
                spotPrecise,
                strikeDecimal.decimalToPreciseDecimal(),
                rateDecimal.decimalToPreciseDecimal(),
                d1,
                d2
            );
            if (isPut) {
                price = put.divideDecimalRoundPrecise(spotPrecise);
            } else {
                price = call.divideDecimalRoundPrecise(spotPrecise);
            }
        }
        return
            IBlackScholes.PricesStdVega(
                price.preciseDecimalToDecimal(),
                v.preciseDecimalToDecimal()
            );
    }
}

//SPDX-License-Identifier: MIT
//MIT License
//
//Copyright (c) 2019 Synthetix
//
//Permission is hereby granted, free of charge, to any person obtaining a copy
//of this software and associated documentation files (the "Software"), to deal
//in the Software without restriction, including without limitation the rights
//to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//copies of the Software, and to permit persons to whom the Software is
//furnished to do so, subject to the following conditions:
//
//The above copyright notice and this permission notice shall be included in all
//copies or substantial portions of the Software.
//
//THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
//SOFTWARE.

pragma solidity >=0.5.0 <=0.8.0;

// Libraries

import "@openzeppelin/contracts-ethereum-package/contracts/math/SignedSafeMath.sol";

// https://docs.synthetix.io/contracts/source/libraries/safedecimalmath
library SignedSafeDecimalMath {
    using SignedSafeMath for int256;

    /* Number of decimal places in the representations. */
    uint8 public constant decimals = 18;
    uint8 public constant highPrecisionDecimals = 27;

    /* The number representing 1.0. */
    int256 public constant UNIT = int256(10**uint256(decimals));

    /* The number representing 1.0 for higher fidelity numbers. */
    int256 public constant PRECISE_UNIT =
        int256(10**uint256(highPrecisionDecimals));
    int256 private constant UNIT_TO_HIGH_PRECISION_CONVERSION_FACTOR =
        int256(10**uint256(highPrecisionDecimals - decimals));

    /**
     * @return Provides an interface to UNIT.
     */
    function unit() external pure returns (int256) {
        return UNIT;
    }

    /**
     * @return Provides an interface to PRECISE_UNIT.
     */
    function preciseUnit() external pure returns (int256) {
        return PRECISE_UNIT;
    }

    /**
     * @return The result of multiplying x and y, interpreting the operands as fixed-point
     * decimals.
     *
     * @dev A unit factor is divided out after the product of x and y is evaluated,
     * so that product must be less than 2**256. As this is an integer division,
     * the internal division always rounds down. This helps save on gas. Rounding
     * is more expensive on gas.
     */
    function multiplyDecimal(int256 x, int256 y)
        internal
        pure
        returns (int256)
    {
        /* Divide by UNIT to remove the extra factor introduced by the product. */
        return x.mul(y) / UNIT;
    }

    /**
     * @return The result of safely multiplying x and y, interpreting the operands
     * as fixed-point decimals of the specified precision unit.
     *
     * @dev The operands should be in the form of a the specified unit factor which will be
     * divided out after the product of x and y is evaluated, so that product must be
     * less than 2**256.
     *
     * Unlike multiplyDecimal, this function rounds the result to the nearest increment.
     * Rounding is useful when you need to retain fidelity for small decimal numbers
     * (eg. small fractions or percentages).
     */
    function _multiplyDecimalRound(
        int256 x,
        int256 y,
        int256 precisionUnit
    ) private pure returns (int256) {
        /* Divide by UNIT to remove the extra factor introduced by the product. */
        int256 quotientTimesTen = x.mul(y) / (precisionUnit / 10);

        if (quotientTimesTen % 10 >= 5) {
            quotientTimesTen += 10;
        }

        return quotientTimesTen / 10;
    }

    /**
     * @return The result of safely multiplying x and y, interpreting the operands
     * as fixed-point decimals of a precise unit.
     *
     * @dev The operands should be in the precise unit factor which will be
     * divided out after the product of x and y is evaluated, so that product must be
     * less than 2**256.
     *
     * Unlike multiplyDecimal, this function rounds the result to the nearest increment.
     * Rounding is useful when you need to retain fidelity for small decimal numbers
     * (eg. small fractions or percentages).
     */
    function multiplyDecimalRoundPrecise(int256 x, int256 y)
        internal
        pure
        returns (int256)
    {
        return _multiplyDecimalRound(x, y, PRECISE_UNIT);
    }

    /**
     * @return The result of safely multiplying x and y, interpreting the operands
     * as fixed-point decimals of a standard unit.
     *
     * @dev The operands should be in the standard unit factor which will be
     * divided out after the product of x and y is evaluated, so that product must be
     * less than 2**256.
     *
     * Unlike multiplyDecimal, this function rounds the result to the nearest increment.
     * Rounding is useful when you need to retain fidelity for small decimal numbers
     * (eg. small fractions or percentages).
     */
    function multiplyDecimalRound(int256 x, int256 y)
        internal
        pure
        returns (int256)
    {
        return _multiplyDecimalRound(x, y, UNIT);
    }

    /**
     * @return The result of safely dividing x and y. The return value is a high
     * precision decimal.
     *
     * @dev y is divided after the product of x and the standard precision unit
     * is evaluated, so the product of x and UNIT must be less than 2**256. As
     * this is an integer division, the result is always rounded down.
     * This helps save on gas. Rounding is more expensive on gas.
     */
    function divideDecimal(int256 x, int256 y) internal pure returns (int256) {
        /* Reintroduce the UNIT factor that will be divided out by y. */
        return x.mul(UNIT).div(y);
    }

    /**
     * @return The result of safely dividing x and y. The return value is as a rounded
     * decimal in the precision unit specified in the parameter.
     *
     * @dev y is divided after the product of x and the specified precision unit
     * is evaluated, so the product of x and the specified precision unit must
     * be less than 2**256. The result is rounded to the nearest increment.
     */
    function _divideDecimalRound(
        int256 x,
        int256 y,
        int256 precisionUnit
    ) private pure returns (int256) {
        int256 resultTimesTen = x.mul(precisionUnit * 10).div(y);

        if (resultTimesTen % 10 >= 5) {
            resultTimesTen += 10;
        }

        return resultTimesTen / 10;
    }

    /**
     * @return The result of safely dividing x and y. The return value is as a rounded
     * standard precision decimal.
     *
     * @dev y is divided after the product of x and the standard precision unit
     * is evaluated, so the product of x and the standard precision unit must
     * be less than 2**256. The result is rounded to the nearest increment.
     */
    function divideDecimalRound(int256 x, int256 y)
        internal
        pure
        returns (int256)
    {
        return _divideDecimalRound(x, y, UNIT);
    }

    /**
     * @return The result of safely dividing x and y. The return value is as a rounded
     * high precision decimal.
     *
     * @dev y is divided after the product of x and the high precision unit
     * is evaluated, so the product of x and the high precision unit must
     * be less than 2**256. The result is rounded to the nearest increment.
     */
    function divideDecimalRoundPrecise(int256 x, int256 y)
        internal
        pure
        returns (int256)
    {
        return _divideDecimalRound(x, y, PRECISE_UNIT);
    }

    /**
     * @dev Convert a standard decimal representation to a high precision one.
     */
    function decimalToPreciseDecimal(int256 i) internal pure returns (int256) {
        return i.mul(UNIT_TO_HIGH_PRECISION_CONVERSION_FACTOR);
    }

    /**
     * @dev Convert a high precision decimal to a standard decimal representation.
     */
    function preciseDecimalToDecimal(int256 i) internal pure returns (int256) {
        int256 quotientTimesTen = i /
            (UNIT_TO_HIGH_PRECISION_CONVERSION_FACTOR / 10);

        if (quotientTimesTen % 10 >= 5) {
            quotientTimesTen += 10;
        }

        return quotientTimesTen / 10;
    }
}

//SPDX-License-Identifier: MIT
//
//Copyright (c) 2019 Synthetix
//
//Permission is hereby granted, free of charge, to any person obtaining a copy
//of this software and associated documentation files (the "Software"), to deal
//in the Software without restriction, including without limitation the rights
//to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//copies of the Software, and to permit persons to whom the Software is
//furnished to do so, subject to the following conditions:
//
//The above copyright notice and this permission notice shall be included in all
//copies or substantial portions of the Software.
//
//THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
//SOFTWARE.

pragma solidity >=0.5.0 <=0.8.0;

// Libraries
import "@openzeppelin/contracts-ethereum-package/contracts/math/SafeMath.sol";

// https://docs.synthetix.io/contracts/source/libraries/SafeDecimalMath/
library SafeDecimalMath {
    using SafeMath for uint256;

    /* Number of decimal places in the representations. */
    uint8 public constant decimals = 18;
    uint8 public constant highPrecisionDecimals = 27;

    /* The number representing 1.0. */
    uint256 public constant UNIT = 10**uint256(decimals);

    /* The number representing 1.0 for higher fidelity numbers. */
    uint256 public constant PRECISE_UNIT = 10**uint256(highPrecisionDecimals);
    uint256 private constant UNIT_TO_HIGH_PRECISION_CONVERSION_FACTOR =
        10**uint256(highPrecisionDecimals - decimals);

    /**
     * @return Provides an interface to UNIT.
     */
    function unit() external pure returns (uint256) {
        return UNIT;
    }

    /**
     * @return Provides an interface to PRECISE_UNIT.
     */
    function preciseUnit() external pure returns (uint256) {
        return PRECISE_UNIT;
    }

    /**
     * @return The result of multiplying x and y, interpreting the operands as fixed-point
     * decimals.
     *
     * @dev A unit factor is divided out after the product of x and y is evaluated,
     * so that product must be less than 2**256. As this is an integer division,
     * the internal division always rounds down. This helps save on gas. Rounding
     * is more expensive on gas.
     */
    function multiplyDecimal(uint256 x, uint256 y)
        internal
        pure
        returns (uint256)
    {
        /* Divide by UNIT to remove the extra factor introduced by the product. */
        return x.mul(y) / UNIT;
    }

    /**
     * @return The result of safely multiplying x and y, interpreting the operands
     * as fixed-point decimals of the specified precision unit.
     *
     * @dev The operands should be in the form of a the specified unit factor which will be
     * divided out after the product of x and y is evaluated, so that product must be
     * less than 2**256.
     *
     * Unlike multiplyDecimal, this function rounds the result to the nearest increment.
     * Rounding is useful when you need to retain fidelity for small decimal numbers
     * (eg. small fractions or percentages).
     */
    function _multiplyDecimalRound(
        uint256 x,
        uint256 y,
        uint256 precisionUnit
    ) private pure returns (uint256) {
        /* Divide by UNIT to remove the extra factor introduced by the product. */
        uint256 quotientTimesTen = x.mul(y) / (precisionUnit / 10);

        if (quotientTimesTen % 10 >= 5) {
            quotientTimesTen += 10;
        }

        return quotientTimesTen / 10;
    }

    /**
     * @return The result of safely multiplying x and y, interpreting the operands
     * as fixed-point decimals of a precise unit.
     *
     * @dev The operands should be in the precise unit factor which will be
     * divided out after the product of x and y is evaluated, so that product must be
     * less than 2**256.
     *
     * Unlike multiplyDecimal, this function rounds the result to the nearest increment.
     * Rounding is useful when you need to retain fidelity for small decimal numbers
     * (eg. small fractions or percentages).
     */
    function multiplyDecimalRoundPrecise(uint256 x, uint256 y)
        internal
        pure
        returns (uint256)
    {
        return _multiplyDecimalRound(x, y, PRECISE_UNIT);
    }

    /**
     * @return The result of safely multiplying x and y, interpreting the operands
     * as fixed-point decimals of a standard unit.
     *
     * @dev The operands should be in the standard unit factor which will be
     * divided out after the product of x and y is evaluated, so that product must be
     * less than 2**256.
     *
     * Unlike multiplyDecimal, this function rounds the result to the nearest increment.
     * Rounding is useful when you need to retain fidelity for small decimal numbers
     * (eg. small fractions or percentages).
     */
    function multiplyDecimalRound(uint256 x, uint256 y)
        internal
        pure
        returns (uint256)
    {
        return _multiplyDecimalRound(x, y, UNIT);
    }

    /**
     * @return The result of safely dividing x and y. The return value is a high
     * precision decimal.
     *
     * @dev y is divided after the product of x and the standard precision unit
     * is evaluated, so the product of x and UNIT must be less than 2**256. As
     * this is an integer division, the result is always rounded down.
     * This helps save on gas. Rounding is more expensive on gas.
     */
    function divideDecimal(uint256 x, uint256 y)
        internal
        pure
        returns (uint256)
    {
        /* Reintroduce the UNIT factor that will be divided out by y. */
        return x.mul(UNIT).div(y);
    }

    /**
     * @return The result of safely dividing x and y. The return value is as a rounded
     * decimal in the precision unit specified in the parameter.
     *
     * @dev y is divided after the product of x and the specified precision unit
     * is evaluated, so the product of x and the specified precision unit must
     * be less than 2**256. The result is rounded to the nearest increment.
     */
    function _divideDecimalRound(
        uint256 x,
        uint256 y,
        uint256 precisionUnit
    ) private pure returns (uint256) {
        uint256 resultTimesTen = x.mul(precisionUnit * 10).div(y);

        if (resultTimesTen % 10 >= 5) {
            resultTimesTen += 10;
        }

        return resultTimesTen / 10;
    }

    /**
     * @return The result of safely dividing x and y. The return value is as a rounded
     * standard precision decimal.
     *
     * @dev y is divided after the product of x and the standard precision unit
     * is evaluated, so the product of x and the standard precision unit must
     * be less than 2**256. The result is rounded to the nearest increment.
     */
    function divideDecimalRound(uint256 x, uint256 y)
        internal
        pure
        returns (uint256)
    {
        return _divideDecimalRound(x, y, UNIT);
    }

    /**
     * @return The result of safely dividing x and y. The return value is as a rounded
     * high precision decimal.
     *
     * @dev y is divided after the product of x and the high precision unit
     * is evaluated, so the product of x and the high precision unit must
     * be less than 2**256. The result is rounded to the nearest increment.
     */
    function divideDecimalRoundPrecise(uint256 x, uint256 y)
        internal
        pure
        returns (uint256)
    {
        return _divideDecimalRound(x, y, PRECISE_UNIT);
    }

    /**
     * @dev Convert a standard decimal representation to a high precision one.
     */
    function decimalToPreciseDecimal(uint256 i)
        internal
        pure
        returns (uint256)
    {
        return i.mul(UNIT_TO_HIGH_PRECISION_CONVERSION_FACTOR);
    }

    /**
     * @dev Convert a high precision decimal to a standard decimal representation.
     */
    function preciseDecimalToDecimal(uint256 i)
        internal
        pure
        returns (uint256)
    {
        uint256 quotientTimesTen = i /
            (UNIT_TO_HIGH_PRECISION_CONVERSION_FACTOR / 10);

        if (quotientTimesTen % 10 >= 5) {
            quotientTimesTen += 10;
        }

        return quotientTimesTen / 10;
    }
}

//SPDX-License-Identifier: ISC
pragma solidity >=0.5.0 <=0.8.0;
pragma experimental ABIEncoderV2;

interface IBlackScholes {
    struct PricesDeltaStdVega {
        uint256 callPrice;
        uint256 putPrice;
        int256 callDelta;
        int256 putDelta;
        uint256 stdVega;
    }

    struct PricesStdVega {
        uint256 price;
        uint256 stdVega;
    }

    function abs(int256 x) external pure returns (uint256);

    function exp(uint256 x) external pure returns (uint256);

    function exp(int256 x) external pure returns (uint256);

    function sqrt(uint256 x) external pure returns (uint256 y);

    function optionPrices(
        uint256 timeToExpirySec,
        uint256 volatilityDecimal,
        uint256 spotDecimal,
        uint256 strikeDecimal,
        int256 rateDecimal
    ) external view returns (uint256 call, uint256 put);

    function optionPricesInUnderlying(
        uint256 timeToExpirySec,
        uint256 volatilityDecimal,
        uint256 spotDecimal,
        uint256 strikeDecimal,
        int256 rateDecimal
    ) external view returns (uint256 call, uint256 put);

    function pricesDeltaStdVega(
        uint256 timeToExpirySec,
        uint256 volatilityDecimal,
        uint256 spotDecimal,
        uint256 strikeDecimal,
        int256 rateDecimal
    ) external pure returns (PricesDeltaStdVega memory);

    function pricesStdVegaInUnderlying(
        uint256 timeToExpirySec,
        uint256 volatilityDecimal,
        uint256 spotDecimal,
        uint256 strikeDecimal,
        int256 rateDecimal,
        bool isPut
    ) external pure returns (PricesStdVega memory);
}

pragma solidity ^0.6.0;

/**
 * @title SignedSafeMath
 * @dev Signed math operations with safety checks that revert on error.
 */
library SignedSafeMath {
    int256 constant private _INT256_MIN = -2**255;

    /**
     * @dev Multiplies two signed integers, reverts on overflow.
     */
    function mul(int256 a, int256 b) internal pure returns (int256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        require(!(a == -1 && b == _INT256_MIN), "SignedSafeMath: multiplication overflow");

        int256 c = a * b;
        require(c / a == b, "SignedSafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Integer division of two signed integers truncating the quotient, reverts on division by zero.
     */
    function div(int256 a, int256 b) internal pure returns (int256) {
        require(b != 0, "SignedSafeMath: division by zero");
        require(!(b == -1 && a == _INT256_MIN), "SignedSafeMath: division overflow");

        int256 c = a / b;

        return c;
    }

    /**
     * @dev Subtracts two signed integers, reverts on overflow.
     */
    function sub(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a - b;
        require((b >= 0 && c <= a) || (b < 0 && c > a), "SignedSafeMath: subtraction overflow");

        return c;
    }

    /**
     * @dev Adds two signed integers, reverts on overflow.
     */
    function add(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a + b;
        require((b >= 0 && c >= a) || (b < 0 && c < a), "SignedSafeMath: addition overflow");

        return c;
    }
}

pragma solidity ^0.6.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}