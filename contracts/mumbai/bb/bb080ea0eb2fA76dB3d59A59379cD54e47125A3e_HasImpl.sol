// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

contract HasImpl {

    function implementation() external view returns (address) {
        // return this contract's address
        return 0x0000000000000000000000000000000000000000;
    }
}