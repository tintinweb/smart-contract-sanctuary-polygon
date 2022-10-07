/**
 *Submitted for verification at polygonscan.com on 2022-10-07
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

contract Test {
   uint number; 
   
   constructor() {
      number = 10;   
   }
   function getNumber() public view returns(uint){
      return number;
   }
   
   function setNumber(uint newNumber) public payable {
      number = newNumber;
   }

}

//sodility strings