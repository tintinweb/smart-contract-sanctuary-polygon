/**
 *Submitted for verification at polygonscan.com on 2023-07-04
*/

pragma solidity ^0.8.18;


contract Lock {
    string greeting;

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