//SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface ERC20 {
  function approve(address spender, uint amount) external returns (bool);
  function balanceOf(address account) external view returns (uint256);
}

interface QuickSwapRouter {
  function factory() external view returns(address);
  function getAmountsOut(uint amountIn, address[] memory path) external view returns (uint[] memory amounts);
  function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline) external payable;
  function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline) external payable;
  function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline) external;
  function swapExactTokensForTokens(uint256 amountIn, uint256 amountOutMin, address[] calldata path, address to, uint256 deadline) external;
}

interface QuickSwapFactory {
  function getPair(address, address) external view returns(address);
}

contract WunderSwapperGamma {
  address internal quickSwapRouterAddress = 0xa5E0829CaCEd8fFDD4De3c43696c57F7D7A678ff;
  address internal wrappedMaticAddress = 0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270;

  event BoughtTokens(address indexed trader, address indexed token, uint maticAmount, uint tokenAmount);
  event SoldTokens(address indexed trader, address indexed token, uint maticAmount, uint tokenAmount);
  event SwappedTokens(address indexed trader, address indexed tokenIn, address indexed tokenOut, uint amountIn, uint amountOut);

  function getAmounts(uint _amount, address[] memory _path) internal view returns(uint[] memory amounts) {
    return QuickSwapRouter(quickSwapRouterAddress).getAmountsOut(_amount, _path);
  }

  function getMaticPriceOf(address _tokenAddress, uint _amount) public view returns(uint matic) {
    address[] memory path = new address[](2);
    path[0] = _tokenAddress;
    path[1] = wrappedMaticAddress;
    return getAmounts(_amount, path)[1];
  }

  function buyTokens(address _tokenAddress) external payable {
    require(msg.value > 0, "NOTHING TO TRADE");

    address[] memory path = new address[](2);
    path[0] = wrappedMaticAddress;
    path[1] = _tokenAddress;

    uint[] memory amounts = getAmounts(msg.value, path);
    QuickSwapRouter(quickSwapRouterAddress).swapExactETHForTokens{value: msg.value}(amounts[1], path, msg.sender, block.timestamp + 1200);
    emit BoughtTokens(msg.sender, _tokenAddress, amounts[0], amounts[1]);
  }

  function sellTokens(address _tokenAddress, uint _amount) public {
    require(_amount > 0, "NOTHING TO TRADE");

    uint balance = ERC20(_tokenAddress).balanceOf(address(this));
    require(balance >= _amount, "NOT ENOUGH FUNDS");

    ERC20(_tokenAddress).approve(quickSwapRouterAddress, _amount);

    address[] memory path = new address[](2);
    path[0] = _tokenAddress;
    path[1] = wrappedMaticAddress;
    uint[] memory amounts = getAmounts(_amount, path);
    QuickSwapRouter(quickSwapRouterAddress).swapExactTokensForETH(amounts[0], amounts[1], path, msg.sender, block.timestamp + 1200);
    emit SoldTokens(msg.sender, _tokenAddress, amounts[1], amounts[0]);
  }

  function sellAllTokens(address _tokenAddress) external {
    uint balance = ERC20(_tokenAddress).balanceOf(address(this));
    sellTokens(_tokenAddress, balance);
  }

  function swapTokens(address _tokenIn, address _tokenOut, uint _amount) public {
    require(_amount > 0, "NOTHING TO TRADE");

    uint balance = ERC20(_tokenIn).balanceOf(address(this));
    require(balance >= _amount, "NOT ENOUGH FUNDS");

    ERC20(_tokenIn).approve(quickSwapRouterAddress, _amount);

    address[] memory path = getPathFor(_tokenIn, _tokenOut);
    uint[] memory amounts = getAmounts(_amount, path);
    QuickSwapRouter(quickSwapRouterAddress).swapExactTokensForTokens(amounts[0], amounts[amounts.length - 1], path, msg.sender, block.timestamp + 1200);
    emit SwappedTokens(msg.sender, _tokenIn, _tokenOut, amounts[0], amounts[amounts.length - 1]);
  }

  function swapAllTokens(address _tokenIn, address _tokenOut) external {
    uint balance = ERC20(_tokenIn).balanceOf(address(this));
    swapTokens(_tokenIn, _tokenOut, balance);
  }

  function getPathFor(address _tokenOne, address _tokenTwo) public view returns(address[] memory) {
    address factoryAddress = QuickSwapRouter(quickSwapRouterAddress).factory();
    if (QuickSwapFactory(factoryAddress).getPair(_tokenOne, _tokenTwo) == address(0)) {
      address[] memory path = new address[](3);
      path[0] = _tokenOne;
      path[1] = wrappedMaticAddress;
      path[2] = _tokenTwo;
      return path;
    } else {
      address[] memory path = new address[](2);
      path[0] = _tokenOne;
      path[1] = _tokenTwo;
      return path;
    }
  }
}