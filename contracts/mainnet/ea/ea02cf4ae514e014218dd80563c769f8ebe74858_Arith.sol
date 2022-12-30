// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

library Arith {
    function divUp(uint256 x, uint256 y) external pure returns (uint256) {
        return (x + y - 1) / y;
    }
}