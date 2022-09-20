// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

contract SampleContract {
    event SampleEvent(string);

    function emitEvent(string memory data) external {
        emit SampleEvent(data);
    }
}