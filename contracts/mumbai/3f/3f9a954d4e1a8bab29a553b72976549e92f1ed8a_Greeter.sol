/**
 *Submitted for verification at polygonscan.com on 2023-02-06
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

contract Greeter {
  string private greeting;

  constructor(string memory _greeting) {
    greeting = _greeting;
  }

  function greet() public view returns (string memory) {
    return greeting;
  }

  function setGreeting(string memory _greeting) public {
    greeting = _greeting;
  }
}