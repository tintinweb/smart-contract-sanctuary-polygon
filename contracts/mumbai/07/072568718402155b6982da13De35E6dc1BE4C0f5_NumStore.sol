/**
 *Submitted for verification at polygonscan.com on 2022-05-13
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

/** 
 * @title NumStore
 */
contract NumStore {
  uint256 public num;

  constructor() {
    num = 1;
  }

  function setNumber(uint256 _num) public {
    require(_num != 0, "Invalid number: zero");
    num = _num;
  }
}