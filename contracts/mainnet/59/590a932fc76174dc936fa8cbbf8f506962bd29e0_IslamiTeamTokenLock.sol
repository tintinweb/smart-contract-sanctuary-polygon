// SPDX-License-Identifier: MIT



// Locked for 3 Years

// Tokens are locked until: Saturday, 26 April 2025 16:13:40

pragma solidity ^0.8.13;

import "./ISLAMICOIN.sol";

contract IslamiTeamTokenLock {
    
    ISLAMICOIN public ISLAMI;

  address public beneficiary;
  uint256 public releaseTime;
  
  

  constructor(ISLAMICOIN _token, address _beneficiary) {
    ISLAMI = _token;
    beneficiary = _beneficiary;
    releaseTime = 1745684020;        //Saturday, 26 April 2025 16:13:40 /  Epoch timestamp: 1745684020
  }
  
  

  function release() public {
      require(beneficiary == msg.sender,"Not Beneficiary!");
    require(block.timestamp >= releaseTime, "Release time is not yet, Saturday, 26 April 2025 16:13:40");

    uint256 amount = ISLAMI.balanceOf(address(this));
    require(amount > 0);

    ISLAMI.transfer(beneficiary, amount);
  }

}