// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;


contract V1 {

   uint public number;

   function initialize(uint _num) external {
       number=_num;
   }

   function increase() external {
       number += 1;
   }
}