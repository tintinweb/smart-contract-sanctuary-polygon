/**
 *Submitted for verification at polygonscan.com on 2022-05-16
*/

pragma solidity ^0.8.7;

contract LedgerBalance {
    struct userstat_struct {
        uint[4] balance;
    }


   uint[4] data;  
   //mapping(address => userstat_struct) public _userstat;


   function buffUser(uint resource, uint newBalance) public returns (uint[4] memory) {
      //_userstat[msg.sender].balance[resource] = newBalance;
      //_userstat[msg.sender].balance[resource] = [uint256(0), uint256(0),uint256(0),uint256(0)];
      data[resource] = newBalance;
      return data;
   }

   function returnUser() public returns (uint) {
      return data[0];
   }

}
contract Updater {

   function readUser() public returns (uint) {
      LedgerBalance ledgerBalance = new LedgerBalance();
      return ledgerBalance.returnUser();
   }

/*
   function updateBalance() public returns (uint) {
      LedgerBalance ledgerBalance = new LedgerBalance();
      ledgerBalance.updateBalance(10);
      return ledgerBalance.balances(address(this));
   }
*/
}