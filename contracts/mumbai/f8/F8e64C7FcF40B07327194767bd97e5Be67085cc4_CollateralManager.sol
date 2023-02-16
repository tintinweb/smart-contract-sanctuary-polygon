pragma solidity >=0.6.0;
pragma experimental ABIEncoderV2;

import "./BaseCollateralManager.sol";
import "../interfaces/IGovernableLiquidityPool.sol";
import "../interfaces/IBaseHedgingManager.sol";

contract CollateralManager is BaseCollateralManager {

    using SafeCast for uint;
    using SafeMath for uint;
    using SignedSafeMath for int;

    struct CollateralData {
        address udlAddr;
        address hmngr;
        bool udlFound;
        int udlFoundIdx;
        int coll;
        int totalDelta;
        int hedgedDelta;
        uint totalAbsDelta;
        address[] underlyings;
        address[] rawUnderlyings;
        int[] _iv;
        uint[] posDeltaNum;
        uint[] posDeltaDenom;
        IOptionsExchange.OptionData[] options;
    }

    function initialize(Deployer deployer) override internal {
        super.initialize(deployer);
    }

    function calcNetCollateralInternal(address[] memory _tokens, uint[] memory _uncovered, uint[] memory _holding, bool is_regular) override internal view returns (int) {
        // multi udl feed refs, need to make core accross all collateral models
        // do not normalize by volumeBase in internal calls for calcCollateralInternal
        

        CollateralData memory cData;
        cData.posDeltaNum = new uint[](_tokens.length);
        cData.posDeltaDenom = new uint[](_tokens.length);
        cData._iv = new int[](_tokens.length);
        cData.options = new IOptionsExchange.OptionData[](_tokens.length);
        cData.underlyings = new address[](_tokens.length);
        cData.rawUnderlyings = new address[](_tokens.length);
        cData.coll = 0;

        //get the underlyings and option data
        for (uint i = 0; i < _tokens.length; i++) {
            IOptionsExchange.OptionData memory opt = exchange.getOptionData(_tokens[i]);
            cData.options[i] = opt;
            cData._iv[i] = calcIntrinsicValue(opt);
            cData.rawUnderlyings[i] = UnderlyingFeed(opt.udlFeed).getUnderlyingAddr();
        }
        //for each underlying calculate the delta of their sub portfolio
        for (uint i = 0; i < _tokens.length; i++) {
            cData.udlAddr = cData.rawUnderlyings[i];            
            (cData.udlFound, cData.udlFoundIdx) = foundUnderlying(cData.udlAddr, cData.underlyings);
            
            if (cData.udlFound == false) {
                cData.totalDelta = 0;
                cData.totalAbsDelta = 0;

                for (uint j = 0; j < _tokens.length; j++) {
                    address udlTemp = cData.rawUnderlyings[j];
                    if (udlTemp == cData.udlAddr){
                        int256 delta = 0;
                        uint256 absDelta = 0;

                        if (_uncovered[j] > 0) {
                            // short this option, thus mult by -1
                            delta = calcDelta(
                                cData.options[j],
                                _uncovered[j]
                            ).mul(-1);
                            absDelta = MoreMath.abs(delta);
                        }

                        if (_holding[j] > 0) {
                            // long thus does not need to be modified
                            delta = calcDelta(
                                cData.options[j],
                                _holding[j]
                            );
                            absDelta = MoreMath.abs(delta);
                        }
                        
                        cData.totalDelta = cData.totalDelta.add(delta);
                        cData.totalAbsDelta = cData.totalAbsDelta.add(absDelta);
                    }
                }

                cData.underlyings[i] = cData.udlAddr;
                cData.posDeltaNum[i] = MoreMath.abs(cData.totalDelta);
                cData.posDeltaDenom[i] = cData.totalAbsDelta;

                cData.totalDelta = 0;
                cData.totalAbsDelta = 0;

                cData.udlFound = true;
            } else {
                // copy preexisting
                cData.underlyings[i] = cData.underlyings[uint(cData.udlFoundIdx)];
                cData.posDeltaNum[i] = cData.posDeltaNum[uint(cData.udlFoundIdx)];
                cData.posDeltaDenom[i] = cData.posDeltaDenom[uint(cData.udlFoundIdx)];
            }

            if (is_regular == false) {
                if (_uncovered[i] > _holding[i]) {
                    continue;
                }
            }

            if ((cData.posDeltaDenom[i] > 0) && (_uncovered[i] > _holding[i])) {
                cData.coll = cData.coll.add(
                    cData._iv[i].mul(
                        int(_uncovered[i]).sub(int(_holding[i]))
                    )
                ).add(
                    int(
                        calcCollateral(
                            exchange.getExchangeFeeds(cData.options[i].udlFeed).upperVol,
                            _uncovered[i],
                            cData.options[i]
                        ).mul(cData.posDeltaNum[i]).div(cData.posDeltaDenom[i])
                    )
                );
            } else if ((_uncovered[i] > _holding[i])) {
                cData.coll = cData.coll.add(
                    cData._iv[i].mul(
                        int(_uncovered[i]).sub(int(_holding[i]))
                    )
                ).add(
                    int(
                        calcCollateral(
                            exchange.getExchangeFeeds(cData.options[i].udlFeed).upperVol,
                            _uncovered[i],
                            cData.options[i]
                        )
                    )
                );
            }
            
        }

        return cData.coll;
    }


    function calcCollateralInternal(address owner, bool is_regular) override internal view returns (int) {
        // multi udl feed refs, need to make core accross all collateral models
        // do not normalize by volumeBase in internal calls for calcCollateralInternal
        

        CollateralData memory cData;
        (,address[] memory _tokens, uint[] memory _holding,, uint[] memory _uncovered, int[] memory _iv, address[] memory _underlying) = exchange.getBook(owner);

        cData.underlyings = new address[](_tokens.length);
        cData.posDeltaNum = new uint[](_tokens.length);
        cData.posDeltaDenom = new uint[](_tokens.length);
        cData.hmngr = (settings.checkPoolSellCreditTradable(owner)) ? IGovernableLiquidityPool(owner).getHedgingManager() : address(0); //HACK: checks if owner is a pool that can sell options with borrowed liquidity
        
        //for each underlying calculate the delta of their sub portfolio
        for (uint i = 0; i < _underlying.length; i++) {
            IOptionsExchange.OptionData memory opt = exchange.getOptionData(_tokens[i]);

            cData.udlAddr = _underlying[i];
            (cData.udlFound, cData.udlFoundIdx) = foundUnderlying(cData.udlAddr, cData.underlyings);
            if (cData.udlFound == false) {
                cData.totalDelta = 0;
                cData.hedgedDelta = 0;
                cData.totalAbsDelta = 0;

                if (settings.isAllowedHedgingManager(cData.hmngr)) {
                     cData.hedgedDelta = int256(
                        IBaseHedgingManager(cData.hmngr).realHedgeExposure(
                           cData.udlAddr
                        )
                    );
                }
                
                for (uint j = 0; j < _tokens.length; j++) {
                    if (_underlying[j] == cData.udlAddr){
                        int256 delta;
                        uint256 absDelta;

                        if (_uncovered[j] > 0) {
                            // net short this option, thus mult by -1
                            delta = calcDelta(
                                opt,
                                _uncovered[j]
                            ).mul(-1);
                            absDelta = MoreMath.abs(delta);
                        }

                        if (_holding[j] > 0) {
                            // net long thus does not need to be modified
                            delta = calcDelta(
                                opt,
                                _holding[j]
                            );
                            absDelta = MoreMath.abs(delta);
                        }
                        
                        cData.totalDelta = cData.totalDelta.add(delta);
                        cData.totalAbsDelta = cData.totalAbsDelta.add(absDelta);
                    }
                }
                cData.underlyings[i] = cData.udlAddr;
                cData.posDeltaNum[i] = MoreMath.abs(cData.totalDelta.sub(cData.hedgedDelta));
                cData.posDeltaDenom[i] = cData.totalAbsDelta;

                cData.totalDelta = 0;
                cData.hedgedDelta = 0;
                cData.totalAbsDelta = 0;

                cData.udlFound = true;
            } else {
                // copy preexisting
                cData.underlyings[i] = cData.underlyings[uint(cData.udlFoundIdx)];
                cData.posDeltaNum[i] = cData.posDeltaNum[uint(cData.udlFoundIdx)];
                cData.posDeltaDenom[i] = cData.posDeltaDenom[uint(cData.udlFoundIdx)];
            }

            if (is_regular == false) {
                if (_uncovered[i] > _holding[i]) {
                    continue;
                }
            }

            if ((cData.posDeltaDenom[i] > 0) && (_uncovered[i] > _holding[i])) {
                cData.coll = cData.coll.add(
                    _iv[i].mul(
                        int(_uncovered[i]).sub(int(_holding[i]))
                    )
                ).add(
                    int(
                        calcCollateral(
                            exchange.getExchangeFeeds(opt.udlFeed).upperVol,
                            _uncovered[i],
                            opt
                        ).mul(cData.posDeltaNum[i]).div(cData.posDeltaDenom[i])
                    )
                );
            } else if ((_uncovered[i] > _holding[i])) {
                cData.coll = cData.coll.add(
                    _iv[i].mul(
                        int(_uncovered[i]).sub(int(_holding[i]))
                    )
                ).add(
                    int(
                        calcCollateral(
                            exchange.getExchangeFeeds(opt.udlFeed).upperVol,
                            _uncovered[i],
                            opt
                        )
                    )
                );
            }
        }
        return cData.coll;
    }

    function foundUnderlying(address udl, address[] memory udlArray) private pure returns (bool, int){
        for (uint i = 0; i < udlArray.length; i++) {
            if (udlArray[i] == udl) {
                return (true, int(i));
            }
        }

        return (false, -1);
    }

    function calcCollateral(
        IOptionsExchange.OptionData calldata opt,
        uint volume
    ) override external view returns (uint)
    {
        IOptionsExchange.FeedData memory fd = exchange.getExchangeFeeds(opt.udlFeed);
        if (fd.lowerVol == 0 || fd.upperVol == 0) {
            fd = getFeedData(opt.udlFeed);
        }

        int coll = calcIntrinsicValue(opt).mul(int(volume)).add(
            int(calcCollateral(fd.upperVol, volume, opt))
        ).div(int(_volumeBase));

        if (opt._type == IOptionsExchange.OptionType.PUT) {
            int max = int(uint(opt.strike).mul(volume).div(_volumeBase));
            coll = MoreMath.min(coll, max);
        }

        return coll > 0 ? uint(coll) : 0;
    }

    function calcDelta(
        IOptionsExchange.OptionData memory opt,
        uint volume
    ) public view returns (int256){
        /* 
            - rfr == 0% assumption
            - (1 / (sigma * sqrt(T - t))) * (ln(S/k) + (((sigma**2) / 2) * ((T-t)))) == d1
                - underlying price S
                - strike price K
        */

        int256 delta;

        uint256 one_year = 60 * 60 * 24 * 365;

        uint256 volPeriod = settings.getVolatilityPeriod();
        
        // using exchange 90 day window
        uint256 price = uint256(getUdlPrice(opt));
        uint256 sigma = UnderlyingFeed(opt.udlFeed).getDailyVolatility(volPeriod).mul(_volumeBase).mul(3).div(price).mul(10); //vol
        int256 price_div_strike = int256(price).mul(int256(_volumeBase)).div(int256(opt.strike));//need to multiply by volume base to get a number in base 1e18 decimals

        //giv expired options no delta
        if (uint256(opt.maturity) < settings.exchangeTime()){
            return 0;
        }
        uint256 dt = (uint256(opt.maturity).sub(settings.exchangeTime())).mul(_volumeBase).div(one_year); //dt relative to a year;

        int256 ln_price_div_strike = MoreMath.ln(price_div_strike);

        int256 d1n = int256((MoreMath.pow(sigma, 2)).mul(dt).div(2e18));
        int256 d1d = int256(sigma.mul(MoreMath.sqrt(dt)));

        int256 d1 = (ln_price_div_strike.add(
            d1n
        )).div(
            d1d
        );

        if (opt._type == IOptionsExchange.OptionType.PUT) {
            // -1 * norm_cdf(-d1) == put_delta
            delta = MoreMath.cdf(d1.mul(-1)).mul(-1);
        
        } else {
            // norm_cdf(d1) == call_delta
            delta = MoreMath.cdf(d1);
        }

        require((-1e18 <= delta) && (delta <= 1e18), "delta out of range");

        return delta.mul(int256(volume)).div(int256(_volumeBase));
    }

    function calcGamma(
        IOptionsExchange.OptionData memory opt,
        uint volume
    ) public view returns (int256){
        /* 
            - rfr == 0% assumption
            - (1 / (sigma * sqrt(T - t))) * (ln(S/k) + (((sigma**2) / 2) * ((T-t)))) == d1
                - underlying price S
                - strike price K
        */


        uint256 one_year = 60 * 60 * 24 * 365;
        
        uint256 volPeriod = settings.getVolatilityPeriod();
        
        // using exchange 90 day window
        uint256 price = uint256(getUdlPrice(opt));
        uint256 sigma = UnderlyingFeed(opt.udlFeed).getDailyVolatility(volPeriod).mul(_volumeBase).mul(3).div(price).mul(10); //vol
        int256 price_div_strike = int256(price).mul(int256(_volumeBase)).div(int256(opt.strike));//need to multiply by volume base to get a number in base 1e18 decimals
        uint256 dt = (uint256(opt.maturity).sub(settings.exchangeTime())).mul(_volumeBase).div(one_year); //dt relative to a year;
        int256 ln_price_div_strike = MoreMath.ln(price_div_strike);

        int256 d1n = int256((MoreMath.pow(sigma, 2)).mul(dt).div(2e18));
        int256 d1d = int256(sigma.mul(MoreMath.sqrt(dt)));

        int256 d1 = (ln_price_div_strike.add(
            d1n
        )).div(
            d1d
        );

        int256 gamma = MoreMath.pdf(d1).mul(int256(_volumeBase)).div(
            int256(price.mul(uint256(d1d)).div(_volumeBase))
        );

        //require((-1e18 <= gamma) && (gamma <= 1e18), "gamma out of range");

        return gamma.mul(int256(volume)).div(int256(_volumeBase));
    }

    function borrowTokensByPreference(address to, address pool, uint value, address[] calldata tokensInOrder, uint[] calldata amountsOutInOrder) external {
        creditProvider.borrowTokensByPreference(to, pool, value, tokensInOrder, amountsOutInOrder);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @title SignedSafeMath
 * @dev Signed math operations with safety checks that revert on error.
 */
library SignedSafeMath {
    int256 constant private _INT256_MIN = -2**255;

    /**
     * @dev Returns the multiplication of two signed integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
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
     * @dev Returns the integer division of two signed integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opsymbol (which leaves remaining gas untouched) while Solidity
     * uses an invalid opsymbol to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(int256 a, int256 b) internal pure returns (int256) {
        require(b != 0, "SignedSafeMath: division by zero");
        require(!(b == -1 && a == _INT256_MIN), "SignedSafeMath: division overflow");

        int256 c = a / b;

        return c;
    }

    /**
     * @dev Returns the subtraction of two signed integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a - b;
        require((b >= 0 && c <= a) || (b < 0 && c > a), "SignedSafeMath: subtraction overflow");

        return c;
    }

    /**
     * @dev Returns the addition of two signed integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a + b;
        require((b >= 0 && c >= a) || (b < 0 && c < a), "SignedSafeMath: addition overflow");

        return c;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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
     *
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
     *
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
     *
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
     *
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
     * `revert` opsymbol (which leaves remaining gas untouched) while Solidity
     * uses an invalid opsymbol to revert (consuming all remaining gas).
     *
     * Requirements:
     *
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
     * `revert` opsymbol (which leaves remaining gas untouched) while Solidity
     * uses an invalid opsymbol to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
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
     * opsymbol (which leaves remaining gas untouched) while Solidity uses an
     * invalid opsymbol to revert (consuming all remaining gas).
     *
     * Requirements:
     *
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
     * opsymbol (which leaves remaining gas untouched) while Solidity uses an
     * invalid opsymbol to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0;

/**
 * @dev Wrappers over Solidity's uintXX/intXX casting operators with added overflow
 * checks.
 *
 * Downcasting from uint256/int256 in Solidity does not revert on overflow. This can
 * easily result in undesired exploitation or bugs, since developers usually
 * assume that overflows raise errors. `SafeCast` restores this intuition by
 * reverting the transaction when such an operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 *
 * Can be combined with {SafeMath} and {SignedSafeMath} to extend it to smaller types, by performing
 * all math on `uint256` and `int256` and then downcasting.
 */
library SafeCast {
    /**
     * @dev Returns the downcasted uint128 from uint256, reverting on
     * overflow (when the input is greater than largest uint128).
     *
     * Counterpart to Solidity's `uint128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     */
    function toUint128(uint256 value) internal pure returns (uint128) {
        require(value < 2**128, "SafeCast: value doesn\'t fit in 128 bits");
        return uint128(value);
    }

    /**
     * @dev Returns the downcasted uint120 from uint256, reverting on
     * overflow (when the input is greater than largest uint120).
     *
     * Counterpart to Solidity's `uint120` operator.
     *
     * Requirements:
     *
     * - input must fit into 120 bits
     */
    function toUint120(uint256 value) internal pure returns (uint120) {
        require(value < 2**120, "SafeCast: value doesn\'t fit in 120 bits");
        return uint120(value);
    }

    /**
     * @dev Returns the downcasted uint64 from uint256, reverting on
     * overflow (when the input is greater than largest uint64).
     *
     * Counterpart to Solidity's `uint64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     */
    function toUint64(uint256 value) internal pure returns (uint64) {
        require(value < 2**64, "SafeCast: value doesn\'t fit in 64 bits");
        return uint64(value);
    }

    /**
     * @dev Returns the downcasted uint32 from uint256, reverting on
     * overflow (when the input is greater than largest uint32).
     *
     * Counterpart to Solidity's `uint32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     */
    function toUint32(uint256 value) internal pure returns (uint32) {
        require(value < 2**32, "SafeCast: value doesn\'t fit in 32 bits");
        return uint32(value);
    }

    /**
     * @dev Returns the downcasted uint16 from uint256, reverting on
     * overflow (when the input is greater than largest uint16).
     *
     * Counterpart to Solidity's `uint16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     */
    function toUint16(uint256 value) internal pure returns (uint16) {
        require(value < 2**16, "SafeCast: value doesn\'t fit in 16 bits");
        return uint16(value);
    }

    /**
     * @dev Returns the downcasted uint8 from uint256, reverting on
     * overflow (when the input is greater than largest uint8).
     *
     * Counterpart to Solidity's `uint8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits.
     */
    function toUint8(uint256 value) internal pure returns (uint8) {
        require(value < 2**8, "SafeCast: value doesn\'t fit in 8 bits");
        return uint8(value);
    }

    /**
     * @dev Converts a signed int256 into an unsigned uint256.
     *
     * Requirements:
     *
     * - input must be greater than or equal to 0.
     */
    function toUint256(int256 value) internal pure returns (uint256) {
        require(value >= 0, "SafeCast: value must be positive");
        return uint256(value);
    }

    /**
     * @dev Returns the downcasted int128 from int256, reverting on
     * overflow (when the input is less than smallest int128 or
     * greater than largest int128).
     *
     * Counterpart to Solidity's `int128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     *
     * _Available since v3.1._
     */
    function toInt128(int256 value) internal pure returns (int128) {
        require(value >= -2**127 && value < 2**127, "SafeCast: value doesn\'t fit in 128 bits");
        return int128(value);
    }

    /**
     * @dev Returns the downcasted int64 from int256, reverting on
     * overflow (when the input is less than smallest int64 or
     * greater than largest int64).
     *
     * Counterpart to Solidity's `int64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     *
     * _Available since v3.1._
     */
    function toInt64(int256 value) internal pure returns (int64) {
        require(value >= -2**63 && value < 2**63, "SafeCast: value doesn\'t fit in 64 bits");
        return int64(value);
    }

    /**
     * @dev Returns the downcasted int32 from int256, reverting on
     * overflow (when the input is less than smallest int32 or
     * greater than largest int32).
     *
     * Counterpart to Solidity's `int32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     *
     * _Available since v3.1._
     */
    function toInt32(int256 value) internal pure returns (int32) {
        require(value >= -2**31 && value < 2**31, "SafeCast: value doesn\'t fit in 32 bits");
        return int32(value);
    }

    /**
     * @dev Returns the downcasted int16 from int256, reverting on
     * overflow (when the input is less than smallest int16 or
     * greater than largest int16).
     *
     * Counterpart to Solidity's `int16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     *
     * _Available since v3.1._
     */
    function toInt16(int256 value) internal pure returns (int16) {
        require(value >= -2**15 && value < 2**15, "SafeCast: value doesn\'t fit in 16 bits");
        return int16(value);
    }

    /**
     * @dev Returns the downcasted int8 from int256, reverting on
     * overflow (when the input is less than smallest int8 or
     * greater than largest int8).
     *
     * Counterpart to Solidity's `int8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits.
     *
     * _Available since v3.1._
     */
    function toInt8(int256 value) internal pure returns (int8) {
        require(value >= -2**7 && value < 2**7, "SafeCast: value doesn\'t fit in 8 bits");
        return int8(value);
    }

    /**
     * @dev Converts an unsigned uint256 into a signed int256.
     *
     * Requirements:
     *
     * - input must be less than or equal to maxInt256.
     */
    function toInt256(uint256 value) internal pure returns (int256) {
        require(value < 2**255, "SafeCast: value doesn't fit in an int256");
        return int256(value);
    }
}

pragma solidity >=0.6.0;

import "./SafeMath.sol";
import "./SignedSafeMath.sol";
import "./FixedPointMathLib.sol";

library MoreMath {

    using SafeMath for uint;
    using SignedSafeMath for int;

    using FixedPointMathLib for int256;
    using FixedPointMathLib for uint256;

    uint256 internal constant HALF_WAD = 0.5 ether;
    uint256 internal constant PI = 3_141592653589793238;
    int256 internal constant SQRT_2PI = 2_506628274631000502;
    int256 internal constant SIGN = -1;
    int256 internal constant SCALAR = 1e18;
    int256 internal constant HALF_SCALAR = 1e9;
    int256 internal constant SCALAR_SQRD = 1e36;
    int256 internal constant HALF = 5e17;
    int256 internal constant ONE = 1e18;
    int256 internal constant TWO = 2e18;
    int256 internal constant NEGATIVE_TWO = -2e18;
    int256 internal constant SQRT2 = 1_414213562373095048; // √2 with 18 decimals of precision.
    int256 internal constant ERFC_A = 1_265512230000000000;
    int256 internal constant ERFC_B = 1_000023680000000000;
    int256 internal constant ERFC_C = 374091960000000000; // 1e-1
    int256 internal constant ERFC_D = 96784180000000000; // 1e-2
    int256 internal constant ERFC_E = -186288060000000000; // 1e-1
    int256 internal constant ERFC_F = 278868070000000000; // 1e-1
    int256 internal constant ERFC_G = -1_135203980000000000;
    int256 internal constant ERFC_H = 1_488515870000000000;
    int256 internal constant ERFC_I = -822152230000000000; // 1e-1
    int256 internal constant ERFC_J = 170872770000000000; // 1e-1
    int256 internal constant IERFC_A = -707110000000000000; // 1e-1
    int256 internal constant IERFC_B = 2_307530000000000000;
    int256 internal constant IERFC_C = 270610000000000000; // 1e-1
    int256 internal constant IERFC_D = 992290000000000000; // 1e-1
    int256 internal constant IERFC_E = 44810000000000000; // 1e-2
    int256 internal constant IERFC_F = 1_128379167095512570;

    //see: https://ethereum.stackexchange.com/questions/8086/logarithm-math-operation-in-solidity

    /// @dev log2(e) as a signed 59.18-decimal fixed-point number.
    int256 internal constant LOG2_E = 1_442695040888963407;

    /// @dev Half the SCALE number.
    int256 internal constant HALF_SCALE = 5e17;

    int256 internal constant SCALE = 1e18;

    int256 internal constant OLD_PI = 3_141592653589793238;

    /// @notice Finds the zero-based index of the first one in the binary representation of x.
    /// @dev See the note on msb in the "Find First Set" Wikipedia article https://en.wikipedia.org/wiki/Find_first_set
    /// @param x The uint256 number for which to find the index of the most significant bit.
    /// @return msb The index of the most significant bit as an uint256.
    function mostSignificantBit(uint256 x) internal pure returns (uint256 msb) {
        if (x >= 2**128) {
            x >>= 128;
            msb += 128;
        }
        if (x >= 2**64) {
            x >>= 64;
            msb += 64;
        }
        if (x >= 2**32) {
            x >>= 32;
            msb += 32;
        }
        if (x >= 2**16) {
            x >>= 16;
            msb += 16;
        }
        if (x >= 2**8) {
            x >>= 8;
            msb += 8;
        }
        if (x >= 2**4) {
            x >>= 4;
            msb += 4;
        }
        if (x >= 2**2) {
            x >>= 2;
            msb += 2;
        }
        if (x >= 2**1) {
            // No need to shift x any more.
            msb += 1;
        }
    }
    /// @notice Calculates the binary logarithm of x.
    ///
    /// @dev Based on the iterative approximation algorithm.
    /// https://en.wikipedia.org/wiki/Binary_logarithm#Iterative_approximation
    ///
    /// Requirements:
    /// - x must be greater than zero.
    ///
    /// Caveats:
    /// - The results are nor perfectly accurate to the last digit, due to the lossy precision of the iterative approximation.
    ///
    /// @param x The signed 59.18-decimal fixed-point number for which to calculate the binary logarithm.
    /// @return result The binary logarithm as a signed 59.18-decimal fixed-point number.
    function old_log2(int256 x) internal pure returns (int256 result) {
        require(x > 0);
        // This works because log2(x) = -log2(1/x).
        int256 sign;
        if (x >= SCALE) {
            sign = 1;
        } else {
            sign = -1;
            // Do the fixed-point inversion inline to save gas. The numerator is SCALE * SCALE.
            assembly {
                x := div(1000000000000000000000000000000000000, x)
            }
        }

        // Calculate the integer part of the logarithm and add it to the result and finally calculate y = x * 2^(-n).
        uint256 n = mostSignificantBit(uint256(x / SCALE));

        // The integer part of the logarithm as a signed 59.18-decimal fixed-point number. The operation can't overflow
        // because n is maximum 255, SCALE is 1e18 and sign is either 1 or -1.
        result = int256(n) * SCALE;

        // This is y = x * 2^(-n).
        int256 y = x >> n;

        // If y = 1, the fractional part is zero.
        if (y == SCALE) {
            return result * sign;
        }

        // Calculate the fractional part via the iterative approximation.
        // The "delta >>= 1" part is equivalent to "delta /= 2", but shifting bits is faster.
        for (int256 delta = int256(HALF_SCALE); delta > 0; delta >>= 1) {
            y = (y * y) / SCALE;

            // Is y^2 > 2 and so in the range [2,4)?
            if (y >= 2 * SCALE) {
                // Add the 2^(-m) factor to the logarithm.
                result += delta;

                // Corresponds to z/2 on Wikipedia.
                y >>= 1;
            }
        }
        result *= sign;
    }

    /// @notice Calculates the natural logarithm of x.
    ///
    /// @dev Based on the insight that ln(x) = log2(x) / log2(e).
    ///
    /// Requirements:
    /// - All from "log2".
    ///
    /// Caveats:
    /// - All from "log2".
    /// - This doesn't return exactly 1 for 2718281828459045235, for that we would need more fine-grained precision.
    ///
    /// @param x The signed 59.18-decimal fixed-point number for which to calculate the natural logarithm.
    /// @return result The natural logarithm as a signed 59.18-decimal fixed-point number.
    function ln(int256 x) internal pure returns (int256 result) {
        // Do the fixed-point multiplication inline to save gas. This is overflow-safe because the maximum value that log2(x)
        // can return is 195205294292027477728.
        result = (old_log2(x) * SCALE) / LOG2_E;
    }

    /*
     * notice Approximation of the Complimentary Error Function.
     * Related to the Error Function: `erfc(x) = 1 - erf(x)`.
     * Both cumulative distribution and error functions are integrals
     * which cannot be expressed in elementary terms. They are called special functions.
     * The error and complimentary error functions have numerical approximations
     * which is what is used in this library to compute the cumulative distribution function.
     *
     *  dev This is a special function with its own identities.
     * Identity: `erfc(-x) = 2 - erfc(x)`.
     * Special Values:
     * erfc(-infinity)  =   2
     * erfc(0)          =   1
     * erfc(infinity)   =   0
     *
     * custom:epsilon Fractional error less than 1.2e-7.
     * custom:source Numerical Recipes in C 2e p221.
     * custom:source https://mathworld.wolfram.com/Erfc.html.
     */
    function erfc(int256 input) internal pure returns (int256 output) {
        uint256 z = abs(input);
        int256 t;
        int256 step;
        int256 k;
        assembly {
            let quo := sdiv(mul(z, ONE), TWO) // 1 / (1 + z / 2).
            let den := add(ONE, quo)
            t := sdiv(SCALAR_SQRD, den)

            function muli(pxn, pxd) -> res {
                res := sdiv(mul(pxn, pxd), ONE)
            }

            {
                step := add(
                    ERFC_F,
                    muli(
                        t,
                        add(
                            ERFC_G,
                            muli(
                                t,
                                add(
                                    ERFC_H,
                                    muli(t, add(ERFC_I, muli(t, ERFC_J)))
                                )
                            )
                        )
                    )
                )
            }
            {
                step := muli(
                    t,
                    add(
                        ERFC_B,
                        muli(
                            t,
                            add(
                                ERFC_C,
                                muli(
                                    t,
                                    add(
                                        ERFC_D,
                                        muli(t, add(ERFC_E, muli(t, step)))
                                    )
                                )
                            )
                        )
                    )
                )
            }

            k := add(sub(mul(SIGN, muli(z, z)), ERFC_A), step)
        }

        int256 expWad = FixedPointMathLib.expWad(k);
        int256 r;
        assembly {
            r := sdiv(mul(t, expWad), ONE)
            switch iszero(slt(input, 0))
            case 0 {
                output := sub(TWO, r)
            }
            case 1 {
                output := r
            }
        }
    }

    /**
     * notice Approximation of the Cumulative Distribution Function.
     *
     * dev Equal to `D(x) = 0.5[ 1 + erf((x - µ) / σ√2)]`.
     * Only computes cdf of a distribution with µ = 0 and σ = 1.
     *
     * custom:error Maximum error of 1.2e-7.
     * custom:source https://mathworld.wolfram.com/NormalDistribution.html.
     */
    function cdf(int256 x) internal pure returns (int256 z) {
        int256 negated;
        assembly {
            let res := sdiv(mul(x, ONE), SQRT2)
            negated := add(not(res), 1)
        }

        int256 _erfc = erfc(negated);
        assembly {
            z := sdiv(mul(ONE, _erfc), TWO)
        }
    }

    /*
     * notice Approximation of the Probability Density Function.
     *
     * dev Equal to `Z(x) = (1 / σ√2π)e^( (-(x - µ)^2) / 2σ^2 )`.
     * Only computes pdf of a distribution with µ = 0 and σ = 1.
     *
     * custom:error Maximum error of 1.2e-7.
     * custom:source https://mathworld.wolfram.com/ProbabilityDensityFunction.html.
     */
    function pdf(int256 x) internal pure returns (int256 z) {
        int256 e;
        assembly {
            e := sdiv(mul(add(not(x), 1), x), TWO) // (-x * x) / 2.
        }
        e = FixedPointMathLib.expWad(e);

        assembly {
            z := sdiv(mul(e, ONE), SQRT_2PI)
        }
    }


    // rounds "v" considering a base "b"
    function round(uint v, uint b) internal pure returns (uint) {

        return v.div(b).add((v % b) >= b.div(2) ? 1 : 0);
    }

    // calculates {[(n/d)^e]*f}
    function powAndMultiply(uint n, uint d, uint e, uint f) internal pure returns (uint) {
        
        if (e == 0) {
            return 1;
        } else if (e == 1) {
            return f.mul(n).div(d);
        } else {
            uint p = powAndMultiply(n, d, e.div(2), f);
            p = p.mul(p).div(f);
            if (e.mod(2) == 1) {
                p = p.mul(n).div(d);
            }
            return p;
        }
    }

    // calculates (n^e)
    function pow(uint n, uint e) internal pure returns (uint) {
        
        if (e == 0) {
            return 1;
        } else if (e == 1) {
            return n;
        } else {
            uint p = pow(n, e.div(2));
            p = p.mul(p);
            if (e.mod(2) == 1) {
                p = p.mul(n);
            }
            return p;
        }
    }

    // calculates {n^(e/b)}
    function powDecimal(uint n, uint e, uint b) internal pure returns (uint v) {
        
        if (e == 0) {
            return b;
        }

        if (e > b) {
            return n.mul(powDecimal(n, e.sub(b), b)).div(b);
        }

        v = b;
        uint f = b;
        uint aux = 0;
        uint rootN = n;
        uint rootB = sqrt(b);
        while (f > 1) {
            f = f.div(2);
            rootN = sqrt(rootN).mul(rootB);
            if (aux.add(f) < e) {
                aux = aux.add(f);
                v = v.mul(rootN).div(b);
            }
        }
    }
    
    // calculates ceil(n/d)
    function divCeil(uint n, uint d) internal pure returns (uint v) {
        
        v = n.div(d);
        if (n.mod(d) > 0) {
            v = v.add(1);
        }
    }
    
    // calculates the square root of "x" and multiplies it by "f"
    function sqrtAndMultiply(uint x, uint f) internal pure returns (uint y) {
    
        y = sqrt(x.mul(1e18)).mul(f).div(1e9);
    }
    
    // calculates the square root of "x"
    function sqrt(uint x) internal pure returns (uint y) {
    
        uint z = (x.div(2)).add(1);
        y = x;
        while (z < y) {
            y = z;
            z = (x.div(z).add(z)).div(2);
        }
    }

    // calculates the standard deviation
    function std(int[] memory array) internal pure returns (uint _std) {

        int avg = sum(array).div(int(array.length));
        uint x2 = 0;
        for (uint i = 0; i < array.length; i++) {
            int p = array[i].sub(avg);
            x2 = x2.add(uint(p.mul(p)));
        }
        _std = sqrt(x2 / array.length);
    }

    function sum(int[] memory array) internal pure returns (int _sum) {

        for (uint i = 0; i < array.length; i++) {
            _sum = _sum.add(array[i]);
        }
    }

    function abs(int a) internal pure returns (uint) {

        return uint(a < 0 ? -a : a);
    }
    
    function max(int a, int b) internal pure returns (int) {
        
        return a > b ? a : b;
    }
    
    function max(uint a, uint b) internal pure returns (uint) {
        
        return a > b ? a : b;
    }
    
    function min(int a, int b) internal pure returns (int) {
        
        return a < b ? a : b;
    }
    
    function min(uint a, uint b) internal pure returns (uint) {
        
        return a < b ? a : b;
    }

    function toString(uint v) internal pure returns (string memory str) {

        str = toString(v, true);
    }
    
    function toString(uint v, bool scientific) internal pure returns (string memory str) {

        if (v == 0) {
            return "0";
        }

        uint maxlength = 100;
        bytes memory reversed = new bytes(maxlength);
        uint i = 0;
        
        while (v != 0) {
            uint remainder = v % 10;
            v = v / 10;
            reversed[i++] = byte(uint8(48 + remainder));
        }

        uint zeros = 0;
        if (scientific) {
            for (uint k = 0; k < i; k++) {
                if (reversed[k] == '0') {
                    zeros++;
                } else {
                    break;
                }
            }
        }

        uint len = i - (zeros > 2 ? zeros : 0);
        bytes memory s = new bytes(len);
        for (uint j = 0; j < len; j++) {
            s[j] = reversed[i - j - 1];
        }

        str = string(s);

        if (scientific && zeros > 2) {
            str = string(abi.encodePacked(s, "e", toString(zeros, false)));
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0;

/// @notice Arithmetic library with operations for fixed-point numbers.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/utils/FixedPointMathLib.sol)
library FixedPointMathLib {
    /*//////////////////////////////////////////////////////////////
                    SIMPLIFIED FIXED POINT OPERATIONS
    //////////////////////////////////////////////////////////////*/

    uint256 internal constant WAD = 1e18; // The scalar of ETH and most ERC20s.

    function mulWadDown(uint256 x, uint256 y) internal pure returns (uint256) {
        return mulDivDown(x, y, WAD); // Equivalent to (x * y) / WAD rounded down.
    }

    function mulWadUp(uint256 x, uint256 y) internal pure returns (uint256) {
        return mulDivUp(x, y, WAD); // Equivalent to (x * y) / WAD rounded up.
    }

    function divWadDown(uint256 x, uint256 y) internal pure returns (uint256) {
        return mulDivDown(x, WAD, y); // Equivalent to (x * WAD) / y rounded down.
    }

    function divWadUp(uint256 x, uint256 y) internal pure returns (uint256) {
        return mulDivUp(x, WAD, y); // Equivalent to (x * WAD) / y rounded up.
    }

    function powWad(int256 x, int256 y) internal pure returns (int256) {
        // Equivalent to x to the power of y because x ** y = (e ** ln(x)) ** y = e ** (ln(x) * y)
        return expWad((lnWad(x) * y) / int256(WAD)); // Using ln(x) means x must be greater than 0.
    }

    function expWad(int256 x) internal pure returns (int256 r) {
        {
            // When the result is < 0.5 we return zero. This happens when
            // x <= floor(log(0.5e18) * 1e18) ~ -42e18
            if (x <= -42139678854452767551) return 0;

            // When the result is > (2**255 - 1) / 1e18 we can not represent it as an
            // int. This happens when x >= floor(log((2**255 - 1) / 1e18) * 1e18) ~ 135.
            if (x >= 135305999368893231589) revert("EXP_OVERFLOW");

            // x is now in the range (-42, 136) * 1e18. Convert to (-42, 136) * 2**96
            // for more intermediate precision and a binary basis. This base conversion
            // is a multiplication by 1e18 / 2**96 = 5**18 / 2**78.
            x = (x << 78) / 5**18;

            // Reduce range of x to (-½ ln 2, ½ ln 2) * 2**96 by factoring out powers
            // of two such that exp(x) = exp(x') * 2**k, where k is an integer.
            // Solving this gives k = round(x / log(2)) and x' = x - k * log(2).
            int256 k = ((x << 96) / 54916777467707473351141471128 + 2**95) >> 96;
            x = x - k * 54916777467707473351141471128;

            // k is in the range [-61, 195].

            // Evaluate using a (6, 7)-term rational approximation.
            // p is made monic, we'll multiply by a scale factor later.
            int256 y = x + 1346386616545796478920950773328;
            y = ((y * x) >> 96) + 57155421227552351082224309758442;
            int256 p = y + x - 94201549194550492254356042504812;
            p = ((p * y) >> 96) + 28719021644029726153956944680412240;
            p = p * x + (4385272521454847904659076985693276 << 96);

            // We leave p in 2**192 basis so we don't need to scale it back up for the division.
            int256 q = x - 2855989394907223263936484059900;
            q = ((q * x) >> 96) + 50020603652535783019961831881945;
            q = ((q * x) >> 96) - 533845033583426703283633433725380;
            q = ((q * x) >> 96) + 3604857256930695427073651918091429;
            q = ((q * x) >> 96) - 14423608567350463180887372962807573;
            q = ((q * x) >> 96) + 26449188498355588339934803723976023;

            assembly {
                // Div in assembly because solidity adds a zero check despite the unchecked.
                // The q polynomial won't have zeros in the domain as all its roots are complex.
                // No scaling is necessary because p is already 2**96 too large.
                r := sdiv(p, q)
            }

            // r should be in the range (0.09, 0.25) * 2**96.

            // We now need to multiply r by:
            // * the scale factor s = ~6.031367120.
            // * the 2**k factor from the range reduction.
            // * the 1e18 / 2**96 factor for base conversion.
            // We do this all at once, with an intermediate result in 2**213
            // basis, so the final right shift is always by a positive amount.
            r = int256((uint256(r) * 3822833074963236453042738258902158003155416615667) >> uint256(195 - k));
        }
    }

    function lnWad(int256 x) internal pure returns (int256 r) {
        {
            require(x > 0, "UNDEFINED");

            // We want to convert x from 10**18 fixed point to 2**96 fixed point.
            // We do this by multiplying by 2**96 / 10**18. But since
            // ln(x * C) = ln(x) + ln(C), we can simply do nothing here
            // and add ln(2**96 / 10**18) at the end.

            // Reduce range of x to (1, 2) * 2**96
            // ln(2^k * x) = k * ln(2) + ln(x)
            int256 k = int256(log2(uint256(x))) - 96;
            x <<= uint256(159 - k);
            x = int256(uint256(x) >> 159);

            // Evaluate using a (8, 8)-term rational approximation.
            // p is made monic, we will multiply by a scale factor later.
            int256 p = x + 3273285459638523848632254066296;
            p = ((p * x) >> 96) + 24828157081833163892658089445524;
            p = ((p * x) >> 96) + 43456485725739037958740375743393;
            p = ((p * x) >> 96) - 11111509109440967052023855526967;
            p = ((p * x) >> 96) - 45023709667254063763336534515857;
            p = ((p * x) >> 96) - 14706773417378608786704636184526;
            p = p * x - (795164235651350426258249787498 << 96);

            // We leave p in 2**192 basis so we don't need to scale it back up for the division.
            // q is monic by convention.
            int256 q = x + 5573035233440673466300451813936;
            q = ((q * x) >> 96) + 71694874799317883764090561454958;
            q = ((q * x) >> 96) + 283447036172924575727196451306956;
            q = ((q * x) >> 96) + 401686690394027663651624208769553;
            q = ((q * x) >> 96) + 204048457590392012362485061816622;
            q = ((q * x) >> 96) + 31853899698501571402653359427138;
            q = ((q * x) >> 96) + 909429971244387300277376558375;
            assembly {
                // Div in assembly because solidity adds a zero check despite the unchecked.
                // The q polynomial is known not to have zeros in the domain.
                // No scaling required because p is already 2**96 too large.
                r := sdiv(p, q)
            }

            // r is in the range (0, 0.125) * 2**96

            // Finalization, we need to:
            // * multiply by the scale factor s = 5.549…
            // * add ln(2**96 / 10**18)
            // * add k * ln(2)
            // * multiply by 10**18 / 2**96 = 5**18 >> 78

            // mul s * 5e18 * 2**96, base is now 5**18 * 2**192
            r *= 1677202110996718588342820967067443963516166;
            // add ln(2) * k * 5e18 * 2**192
            r += 16597577552685614221487285958193947469193820559219878177908093499208371 * k;
            // add ln(2**96 / 10**18) * 5e18 * 2**192
            r += 600920179829731861736702779321621459595472258049074101567377883020018308;
            // base conversion: mul 2**18 / 2**192
            r >>= 174;
        }
    }

    /*//////////////////////////////////////////////////////////////
                    LOW LEVEL FIXED POINT OPERATIONS
    //////////////////////////////////////////////////////////////*/

    function mulDivDown(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 z) {
        assembly {
            // Store x * y in z for now.
            z := mul(x, y)

            // Equivalent to require(denominator != 0 && (x == 0 || (x * y) / x == y))
            if iszero(and(iszero(iszero(denominator)), or(iszero(x), eq(div(z, x), y)))) {
                revert(0, 0)
            }

            // Divide z by the denominator.
            z := div(z, denominator)
        }
    }

    function mulDivUp(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 z) {
        assembly {
            // Store x * y in z for now.
            z := mul(x, y)

            // Equivalent to require(denominator != 0 && (x == 0 || (x * y) / x == y))
            if iszero(and(iszero(iszero(denominator)), or(iszero(x), eq(div(z, x), y)))) {
                revert(0, 0)
            }

            // First, divide z - 1 by the denominator and add 1.
            // We allow z - 1 to underflow if z is 0, because we multiply the
            // end result by 0 if z is zero, ensuring we return 0 if z is zero.
            z := mul(iszero(iszero(z)), add(div(sub(z, 1), denominator), 1))
        }
    }

    function rpow(
        uint256 x,
        uint256 n,
        uint256 scalar
    ) internal pure returns (uint256 z) {
        assembly {
            switch x
            case 0 {
                switch n
                case 0 {
                    // 0 ** 0 = 1
                    z := scalar
                }
                default {
                    // 0 ** n = 0
                    z := 0
                }
            }
            default {
                switch mod(n, 2)
                case 0 {
                    // If n is even, store scalar in z for now.
                    z := scalar
                }
                default {
                    // If n is odd, store x in z for now.
                    z := x
                }

                // Shifting right by 1 is like dividing by 2.
                let half := shr(1, scalar)

                for {
                    // Shift n right by 1 before looping to halve it.
                    n := shr(1, n)
                } n {
                    // Shift n right by 1 each iteration to halve it.
                    n := shr(1, n)
                } {
                    // Revert immediately if x ** 2 would overflow.
                    // Equivalent to iszero(eq(div(xx, x), x)) here.
                    if shr(128, x) {
                        revert(0, 0)
                    }

                    // Store x squared.
                    let xx := mul(x, x)

                    // Round to the nearest number.
                    let xxRound := add(xx, half)

                    // Revert if xx + half overflowed.
                    if lt(xxRound, xx) {
                        revert(0, 0)
                    }

                    // Set x to scaled xxRound.
                    x := div(xxRound, scalar)

                    // If n is even:
                    if mod(n, 2) {
                        // Compute z * x.
                        let zx := mul(z, x)

                        // If z * x overflowed:
                        if iszero(eq(div(zx, x), z)) {
                            // Revert if x is non-zero.
                            if iszero(iszero(x)) {
                                revert(0, 0)
                            }
                        }

                        // Round to the nearest number.
                        let zxRound := add(zx, half)

                        // Revert if zx + half overflowed.
                        if lt(zxRound, zx) {
                            revert(0, 0)
                        }

                        // Return properly scaled zxRound.
                        z := div(zxRound, scalar)
                    }
                }
            }
        }
    }

    /*//////////////////////////////////////////////////////////////
                        GENERAL NUMBER UTILITIES
    //////////////////////////////////////////////////////////////*/

    function sqrt(uint256 x) internal pure returns (uint256 z) {
        assembly {
            let y := x // We start y at x, which will help us make our initial estimate.

            z := 181 // The "correct" value is 1, but this saves a multiplication later.

            // This segment is to get a reasonable initial estimate for the Babylonian method. With a bad
            // start, the correct # of bits increases ~linearly each iteration instead of ~quadratically.

            // We check y >= 2^(k + 8) but shift right by k bits
            // each branch to ensure that if x >= 256, then y >= 256.
            if iszero(lt(y, 0x10000000000000000000000000000000000)) {
                y := shr(128, y)
                z := shl(64, z)
            }
            if iszero(lt(y, 0x1000000000000000000)) {
                y := shr(64, y)
                z := shl(32, z)
            }
            if iszero(lt(y, 0x10000000000)) {
                y := shr(32, y)
                z := shl(16, z)
            }
            if iszero(lt(y, 0x1000000)) {
                y := shr(16, y)
                z := shl(8, z)
            }

            // Goal was to get z*z*y within a small factor of x. More iterations could
            // get y in a tighter range. Currently, we will have y in [256, 256*2^16).
            // We ensured y >= 256 so that the relative difference between y and y+1 is small.
            // That's not possible if x < 256 but we can just verify those cases exhaustively.

            // Now, z*z*y <= x < z*z*(y+1), and y <= 2^(16+8), and either y >= 256, or x < 256.
            // Correctness can be checked exhaustively for x < 256, so we assume y >= 256.
            // Then z*sqrt(y) is within sqrt(257)/sqrt(256) of sqrt(x), or about 20bps.

            // For s in the range [1/256, 256], the estimate f(s) = (181/1024) * (s+1) is in the range
            // (1/2.84 * sqrt(s), 2.84 * sqrt(s)), with largest error when s = 1 and when s = 256 or 1/256.

            // Since y is in [256, 256*2^16), let a = y/65536, so that a is in [1/256, 256). Then we can estimate
            // sqrt(y) using sqrt(65536) * 181/1024 * (a + 1) = 181/4 * (y + 65536)/65536 = 181 * (y + 65536)/2^18.

            // There is no overflow risk here since y < 2^136 after the first branch above.
            z := shr(18, mul(z, add(y, 65536))) // A mul() is saved from starting z at 181.

            // Given the worst case multiplicative error of 2.84 above, 7 iterations should be enough.
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))

            // If x+1 is a perfect square, the Babylonian method cycles between
            // floor(sqrt(x)) and ceil(sqrt(x)). This statement ensures we return floor.
            // See: https://en.wikipedia.org/wiki/Integer_square_root#Using_only_integer_division
            // Since the ceil is rare, we save gas on the assignment and repeat division in the rare case.
            // If you don't care whether the floor or ceil square root is returned, you can remove this statement.
            z := sub(z, lt(div(x, z), z))
        }
    }

    function log2(uint256 x) internal pure returns (uint256 r) {
        require(x > 0, "UNDEFINED");

        assembly {
            r := shl(7, lt(0xffffffffffffffffffffffffffffffff, x))
            r := or(r, shl(6, lt(0xffffffffffffffff, shr(r, x))))
            r := or(r, shl(5, lt(0xffffffff, shr(r, x))))
            r := or(r, shl(4, lt(0xffff, shr(r, x))))
            r := or(r, shl(3, lt(0xff, shr(r, x))))
            r := or(r, shl(2, lt(0xf, shr(r, x))))
            r := or(r, shl(1, lt(0x3, shr(r, x))))
            r := or(r, lt(0x1, shr(r, x)))
        }
    }

    function unsafeMod(uint256 x, uint256 y) internal pure returns (uint256 z) {
        assembly {
            // z will equal 0 if y is 0, unlike in Solidity where it will revert.
            z := mod(x, y)
        }
    }

    function unsafeDiv(uint256 x, uint256 y) internal pure returns (uint256 z) {
        assembly {
            // z will equal 0 if y is 0, unlike in Solidity where it will revert.
            z := div(x, y)
        }
    }

    /// @dev Will return 0 instead of reverting if y is zero.
    function unsafeDivUp(uint256 x, uint256 y) internal pure returns (uint256 z) {
        assembly {
            // Add 1 to x * y if x % y > 0.
            z := add(gt(mod(x, y), 0), div(x, y))
        }
    }
}

/*
    Copyright 2019 dYdX Trading Inc.

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.
*/

pragma solidity >=0.6.0;
pragma experimental ABIEncoderV2;

import { SafeMath } from "./SafeMath.sol";

/**
 * @title Decimal
 * @author dYdX
 *
 * Library that defines a fixed-point number with 18 decimal places.
 */
library Decimal {
    using SafeMath for uint256;

    // ============ Constants ============

    uint256 constant BASE = 10**18;

    // ============ Structs ============


    struct D256 {
        uint256 value;
    }

    // ============ Static Functions ============

    function zero()
    internal
    pure
    returns (D256 memory)
    {
        return D256({ value: 0 });
    }

    function one()
    internal
    pure
    returns (D256 memory)
    {
        return D256({ value: BASE });
    }

    function from(
        uint256 a
    )
    internal
    pure
    returns (D256 memory)
    {
        return D256({ value: a.mul(BASE) });
    }

    function ratio(
        uint256 a,
        uint256 b
    )
    internal
    pure
    returns (D256 memory)
    {
        return D256({ value: getPartial(a, BASE, b) });
    }

    // ============ Self Functions ============

    function add(
        D256 memory self,
        uint256 b
    )
    internal
    pure
    returns (D256 memory)
    {
        return D256({ value: self.value.add(b.mul(BASE)) });
    }

    function sub(
        D256 memory self,
        uint256 b
    )
    internal
    pure
    returns (D256 memory)
    {
        return D256({ value: self.value.sub(b.mul(BASE)) });
    }

    function sub(
        D256 memory self,
        uint256 b,
        string memory reason
    )
    internal
    pure
    returns (D256 memory)
    {
        return D256({ value: self.value.sub(b.mul(BASE), reason) });
    }

    function mul(
        D256 memory self,
        uint256 b
    )
    internal
    pure
    returns (D256 memory)
    {
        return D256({ value: self.value.mul(b) });
    }

    function div(
        D256 memory self,
        uint256 b
    )
    internal
    pure
    returns (D256 memory)
    {
        return D256({ value: self.value.div(b) });
    }

    function pow(
        D256 memory self,
        uint256 b
    )
    internal
    pure
    returns (D256 memory)
    {
        if (b == 0) {
            return from(1);
        }

        D256 memory temp = D256({ value: self.value });
        for (uint256 i = 1; i < b; i++) {
            temp = mul(temp, self);
        }

        return temp;
    }

    function add(
        D256 memory self,
        D256 memory b
    )
    internal
    pure
    returns (D256 memory)
    {
        return D256({ value: self.value.add(b.value) });
    }

    function sub(
        D256 memory self,
        D256 memory b
    )
    internal
    pure
    returns (D256 memory)
    {
        return D256({ value: self.value.sub(b.value) });
    }

    function sub(
        D256 memory self,
        D256 memory b,
        string memory reason
    )
    internal
    pure
    returns (D256 memory)
    {
        return D256({ value: self.value.sub(b.value, reason) });
    }

    function mul(
        D256 memory self,
        D256 memory b
    )
    internal
    pure
    returns (D256 memory)
    {
        return D256({ value: getPartial(self.value, b.value, BASE) });
    }

    function div(
        D256 memory self,
        D256 memory b
    )
    internal
    pure
    returns (D256 memory)
    {
        return D256({ value: getPartial(self.value, BASE, b.value) });
    }

    function equals(D256 memory self, D256 memory b) internal pure returns (bool) {
        return self.value == b.value;
    }

    function greaterThan(D256 memory self, D256 memory b) internal pure returns (bool) {
        return compareTo(self, b) == 2;
    }

    function lessThan(D256 memory self, D256 memory b) internal pure returns (bool) {
        return compareTo(self, b) == 0;
    }

    function greaterThanOrEqualTo(D256 memory self, D256 memory b) internal pure returns (bool) {
        return compareTo(self, b) > 0;
    }

    function lessThanOrEqualTo(D256 memory self, D256 memory b) internal pure returns (bool) {
        return compareTo(self, b) < 2;
    }

    function isZero(D256 memory self) internal pure returns (bool) {
        return self.value == 0;
    }

    function asUint256(D256 memory self) internal pure returns (uint256) {
        return self.value.div(BASE);
    }

    // ============ Core Methods ============

    function getPartial(
        uint256 target,
        uint256 numerator,
        uint256 denominator
    )
    private
    pure
    returns (uint256)
    {
        return target.mul(numerator).div(denominator);
    }

    function compareTo(
        D256 memory a,
        D256 memory b
    )
    private
    pure
    returns (uint256)
    {
        if (a.value == b.value) {
            return 1;
        }
        return a.value > b.value ? 2 : 0;
    }
}

pragma solidity >=0.6.0;

interface UnderlyingFeed {

    function symbol() external view returns (string memory);

    function getUnderlyingAddr() external view returns (address);

    function getUnderlyingAggAddr() external view returns (address);

    function getLatestPrice() external view returns (uint timestamp, int price);

    function getPrice(uint position) external view returns (uint timestamp, int price);

    function getDailyVolatility(uint timespan) external view returns (uint vol);

    function getDailyVolatilityCached(uint timespan) external view returns (uint vol, bool cached);

    function calcLowerVolatility(uint vol) external view returns (uint lowerVol);

    function calcUpperVolatility(uint vol) external view returns (uint upperVol);

    function prefetchSample() external;

    function prefetchDailyPrice(uint roundId) external;

    function prefetchDailyVolatility(uint timespan) external;
}

pragma solidity >=0.6.0;

interface IUnderlyingVault {
    function balanceOf(address owner, address token) external view returns (uint);
    function liquidate(address owner, address token, address feed, uint amountOut) external returns (uint _in, uint _out);
    function release(address owner, address token, address feed, uint value) external;
    function lock(address owner, address token, uint value) external;
}

pragma solidity >=0.6.0;
pragma experimental ABIEncoderV2;

interface IProtocolSettings {
	function getCreditWithdrawlTimeLock() external view returns (uint);
    function updateCreditWithdrawlTimeLock(uint duration) external;
	function checkPoolBuyCreditTradable(address poolAddress) external view returns (bool);
	function checkUdlIncentiveBlacklist(address udlAddr) external view returns (bool);
	function checkDexAggIncentiveBlacklist(address dexAggAddress) external view returns (bool);
    function checkPoolSellCreditTradable(address poolAddress) external view returns (bool);
    function getPoolCreditTradeable(address poolAddr) external view returns (uint);
	function applyCreditInterestRate(uint value, uint date) external view returns (uint);
	function getSwapRouterInfo() external view returns (address router, address token);
	function getSwapRouterTolerance() external view returns (uint r, uint b);
	function getSwapPath(address from, address to) external view returns (address[] memory path);
    function getTokenRate(address token) external view returns (uint v, uint b);
    function getCirculatingSupply() external view returns (uint);
    function getUdlFeed(address addr) external view returns (int);
    function setUdlCollateralManager(address udlFeed, address ctlMngr) external;
    function getUdlCollateralManager(address udlFeed) external view returns (address);
    function getVolatilityPeriod() external view returns(uint);
    function getAllowedTokens() external view returns (address[] memory);
    function setDexOracleTwapPeriod(address dexOracleAddress, uint256 _twapPeriod) external;
    function getDexOracleTwapPeriod(address dexOracleAddress) external view returns (uint256);
    function setBaseIncentivisation(uint amount) external;
    function getBaseIncentivisation() external view returns (uint);
    function getProcessingFee() external view returns (uint v, uint b);
    function getMinShareForProposal() external view returns (uint v, uint b);
    function isAllowedHedgingManager(address hedgeMngr) external view returns (bool);
    function isAllowedCustomPoolLeverage(address poolAddr) external view returns (bool);
    function transferTokenBalance(address to, address tokenAddr, uint256 value) external;
    function exchangeTime() external view returns (uint256);
}

pragma solidity >=0.6.0;
pragma experimental ABIEncoderV2;

interface IOptionsExchange {
    enum OptionType { CALL, PUT }
    
    struct OptionData {
        address udlFeed;
        OptionType _type;
        uint120 strike;
        uint32 maturity;
    }

    struct FeedData {
        uint120 lowerVol;
        uint120 upperVol;
    }

    struct OpenExposureVars {
        string symbol;
        uint vol;
        bool isCovered;
        address poolAddr;
        address[] _tokens;
        uint[] _uncovered;
        uint[] _holding;
    }

    struct OpenExposureInputs {
        string[] symbols;
        uint[] volume;
        bool[] isShort;
        bool[] isCovered;
        address[] poolAddrs;
        address[] paymentTokens;
    }

    function volumeBase() external view returns (uint);
    function collateral(address owner) external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function createPool(string calldata nameSuffix, string calldata symbolSuffix) external returns (address pool);
    function resolveToken(string calldata symbol) external view returns (address);
    function getExchangeFeeds(address udlFeed) external view returns (FeedData memory);
    function getFeedData(address udlFeed) external view returns (FeedData memory fd);
    function getBook(address owner) external view returns (string memory symbols, address[] memory tokens, uint[] memory holding, uint[] memory written, uint[] memory uncovered, int[] memory iv, address[] memory underlying);
    function getOptionData(address tkAddr) external view returns (IOptionsExchange.OptionData memory);
    function calcExpectedPayout(address owner) external view returns (int payout);
    function calcIntrinsicValue(address udlFeed, OptionType optType, uint strike, uint maturity) external view returns (int);
    function calcIntrinsicValue(OptionData calldata opt) external view returns (int value);
    function calcCollateral(address owner, bool is_regular) external view returns (uint);
    function calcCollateral(address udlFeed, uint volume, OptionType optType, uint strike,  uint maturity) external view returns (uint);
    function openExposure(
        OpenExposureInputs calldata oEi,
        address to
    ) external;
    function transferBalance(address to, uint value) external;
    function poolSymbols(uint index) external view returns (string memory);
    function totalPoolSymbols() external view returns (uint);
    function getPoolAddress(string calldata poolSymbol) external view returns (address);
    function transferBalance(address from, address to, uint value) external;
    function underlyingBalance(address owner, address _tk) external view returns (uint);
    function getOptionSymbol(OptionData calldata opt) external view returns (string memory symbol);
    function cleanUp(address owner, address _tk) external;
    function release(address owner, uint udl, uint coll) external;
    function depositTokens(address to, address token, uint value) external;
    function transferOwnership(string calldata symbol, address from, address to, uint value) external;
    function burn(address owner, uint value, address _tk) external;
}

pragma solidity >=0.6.0;

interface IOptionToken {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function burn(uint value) external;
    function issue(address from, address to, uint value) external;
    function burn(address owner, uint value) external;
    function writtenVolume(address owner) external view returns (uint);
    function uncoveredVolume(address owner) external view returns (uint);
    function permit(
        address owner, 
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;
}

pragma solidity >=0.6.0;

import "../interfaces/IOptionsExchange.sol";


interface IGovernableLiquidityPool {

    enum Operation { NONE, BUY, SELL }

    struct PricingParameters {
        address udlFeed;
        IOptionsExchange.OptionType optType;
        uint120 strike;
        uint32 maturity;
        uint32 t0;
        uint32 t1;
        uint[3] bsStockSpread; //buyStock == bsStockSpread[0], sellStock == bsStockSpread[1], spread == bsStockSpread[2]
        uint120[] x;
        uint120[] y;
    }

    struct Range {
        uint120 start;
        uint120 end;
    }

    event AddSymbol(string optSymbol);
    
    //event RemoveSymbol(string optSymbol);

    event Buy(address indexed token, address indexed buyer, uint price, uint volume);
    
    event Sell(address indexed token, address indexed seller, uint price, uint volume);

    function yield(uint dt) external view returns (uint);

    function depositTokens(address to, address token, uint value) external;

    function withdraw(uint amount) external;

    function valueOf(address ownr) external view returns (uint);
    
    function maturity() external view returns (uint);
    
    function withdrawFee() external view returns (uint);

    function calcFreeBalance() external view returns (uint balance);

    function listSymbols() external view returns (string memory available);

    function queryBuy(string calldata optSymbol, bool isBuy) external view returns (uint price, uint volume);


    function buy(string calldata optSymbol, uint price, uint volume, address token)
        external
        returns (address addr);

    function sell(
        string calldata optSymbol,
        uint price,
        uint volume
    )
        external;

    function getHedgingManager() external view returns (address manager);
    function getLeverage() external view returns (uint leverage);
    function getHedgeNotionalThreshold() external view returns (uint threshold);
}

pragma solidity >=0.6.0;
pragma experimental ABIEncoderV2;

interface ICreditProvider {
    function addBalance(address to, address token, uint value) external;
    function addBalance(uint value) external;
    function balanceOf(address owner) external view returns (uint);
    function totalTokenStock() external view returns (uint v);
    function grantTokens(address to, uint value) external;
    function getTotalOwners() external view returns (uint);
    function getTotalBalance() external view returns (uint);
    function processPayment(address from, address to, uint value) external;
    function transferBalance(address from, address to, uint value) external;
    function withdrawTokens(address owner, uint value) external;
    function withdrawTokens(address owner, uint value , address[] calldata tokensInOrder, uint[] calldata amountsOutInOrder) external;
    function insertPoolCaller(address llp) external;
    function processIncentivizationPayment(address to, uint credit) external;
    function borrowBuyLiquidity(address to, uint credit, address option) external;
    function borrowSellLiquidity(address to, uint credit, address option) external;
    function issueCredit(address to, uint value) external;
    function processEarlyLpWithdrawal(address to, uint credit) external;
    function nullOptionBorrowBalance(address option, address pool) external;
    function creditPoolBalance(address to, address token, uint value) external;
    function borrowTokensByPreference(address to, address pool, uint value, address[] calldata tokensInOrder, uint[] calldata amountsOutInOrder) external;
    function ensureCaller(address addr) external view;
}

pragma solidity >=0.6.0;
pragma experimental ABIEncoderV2;

interface IBaseHedgingManager {
	function getPosSize(address underlying, bool isLong) external view returns (uint[] memory);
    function getHedgeExposure(address underlying) external view returns (int256);
    function idealHedgeExposure(address underlying) external view returns (int256);
    function realHedgeExposure(address udlFeedAddr) external view returns (int256);
    function balanceExposure(address underlying) external returns (bool);
    function totalTokenStock() external view returns (uint v);
    function transferTokensToCreditProvider(address tokenAddr) external;

}

pragma solidity >=0.6.0;
pragma experimental ABIEncoderV2;

import "./IOptionsExchange.sol";

interface IBaseCollateralManager {
    function calcCollateral(IOptionsExchange.OptionData calldata opt, uint volume) external view returns (uint);
    function calcIntrinsicValue(IOptionsExchange.OptionData calldata opt) external view returns (int value);
    function calcCollateral(address owner, bool is_regular) external view returns (uint);
    function calcNetCollateral(address[] calldata _tokens, uint[] calldata _uncovered, uint[] calldata _holding, bool is_regular) external view returns (uint);
    function calcExpectedPayout(address owner) external view returns (int payout);
    function liquidateExpired(address _tk, address[] calldata owners) external;
    function liquidateOptions(address _tk, address owner) external returns (uint value);
    function queryPoolPrice(address poolAddr, string calldata symbol) external view returns (int);
    function getFeedData(address udlFeed) external view returns (IOptionsExchange.FeedData memory fd);
}

pragma solidity >=0.6.0;
pragma experimental ABIEncoderV2;

import "../deployment/Deployer.sol";
import "../deployment/ManagedContract.sol";
import "../interfaces/IProtocolSettings.sol";
import "../interfaces/UnderlyingFeed.sol";
import "../interfaces/IGovernableLiquidityPool.sol";
import "../interfaces/ICreditProvider.sol";
import "../interfaces/IOptionsExchange.sol";
import "../interfaces/IOptionToken.sol";
import "../interfaces/IUnderlyingVault.sol";
import "../interfaces/IBaseCollateralManager.sol";
import "../utils/SafeCast.sol";
import "../utils/MoreMath.sol";
import "../utils/Decimal.sol";

abstract contract BaseCollateralManager is ManagedContract, IBaseCollateralManager {

    using SafeCast for uint;
    using SafeMath for uint;
    using SignedSafeMath for int;
    using Decimal for Decimal.D256;
    
    IUnderlyingVault private vault;
    IProtocolSettings internal settings;
    ICreditProvider internal creditProvider;
    IOptionsExchange internal exchange;

    uint private timeBase;
    uint private sqrtTimeBase;
    uint private collateralCallPeriod;
    uint internal _volumeBase;

    mapping(address => mapping(address => uint256)) private writerCollateralCall;

    event LiquidateEarly(
        address indexed token,
        address indexed sender,
        address indexed onwer,
        uint volume
    );

    event CollateralCall(
        address indexed token,
        address indexed sender,
        address indexed onwer,
        uint volume
    );

    event LiquidateExpired(
        address indexed token,
        address indexed sender,
        address indexed onwer,
        uint volume
    );

    function initialize(Deployer deployer) virtual override internal {

        creditProvider = ICreditProvider(deployer.getContractAddress("CreditProvider"));
        settings = IProtocolSettings(deployer.getContractAddress("ProtocolSettings"));
        exchange = IOptionsExchange(deployer.getContractAddress("OptionsExchange"));
        vault = IUnderlyingVault(deployer.getContractAddress("UnderlyingVault"));

        _volumeBase = 1e18;
        timeBase = 1e18;
        sqrtTimeBase = 1e9;
        collateralCallPeriod = 1 days;
    }

    function collateralSkew() private view returns (int) {
        // core across all collateral models
        /*
            This allows the exchange to split any excess credit balance (due to debt) onto any new deposits while still holding debt balance for an individual account 
                OR
            split any excess stablecoin balance (due to more collected from debt than debt outstanding) to discount any new deposits()
        */
        int totalStableCoinBalance = int(creditProvider.totalTokenStock()); // stable coin balance
        int totalCreditBalance = int(creditProvider.getTotalBalance()); // credit balance
        int totalOwners = int(creditProvider.getTotalOwners()).add(1);
        int skew = totalCreditBalance.sub(totalStableCoinBalance);

        // try to split between if short stable coins
        return skew.div(totalOwners);  
    }

    function collateralSkewForPosition(int coll) internal view returns (int) {
        // core across all collateral models
        int modColl;
        int skew = collateralSkew();
        Decimal.D256 memory skewPct;
        if (skew != 0){
            skewPct = Decimal.ratio(uint(coll), MoreMath.abs(skew));
        } else {
            skewPct = Decimal.zero();
        }

        if (skewPct.greaterThanOrEqualTo(Decimal.one())) {
            modColl = coll.add(skew);
        } else {
            // shortage/surplus per addr exceeds underlying collateral reqs, only add/sub percentage increase of underlying collateral reqs

            int modSkew = int(Decimal.mul(skewPct, uint(coll)).asUint256());
            modColl = (skew >= 0) ? coll.add(modSkew) : coll.sub(modSkew);
        }

        return modColl;
    }

    function calcExpectedPayout(address owner) override external view returns (int payout) {
        // multi udl feed refs, need to make core accross all collateral models
        (,address[] memory _tokens, uint[] memory _holding, uint[] memory _written,, int[] memory _iv,) = exchange.getBook(owner);

        for (uint i = 0; i < _tokens.length; i++) {
            int price = queryPoolPrice(owner, IOptionToken(_tokens[i]).name());
            payout = payout.add(
                (price != 0 ? price : _iv[i]).mul(
                    int(_holding[i]).sub(int(_written[i]))
                )
            );
        }

        payout = payout.div(int(_volumeBase));
    }

    function calcCollateralInternal(address owner, bool is_regular) virtual internal view returns (int);

    function calcNetCollateralInternal(address[] memory _tokens, uint[] memory _uncovered, uint[] memory _holding, bool is_regular)  virtual internal view returns (int);

    function calcLiquidationVolume(
        address owner,
        IOptionsExchange.OptionData memory opt,
        address _tk,
        IOptionsExchange.FeedData memory fd,
        uint written
    )
        private
        returns (uint volume)
    {    
        uint bal = creditProvider.balanceOf(owner);
        uint coll = calcCollateral(owner, true);

        if (coll > bal) {
            if (writerCollateralCall[owner][_tk] != 0) {
                // cancel collateral call
                writerCollateralCall[owner][_tk] = 0;
            }
        }
        require(coll > bal, "Collateral Manager: unfit for liquidation");
        
        volume = coll.sub(bal).mul(_volumeBase).mul(written).div(
            calcCollateral(
                uint(fd.upperVol).sub(uint(fd.lowerVol)),
                written,
                opt
            )
        );

        volume = MoreMath.min(volume, written);
    }

    function calcLiquidationValue(
        IOptionsExchange.OptionData memory opt,
        uint vol,
        uint written,
        uint volume,
        uint iv
    )
        private
        view
        returns (uint value)
    {    
        value = calcCollateral(vol, written, opt).add(iv).mul(volume).div(written);
    }

    function calcIntrinsicValue(IOptionsExchange.OptionData memory opt) override public view returns (int value) {
        
        int udlPrice = getUdlPrice(opt);
        int strike = int(opt.strike);

        if (opt._type == IOptionsExchange.OptionType.CALL) {
            value = MoreMath.max(0, udlPrice.sub(strike));
        } else if (opt._type == IOptionsExchange.OptionType.PUT) {
            value = MoreMath.max(0, strike.sub(udlPrice));
        }
    }

    function queryPoolPrice(
        address poolAddr,
        string memory symbol
    )
        override public
        view
        returns (int)
    {
        uint price = 0;
        IGovernableLiquidityPool pool = IGovernableLiquidityPool(poolAddr);
        

        try pool.queryBuy(symbol, true) returns (uint _buyPrice, uint) {
            price = price.add(_buyPrice);
        } catch (bytes memory /*lowLevelData*/) {
            return 0;
        }

        try pool.queryBuy(symbol, false) returns (uint _sellPrice, uint) {
            price = price.add(_sellPrice);
        } catch (bytes memory /*lowLevelData*/) {
            return 0;
        }

        return int(price).div(2);
    }

    function getFeedData(address udlFeed) override public view returns (IOptionsExchange.FeedData memory fd) {
        UnderlyingFeed feed = UnderlyingFeed(udlFeed);

        uint vol = feed.getDailyVolatility(settings.getVolatilityPeriod());

        fd = IOptionsExchange.FeedData(
            feed.calcLowerVolatility(uint(vol)).toUint120(),
            feed.calcUpperVolatility(uint(vol)).toUint120()
        );
    }

    function calcCollateral(
        IOptionsExchange.OptionData calldata opt,
        uint volume
    ) override virtual external view returns (uint);
    
    function calcCollateral(uint vol, uint volume, IOptionsExchange.OptionData memory opt) internal view returns (uint) {
        
        return (vol.mul(volume).mul(
            MoreMath.sqrt(daysToMaturity(opt)))
        ).div(sqrtTimeBase);
    }

    function liquidateExpired(address _tk, address[] calldata owners) override external {

        IOptionsExchange.OptionData memory opt = exchange.getOptionData(_tk);
        IOptionToken tk = IOptionToken(_tk);
        require(getUdlNow(opt) >= opt.maturity, "Collateral Manager: option not expired");
        uint iv = uint(calcIntrinsicValue(opt));

        for (uint i = 0; i < owners.length; i++) {
            liquidateOptions(owners[i], opt, tk, true, iv);
        }
    }

    function liquidateOptions(address _tk, address owner) override external returns (uint value) {
        
        IOptionsExchange.OptionData memory opt = exchange.getOptionData(_tk);
        require(opt.udlFeed != address(0), "invalid token");

        IOptionToken tk = IOptionToken(_tk);
        require(tk.writtenVolume(owner) > 0, "Collateral Manager: invalid owner");

        bool isExpired = getUdlNow(opt) >= opt.maturity;
        uint iv = uint(calcIntrinsicValue(opt));
        
        value = liquidateOptions(owner, opt, tk, isExpired, iv);
    }

    function liquidateOptions(
        address owner,
        IOptionsExchange.OptionData memory opt,
        IOptionToken tk,
        bool isExpired,
        uint iv
    )
        private
        returns (uint value)
    {
        uint written = isExpired ?
            tk.writtenVolume(owner) :
            tk.uncoveredVolume(owner);
        iv = iv.mul(written);

        if (isExpired) {
            value = liquidateAfterMaturity(owner, tk, opt.udlFeed, written, iv);
            emit LiquidateExpired(address(tk), msg.sender, owner, written);
        } else {
            require(written > 0, "Collateral Manager: invalid volume");
            value = liquidateBeforeMaturity(owner, opt, tk, written, iv);
        }
    }



    function liquidateAfterMaturity(
        address owner,
        IOptionToken tk,
        address feed,
        uint written,
        uint iv
    )
        private
        returns (uint value)
    {

        // if borrowed liquidty was used to write options need to debit it from pool addr
        creditProvider.processIncentivizationPayment(msg.sender, settings.getBaseIncentivisation());
        creditProvider.nullOptionBorrowBalance(address(tk), owner);

        if (iv > 0) {
            value = iv.div(_volumeBase);
            vault.liquidate(owner, address(tk), feed, value);
            creditProvider.processPayment(owner, address(tk), value);
        }

        vault.release(owner, address(tk), feed, uint(-1));

        if (written > 0) {
            exchange.burn(owner, written, address(tk));
        }
    }

    function liquidateBeforeMaturity(
        address owner,
        IOptionsExchange.OptionData memory opt,
        IOptionToken tk,
        uint written,
        uint iv
    )
        private
        returns (uint value)
    {
        IOptionsExchange.FeedData memory fd = exchange.getExchangeFeeds(opt.udlFeed);
        address tkAddr = address(tk);
        uint volume = calcLiquidationVolume(owner, opt, tkAddr, fd, written);
        value = calcLiquidationValue(opt, fd.lowerVol, written, volume, iv)
            .div(_volumeBase);

        if (writerCollateralCall[owner][tkAddr] == 0){
            // the first time triggers a margin call event for the owner (how to incentivize? 10$ in exchange credit)
            if (msg.sender != owner) {
                writerCollateralCall[owner][tkAddr] = settings.exchangeTime();
                creditProvider.processIncentivizationPayment(msg.sender, settings.getBaseIncentivisation());
                emit CollateralCall(tkAddr, msg.sender, owner, volume);
            }
        } else {
            require(settings.exchangeTime().sub(writerCollateralCall[owner][tkAddr]) >= collateralCallPeriod, "Collateral Manager: active collateral call");
        }

        if (msg.sender != owner){
            // second step triggers the actual liquidation (incentivized, 5% of collateral liquidated in exchange creditbalance, owner gets charged 105%)
            uint256 creditingValue = value.mul(5).div(100);
            creditProvider.processPayment(owner, tkAddr, value.add(creditingValue));
            creditProvider.processIncentivizationPayment(msg.sender, creditingValue);
            // if borrowed liquidty was used to write options need to debit it from pool addr
            creditProvider.nullOptionBorrowBalance(address(tk), owner);
        }

        if (volume > 0) {
            exchange.burn(owner, volume, address(tk));
        }

        emit LiquidateEarly(tkAddr, msg.sender, owner, volume);
    }

    function calcCollateral(address owner, bool is_regular) override public view returns (uint) {     
        // takes custom collateral requirements and applies exchange level normalizations   
        int coll = calcCollateralInternal(owner, is_regular);
        
        coll = collateralSkewForPosition(coll);
        coll = coll.div(int(_volumeBase));

        if (is_regular == false) {
            return uint(coll);
        }

        if (coll < 0)
            return 0;
        return uint(coll);
    }

    function calcNetCollateral(address[] memory _tokens, uint[] memory _uncovered, uint[] memory _holding, bool is_regular) override public view returns (uint) {     
        // takes custom collateral requirements and applies exchange level normalizations on prospective positions
        int coll = calcNetCollateralInternal(_tokens, _uncovered, _holding, is_regular);
        
        coll = collateralSkewForPosition(coll);
        coll = coll.div(int(_volumeBase));

        if (is_regular == false) {
            return uint(coll);
        }

        if (coll < 0)
            return 0;
        return uint(coll);
    }

    function daysToMaturity(IOptionsExchange.OptionData memory opt) private view returns (uint d) {
        uint _now = getUdlNow(opt);
        if (opt.maturity > _now) {
            d = (timeBase.mul(uint(opt.maturity).sub(uint(_now)))).div(1 days);
        } else {
            d = 0;
        }
    }

    function getUdlPrice(IOptionsExchange.OptionData memory opt) internal view returns (int answer) {

        if (opt.maturity > settings.exchangeTime()) {
            (,answer) = UnderlyingFeed(opt.udlFeed).getLatestPrice();
        } else {
            (,answer) = UnderlyingFeed(opt.udlFeed).getPrice(opt.maturity);
        }
    }

    function getUdlNow(IOptionsExchange.OptionData memory opt) private view returns (uint timestamp) {
        (timestamp,) = UnderlyingFeed(opt.udlFeed).getLatestPrice();
    }
}

pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

// *** IMPORTANT ***
// "onwer" storage variable must be set to a GnosisSafe multisig wallet address:
// - https://github.com/gnosis/safe-contracts/blob/main/contracts/GnosisSafe.sol

contract Proxy {

    // ATTENTION: storage variable alignment
    address private owner;
    address private pendingOwner;
    address private implementation;
    uint private locked; // 1 = Initialized; 2 = Non upgradable
    // --------------------------------------------------------

    event OwnershipTransferRequested(address indexed from, address indexed to);
    
    event OwnershipTransferred(address indexed from, address indexed to);

    event SetNonUpgradable();

    event ImplementationUpdated(address indexed from, address indexed to);

    constructor(address _owner, address _implementation) public {

        owner = _owner;
        implementation = _implementation;
    }

    fallback () payable external {
        
        _fallback();
    }

    receive () payable external {

        _fallback();
    }
    
    function transferOwnership(address _to) external {
        
        require(msg.sender == owner);
        pendingOwner = _to;
        emit OwnershipTransferRequested(owner, _to);
    }

    function acceptOwnership() external {
    
        require(msg.sender == pendingOwner);
        address oldOwner = owner;
        owner = msg.sender;
        pendingOwner = address(0);
        emit OwnershipTransferred(oldOwner, msg.sender);
    }

    function setNonUpgradable() public {

        require(msg.sender == owner && locked == 1);
        locked = 2;
        emit SetNonUpgradable();
    }

    function setImplementation(address _implementation) public {

        require(msg.sender == owner && locked != 2);
        address oldImplementation = implementation;
        implementation = _implementation;
        emit ImplementationUpdated(oldImplementation, _implementation);
    }

    function delegate(address _implementation) internal {
        assembly {

            calldatacopy(0, 0, calldatasize())

            let result := delegatecall(gas(), _implementation, 0, calldatasize(), 0, 0)

            returndatacopy(0, 0, returndatasize())

            switch result

            case 0 { revert(0, returndatasize()) }
            default { return(0, returndatasize()) }
        }
    }

    function _fallback() internal {
        willFallback();
        delegate(implementation);
    }

    function willFallback() internal virtual {
        
    }
}

pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

import "./Deployer.sol";
// *** IMPORTANT ***
// "onwer" storage variable must be set to a GnosisSafe multisig wallet address:
// - https://github.com/gnosis/safe-contracts/blob/main/contracts/GnosisSafe.sol

contract ManagedContract {

    // ATTENTION: storage variable alignment
    address private owner;
    address private pendingOwner;
    address private implementation;
    uint private locked; // 1 = Initialized; 2 = Non upgradable
    // --------------------------------------------------------

    function initializeAndLock(Deployer deployer) public {

        require(locked == 0, "initialization locked");
        locked = 1;
        initialize(deployer);
    }

    function initialize(Deployer deployer) virtual internal {

    }

    function getOwner() public view returns (address) {

        return owner;
    }

    function getImplementation() public view returns (address) {

        return implementation;
    }
}

pragma solidity >=0.6.0;
pragma experimental ABIEncoderV2;

import "./ManagedContract.sol";
import "./Proxy.sol";

contract Deployer {

    struct ContractData {
        string key;
        address origAddr;
        bool upgradeable;
    }

    mapping(string => address) private contractMap;
    mapping(string => string) private aliases;

    address private owner;
    ContractData[] private contracts;
    bool private deployed;

    constructor(address _owner) public {

        owner = _owner;
    }

    function hasKey(string memory key) public view returns (bool) {
        
        return contractMap[key] != address(0) || contractMap[aliases[key]] != address(0);
    }

    function setContractAddress(string memory key, address addr) public {

        setContractAddress(key, addr, true);
    }

    function setContractAddress(string memory key, address addr, bool upgradeable) public {
        
        require(!hasKey(key), buildKeyAlreadySetMessage(key));

        ensureNotDeployed();
        ensureCaller();
        
        contracts.push(ContractData(key, addr, upgradeable));
        contractMap[key] = address(1);
    }

    function addAlias(string memory fromKey, string memory toKey) public {
        
        ensureNotDeployed();
        ensureCaller();
        require(contractMap[toKey] != address(0), buildAddressNotSetMessage(toKey));
        aliases[fromKey] = toKey;
    }

    function getContractAddress(string memory key) public view returns (address) {
        
        require(hasKey(key), buildAddressNotSetMessage(key));
        address addr = contractMap[key];
        if (addr == address(0)) {
            addr = contractMap[aliases[key]];
        }
        require(addr != address(1), buildProxyNotDeployedMessage(key));
        return addr;
    }

    function getPayableContractAddress(string memory key) public view returns (address payable) {

        return address(uint160(address(getContractAddress(key))));
    }

    function isDeployed() public view returns(bool) {
        
        return deployed;
    }

    function deploy() public {

        deploy(owner);
    }

    function deploy(address _owner) public {

        ensureNotDeployed();
        ensureCaller();
        deployed = true;

        for (uint i = contracts.length - 1; i != uint(-1); i--) {
            if (contractMap[contracts[i].key] == address(1)) {
                if (contracts[i].upgradeable) {
                    Proxy p = new Proxy(_owner, contracts[i].origAddr);
                    contractMap[contracts[i].key] = address(p);
                } else {
                    contractMap[contracts[i].key] = contracts[i].origAddr;
                }
            } else {
                contracts[i] = contracts[contracts.length - 1];
                contracts.pop();
            }
        }

        for (uint i = 0; i < contracts.length; i++) {
            if (contracts[i].upgradeable) {
                address p = contractMap[contracts[i].key];
                ManagedContract(p).initializeAndLock(this);
            }
        }
    }

    function reset() public {

        ensureCaller();
        deployed = false;

        for (uint i = 0; i < contracts.length; i++) {
            contractMap[contracts[i].key] = address(1);
        }
    }

    function ensureNotDeployed() private view {

        require(!deployed, "already deployed");
    }

    function ensureCaller() private view {

        require(owner == address(0) || msg.sender == owner, "unallowed caller");
    }

    function buildKeyAlreadySetMessage(string memory key) private pure returns(string memory) {

        return string(abi.encodePacked("key already set: ", key));
    }

    function buildAddressNotSetMessage(string memory key) private pure returns(string memory) {

        return string(abi.encodePacked("contract address not set: ", key));
    }

    function buildProxyNotDeployedMessage(string memory key) private pure returns(string memory) {

        return string(abi.encodePacked("proxy not deployed: ", key));
    }
}