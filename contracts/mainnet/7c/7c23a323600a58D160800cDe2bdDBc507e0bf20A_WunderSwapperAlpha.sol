/**
 *Submitted for verification at polygonscan.com on 2022-03-03
*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface ERC20 {
  function approve(address spender, uint amount) external returns (bool);
  function balanceOf(address account) external view returns (uint256);
}

interface QuickSwapRouter {
  function factory() external view returns(address);
  function getAmountsOut(uint amountIn, address[] memory path) external view returns (uint[] memory amounts);
  function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline) external payable returns (uint[] memory amounts);
  function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline) external returns (uint[] memory amounts);
}

interface QuickSwapFactory {
  function getPair(address, address) external view returns(address);
}

contract WunderSwapperAlpha {
  address internal quickSwapRouterAddress = 0xa5E0829CaCEd8fFDD4De3c43696c57F7D7A678ff;
  address internal wrappedMaticAddress = 0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270;

  event BoughtTokens(address indexed trader, address indexed token, uint maticAmount, uint tokenAmount);
  event SoldTokens(address indexed trader, address indexed token, uint maticAmount, uint tokenAmount);

  function getAmounts(uint _amount, address[] memory _path) internal view returns(uint[] memory amounts) {
    return QuickSwapRouter(quickSwapRouterAddress).getAmountsOut(_amount, _path);
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

  function sellTokens(address _tokenAddress, uint _amount) external {
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

  function getPairFor(address _tokenAddress) external view returns(address) {
    address factoryAddress = QuickSwapRouter(quickSwapRouterAddress).factory();
    return QuickSwapFactory(factoryAddress).getPair(_tokenAddress, wrappedMaticAddress);
  }
}