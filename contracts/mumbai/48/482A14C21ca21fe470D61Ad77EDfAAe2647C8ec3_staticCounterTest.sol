// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

contract staticCounterTest {
    uint256 private totalCount;

    function increaseCount(uint256 _incrementAmount) external {
        totalCount = totalCount + _incrementAmount;
    }

    function getTotalCount() external view returns (uint256) {
        return totalCount;
    }
}