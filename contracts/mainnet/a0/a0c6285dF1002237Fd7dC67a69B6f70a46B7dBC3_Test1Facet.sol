// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Test1Facet {
    event TestEvent(address something);

    uint256 public numA;
    uint256 public numB;

    function test1Func1() external {
        numA++;
    }

    function test1Func2() external {
        numB++;
    }
}