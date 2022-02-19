/**
 *Submitted for verification at polygonscan.com on 2022-02-19
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

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

interface IUniswapV2Pair {
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

// computes square roots using the babylonian method
// https://en.wikipedia.org/wiki/Methods_of_computing_square_roots#Babylonian_method
library Babylonian {
    function sqrt(uint y) internal pure returns (uint z) {
        if (y > 3) {
            z = y;
            uint x = y / 2 + 1;
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
        uint _x;
    }

    uint8 private constant RESOLUTION = 112;
    uint private constant Q112 = uint(1) << RESOLUTION;
    uint private constant Q224 = Q112 << RESOLUTION;

    // encode a uint112 as a UQ112x112
    function encode(uint112 x) internal pure returns (uq112x112 memory) {
        return uq112x112(uint224(x) << RESOLUTION);
    }

    // encodes a uint144 as a UQ144x112
    function encode144(uint144 x) internal pure returns (uq144x112 memory) {
        return uq144x112(uint256(x) << RESOLUTION);
    }

    // divide a UQ112x112 by a uint112, returning a UQ112x112
    function div(uq112x112 memory self, uint112 x) internal pure returns (uq112x112 memory) {
        require(x != 0, 'FixedPoint: DIV_BY_ZERO');
        return uq112x112(self._x / uint224(x));
    }

    // multiply a UQ112x112 by a uint, returning a UQ144x112
    // reverts on overflow
    function mul(uq112x112 memory self, uint y) internal pure returns (uq144x112 memory) {
        uint z;
        require(y == 0 || (z = uint(self._x) * y) / y == uint(self._x), "FixedPoint: MULTIPLICATION_OVERFLOW");
        return uq144x112(z);
    }

    // returns a UQ112x112 which represents the ratio of the numerator to the denominator
    // equivalent to encode(numerator).div(denominator)
    function fraction(uint112 numerator, uint112 denominator) internal pure returns (uq112x112 memory) {
        require(denominator > 0, "FixedPoint: DIV_BY_ZERO");
        return uq112x112((uint224(numerator) << RESOLUTION) / denominator);
    }

    // decode a UQ112x112 into a uint112 by truncating after the radix point
    function decode(uq112x112 memory self) internal pure returns (uint112) {
        return uint112(self._x >> RESOLUTION);
    }

    // decode a UQ144x112 into a uint144 by truncating after the radix point
    function decode144(uq144x112 memory self) internal pure returns (uint144) {
        return uint144(self._x >> RESOLUTION);
    }

    // take the reciprocal of a UQ112x112
    function reciprocal(uq112x112 memory self) internal pure returns (uq112x112 memory) {
        require(self._x != 0, 'FixedPoint: ZERO_RECIPROCAL');
        return uq112x112(uint224(Q224 / self._x));
    }

    // square root of a UQ112x112
    function sqrt(uq112x112 memory self) internal pure returns (uq112x112 memory) {
        return uq112x112(uint224(Babylonian.sqrt(uint256(self._x)) << 56));
    }
}

// library with helper methods for oracles that are concerned with computing average prices
library UniswapV2OracleLibrary {
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
        price0Cumulative = IUniswapV2Pair(pair).price0CumulativeLast();
        price1Cumulative = IUniswapV2Pair(pair).price1CumulativeLast();

        // if time has elapsed since the last update on the pair, mock the accumulated price values
        (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast) = IUniswapV2Pair(pair).getReserves();
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

interface IUniswapOracle {
    function consult(address token, uint256 amountIn) external view returns (uint256);
    function getPrice() external view returns (uint256);
    function token0() external view returns (address);
    function token1() external view returns (address);
}

contract PriceOraclePolygon {
    address public iETHUSDCOracle;  // Uniswap Oracle
    address public xETHUSDCOracle;  // Uniswap Oracle
    address public IESUSDCOracle;  // Uniswap Oracle

    address public immutable ETHPriceOracleAddr;  // Chainlink Oracle
    address public immutable USDCPriceOracleAddr;  // Chainlink Oracle

    address public immutable ETHUSDCQSAddr;  // Uniswap Oracle
    address public immutable ETHUSDCSSAddr;  // Uniswap Oracle

    address public immutable iETH;
    address public immutable xETH;
    address public immutable IES;

    address public immutable wETH;
    address public immutable USDC;

    AggregatorV3Interface ethPriceFeed;
    AggregatorV3Interface usdcPriceFeed;

    constructor(
        address _iETHUSDCOracle,  // Uniswap pair for <iETH, USDC>
        address _xETHUSDCOracle,  // Uniswap pair for <xETH, USDC>
        address _IESUSDCOracle  // Uniswap pair for <IES, USDC>
    ) {
        if (_iETHUSDCOracle == address(0) ||
            _xETHUSDCOracle == address(0) ||
            _IESUSDCOracle == address(0)) revert("Invaild address");

        iETHUSDCOracle = _iETHUSDCOracle;
        xETHUSDCOracle = _xETHUSDCOracle;
        IESUSDCOracle = _IESUSDCOracle;

        ETHPriceOracleAddr = 0xF9680D99D6C9589e2a93a78A04A279e509205945;  // Polygon
        USDCPriceOracleAddr = 0xfE4A8cc5b5B2366C1B58Bea3858e81843581b2F7;  // Polygon

        ETHUSDCQSAddr = 0xF409Dc0636084826Ae50F4C3f40BaA4f1089D931;  // Quickswap
        ETHUSDCSSAddr = 0xBfDaDD461ea48fB63F586796Ba5Bea577f9AF0d8;  // Sushiwwap

        wETH = 0x7ceB23fD6bC0adD59E62ac25578270cFf1b9f619;
        USDC = 0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174;
        iETH = _getToken(iETHUSDCOracle);
        xETH = _getToken(xETHUSDCOracle);
        IES = _getToken(IESUSDCOracle);

        ethPriceFeed = AggregatorV3Interface(ETHPriceOracleAddr);
        usdcPriceFeed = AggregatorV3Interface(USDCPriceOracleAddr);
    }

    // Chainlink Oracle ETH/USD price
    function getETHPrice() external view returns (uint256) {
        return _getETHPrice();
    }

    // ETH-USDC uniswap market prices
    function getETHMarketPrice() external view returns (uint256) {
        return _getETHMarketPrice();
    }

    /// USDC/USD Chainlink market price
    function getUSDCPrice() external view returns (uint256) {
        return _getUSDCPrice();
    }

    function getIETHMarketPrice() external view returns (uint256) {
        return _getIETHMarketPrice();
    }

    function getXETHMarketPrice() external view returns (uint256) {
        return _getXETHMarketPrice();
    }

    function getIESMarketPrice() external view returns (uint256) {
        return _getIESMarketPrice();
    }

    function _getETHPrice() private view returns (uint256) {
        (,int price,,,) = ethPriceFeed.latestRoundData();
        require(price > 0, "Negative ETH price");
        return uint256(price) / 10**2;  // decimals 6
    }

    function _getUSDCPrice() private view returns (uint256) {
        (,int price,,,) = usdcPriceFeed.latestRoundData();
        require(price > 0, "Negative USDC price");
        return uint256(price) / 10**2;  // decimals 6
    }

    // Uniswap ETH-USDC market average price
    function _getETHMarketPrice() private view returns (uint256) {
        uint256 p1 = IUniswapOracle(ETHUSDCQSAddr).consult(wETH, 1e18);
        uint256 p2 = IUniswapOracle(ETHUSDCSSAddr).consult(wETH, 1e18);
        return p1/2 + p2/2;
    }

    // x*y=k. if x is iETH, and y is USDC, x has 18 decimals, and y has 6 decimals, then
    // k has 24 decimals. To get the price of iETH in terms of USDC, then put in
    // a number with 18 decimals, and the amount of USDC will be returned.
    function _getIETHMarketPrice() private view returns (uint256) {
        return IUniswapOracle(iETHUSDCOracle).consult(iETH, 1e18);  // iETH in, USDC out.
    }

    function _getXETHMarketPrice() private view returns (uint256) {
        return IUniswapOracle(xETHUSDCOracle).consult(xETH, 1e18);  // xETH in, USDC out
    }

    function _getIESMarketPrice() private view returns (uint256) {
        return IUniswapOracle(IESUSDCOracle).consult(IES, 1e18);  // IES in, USDC out
    }

    function _getToken(address oracle_) private view returns (address token) {
        IUniswapOracle oracle = IUniswapOracle(oracle_);
        token = oracle.token0();
        if (token == USDC) {
            token = oracle.token1();
        }
    }

    function _getMedian(uint256 x, uint256 y, uint256 z) private pure returns (uint256) {
        if (x > y) {
            if (y > z) {
                return y;
            } else if (x > z) {
                return z;
            } else { // x > y && y < z && x < z
                return x;
            }
        } else {
            if (y < z) {
                return y;
            } else if (x > z) {
                return x;
            } else {  // x < y && z < y && x < z
                return z;
            }
        }
    }
}