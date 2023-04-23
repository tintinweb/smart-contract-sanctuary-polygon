/**
 *Submitted for verification at polygonscan.com on 2023-04-22
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;

contract Donate { 
    
  address payable owner; 
  constructor() {
    owner = payable(msg.sender);    
  }
  
  event Received(address addressFrom, uint amountSent);
  error InsufficientBalance(uint requestedAmount, uint availableFunds);

  receive() external payable {
      if(address(msg.sender).balance <= msg.value) {
        revert InsufficientBalance({
          requestedAmount: msg.value, 
          availableFunds: address(msg.sender).balance
        });
      }
      else {
        owner.transfer(msg.value); //recepient is given the transfer amount 
        emit Received(msg.sender, msg.value);
      }
  }

}