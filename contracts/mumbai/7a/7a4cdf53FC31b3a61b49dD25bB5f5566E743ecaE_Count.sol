pragma solidity ^0.8.18;

// SPDX-License-Identifier: MIT

contract Count {
    uint256 public count = 10;

    constructor() {}

    function addOne() external {
        ++count;
    }

    function subOne() external {
        --count;
    }

    function getCount() external view returns (uint256) {
        return count;
    }
}