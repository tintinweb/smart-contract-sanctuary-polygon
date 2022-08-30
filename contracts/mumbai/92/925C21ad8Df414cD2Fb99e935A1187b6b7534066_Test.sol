//SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

contract Test {

    event TestEvent(uint256 val, uint256[] constants, bytes[] sources);

    constructor() {}

    function fn(uint256 val, uint256[] calldata constants, bytes[] calldata sources) public returns (uint256, uint256[] calldata, bytes[] calldata) {
      emit TestEvent(val, constants, sources);
      return (val, constants, sources);
    }   
}