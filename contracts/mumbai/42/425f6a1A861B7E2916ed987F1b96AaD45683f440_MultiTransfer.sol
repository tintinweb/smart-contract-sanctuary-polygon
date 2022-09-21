/**
 *Submitted for verification at polygonscan.com on 2022-09-20
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

contract MultiTransfer {

  function transfer(address[] memory targets) payable external {
    for (uint i = 0; i < targets.length; i++) {
      (bool success, ) = targets[i].call{ value: msg.value / targets.length }('');
      require(success, 'Something failed');
    }
  }

}