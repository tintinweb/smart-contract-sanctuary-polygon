/**
 *Submitted for verification at polygonscan.com on 2022-12-27
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

// updated number storage
contract NumberStorageV33 {
  uint256 private _magicnumber;

  function setMagicNumber(uint256 value) external {
    _magicnumber = value;
  }

  function getMagicNumber() public view returns (uint256) {
    return _magicnumber;
  }
}