// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

// import "../node_modules/@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract Gamble {
  address owner;
  bytes32 token;
  mapping(bytes32 => address) public whitelistedTokens;
  mapping(address => mapping(bytes32 => uint256)) public accountBalances;
  mapping(address => uint256) public deposited;  
  constructor() {
    owner = msg.sender;
  }

    receive() payable external{
        
    }
//   function whitelistToken(bytes32 symbol, address tokenAddress) external {
//     require(msg.sender == owner, 'This function is not public');
//     token = symbol;
//     whitelistedTokens[symbol] = tokenAddress;
//   }

//   function getWhitelistedTokenAddresses(bytes32 token) external returns(address) {
//     return whitelistedTokens[token];
//   }

//   function depositTokens(uint256 amount, bytes32 symbol) external {
//     require(amount > 0 && token == symbol, "Amount should be greater than zero");
//     accountBalances[msg.sender][symbol] += amount;
//     ERC20(whitelistedTokens[symbol]).transferFrom(msg.sender, address(this), amount);
//   }

//   function withdrawTokens(uint256 amount, bytes32 symbol) external {
//     require(accountBalances[msg.sender][symbol] >= amount, 'Insufficent funds');

//     accountBalances[msg.sender][symbol] -= amount;
//     ERC20(whitelistedTokens[symbol]).transfer(msg.sender, amount);
//   }
    function transfer(address  _trans,uint256  _amount)public {
        deposited[msg.sender] += _amount;
        payable(_trans).transfer(_amount);
    }

}