// SPDX-License-Identifier: MIT

pragma solidity 0.8.7;

contract Message{

    string public contractMessage;

    function setNewMessage(string memory _msg) public {
        contractMessage = _msg;
    }
}