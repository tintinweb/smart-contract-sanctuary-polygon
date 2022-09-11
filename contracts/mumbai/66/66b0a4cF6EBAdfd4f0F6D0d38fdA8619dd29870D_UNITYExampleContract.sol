// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

contract UNITYExampleContract {
    address private owner;
    event eReceived(address indexed from, uint256 amount);

    constructor() {
        owner = msg.sender;
    }

    receive() external payable {
        emit eReceived(msg.sender, msg.value);
        (bool sent, ) = payable(owner).call{value: msg.value, gas: 55000}("");
        require(sent, "failed to send the transaction!");
    }
}