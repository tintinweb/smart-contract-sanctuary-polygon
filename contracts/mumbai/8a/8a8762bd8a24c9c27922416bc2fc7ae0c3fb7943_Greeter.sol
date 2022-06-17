/**
 *Submitted for verification at polygonscan.com on 2022-06-16
*/

pragma solidity ^0.8.14;
 contract Greeter {
     string public greeting;

     constructor() public {
         greeting = 'Hello';
     }

     function setGreeting(string memory _greeting) public {
         greeting = _greeting;
     }

     function greet() view public returns (string memory) {
         return greeting;
     }
 }