/**
 *Submitted for verification at polygonscan.com on 2023-06-01
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Exchange {
    mapping(address => uint256) public balances;

    event Deposit(address indexed user, uint256 amount);
    event Withdraw(address indexed user, uint256 amount);
    event Trade(address indexed user, uint256 amountIn, uint256 amountOut);

    function deposit() external payable {
        require(msg.value > 0, "You must deposit some Ether.");
        balances[msg.sender] += msg.value;
        emit Deposit(msg.sender, msg.value);
    }

    function withdraw(uint256 amount) external {
        require(balances[msg.sender] >= amount, "Insufficient balance.");
        balances[msg.sender] -= amount;
        payable(msg.sender).transfer(amount);
        emit Withdraw(msg.sender, amount);
    }

    function trade(uint256 amountIn, uint256 amountOut) external {
        require(balances[msg.sender] >= amountIn, "Insufficient balance.");
        balances[msg.sender] -= amountIn;
        balances[msg.sender] += amountOut;
        emit Trade(msg.sender, amountIn, amountOut);
    }
}