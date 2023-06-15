/**
 *Submitted for verification at polygonscan.com on 2023-06-14
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface USDT {
    function balanceOf(address account) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
}

contract transferUSDT {
    USDT public USDt;
    event PaymentDone (address senderAddress , uint256 amount , uint256 productId , uint256 date);
    event PaymentFailed(address senderAddress, uint256 amount, uint256 productId, uint256 date);
    constructor() {
        USDt = USDT(0xfe4F5145f6e09952a5ba9e956ED0C25e3Fa4c7F1);
    }
    function depositTokens(address adminAddress , uint256 amount , uint256 transactionId) public {

        // amount should be > 0
        require(USDt.balanceOf(msg.sender) >= amount , "Insufficient value");
        // Transfer USDT to this contract
        bool success = USDt.transferFrom(msg.sender, adminAddress, amount);
        
        if (success) {
            emit PaymentDone(msg.sender, amount, transactionId, block.timestamp);
        } else {
            emit PaymentFailed(msg.sender, amount, transactionId, block.timestamp);
        }
    }
}