/**
 *Submitted for verification at polygonscan.com on 2023-05-12
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC20 {
    function transfer(address recipient, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
}

contract Presale {
    uint256 public constant MAX_SALE_AMOUNT = 100 ether; // Maximum sale amount is 100 WETH
    uint256 public totalSaleAmount; // Total sale amount so far
    uint256 public tokenSaleRate; // Token sale rate set by the contract deployer
    address public tokenAddress; // Token address
    address payable public owner; // Contract owner

    constructor(address _tokenAddress) {
        tokenAddress = _tokenAddress;
        owner = payable(msg.sender);
        tokenSaleRate = 1000000; // Set the token sale rate to 1 million tokens per 1 WETH
    }

    receive() external payable {
        require(totalSaleAmount < MAX_SALE_AMOUNT, "Sale has ended"); // Check if the sale has ended
        require(msg.value > 0, "Amount must be greater than zero"); // Check if the amount is greater than zero

        IERC20 token = IERC20(tokenAddress);
        uint256 tokenAmount = msg.value * tokenSaleRate; // Calculate the number of tokens to be transferred
        require(token.balanceOf(address(this)) >= tokenAmount, "Insufficient token balance in contract"); // Check if the contract has enough tokens

        token.transfer(msg.sender, tokenAmount); // Transfer tokens to the buyer immediately
        owner.transfer(msg.value); // Send the purchased funds to the contract deployer
        totalSaleAmount += msg.value; // Update total sale amount

        if (totalSaleAmount >= MAX_SALE_AMOUNT) {
            owner.transfer(address(this).balance); // Transfer remaining WETH to the contract owner
        }
    }

    function withdraw() external {
        require(msg.sender == owner, "Only owner can withdraw");
        require(totalSaleAmount >= MAX_SALE_AMOUNT, "Sale is not yet completed");

        uint256 balance = address(this).balance;
        owner.transfer(balance); // Transfer all WETH to the contract owner
    }
}