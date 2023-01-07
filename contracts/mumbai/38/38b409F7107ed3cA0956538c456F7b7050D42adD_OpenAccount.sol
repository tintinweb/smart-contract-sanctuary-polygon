/**
 *Submitted for verification at polygonscan.com on 2023-01-07
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0;

contract OpenAccount {
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