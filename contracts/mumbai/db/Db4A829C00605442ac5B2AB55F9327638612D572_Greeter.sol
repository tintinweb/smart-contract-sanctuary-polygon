/**
 *Submitted for verification at polygonscan.com on 2022-02-08
*/

pragma solidity ^0.8.7;

contract Greeter {

  string private greeting;

  constructor(string memory _greeting) {
    greeting = _greeting;
  }

  function greet(string memory _name) public view returns (string memory) {
    return string(abi.encodePacked(greeting, ", ", _name));
  }
}