/**
 *Submitted for verification at polygonscan.com on 2022-08-03
*/

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

contract Greeter {
  string private greeting;

  event TestEvent(address from, string str);

  constructor(string memory _greeting) {
    greeting = _greeting;
  }

  function greet() public view returns (string memory) {
    return greeting;
  }

  function setGreeting(string memory _greeting) public returns (string memory) {
    emit TestEvent(msg.sender, _greeting);
    greeting = _greeting;
    return greeting;
  }
}