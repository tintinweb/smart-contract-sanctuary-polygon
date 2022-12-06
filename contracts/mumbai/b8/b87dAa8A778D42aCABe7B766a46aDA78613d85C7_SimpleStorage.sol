/**
 *Submitted for verification at polygonscan.com on 2022-12-05
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;


contract SimpleStorage {
uint256 storedData;


function setCoolNumber(uint256 x) public {
   storedData = x;
  }

  function coolNumber() public view returns (uint256) {
    return storedData;
  }
}