// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract EscrowV1 {
    address public depositor;
    address public beneficiary;
    address public arbiter;
    bool public isApproved = false;
    uint public amount;
    

    event Approved(uint256 balance);

    constructor(address _arbiter) payable {
        arbiter = _arbiter;
        depositor = msg.sender;
        amount = msg.value;
    }

    function approve(address _beneficiary) public payable {
        require(msg.sender == arbiter, "Only arbiter can approve");

        isApproved = true;
        beneficiary = _beneficiary;
        (bool sent, ) = beneficiary.call{value: amount}("");
        require(sent, "Failed to send Ether");

        emit Approved(amount);
    }
}