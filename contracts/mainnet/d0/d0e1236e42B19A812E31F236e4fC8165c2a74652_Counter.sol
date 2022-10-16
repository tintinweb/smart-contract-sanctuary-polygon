// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

contract Counter {
    uint256 public count;
    uint256 public lastTimestamp;

    event LogCountSet(uint256 _newCount, uint256 _timestamp);

    function setCount(uint256 _count) external {
        count = _count;
        emit LogCountSet(_count, block.timestamp);
    }

    function canSetCount() external view returns (bool) {
        if (block.timestamp >= lastTimestamp + 5 minutes) return true;
        return false;
    }
}