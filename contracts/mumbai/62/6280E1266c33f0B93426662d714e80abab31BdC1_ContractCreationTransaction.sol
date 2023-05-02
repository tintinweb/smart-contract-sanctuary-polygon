// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;


contract ContractCreationTransaction {
    function addNumbers(uint a, uint b) external view returns (uint) {
        return a + b;
    }

    function subNumbers(uint a, uint b) external view returns (uint) {
        return a - b;
    }
}