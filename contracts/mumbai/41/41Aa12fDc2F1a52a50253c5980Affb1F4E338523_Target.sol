// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.14;

contract Target {
  string public greeting;

  function updateGreeting(string memory newGreeting) external {
    greeting = newGreeting;
  }
}