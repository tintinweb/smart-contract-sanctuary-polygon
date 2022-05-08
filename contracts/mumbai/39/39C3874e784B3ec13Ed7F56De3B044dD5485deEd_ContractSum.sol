// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract ContractSum {
    uint256 public var1;

    function sumTest(uint256 a, uint256 b) public {
        var1 = a + b;
    }
}