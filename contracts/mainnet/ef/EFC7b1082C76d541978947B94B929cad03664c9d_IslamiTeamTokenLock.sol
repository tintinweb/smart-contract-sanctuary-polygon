// SPDX-License-Identifier: MIT


pragma solidity ^0.8.13;

import "./ISLAMICOIN.sol";

contract IslamiTeamTokenLock {
    
    ISLAMICOIN public ISLAMI;

  address public beneficiary;
  uint256 public releaseTime;
  uint256 public claimed;
  
  

  constructor(ISLAMICOIN _token, address _beneficiary) {
    ISLAMI = _token;
    beneficiary = _beneficiary;
    releaseTime = 1715369744;        //Friday, 10 May 2024 19:35:44
    claimed = 0;
  }
  
  function release() public {
      require(beneficiary == msg.sender,"Not Beneficiary!");
    require(block.timestamp >= releaseTime, "Release time is not yet, Friday, 10 May 2024 19:35:44");
    uint256 amount = ISLAMI.balanceOf(address(this));
    require(amount > 0);
    if(claimed == 0){
    ISLAMI.transfer(beneficiary, amount/2);
    releaseTime += 30 days;
    claimed = 1;
    }
    else{
      ISLAMI.transfer(beneficiary, amount);
    }
  }

}