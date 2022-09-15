/**
 *Submitted for verification at polygonscan.com on 2022-09-14
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface WTF {
    
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address to, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    
}

contract OWW {

  address owner;
  mapping(bytes32 => address) public WHAT;
  mapping(address => mapping(bytes32 => uint256)) public accountBalances;

  constructor() {
    owner = msg.sender;
  }

  function whitelistToken(bytes32 symbol, address tokenAddress) external {
    require(msg.sender == owner, 'This function is not public');
    WHAT[symbol] = tokenAddress;
  }

  function getWhitelistedTokenAddresses(bytes32 token) external view returns(address) {
    return WHAT[token];
  }

  function depositTokens(uint256 amount, bytes32 symbol) external {
    accountBalances[msg.sender][symbol] += amount;
    WTF(WHAT[symbol]).transferFrom(msg.sender, address(this), amount);
  }

  function withdrawTokens(uint256 amount, bytes32 symbol) external {
    require(accountBalances[msg.sender][symbol] >= amount, 'Insufficent funds');
    accountBalances[msg.sender][symbol] -= amount;
    WTF(WHAT[symbol]).transfer(msg.sender, amount);
  }
}