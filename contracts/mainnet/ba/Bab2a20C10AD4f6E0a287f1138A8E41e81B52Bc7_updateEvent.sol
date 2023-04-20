//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract updateEvent {
   event Update(address indexed _from, uint _value);
   
   uint256 public num = 1;

   function update() public {      
      emit Update(msg.sender, num);
      num += 1;
   }
}