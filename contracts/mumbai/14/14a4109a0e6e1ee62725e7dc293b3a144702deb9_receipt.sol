/**
 *Submitted for verification at polygonscan.com on 2022-10-23
*/

pragma solidity ^0.4.18;

contract receipt {

 
  string merchantName;
  string itemName;
  uint256 itemValue;
  uint256 itemAgeRestriction;

 
  mapping(address => uint256) balances; // a mapping of all user's balances
  
 
  function transfer(address recipient, uint256 value) public {

    balances[msg.sender] -= value;

    balances[recipient] += value;
  }

  function issueReceipt(address recipient, string merchantName, string itemName, uint256 itemValue, uint256 itemAgeRestriction) {


    balances[msg.sender] -= 1;
    balances[recipient] += 1;
  }
  
  function balanceOf(address account) public constant returns (uint256) {

    return balances[account];
  }

}