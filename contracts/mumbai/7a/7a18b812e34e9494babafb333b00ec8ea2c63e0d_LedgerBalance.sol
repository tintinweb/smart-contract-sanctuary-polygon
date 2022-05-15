/**
 *Submitted for verification at polygonscan.com on 2022-05-14
*/

pragma solidity ^0.8.7;

// A contract is a collection of functions and data (its state)
// that resides at a specific address on the Ethereum blockchain.

contract LedgerBalance {
   mapping(address => uint) public balances;

   function updateBalance(uint newBalance) public {
      balances[msg.sender] = newBalance;
   }
}
contract Updater {
   function updateBalance() public returns (uint) {
      LedgerBalance ledgerBalance = new LedgerBalance();
      ledgerBalance.updateBalance(10);
      return ledgerBalance.balances(address(this));
   }
}