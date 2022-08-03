// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

contract Uint216 {
    uint256 public count;

    function increaseCount(uint216 _count) external {
        count += _count;
    }
}