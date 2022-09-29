// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

contract V1 {
   uint public value;
   address public deployer;

   function initialValue(uint _num) external {
       deployer = msg.sender;
       value=_num;
   }

   function increase() external {
       value += 1;
   }
}