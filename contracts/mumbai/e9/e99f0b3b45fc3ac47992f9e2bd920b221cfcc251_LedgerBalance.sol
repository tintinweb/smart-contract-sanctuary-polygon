/**
 *Submitted for verification at polygonscan.com on 2022-05-16
*/

pragma solidity ^0.8.7;

contract LedgerBalance {

   struct user_status {
      uint[4] balance;
   }

   //mapping(address => uint) public balances;
   mapping(address => user_status) _userstatus;
   uint[4] public data;

   function updateBalance(uint resource, uint newBalance) public {
      
      _userstatus[msg.sender].balance[resource] += newBalance;
      
      //balances[msg.sender] = _userstatus[msg.sender].balance[resource];
      //data[resource] = 1000;
   }

   function requestBalance() public {
      data = _userstatus[msg.sender].balance;
   }

}

contract Updater {
   function updateBalance() public returns (uint) {
      LedgerBalance ledgerBalance = new LedgerBalance();
      ledgerBalance.updateBalance(0, 10);
      //return ledgerBalance.balances(address(this));
      //return ledgerBalance.returnBalance();
      return 0;
   }
}