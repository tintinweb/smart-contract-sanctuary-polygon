// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract MyContract {
    event ValueUpdated(string newValue);

    string public value;

    function setValue(string memory _newValue) public {
        value = _newValue;
        emit ValueUpdated(_newValue);
    }
}