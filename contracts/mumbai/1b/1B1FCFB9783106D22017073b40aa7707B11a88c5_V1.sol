// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

contract V1 {
   uint public value;

   function initialValue(uint _num) external {
       value=_num;
   }

   function increase() external {
       value += 1;
   }
}