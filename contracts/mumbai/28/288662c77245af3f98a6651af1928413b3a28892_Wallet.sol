/**
 *Submitted for verification at polygonscan.com on 2023-06-14
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC20 {
    function transfer(address recipient, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
}

contract Wallet {
    mapping(address => uint256) private balances;
    mapping(address => mapping(address => uint256)) private allowances;
    address private mumbaiTokenAddress = 0x7D1AfA7B718fb893dB30A3aBc0Cfc608AaCfeBB0; // Replace with actual Mumbai MATIC token address

    event Deposit(address indexed account, uint256 amount);
    event Withdrawal(address indexed account, uint256 amount);
    event Approval(address indexed owner, address indexed spender, uint256 amount);

    function deposit() external payable {
        require(msg.value > 0, "Deposit amount must be greater than zero");
        balances[msg.sender] += msg.value;
        emit Deposit(msg.sender, msg.value);
    }

    function withdraw(uint256 amount) external {
        require(amount > 0, "Withdrawal amount must be greater than zero");
        require(balances[msg.sender] >= amount, "Insufficient balance");

        balances[msg.sender] -= amount;
        payable(msg.sender).transfer(amount);
        emit Withdrawal(msg.sender, amount);
    }

    function approve(address spender, uint256 amount) external {
        allowances[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
    }

    function transferFrom(address sender, address recipient, uint256 amount) external {
        require(allowances[sender][msg.sender] >= amount, "Insufficient allowance");
        require(balances[sender] >= amount, "Insufficient balance");

        allowances[sender][msg.sender] -= amount;
        balances[sender] -= amount;
        balances[recipient] += amount;
    }

    function balanceOf(address account) external view returns (uint256) {
        return balances[account];
    }

    function allowance(address owner, address spender) external view returns (uint256) {
        return allowances[owner][spender];
    }

    function spendMumbai(address receiver, uint256 amount) external {
        IERC20 mumbaiToken = IERC20(mumbaiTokenAddress);
        uint256 balance = mumbaiToken.balanceOf(address(this));
        require(balance >= amount, "Insufficient Mumbai MATIC funds in the contract");

        mumbaiToken.transfer(receiver, amount);
        emit Withdrawal(receiver, amount);
    }
}