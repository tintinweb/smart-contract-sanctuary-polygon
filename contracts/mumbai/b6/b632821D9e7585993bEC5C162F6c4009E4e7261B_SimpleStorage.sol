/**
 *Submitted for verification at polygonscan.com on 2022-12-05
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;


contract SimpleStorage {
string storedData;


function set(string memory x) public {
   storedData = x;
  }

  function get() public view returns (string memory ) {
    return storedData;
  }
}