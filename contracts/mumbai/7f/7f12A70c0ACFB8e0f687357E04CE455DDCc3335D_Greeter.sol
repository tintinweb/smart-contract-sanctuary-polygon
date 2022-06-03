//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

contract Greeter {
    string public secret;

    event secretUpdated(string _secret);

    function setStorage(string memory _value) public {
        secret = _value;
        emit secretUpdated(_value);
    }
}