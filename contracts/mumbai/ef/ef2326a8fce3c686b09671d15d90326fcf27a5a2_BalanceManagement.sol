/**
 *Submitted for verification at polygonscan.com on 2023-01-05
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.13;
contract BalanceManagement {
   uint256 balance;
   address payable public admin;
 constructor() {
       admin = payable(msg.sender);
       balance = 0;
       updateBalance();
 
  
}
   function updateBalance() internal {
       balance += msg.value;
   }
   function withdraw(uint256 amount)  public{
       require(msg.sender == admin, "Withdrawing is possible only for an admin");
       require(amount <= balance, "Withdraw can not be proceeded, because of limited balance");   
       balance = balance - amount;
  
 }

   function deposite(uint256 amount) public returns (uint256) { return balance = balance + amount; }
   function checkDepositBalance() public view returns (uint256) { return balance; }
}