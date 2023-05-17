/**
 *Submitted for verification at polygonscan.com on 2023-05-16
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

contract LabsDistributions {
    address public owner;

    constructor() {
        owner = msg.sender;
    }

    function distributeFunds(address payable recipient) external payable {
        uint256 amountToSend = (msg.value * 90) / 100; // Calculate 90% of the received value
        uint256 amountToRecipient = (msg.value * 10) / 100; // Calculate 10% of the received value

        require(recipient != address(0), "Invalid recipient address");
        require(amountToRecipient > 0, "Invalid amount to recipient");

        require(payable(recipient).send(amountToRecipient), "Failed to send funds to the recipient");

        require(payable(owner).send(amountToSend), "Failed to send funds to the contract owner");
    }
}