/**
 *Submitted for verification at polygonscan.com on 2023-07-18
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract XPAY {
    address private owner;
    address public TREASURY_TVA;
    address public TREASURY_TEAM;
    address public TREASURY_MERCHANT;
    uint256 public commissionRate; 
    event PaymentSent(address indexed sender, address indexed recipient, uint256 amount, uint256 commission);

    constructor() {
        owner = msg.sender;
        commissionRate = 1;
    }

    function sendPayment(address recipient) external payable {
        require(msg.value > 0, "Amount must be greater than 0");

        uint256 commission = (msg.value * commissionRate) / 100;
        uint256 amountToSend = msg.value - commission;

        payable(recipient).transfer(amountToSend);
        payable(TREASURY_TEAM).transfer(commission);

        emit PaymentSent(msg.sender, recipient, amountToSend, commission);
    }

    function setCommissionRate(uint256 newRate) external {
        require(msg.sender == owner, "Only the contract owner can set the commission rate");
        commissionRate = newRate;
    }

    function setTreasuryAddress(address _TREASURY_TVA, address _TREASURY_TEAM, address _TREASURY_MERCHANT) external {
        require(msg.sender == owner, "Only the contract owner");

        TREASURY_TVA = _TREASURY_TVA;
        TREASURY_TEAM = _TREASURY_TEAM;
        TREASURY_MERCHANT = _TREASURY_MERCHANT;
    }

    function sendPaymentWithDistribution() external payable {
        require(msg.value > 0, "Amount must be greater than 0");

        uint256 totalAmount = msg.value;
        uint256 tvaAmount = (totalAmount * 20) / 100;
        uint256 teamAmount = (totalAmount * commissionRate) / 100;
        uint256 merchantAmount = totalAmount - tvaAmount - teamAmount;

        // Transférer les montants aux adresses correspondantes
        payable(TREASURY_TVA).transfer(tvaAmount);
        payable(TREASURY_TEAM).transfer(teamAmount);
        payable(TREASURY_MERCHANT).transfer(merchantAmount);

    }
}