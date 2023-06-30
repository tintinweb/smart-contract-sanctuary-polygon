// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

contract Counter {
    uint256 public count;

    function getCount() public view returns (uint256) {
        return count;
    }

    function setCount(uint256 newCount) public {
        count = newCount;
    }
}