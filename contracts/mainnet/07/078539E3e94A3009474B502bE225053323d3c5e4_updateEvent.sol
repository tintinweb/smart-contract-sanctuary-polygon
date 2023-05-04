//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract updateEvent {
   event Update(address indexed _from, address _contract, uint _value);
   
   function update(address _contract, uint256 _id) public {      
      emit Update(msg.sender, _contract, _id);
   }
}