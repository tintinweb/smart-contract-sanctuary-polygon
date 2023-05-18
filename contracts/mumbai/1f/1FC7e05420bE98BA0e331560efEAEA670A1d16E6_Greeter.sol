/**
 *Submitted for verification at polygonscan.com on 2023-05-18
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;
// importing hardhat  //console

contract Greeter{
   string private greeting;

   constructor(string memory _greeting){
      //console.log("Deploying a Greeter with greetings:", _greeting);
      greeting= _greeting;
   }

   function addition(uint256 a,uint256 b) public pure returns(uint256)
   {
      return a+b;
   }

   function sub(uint256 x,uint256 y) public pure returns(uint256)
   {
      return x-y;
   }
}