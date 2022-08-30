//SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

contract Test {

    event TestEvent(uint256 val);

    constructor() {}

    function fn(uint256 val) public returns (uint256) {
      emit TestEvent(val);
      return val;
    }   
}