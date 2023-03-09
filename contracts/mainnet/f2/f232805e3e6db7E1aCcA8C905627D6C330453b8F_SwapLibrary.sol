// SPDX-License-Identifier: MIT

pragma solidity 0.8.13;

import "../interface/IRouter.sol";
import "../interface/IFactory.sol";
import "../interface/IPair.sol";
import "../lib/Math.sol";

contract SwapLibrary {
    address public immutable factory;
    IRouter public immutable router;
    bytes32 immutable pairCodeHash;

    constructor(address _router) {
        router = IRouter(_router);
        factory = IRouter(_router).factory();
        pairCodeHash = IFactory(IRouter(_router).factory()).pairCodeHash();
    }

    function _f(uint x0, uint y) internal pure returns (uint) {
        return (x0 * ((((y * y) / 1e18) * y) / 1e18)) / 1e18 + (((((x0 * x0) / 1e18) * x0) / 1e18) * y) / 1e18;
    }

    function _d(uint x0, uint y) internal pure returns (uint) {
        return (3 * x0 * ((y * y) / 1e18)) / 1e18 + ((((x0 * x0) / 1e18) * x0) / 1e18);
    }

    function _get_y(uint x0, uint xy, uint y) internal pure returns (uint) {
        for (uint i = 0; i < 255; i++) {
            uint y_prev = y;
            uint k = _f(x0, y);
            if (k < xy) {
                uint dy = ((xy - k) * 1e18) / _d(x0, y);
                y = y + dy;
            } else {
                uint dy = ((k - xy) * 1e18) / _d(x0, y);
                y = y - dy;
            }
            if (y > y_prev) {
                if (y - y_prev <= 1) {
                    return y;
                }
            } else {
                if (y_prev - y <= 1) {
                    return y;
                }
            }
        }
        return y;
    }

    function getTradeDiff(uint amountIn, address tokenIn, address tokenOut, bool stable) external view returns (uint a, uint b) {
        (uint dec0, uint dec1, uint r0, uint r1, bool st, address t0, ) = IPair(router.pairFor(tokenIn, tokenOut, stable)).metadata();
        uint sample = tokenIn == t0 ? (r0 * dec1) / r1 : (r1 * dec0) / r0;
        a = (_getAmountOut(sample, tokenIn, r0, r1, t0, dec0, dec1, st) * 1e18) / sample;
        b = (_getAmountOut(amountIn, tokenIn, r0, r1, t0, dec0, dec1, st) * 1e18) / amountIn;
    }

    function getTradeDiffSimple(uint amountIn, address tokenIn, address tokenOut, bool stable, uint sample) external view returns (uint a, uint b) {
        (uint dec0, uint dec1, uint r0, uint r1, bool st, address t0, ) = IPair(router.pairFor(tokenIn, tokenOut, stable)).metadata();
        if (sample == 0) {
            sample = _calcSample(tokenIn, t0, dec0, dec1);
        }
        a = (_getAmountOut(sample, tokenIn, r0, r1, t0, dec0, dec1, st) * 1e18) / sample;
        b = (_getAmountOut(amountIn, tokenIn, r0, r1, t0, dec0, dec1, st) * 1e18) / amountIn;
    }

    function getTradeDiff2(uint amountIn, address tokenIn, address tokenOut, bool stable) external view returns (uint a, uint b) {
        (uint dec0, uint dec1, uint r0, uint r1, bool st, address t0, ) = IPair(router.pairFor(tokenIn, tokenOut, stable)).metadata();
        uint sample;
        if (!stable) {
            sample = tokenIn == t0 ? (r0 * dec1) / r1 : (r1 * dec0) / r0;
        } else {
            sample = _calcSample(tokenIn, t0, dec0, dec1);
        }
        a = (_getAmountOut(sample, tokenIn, r0, r1, t0, dec0, dec1, st) * 1e18) / sample;
        b = (_getAmountOut(amountIn, tokenIn, r0, r1, t0, dec0, dec1, st) * 1e18) / amountIn;
    }

    function getTradeDiff3(uint amountIn, address tokenIn, address tokenOut, bool stable) external view returns (uint a, uint b) {
        (uint dec0, uint dec1, uint r0, uint r1, bool st, address t0, ) = IPair(router.pairFor(tokenIn, tokenOut, stable)).metadata();
        uint sample;
        if (!stable) {
            a = (amountIn * 1e18) / (tokenIn == t0 ? (r0 * 1e18) / r1 : (r1 * 1e18) / r0);
        } else {
            sample = _calcSample(tokenIn, t0, dec0, dec1);
            a = (_getAmountOut(sample, tokenIn, r0, r1, t0, dec0, dec1, st) * amountIn) / sample;
        }
        b = _getAmountOut(amountIn, tokenIn, r0, r1, t0, dec0, dec1, st);
    }

    function _calcSample(address tokenIn, address t0, uint dec0, uint dec1) internal pure returns (uint) {
        uint tokenInDecimals = tokenIn == t0 ? dec0 : dec1;
        uint tokenOutDecimals = tokenIn == t0 ? dec1 : dec0;
        return 10 ** Math.max((tokenInDecimals > tokenOutDecimals ? tokenInDecimals - tokenOutDecimals : tokenOutDecimals - tokenInDecimals), 1) * 10_000;
    }

    function getTradeDiff(uint amountIn, address tokenIn, address pair) external view returns (uint a, uint b) {
        (uint dec0, uint dec1, uint r0, uint r1, bool st, address t0, ) = IPair(pair).metadata();
        uint sample = tokenIn == t0 ? (r0 * dec1) / r1 : (r1 * dec0) / r0;
        a = (_getAmountOut(sample, tokenIn, r0, r1, t0, dec0, dec1, st) * 1e18) / sample;
        b = (_getAmountOut(amountIn, tokenIn, r0, r1, t0, dec0, dec1, st) * 1e18) / amountIn;
    }

    function getSample(address tokenIn, address tokenOut, bool stable) external view returns (uint) {
        (uint dec0, uint dec1, uint r0, uint r1, bool st, address t0, ) = IPair(router.pairFor(tokenIn, tokenOut, stable)).metadata();
        uint sample = tokenIn == t0 ? (r0 * dec1) / r1 : (r1 * dec0) / r0;
        return (_getAmountOut(sample, tokenIn, r0, r1, t0, dec0, dec1, st) * 1e18) / sample;
    }

    function getMinimumValue(address tokenIn, address tokenOut, bool stable) external view returns (uint, uint, uint) {
        (uint dec0, uint dec1, uint r0, uint r1, , address t0, ) = IPair(router.pairFor(tokenIn, tokenOut, stable)).metadata();
        uint sample = tokenIn == t0 ? (r0 * dec1) / r1 : (r1 * dec0) / r0;
        return (sample, r0, r1);
    }

    function getAmountOut(uint amountIn, address tokenIn, address tokenOut, bool stable) external view returns (uint) {
        (uint dec0, uint dec1, uint r0, uint r1, bool st, address t0, ) = IPair(router.pairFor(tokenIn, tokenOut, stable)).metadata();
        return (_getAmountOut(amountIn, tokenIn, r0, r1, t0, dec0, dec1, st) * 1e18) / amountIn;
    }

    function _getAmountOut(
        uint amountIn,
        address tokenIn,
        uint _reserve0,
        uint _reserve1,
        address token0,
        uint decimals0,
        uint decimals1,
        bool stable
    ) internal pure returns (uint) {
        if (stable) {
            uint xy = _k(_reserve0, _reserve1, stable, decimals0, decimals1);
            _reserve0 = (_reserve0 * 1e18) / decimals0;
            _reserve1 = (_reserve1 * 1e18) / decimals1;
            (uint reserveA, uint reserveB) = tokenIn == token0 ? (_reserve0, _reserve1) : (_reserve1, _reserve0);
            amountIn = tokenIn == token0 ? (amountIn * 1e18) / decimals0 : (amountIn * 1e18) / decimals1;
            uint y = reserveB - _get_y(amountIn + reserveA, xy, reserveB);
            return (y * (tokenIn == token0 ? decimals1 : decimals0)) / 1e18;
        } else {
            (uint reserveA, uint reserveB) = tokenIn == token0 ? (_reserve0, _reserve1) : (_reserve1, _reserve0);
            return (amountIn * reserveB) / (reserveA + amountIn);
        }
    }

    function _k(uint x, uint y, bool stable, uint decimals0, uint decimals1) internal pure returns (uint) {
        if (stable) {
            uint _x = (x * 1e18) / decimals0;
            uint _y = (y * 1e18) / decimals1;
            uint _a = (_x * _y) / 1e18;
            uint _b = ((_x * _x) / 1e18 + (_y * _y) / 1e18);
            return (_a * _b) / 1e18;
            // x3y+y3x >= k
        } else {
            return x * y;
            // xy >= k
        }
    }

    function getNormalizedReserves(address tokenA, address tokenB, bool stable) external view returns (uint reserveA, uint reserveB) {
        address pair = pairFor(tokenA, tokenB, stable);
        if (pair == address(0)) {
            return (0, 0);
        }
        (uint decimals0, uint decimals1, uint reserve0, uint reserve1, , address t0, address t1) = IPair(pair).metadata();

        reserveA = tokenA == t0 ? reserve0 : reserve1;
        reserveB = tokenA == t1 ? reserve0 : reserve1;
        uint decimalsA = tokenA == t0 ? decimals0 : decimals1;
        uint decimalsB = tokenA == t1 ? decimals0 : decimals1;
        reserveA = (reserveA * 1e18) / decimalsA;
        reserveB = (reserveB * 1e18) / decimalsB;
    }

    /// @dev Calculates the CREATE2 address for a pair without making any external calls.
    function pairFor(address tokenA, address tokenB, bool stable) public view returns (address pair) {
        pair = router.pairFor(tokenA, tokenB, stable);
    }

    function sortTokens(address tokenA, address tokenB) public pure returns (address token0, address token1) {
        require(tokenA != tokenB, "IDENTICAL_ADDRESSES");
        (token0, token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        require(token0 != address(0), "ZERO_ADDRESS");
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

interface IRouter {
    function factory() external view returns (address);
    function WMATIC() external view returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        bool stable,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);
    function addLiquidityMATIC(
        address token,
        bool stable,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountMATICMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountMATIC, uint liquidity);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        bool stable,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityMATIC(
        address token,
        bool stable,
        uint liquidity,
        uint amountTokenMin,
        uint amountMATICMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountMATIC);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        bool stable,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityMATICWithPermit(
        address token,
        bool stable,
        uint liquidity,
        uint amountTokenMin,
        uint amountMATICMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountMATIC);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapExactMATICForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function swapTokensForExactMATIC(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapExactTokensForMATIC(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapMATICForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);

  function quoteRemoveLiquidity(
    address tokenA,
    address tokenB,
    bool stable,
    uint liquidity
  ) external view returns (uint amountA, uint amountB);
    function quoteAddLiquidity(
    address tokenA,
    address tokenB,
    bool stable,
    uint amountADesired,
    uint amountBDesired
  ) external view returns (uint amountA, uint amountB, uint liquidity);

    function pairFor(address tokenA, address tokenB, bool stable) external view returns (address pair);
    function sortTokens(address tokenA, address tokenB) external pure returns (address token0, address token1);
    function quoteLiquidity(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut, bool stable);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn, bool stable);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
    function getReserves(address tokenA, address tokenB, bool stable) external view returns (uint reserveA, uint reserveB);
}

//SPDX-License-Identifier: MIT

pragma solidity 0.8.13;

interface IFactory {
    function isPair(address pair) external view returns (bool);

    function treasury() external view returns (address);

    function pairCodeHash() external pure returns (bytes32);

    function getPair(address tokenA, address token, bool stable) external view returns (address);

    function paused(address _pool) external view returns (bool);

    function createPair(address tokenA, address tokenB, bool stable) external returns (address pair);
}

//SPDX-License-Identifier: MIT

pragma solidity 0.8.13;

interface IPair {
    event Fees(address indexed sender, uint256 amount0, uint256 amount1);
    event Mint(address indexed sender, uint256 amount0, uint256 amount1);
    event Burn(address indexed sender, uint256 amount0, uint256 amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint256 amount0In,
        uint256 amount1In,
        uint256 amount0Out,
        uint256 amount1Out,
        address indexed to
    );
    event Sync(uint256 reserve0, uint256 reserve1);
    event Claim(
        address indexed sender,
        address indexed recipient,
        uint256 amount0,
        uint256 amount1
    );

    event FeesChanged(uint256 newValue);

    //Structure to capture time period observations every 30 minutes, used for local oracle
    struct Observation {
        uint256 timestamp;
        uint256 reserve0Cumulative;
        uint256 reserve1Cumulative;
    }

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    function swap(
        uint256 amount0Out,
        uint256 amount1Out,
        address to,
        bytes calldata data
    ) external;

    function burn(address to) external returns (uint256 amount0, uint256 amount1);

    function mint(address to) external returns (uint256 liquidity);

    function getReserves()
        external
        view
        returns (
            uint256 _reserve0,
            uint256 _reserve1,
            uint256 _blockTimestampLast
        );

    function getAmountOut(uint256, address) external view returns (uint256);

    function claimFees() external returns (uint256, uint256);

    function tokens() external view returns (address, address);

    function token0() external view returns (address);

    function token1() external view returns (address);

    function stable() external view returns (bool);

    function metadata()
        external
        view
        returns (
            uint256 dec0,
            uint256 dec1,
            uint256 r0,
            uint256 r1,
            bool st,
            address t0,
            address t1
        );
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.11;

library Math {
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    function positiveInt128(int128 value) internal pure returns (int128) {
        return value < 0 ? int128(0) : value;
    }

    function closeTo(
        uint256 a,
        uint256 b,
        uint256 target
    ) internal pure returns (bool) {
        if (a > b) {
            if (a - b <= target) {
                return true;
            }
        } else {
            if (b - a <= target) {
                return true;
            }
        }
        return false;
    }

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
    }
}