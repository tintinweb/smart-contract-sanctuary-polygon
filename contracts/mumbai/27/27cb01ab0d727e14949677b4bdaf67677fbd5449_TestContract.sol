/**
 *Submitted for verification at polygonscan.com on 2023-04-26
*/

// File: contracts/TestContract.sol

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.14;

contract TestContract {
  event FilterEvent(uint256 amount);

  function emitEvent() external {
    emit FilterEvent(100);
  }
}