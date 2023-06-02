/**
 *Submitted for verification at polygonscan.com on 2023-06-01
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract BillPaymentContract {
    mapping(address => uint256) private balances;
    mapping(address => mapping(uint256 => uint256)) private scheduledPayments;
    uint256 private nextPaymentId;

    function deposit() external payable {
        balances[msg.sender] += msg.value;
    }

    function schedulePayment(uint256 amount, uint256 frequency) external {
        require(amount > 0, "Invalid amount");
        require(frequency > 0, "Invalid frequency");

        uint256 paymentId = nextPaymentId++;
        scheduledPayments[msg.sender][paymentId] = amount;
    }

    function processScheduledPayments() external {
        uint256 totalPayments = scheduledPayments[msg.sender][nextPaymentId];
        require(totalPayments > 0, "No scheduled payments");
        require(balances[msg.sender] >= totalPayments, "Insufficient balance");

        balances[msg.sender] -= totalPayments;

        // Perform the actual payment operation here
        emit PaymentProcessed(msg.sender, totalPayments, block.timestamp);

        delete scheduledPayments[msg.sender][nextPaymentId];
        nextPaymentId++;
    }

    function getBalance() external view returns (uint256) {
        return balances[msg.sender];
    }

    event PaymentProcessed(address indexed payer, uint256 amount, uint256 timestamp);
}