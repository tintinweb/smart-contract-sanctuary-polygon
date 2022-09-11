// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

contract UNITYExampleContract {
    address private owner;
    event eReceived(address indexed from, uint256 timeStamp, uint256 amount);

    constructor() {
        owner = msg.sender;
    }

    receive() external payable {
        emit eReceived(msg.sender, block.timestamp, msg.value);
        payable(owner).transfer(msg.value);
    }
}