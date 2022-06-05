//SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

contract Verify{
  string private greeting;
  constructor(){

  }

  function hello(bool _sayHello) public pure returns (string memory) {
    if(_sayHello)
      return "hello";
    else
      return "";
  }

}