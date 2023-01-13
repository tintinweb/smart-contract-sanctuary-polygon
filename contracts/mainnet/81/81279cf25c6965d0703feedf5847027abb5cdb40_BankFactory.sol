/**
 *Submitted for verification at polygonscan.com on 2023-01-13
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract Bank {
  uint256 public bank_funds;
  address public owner;
  address public deployer;

  constructor(address _owner, uint256 _funds) {
    bank_funds = _funds;
    owner = _owner;
    deployer = msg.sender;
  }
}

contract BankFactory {
  // instantiate Bank contract
  Bank bank;
  //keep track of created Bank addresses in array 
  Bank[] public list_of_banks;

  // function arguments are passed to the constructor of the new created contract 
  function createBank(address _owner, uint256 _funds) external {
    bank = new Bank(_owner, _funds);
    list_of_banks.push(bank);
  }
}