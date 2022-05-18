/**
 *Submitted for verification at polygonscan.com on 2022-05-18
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

/** 
 * @title StrStore
 */
contract StrStore {
  string public str;

  constructor() {
    str = "hello";
  }

  function setString(string memory _str) public {
    require(bytes(_str).length > 0, "Invalid empty string");
    str = _str;
  }
}