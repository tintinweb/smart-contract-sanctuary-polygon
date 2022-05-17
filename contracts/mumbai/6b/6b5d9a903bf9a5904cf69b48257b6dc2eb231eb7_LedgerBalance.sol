/**
 *Submitted for verification at polygonscan.com on 2022-05-16
*/

pragma solidity ^0.8.7;

contract LedgerBalance {

   struct user_status {
      uint[4] balance;
   }

   mapping(address => uint) public balances;
   mapping(address => user_status) _userstatus;

   uint[4] public data;

   function updateBalance(uint resource, uint newBalance) public {
      
      _userstatus[msg.sender].balance[resource] += newBalance;
      balances[msg.sender] = _userstatus[msg.sender].balance[resource];
      data[resource] = 1000;
   }

   function returnBalance() public returns (uint){
      return data[0];
   }

}

contract Updater {
   function updateBalance() public returns (uint) {
      LedgerBalance ledgerBalance = new LedgerBalance();
      ledgerBalance.updateBalance(0, 10);
      //return ledgerBalance.balances(address(this));
      return ledgerBalance.returnBalance();
   }
}