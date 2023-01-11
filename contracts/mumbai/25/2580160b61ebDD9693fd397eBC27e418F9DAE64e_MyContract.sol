/**
 *Submitted for verification at polygonscan.com on 2023-01-10
*/

pragma solidity >=0.8.0 <0.9.0;
//SPDX-License-Identifier: MIT

contract MyContract {

  event SetNumber(address sender, uint number);

  uint public number = 0;

  function setNumber(uint newNumber) public payable {
      number = newNumber;
      emit SetNumber(msg.sender, number);
  }
}