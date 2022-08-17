// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

contract Event {
    constructor() {}

    uint256 public eventCount;

    event RandomEvent();

    function emitRandomEvent() public {
        eventCount++;
        emit RandomEvent();
    }
}