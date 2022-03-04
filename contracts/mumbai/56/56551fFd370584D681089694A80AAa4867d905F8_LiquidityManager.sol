// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./libs/IUniswapV2Router.sol";
import "./libs/IUniswapV2Factory.sol";

contract LiquidityManager {
  address public burnAddress = 0x000000000000000000000000000000000000dEaD;

  function createPair(
    address _routerAddress,
    address _tokenA,
    address _tokenB
  ) public returns (address) {
    address factory = IUniswapV2Router(_routerAddress).factory();
    return
      IUniswapV2Factory(factory).createPair(address(_tokenA), address(_tokenB));
  }

  function getLiquidityCreated(
    address _routerAddress,
    address _tokenA,
    address _tokenB
  ) public view returns (bool) {
    address factory = IUniswapV2Router(_routerAddress).factory();
    return (
      IUniswapV2Factory(factory).getPair(address(_tokenA), address(_tokenB)) ==
        address(0)
        ? false
        : true
    );
  }

  function getPairAddress(
    address _routerAddress,
    address _tokenA,
    address _tokenB
  ) public view returns (address) {
    address factory = IUniswapV2Router(_routerAddress).factory();
    return
      IUniswapV2Factory(factory).getPair(address(_tokenA), address(_tokenB));
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IUniswapV2Router {
  function factory() external view returns (address);
  function addLiquidity(address tokenA, address tokenB, uint amountADesired, uint amountBDesired, uint amountAMin, uint amountBMin, address to, uint deadline) external returns (uint amountA, uint amountB, uint liquidity);
}

contract UniswapV2RouterMock is IUniswapV2Router {
  address private _factoryAddress;
  address private _tokenA;
  address private _tokenB;
  uint private _amountADesired;
  uint private _amountBDesired;
  uint private _amountAMin;
  uint private _amountBMin;
  address private _to;
  uint private _deadline;

  constructor(address factoryAddress) {
    _factoryAddress = factoryAddress;
  }

  function factory() external view returns (address) {
    return _factoryAddress;
  }

  function addLiquidity(address tokenA, address tokenB, uint amountADesired, uint amountBDesired, uint amountAMin, uint amountBMin, address to, uint deadline) external returns (uint amountA, uint amountB, uint liquidity) {
    _tokenA = tokenA;
    _tokenB = tokenB;
    _amountADesired = amountADesired;
    _amountBDesired = amountBDesired;
    _amountAMin = amountAMin;
    _amountBMin = amountBMin;
    _to = to;
    _deadline = deadline;
    return (1, 1, 1);
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IUniswapV2Factory {
  event PairCreated(address indexed token0, address indexed token1, address pair, uint);
  function getPair(address tokenA, address tokenB) external view returns (address pair);
  function createPair(address tokenA, address tokenB) external returns (address pair);
}

contract UniswapV2FactoryMock is IUniswapV2Factory {
  address private _lpTokenAddress;
  address private _tokenA;
  address private _tokenB;

  constructor(address lpTokenAddress) {
    _lpTokenAddress = lpTokenAddress;
  }

  function getPair(address tokenA, address tokenB) external view returns (address) {
    tokenA = tokenB;
    return _lpTokenAddress;
  }

  function createPair(address tokenA, address tokenB) external returns (address) {
    _tokenA = tokenA;
    _tokenB = tokenB;
    return _lpTokenAddress;
  }
}