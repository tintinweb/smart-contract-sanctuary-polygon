/**
 *Submitted for verification at polygonscan.com on 2022-05-16
*/

pragma solidity ^0.8.7;

contract LedgerBalance {
   mapping(address => uint) public balances;

   uint[4] public data;

   function updateBalance(uint resource, uint newBalance) public {
      //balances[msg.sender] = newBalance;
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