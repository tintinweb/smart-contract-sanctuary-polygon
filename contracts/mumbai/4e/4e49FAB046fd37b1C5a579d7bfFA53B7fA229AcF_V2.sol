// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

contract V2 {
   uint public number;
   uint public test;

   function initialize(uint _num) external {
       number=_num;
   }

   function increase() external {
       number += 1;
   }

// UPGRADED FUNCTION
   function decrease() external {
       number -= 1;
   }
}