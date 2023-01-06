/**
 *Submitted for verification at polygonscan.com on 2023-01-06
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.4.21;

contract Bank {
  uint totalContractBalance = 0;
  
  function getContractBalance() public view returns(uint){
    return totalContractBalance;
  }  

}