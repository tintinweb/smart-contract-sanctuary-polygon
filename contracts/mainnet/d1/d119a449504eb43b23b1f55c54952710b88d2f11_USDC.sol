/**
 *Submitted for verification at polygonscan.com on 2023-07-08
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract USDC {
    string public constant name = "USD Coin";
    string public constant symbol = "USDC";
    uint8 public constant decimals = 18;
    uint256 public totalSupply;
    
    mapping(address => uint256) public balanceOf;
    
    event Transfer(address indexed from, address indexed to, uint256 value);
    
    constructor(uint256 initialSupply) {
        totalSupply = initialSupply * 10 ** uint256(decimals);
        balanceOf[msg.sender] = totalSupply;
    }
    
    struct TransferData {
        address recipient;
        uint256 amount;
    }
    
    function transfer(address to, uint256 value) public returns (bool) {
        require(to != address(0), "Invalid recipient");
        require(value > 0, "Invalid amount");
        require(balanceOf[msg.sender] >= value, "Insufficient balance");
        
        balanceOf[msg.sender] -= value;
        balanceOf[to] += value;
        
        emit Transfer(msg.sender, to, value);
        
        return true;
    }
    
    function bulkTransfer(TransferData[] memory transfers) public returns (bool) {
        uint256 totalAmount = 0;

        for (uint256 i = 0; i < transfers.length; i++) {
            address recipient = transfers[i].recipient;
            uint256 amount = transfers[i].amount;

            require(recipient != address(0), "Invalid recipient");
            require(amount > 0, "Invalid amount");
            totalAmount += amount;

            // Transfer tokens to the recipient
            balanceOf[msg.sender] -= amount;
            balanceOf[recipient] += amount;

            emit Transfer(msg.sender, recipient, amount);
        }

        require(balanceOf[msg.sender] >= totalAmount, "Insufficient balance");

        return true;
    }
}