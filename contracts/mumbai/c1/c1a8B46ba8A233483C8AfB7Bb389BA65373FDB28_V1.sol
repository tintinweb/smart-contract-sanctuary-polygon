// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

contract V1 {
   uint public number;

   function initialValue() external {
       number=500;
   }

   function increase() external {
       number += 1;
   }
}