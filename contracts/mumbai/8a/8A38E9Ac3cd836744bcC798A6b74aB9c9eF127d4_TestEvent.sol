//SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

contract TestEvent {
    event calledTheFxn(string hello, uint val);

    function emitEvent() public {
        emit calledTheFxn("hello", 1234);
    }
}