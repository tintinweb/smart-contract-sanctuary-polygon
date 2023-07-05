// SPDX-License-Identifier: MIT

pragma solidity 0.8.13;

import "./interfaces/IRouter.sol";
import "./interfaces/IPairFactory.sol";
import "./interfaces/IPair.sol";
import "./libraries/Math.sol";

contract SwapLibrary {

  address immutable public factory;
  IRouter immutable public router;
  bytes32 immutable pairCodeHash;

  constructor(address _router) {
    router = IRouter(_router);
    factory = IRouter(_router).factory();
    pairCodeHash = IPairFactory(IRouter(_router).factory()).pairCodeHash();
  }

  function _f(uint x0, uint y) internal pure returns (uint) {
    return x0 * (y * y / 1e18 * y / 1e18) / 1e18 + (x0 * x0 / 1e18 * x0 / 1e18) * y / 1e18;
  }

  function _d(uint x0, uint y) internal pure returns (uint) {
    return 3 * x0 * (y * y / 1e18) / 1e18 + (x0 * x0 / 1e18 * x0 / 1e18);
  }

  function _get_y(uint x0, uint xy, uint y) internal pure returns (uint) {
    for (uint i = 0; i < 255; i++) {
      uint y_prev = y;
      uint k = _f(x0, y);
      if (k < xy) {
        uint dy = (xy - k) * 1e18 / _d(x0, y);
        y = y + dy;
      } else {
        uint dy = (k - xy) * 1e18 / _d(x0, y);
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
    (uint dec0, uint dec1, uint r0, uint r1, bool st, address t0,) = IPair(router.pairFor(tokenIn, tokenOut, stable)).metadata();
    uint sample = tokenIn == t0 ? r0 * dec1 / r1 : r1 * dec0 / r0;
    a = _getAmountOut(sample, tokenIn, r0, r1, t0, dec0, dec1, st) * 1e18 / sample;
    b = _getAmountOut(amountIn, tokenIn, r0, r1, t0, dec0, dec1, st) * 1e18 / amountIn;
  }

  function getTradeDiffSimple(uint amountIn, address tokenIn, address tokenOut, bool stable, uint sample) external view returns (uint a, uint b) {
    (uint dec0, uint dec1, uint r0, uint r1, bool st, address t0,) = IPair(router.pairFor(tokenIn, tokenOut, stable)).metadata();
    if (sample == 0) {
      sample = _calcSample(tokenIn, t0, dec0, dec1);
    }
    a = _getAmountOut(sample, tokenIn, r0, r1, t0, dec0, dec1, st) * 1e18 / sample;
    b = _getAmountOut(amountIn, tokenIn, r0, r1, t0, dec0, dec1, st) * 1e18 / amountIn;
  }

  function getTradeDiff2(uint amountIn, address tokenIn, address tokenOut, bool stable) external view returns (uint a, uint b) {
    (uint dec0, uint dec1, uint r0, uint r1, bool st, address t0,) = IPair(router.pairFor(tokenIn, tokenOut, stable)).metadata();
    uint sample;
    if (!stable) {
      sample = tokenIn == t0 ? r0 * dec1 / r1 : r1 * dec0 / r0;
    } else {
      sample = _calcSample(tokenIn, t0, dec0, dec1);
    }
    a = _getAmountOut(sample, tokenIn, r0, r1, t0, dec0, dec1, st) * 1e18 / sample;
    b = _getAmountOut(amountIn, tokenIn, r0, r1, t0, dec0, dec1, st) * 1e18 / amountIn;
  }

  function getTradeDiff3(uint amountIn, address tokenIn, address tokenOut, bool stable) external view returns (uint a, uint b) {
    (uint dec0, uint dec1, uint r0, uint r1, bool st, address t0,) = IPair(router.pairFor(tokenIn, tokenOut, stable)).metadata();
    uint sample;
    if (!stable) {
      a = amountIn * 1e18 / (tokenIn == t0 ? r0 * 1e18 / r1 : r1 * 1e18 / r0);
    } else {
      sample = _calcSample(tokenIn, t0, dec0, dec1);
      a = _getAmountOut(sample, tokenIn, r0, r1, t0, dec0, dec1, st) * amountIn / sample;
    }
    b = _getAmountOut(amountIn, tokenIn, r0, r1, t0, dec0, dec1, st);
  }

  function _calcSample(address tokenIn, address t0, uint dec0, uint dec1) internal pure returns (uint){
    uint tokenInDecimals = tokenIn == t0 ? dec0 : dec1;
    uint tokenOutDecimals = tokenIn == t0 ? dec1 : dec0;
    return 10 ** Math.max(
      (tokenInDecimals > tokenOutDecimals ?
    tokenInDecimals - tokenOutDecimals
    : tokenOutDecimals - tokenInDecimals)
    , 1) * 10_000;
  }

  function getTradeDiff(uint amountIn, address tokenIn, address pair) external view returns (uint a, uint b) {
    (uint dec0, uint dec1, uint r0, uint r1, bool st, address t0,) = IPair(pair).metadata();
    uint sample = tokenIn == t0 ? r0 * dec1 / r1 : r1 * dec0 / r0;
    a = _getAmountOut(sample, tokenIn, r0, r1, t0, dec0, dec1, st) * 1e18 / sample;
    b = _getAmountOut(amountIn, tokenIn, r0, r1, t0, dec0, dec1, st) * 1e18 / amountIn;
  }

  function getSample(address tokenIn, address tokenOut, bool stable) external view returns (uint) {
    (uint dec0, uint dec1, uint r0, uint r1, bool st, address t0,) = IPair(router.pairFor(tokenIn, tokenOut, stable)).metadata();
    uint sample = tokenIn == t0 ? r0 * dec1 / r1 : r1 * dec0 / r0;
    return _getAmountOut(sample, tokenIn, r0, r1, t0, dec0, dec1, st) * 1e18 / sample;
  }

  function getMinimumValue(address tokenIn, address tokenOut, bool stable) external view returns (uint, uint, uint) {
    (uint dec0, uint dec1, uint r0, uint r1,, address t0,) = IPair(router.pairFor(tokenIn, tokenOut, stable)).metadata();
    uint sample = tokenIn == t0 ? r0 * dec1 / r1 : r1 * dec0 / r0;
    return (sample, r0, r1);
  }

  function getAmountOut(uint amountIn, address tokenIn, address tokenOut, bool stable) external view returns (uint) {
    (uint dec0, uint dec1, uint r0, uint r1, bool st, address t0,) = IPair(router.pairFor(tokenIn, tokenOut, stable)).metadata();
    return _getAmountOut(amountIn, tokenIn, r0, r1, t0, dec0, dec1, st) * 1e18 / amountIn;
  }

  function _getAmountOut(uint amountIn, address tokenIn, uint _reserve0, uint _reserve1, address token0, uint decimals0, uint decimals1, bool stable) internal pure returns (uint) {
    if (stable) {
      uint xy = _k(_reserve0, _reserve1, stable, decimals0, decimals1);
      _reserve0 = _reserve0 * 1e18 / decimals0;
      _reserve1 = _reserve1 * 1e18 / decimals1;
      (uint reserveA, uint reserveB) = tokenIn == token0 ? (_reserve0, _reserve1) : (_reserve1, _reserve0);
      amountIn = tokenIn == token0 ? amountIn * 1e18 / decimals0 : amountIn * 1e18 / decimals1;
      uint y = reserveB - _get_y(amountIn + reserveA, xy, reserveB);
      return y * (tokenIn == token0 ? decimals1 : decimals0) / 1e18;
    } else {
      (uint reserveA, uint reserveB) = tokenIn == token0 ? (_reserve0, _reserve1) : (_reserve1, _reserve0);
      return amountIn * reserveB / (reserveA + amountIn);
    }
  }

  function _k(uint x, uint y, bool stable, uint decimals0, uint decimals1) internal pure returns (uint) {
    if (stable) {
      uint _x = x * 1e18 / decimals0;
      uint _y = y * 1e18 / decimals1;
      uint _a = (_x * _y) / 1e18;
      uint _b = ((_x * _x) / 1e18 + (_y * _y) / 1e18);
      return _a * _b / 1e18;
      // x3y+y3x >= k
    } else {
      return x * y;
      // xy >= k
    }
  }

  function getNormalizedReserves(address tokenA, address tokenB, bool stable) external view returns (uint reserveA, uint reserveB){
    address pair = pairFor(tokenA, tokenB, stable);
    if (pair == address(0)) {
      return (0, 0);
    }
    (uint decimals0, uint decimals1, uint reserve0, uint reserve1,, address t0, address t1) = IPair(pair).metadata();

    reserveA = tokenA == t0 ? reserve0 : reserve1;
    reserveB = tokenA == t1 ? reserve0 : reserve1;
    uint decimalsA = tokenA == t0 ? decimals0 : decimals1;
    uint decimalsB = tokenA == t1 ? decimals0 : decimals1;
    reserveA = reserveA * 1e18 / decimalsA;
    reserveB = reserveB * 1e18 / decimalsB;
  }

  /// @dev Calculates the CREATE2 address for a pair without making any external calls.
  function pairFor(address tokenA, address tokenB, bool stable) public view returns (address pair) {
    (address token0, address token1) = sortTokens(tokenA, tokenB);
    pair = address(uint160(uint(keccak256(abi.encodePacked(
        hex'ff',
        factory,
        keccak256(abi.encodePacked(token0, token1, stable)),
        pairCodeHash // init code hash
      )))));
  }

  function sortTokens(address tokenA, address tokenB) public pure returns (address token0, address token1) {
    require(tokenA != tokenB, 'IDENTICAL_ADDRESSES');
    (token0, token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
    require(token0 != address(0), 'ZERO_ADDRESS');
  }

}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

library Math {
    function max(uint a, uint b) internal pure returns (uint) {
        return a >= b ? a : b;
    }
    function min(uint a, uint b) internal pure returns (uint) {
        return a < b ? a : b;
    }
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
    }
    function cbrt(uint256 n) internal pure returns (uint256) { unchecked {
        uint256 x = 0;
        for (uint256 y = 1 << 255; y > 0; y >>= 3) {
            x <<= 1;
            uint256 z = 3 * x * (x + 1) + 1;
            if (n / y >= z) {
                n -= y * z;
                x += 1;
            }
        }
        return x;
    }}
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

interface IPairFactory {
    function allPairsLength() external view returns (uint);
    function isPair(address pair) external view returns (bool);
    function allPairs(uint index) external view returns (address);
    function pairCodeHash() external pure returns (bytes32);
    function getPair(address tokenA, address token, bool stable) external view returns (address);
    function createPair(address tokenA, address tokenB, bool stable) external returns (address pair);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

interface IRouter {
    function pairFor(address tokenA, address tokenB, bool stable) external view returns (address pair);
    function factory() external view returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

interface IPair {
    function metadata() external view returns (uint dec0, uint dec1, uint r0, uint r1, bool st, address t0, address t1);
    function claimFees() external returns (uint, uint);
    function tokens() external view returns (address, address);
    function transferFrom(address src, address dst, uint amount) external returns (bool);
    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function burn(address to) external returns (uint amount0, uint amount1);
    function mint(address to) external returns (uint liquidity);
    function getReserves() external view returns (uint _reserve0, uint _reserve1, uint _blockTimestampLast);
    function getAmountOut(uint, address) external view returns (uint);

    function name() external view returns(string memory);
    function symbol() external view returns(string memory);
    function totalSupply() external view returns (uint);
    function decimals() external view returns (uint8);

    function claimable0(address _user) external view returns (uint);
    function claimable1(address _user) external view returns (uint);

    function isStable() external view returns(bool);


    function token0() external view returns(address);
    function reserve0() external view returns(uint256);
    function token1() external view returns(address);
    function reserve1() external view returns(uint256);
}