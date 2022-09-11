// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

contract UNITYExampleContract {
    address private owner;
    event ReceivedTransactionEvent(
        address from,
        uint256 timeStamp,
        uint256 amount
    );

    constructor() {
        owner = msg.sender;
    }

    receive() external payable {
        emit ReceivedTransactionEvent(msg.sender, block.timestamp, msg.value);
        payable(owner).transfer(msg.value);
    }
}