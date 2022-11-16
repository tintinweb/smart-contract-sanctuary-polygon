// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
contract Test {
    event msgEvent(address indexed from, string msg);
    function message(string memory message) public {
       emit msgEvent(msg.sender, message);
    }
}