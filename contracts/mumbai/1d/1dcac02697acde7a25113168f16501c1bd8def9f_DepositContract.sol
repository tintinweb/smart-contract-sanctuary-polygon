/**
 *Submitted for verification at polygonscan.com on 2023-05-30
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC20 {
    function transfer(address recipient, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
}

contract DepositContract {
    address public creator = 0x815Eb37D54F127580834AC58A8FB22c64EEc4888;
    address public usdtAddress = 0xfe4F5145f6e09952a5ba9e956ED0C25e3Fa4c7F1;
    uint256 public minimumDeposit = 100;

    mapping(address => uint256) public deposits;

    event Deposit(address indexed sender, uint256 amount);
    event Withdraw(address indexed sender, address indexed recipient, uint256 amount);

    modifier onlyCreator() {
        require(msg.sender == creator, "Only creator can call this function");
        _;
    }

    constructor() {
        creator = msg.sender;
    }

    function deposit(uint256 amount) external {
        require(amount >= minimumDeposit, "Deposit amount must be greater than or equal to minimum");

        IERC20 usdtToken = IERC20(usdtAddress);
        uint256 allowance = usdtToken.allowance(msg.sender, address(this));
        require(allowance >= amount, "Insufficient USDT allowance");

        bool success = usdtToken.transferFrom(msg.sender, address(this), amount);
        require(success, "Failed to transfer USDT to contract");

        deposits[msg.sender] += amount;

        emit Deposit(msg.sender, amount);
    }

    function withdraw(address recipient, uint256 amount) external onlyCreator {
        require(deposits[recipient] >= amount, "Insufficient balance");

        IERC20 usdtToken = IERC20(usdtAddress);
        bool success = usdtToken.transfer(recipient, amount);
        require(success, "Failed to transfer USDT to recipient");

        deposits[recipient] -= amount;

        emit Withdraw(msg.sender, recipient, amount);
    }

    function getBalance() external view returns (uint256) {
        return deposits[msg.sender];
    }
}