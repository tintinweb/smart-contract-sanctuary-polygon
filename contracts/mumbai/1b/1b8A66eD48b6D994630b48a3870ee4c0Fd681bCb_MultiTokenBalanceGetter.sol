/**
 *Submitted for verification at polygonscan.com on 2023-07-13
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

interface IERC20 {
  function balanceOf(address) external view returns (uint256);
}

contract MultiTokenBalanceGetter {
  function getMultipleBalances(address[] memory tokens, address account) view external returns (uint256, uint256[] memory) {
  uint256[] memory balances = new uint256[](tokens.length);

  for (uint i = 0; i < tokens.length; i++) {
    if (tokens[i] != address(0x0)) { 
      balances[i] = IERC20(tokens[i]).balanceOf(account);
    } else {
      balances[i] = account.balance; // ETH balance    
    }
  }  

  return (block.number, balances);
  }
}