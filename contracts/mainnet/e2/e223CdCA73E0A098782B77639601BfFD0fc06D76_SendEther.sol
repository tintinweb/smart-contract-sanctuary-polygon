// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

contract SendEther {
    constructor() {}

    function sendEther(address payable recipient) public payable {
        (bool sent, ) = recipient.call{value: msg.value}("");
        require(sent);
    }
}