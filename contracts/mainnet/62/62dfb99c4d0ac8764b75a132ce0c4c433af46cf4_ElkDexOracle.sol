/**
 *Submitted for verification at polygonscan.com on 2023-07-17
*/

// SPDX-License-Identifier: BUSL-1.1
//
// Copyright (c) 2023 ElkLabs
// License terms: https://github.com/elkfinance/faas/blob/main/LICENSE
//
// Authors:
// - Seth <[email protected]>
// - Baal <[email protected]>
// - Elijah <[email protected]>
// - Snake <[email protected]>

// File: @elkdex/avax-exchange-contracts/contracts/elk-periphery/libraries/SafeMath.sol

pragma solidity =0.6.6;

// a library for performing overflow-safe math, courtesy of DappHub (https://github.com/dapphub/ds-math)

library SafeMath {
    function add(uint x, uint y) internal pure returns (uint z) {
        require((z = x + y) >= x, 'ds-math-add-overflow');
    }

    function sub(uint x, uint y) internal pure returns (uint z) {
        require((z = x - y) <= x, 'ds-math-sub-underflow');
    }

    function mul(uint x, uint y) internal pure returns (uint z) {
        require(y == 0 || (z = x * y) / y == x, 'ds-math-mul-overflow');
    }
}

// File: @elkdex/avax-exchange-contracts/contracts/elk-lib/libraries/Babylonian.sol



pragma solidity >=0.4.0;

// computes square roots using the babylonian method
// https://en.wikipedia.org/wiki/Methods_of_computing_square_roots#Babylonian_method
library Babylonian {
    function sqrt(uint256 y) internal pure returns (uint256 z) {
        if (y > 3) {
            z = y;
            uint256 x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
        // else z = 0
    }
}

// File: @elkdex/avax-exchange-contracts/contracts/elk-lib/libraries/FullMath.sol


pragma solidity >=0.4.0 <0.8.0;

// taken from https://medium.com/coinmonks/math-in-solidity-part-3-percents-and-proportions-4db014e080b1
// license is CC-BY-4.0
library FullMath {
    function fullMul(uint256 x, uint256 y) private pure returns (uint256 l, uint256 h) {
        uint256 mm = mulmod(x, y, uint256(-1));
        l = x * y;
        h = mm - l;
        if (mm < l) h -= 1;
    }

    function fullDiv(
        uint256 l,
        uint256 h,
        uint256 d
    ) private pure returns (uint256) {
        uint256 pow2 = d & -d;
        d /= pow2;
        l /= pow2;
        l += h * ((-pow2) / pow2 + 1);
        uint256 r = 1;
        r *= 2 - d * r;
        r *= 2 - d * r;
        r *= 2 - d * r;
        r *= 2 - d * r;
        r *= 2 - d * r;
        r *= 2 - d * r;
        r *= 2 - d * r;
        r *= 2 - d * r;
        return l * r;
    }

    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 d
    ) internal pure returns (uint256) {
        (uint256 l, uint256 h) = fullMul(x, y);
        uint256 mm = mulmod(x, y, d);
        if (mm > l) h -= 1;
        l -= mm;
        require(h < d, 'FullMath: FULLDIV_OVERFLOW');
        return fullDiv(l, h, d);
    }
}

// File: @elkdex/avax-exchange-contracts/contracts/elk-lib/libraries/FixedPoint.sol


pragma solidity >=0.4.0 <0.8.0;



// a library for handling binary fixed point numbers (https://en.wikipedia.org/wiki/Q_(number_format))
library FixedPoint {
    // range: [0, 2**112 - 1]
    // resolution: 1 / 2**112
    struct uq112x112 {
        uint224 _x;
    }

    // range: [0, 2**144 - 1]
    // resolution: 1 / 2**112
    struct uq144x112 {
        uint256 _x;
    }

    uint8 private constant RESOLUTION = 112;
    uint256 private constant Q112 = 0x10000000000000000000000000000;
    uint256 private constant Q224 = 0x100000000000000000000000000000000000000000000000000000000;
    uint256 private constant LOWER_MASK = 0xffffffffffffffffffffffffffff; // decimal of UQ*x112 (lower 112 bits)

    // encode a uint112 as a UQ112x112
    function encode(uint112 x) internal pure returns (uq112x112 memory) {
        return uq112x112(uint224(x) << RESOLUTION);
    }

    // encodes a uint144 as a UQ144x112
    function encode144(uint144 x) internal pure returns (uq144x112 memory) {
        return uq144x112(uint256(x) << RESOLUTION);
    }

    // decode a UQ112x112 into a uint112 by truncating after the radix point
    function decode(uq112x112 memory self) internal pure returns (uint112) {
        return uint112(self._x >> RESOLUTION);
    }

    // decode a UQ144x112 into a uint144 by truncating after the radix point
    function decode144(uq144x112 memory self) internal pure returns (uint144) {
        return uint144(self._x >> RESOLUTION);
    }

    // multiply a UQ112x112 by a uint, returning a UQ144x112
    // reverts on overflow
    function mul(uq112x112 memory self, uint256 y) internal pure returns (uq144x112 memory) {
        uint256 z = 0;
        require(y == 0 || (z = self._x * y) / y == self._x, 'FixedPoint: MUL_OVERFLOW');
        return uq144x112(z);
    }

    // multiply a UQ112x112 by an int and decode, returning an int
    // reverts on overflow
    function muli(uq112x112 memory self, int256 y) internal pure returns (int256) {
        uint256 z = FullMath.mulDiv(self._x, uint256(y < 0 ? -y : y), Q112);
        require(z < 2**255, 'FixedPoint: MULI_OVERFLOW');
        return y < 0 ? -int256(z) : int256(z);
    }

    // multiply a UQ112x112 by a UQ112x112, returning a UQ112x112
    // lossy
    function muluq(uq112x112 memory self, uq112x112 memory other) internal pure returns (uq112x112 memory) {
        if (self._x == 0 || other._x == 0) {
            return uq112x112(0);
        }
        uint112 upper_self = uint112(self._x >> RESOLUTION); // * 2^0
        uint112 lower_self = uint112(self._x & LOWER_MASK); // * 2^-112
        uint112 upper_other = uint112(other._x >> RESOLUTION); // * 2^0
        uint112 lower_other = uint112(other._x & LOWER_MASK); // * 2^-112

        // partial products
        uint224 upper = uint224(upper_self) * upper_other; // * 2^0
        uint224 lower = uint224(lower_self) * lower_other; // * 2^-224
        uint224 uppers_lowero = uint224(upper_self) * lower_other; // * 2^-112
        uint224 uppero_lowers = uint224(upper_other) * lower_self; // * 2^-112

        // so the bit shift does not overflow
        require(upper <= uint112(-1), 'FixedPoint: MULUQ_OVERFLOW_UPPER');

        // this cannot exceed 256 bits, all values are 224 bits
        uint256 sum = uint256(upper << RESOLUTION) + uppers_lowero + uppero_lowers + (lower >> RESOLUTION);

        // so the cast does not overflow
        require(sum <= uint224(-1), 'FixedPoint: MULUQ_OVERFLOW_SUM');

        return uq112x112(uint224(sum));
    }

    // divide a UQ112x112 by a UQ112x112, returning a UQ112x112
    function divuq(uq112x112 memory self, uq112x112 memory other) internal pure returns (uq112x112 memory) {
        require(other._x > 0, 'FixedPoint: DIV_BY_ZERO_DIVUQ');
        if (self._x == other._x) {
            return uq112x112(uint224(Q112));
        }
        if (self._x <= uint144(-1)) {
            uint256 value = (uint256(self._x) << RESOLUTION) / other._x;
            require(value <= uint224(-1), 'FixedPoint: DIVUQ_OVERFLOW');
            return uq112x112(uint224(value));
        }

        uint256 result = FullMath.mulDiv(Q112, self._x, other._x);
        require(result <= uint224(-1), 'FixedPoint: DIVUQ_OVERFLOW');
        return uq112x112(uint224(result));
    }

    // returns a UQ112x112 which represents the ratio of the numerator to the denominator
    // lossy
    function fraction(uint112 numerator, uint112 denominator) internal pure returns (uq112x112 memory) {
        require(denominator > 0, 'FixedPoint: DIV_BY_ZERO_FRACTION');
        return uq112x112((uint224(numerator) << RESOLUTION) / denominator);
    }

    // take the reciprocal of a UQ112x112
    // reverts on overflow
    // lossy
    function reciprocal(uq112x112 memory self) internal pure returns (uq112x112 memory) {
        require(self._x > 1, 'FixedPoint: DIV_BY_ZERO_RECIPROCAL_OR_OVERFLOW');
        return uq112x112(uint224(Q224 / self._x));
    }

    // square root of a UQ112x112
    // lossy between 0/1 and 40 bits
    function sqrt(uq112x112 memory self) internal pure returns (uq112x112 memory) {
        if (self._x <= uint144(-1)) {
            return uq112x112(uint224(Babylonian.sqrt(uint256(self._x) << 112)));
        }

        uint8 safeShiftBits = 32;
        while (safeShiftBits < 112) {
            if (self._x < (uint256(1) << (256 - safeShiftBits - 2))) {
                safeShiftBits += 2;
            } else {
                break;
            }
        }
        return uq112x112(uint224(Babylonian.sqrt(uint256(self._x) << safeShiftBits) << ((112 - safeShiftBits) / 2)));
    }
}

// File: @elkdex/avax-exchange-contracts/contracts/elk-core/interfaces/IElkPair.sol

pragma solidity >=0.5.0;

interface IElkPair {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;

    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    function kLast() external view returns (uint);

    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;

    function initialize(address, address) external;
}

// File: @elkdex/avax-exchange-contracts/contracts/elk-periphery/libraries/UniswapV2OracleLibrary.sol

pragma solidity >=0.5.0;



// library with helper methods for oracles that are concerned with computing average prices
library ElkOracleLibrary {
    using FixedPoint for *;

    // helper function that returns the current block timestamp within the range of uint32, i.e. [0, 2**32 - 1]
    function currentBlockTimestamp() internal view returns (uint32) {
        return uint32(block.timestamp % 2 ** 32);
    }

    // produces the cumulative price using counterfactuals to save gas and avoid a call to sync.
    function currentCumulativePrices(
        address pair
    ) internal view returns (uint price0Cumulative, uint price1Cumulative, uint32 blockTimestamp) {
        blockTimestamp = currentBlockTimestamp();
        price0Cumulative = IElkPair(pair).price0CumulativeLast();
        price1Cumulative = IElkPair(pair).price1CumulativeLast();

        // if time has elapsed since the last update on the pair, mock the accumulated price values
        (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast) = IElkPair(pair).getReserves();
        if (blockTimestampLast != blockTimestamp) {
            // subtraction overflow is desired
            uint32 timeElapsed = blockTimestamp - blockTimestampLast;
            // addition overflow is desired
            // counterfactual
            price0Cumulative += uint(FixedPoint.fraction(reserve1, reserve0)._x) * timeElapsed;
            // counterfactual
            price1Cumulative += uint(FixedPoint.fraction(reserve0, reserve1)._x) * timeElapsed;
        }
    }
}

// File: @elkdex/avax-exchange-contracts/contracts/elk-core/interfaces/IElkFactory.sol

pragma solidity >=0.5.0;

interface IElkFactory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
}

// File: @elkdex/avax-exchange-contracts/contracts/elk-periphery/libraries/ElkLibrary.sol

pragma solidity >=0.5.0;




library ElkLibrary {
    using SafeMath for uint;

    // returns sorted token addresses, used to handle return values from pairs sorted in this order
    function sortTokens(address tokenA, address tokenB) internal pure returns (address token0, address token1) {
        require(tokenA != tokenB, 'ElkLibrary: IDENTICAL_ADDRESSES');
        (token0, token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        require(token0 != address(0), 'ElkLibrary: ZERO_ADDRESS');
    }

    // calculates the CREATE2 address for a pair without making any external calls
    function pairFor(address factory, address tokenA, address tokenB) internal pure returns (address pair) {
        (address token0, address token1) = sortTokens(tokenA, tokenB);
        pair = address(uint(keccak256(abi.encodePacked(
                hex'ff',
                factory,
                keccak256(abi.encodePacked(token0, token1)),
                hex'84845e7ccb283dec564acfcd3d9287a491dec6d675705545a2ab8be22ad78f31' // init code hash
            ))));
    }

    // fetches and sorts the reserves for a pair
    function getReserves(address factory, address tokenA, address tokenB) internal view returns (uint reserveA, uint reserveB) {
        (address token0,) = sortTokens(tokenA, tokenB);
        (uint reserve0, uint reserve1,) = IElkPair(pairFor(factory, tokenA, tokenB)).getReserves();
        (reserveA, reserveB) = tokenA == token0 ? (reserve0, reserve1) : (reserve1, reserve0);
    }

    // given some amount of an asset and pair reserves, returns an equivalent amount of the other asset
    function quote(uint amountA, uint reserveA, uint reserveB) internal pure returns (uint amountB) {
        require(amountA > 0, 'ElkLibrary: INSUFFICIENT_AMOUNT');
        require(reserveA > 0 && reserveB > 0, 'ElkLibrary: INSUFFICIENT_LIQUIDITY');
        amountB = amountA.mul(reserveB) / reserveA;
    }

    // given an input amount of an asset and pair reserves, returns the maximum output amount of the other asset
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) internal pure returns (uint amountOut) {
        require(amountIn > 0, 'ElkLibrary: INSUFFICIENT_INPUT_AMOUNT');
        require(reserveIn > 0 && reserveOut > 0, 'ElkLibrary: INSUFFICIENT_LIQUIDITY');
        uint amountInWithFee = amountIn.mul(997);
        uint numerator = amountInWithFee.mul(reserveOut);
        uint denominator = reserveIn.mul(1000).add(amountInWithFee);
        amountOut = numerator / denominator;
    }

    // given an output amount of an asset and pair reserves, returns a required input amount of the other asset
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) internal pure returns (uint amountIn) {
        require(amountOut > 0, 'ElkLibrary: INSUFFICIENT_OUTPUT_AMOUNT');
        require(reserveIn > 0 && reserveOut > 0, 'ElkLibrary: INSUFFICIENT_LIQUIDITY');
        uint numerator = reserveIn.mul(amountOut).mul(1000);
        uint denominator = reserveOut.sub(amountOut).mul(997);
        amountIn = (numerator / denominator).add(1);
    }

    // performs chained getAmountOut calculations on any number of pairs
    function getAmountsOut(address factory, uint amountIn, address[] memory path) internal view returns (uint[] memory amounts) {
        require(path.length >= 2, 'ElkLibrary: INVALID_PATH');
        amounts = new uint[](path.length);
        amounts[0] = amountIn;
        for (uint i; i < path.length - 1; i++) {
            (uint reserveIn, uint reserveOut) = getReserves(factory, path[i], path[i + 1]);
            amounts[i + 1] = getAmountOut(amounts[i], reserveIn, reserveOut);
        }
    }

    // performs chained getAmountIn calculations on any number of pairs
    function getAmountsIn(address factory, uint amountOut, address[] memory path) internal view returns (uint[] memory amounts) {
        require(path.length >= 2, 'ElkLibrary: INVALID_PATH');
        amounts = new uint[](path.length);
        amounts[amounts.length - 1] = amountOut;
        for (uint i = path.length - 1; i > 0; i--) {
            (uint reserveIn, uint reserveOut) = getReserves(factory, path[i - 1], path[i]);
            amounts[i - 1] = getAmountIn(amounts[i], reserveIn, reserveOut);
        }
    }
}

// File: contracts/ElkDexOracle.sol


//
// Copyright (c) 2023 ElkLabs
// License terms: https://github.com/elkfinance/faas/blob/main/LICENSE
//
// Authors:
// - Seth <[email protected]>
// - Baal <[email protected]>
// - Elijah <[email protected]>
// - Snake <[email protected]>

pragma solidity =0.6.6;







/**
 * @title SlidingWindowOracle
 * @notice provides moving price averages in the past `windowSize` with a precision of `windowSize / granularity`
 * @dev this is a singleton oracle. only needs to be deployed once per desired parameters.
 * @dev differs from the simple oracle which must be deployed once per pair.
 */
contract ElkDexOracle {
    using FixedPoint for *;
    using SafeMath for uint;

    struct Observation {
        uint timestamp;
        uint price0Cumulative;
        uint price1Cumulative;
    }

    /* ========== STATE VARIABLES ========== */

    /// @notice the wrapped native currency on this chain
    address public immutable weth;

    /// @notice the ElkDex factory
    address public immutable factory;

    /// @notice the desired amount of time over which the moving average should be computed, e.g. 24 hours
    uint public immutable windowSize;

    /**
     * @notice the number of observations stored for each pair,
     * @dev i.e. how many price observations are stored for the window.
     * as granularity increases from 1, more frequent updates are needed, but moving averages become more precise.
     * averages are computed over intervals with sizes in the range:
     *   [windowSize - (windowSize / granularity) * 2, windowSize]
     * e.g. if the window size is 24 hours, and the granularity is 24, the oracle will return the average price for
     *   the period:
     *   [now - [22 hours, 24 hours], now]
     */
    uint8 public immutable granularity;

    // this is redundant with granularity and windowSize, but stored for gas savings & informational purposes.
    uint public immutable periodSize;

    // mapping from pair address to a list of price observations of that pair
    mapping(address => Observation[]) public pairObservations;

    /**
     * @param _weth the address of the WETH contract
     * @param _factory the address of the ElkFactory contract
     * @param _windowSize the size of the time window over which the moving average is computed
     * @param _granularity the number of observations to store for each pair
     */
    constructor(
        address _weth,
        address _factory,
        uint _windowSize,
        uint8 _granularity
    ) public {
        require(_weth != address(0) && _factory != address(0), "ElkDexOracle: ZERO_ADDRESS");
        require(_granularity > 1, "ElkDexOracle: GRANULARITY");
        require(
            (periodSize = _windowSize / _granularity) * _granularity ==
                _windowSize,
            "ElkDexOracle: WINDOW_NOT_EVENLY_DIVISIBLE"
        );
        weth = _weth;
        factory = _factory;
        windowSize = _windowSize;
        granularity = _granularity;
    }

    /**
     * @notice returns the current price of the token in terms of the WETH token
     * @return index of the observation corresponding to the given timestamp
     */
    function observationIndexOf(
        uint _timestamp
    ) public view returns (uint8 index) {
        uint epochPeriod = _timestamp / periodSize;
        return uint8(epochPeriod % granularity);
    }

    /**
     * @notice returns the current price of the token in terms of the WETH token
     * @param _pair the address of the token pair to compute the price of
     * @return firstObservation the observation from the oldest epoch (at the beginning of the window) relative to the current time
     */
    function getFirstObservationInWindow(
        address _pair
    ) private view returns (Observation storage firstObservation) {
        uint8 observationIndex = observationIndexOf(block.timestamp);
        // no overflow issue. if observationIndex + 1 overflows, result is still zero.
        uint8 firstObservationIndex = (observationIndex + 1) % granularity;
        firstObservation = pairObservations[_pair][firstObservationIndex];
    }

    /**
     * @notice update the cumulative price for the observation at the current timestamp. each observation is updated at most once per epoch period.
     * @param _tokenA the address of the first token in the pair
     * @param _tokenB the address of the second token in the pair
     */
    function update(address _tokenA, address _tokenB) public {
        
        // Do nothing if both tokens are weth of the chain. Still want to require the tokens to be different for 
        // the remaining logic.
        if (_tokenA == weth && _tokenB == weth) {
            return;
        } 

        require(_tokenA != _tokenB, "ElkDexOracle: IDENTICAL_ADDRESSES");

        address pair = ElkLibrary.pairFor(factory, _tokenA, _tokenB);

        /// @dev populate the array with empty observations (first call only)
        for (uint i = pairObservations[pair].length; i < granularity; i++) {
            pairObservations[pair].push();
        }

        /// @dev get the observation for the current period
        uint8 observationIndex = observationIndexOf(block.timestamp);
        Observation storage observation = pairObservations[pair][
            observationIndex
        ];

        /// @dev we only want to commit updates once per period (i.e. windowSize / granularity)
        uint timeElapsed = block.timestamp - observation.timestamp;
        if (timeElapsed > periodSize) {
            (uint price0Cumulative, uint price1Cumulative, ) = ElkOracleLibrary
                .currentCumulativePrices(pair);
            observation.timestamp = block.timestamp;
            observation.price0Cumulative = price0Cumulative;
            observation.price1Cumulative = price1Cumulative;
        }
    }

    /**
     * @notice returns the current price of the token in terms of the WETH token
     * @param _token the address of the token to compute the price of
     */
    function updateWeth(address _token) external {
        update(_token, weth);
    }

    /**
     * @notice given the cumulative prices of the start and end of a period, and the length of the period, compute the average price in terms of how much amount out is received for the amount in.
     * @param _priceCumulativeStart the cumulative price at the beginning of the period
     * @param _priceCumulativeEnd the cumulative price at the end of the period
     * @param _timeElapsed the length of the period over which the cumulative prices span
     * @param _amountIn the amount of token in to compute the output amount of token out
     */
    function computeAmountOut(
        uint _priceCumulativeStart,
        uint _priceCumulativeEnd,
        uint _timeElapsed,
        uint _amountIn
    ) private pure returns (uint amountOut) {
        // overflow is desired.
        FixedPoint.uq112x112 memory priceAverage = FixedPoint.uq112x112(
            uint224(
                (_priceCumulativeEnd - _priceCumulativeStart) / _timeElapsed
            )
        );
        amountOut = priceAverage.mul(_amountIn).decode144();
    }

    /**
     * @notice returns the amount out corresponding to the amount in for a given token using the moving average over the time range [now - [windowSize, windowSize - periodSize * 2], now]
     * @dev update must have been called for the bucket corresponding to timestamp `now - windowSize`
     * @param _tokenIn the address of the token to swap from
     * @param _amountIn the amount of token to swap from
     * @param _tokenOut the address of the token to swap to
     * @return amountOut the amount of token to swap to
     */
    function consult(
        address _tokenIn,
        uint _amountIn,
        address _tokenOut
    ) public view returns (uint amountOut) {
        if (_tokenIn == _tokenOut) {
            return _amountIn;
        }

        address pair = ElkLibrary.pairFor(factory, _tokenIn, _tokenOut);
        Observation storage firstObservation = getFirstObservationInWindow(
            pair
        );

        uint timeElapsed = block.timestamp - firstObservation.timestamp;
        require(
            timeElapsed <= windowSize,
            "ElkDexOracle: MISSING_HISTORICAL_OBSERVATION"
        );

        /// @dev should never happen.
        require(
            timeElapsed >= windowSize - periodSize * 2,
            "ElkDexOracle: UNEXPECTED_TIME_ELAPSED"
        );

        (uint price0Cumulative, uint price1Cumulative, ) = ElkOracleLibrary
            .currentCumulativePrices(pair);
        (address token0, ) = ElkLibrary.sortTokens(_tokenIn, _tokenOut);

        if (token0 == _tokenIn) {
            return
                computeAmountOut(
                    firstObservation.price0Cumulative,
                    price0Cumulative,
                    timeElapsed,
                    _amountIn
                );
        } else {
            return
                computeAmountOut(
                    firstObservation.price1Cumulative,
                    price1Cumulative,
                    timeElapsed,
                    _amountIn
                );
        }
    }

    /**
     * @notice calls consult for the WETH token
     * @param _tokenIn the address of the token to swap from
     * @param _amountIn the amount of token to swap from
     * @return amountOut the amount of WETH to swap to
     */
    function consultWeth(
        address _tokenIn,
        uint _amountIn
    ) external view returns (uint amountOut) {
        return consult(_tokenIn, _amountIn, weth);
    }
}