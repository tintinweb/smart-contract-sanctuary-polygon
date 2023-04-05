/**
 *Submitted for verification at polygonscan.com on 2023-04-04
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract MaticPool {
    address public owner;
    uint256 public totalMatic;
    uint256 public treasuryPool;
    uint256 public lastPayout;
    mapping(address => uint256) public maticBalance;
    mapping(address => uint256) public lastDividendClaim;

    event Deposit(address indexed user, uint256 amount);
    event Withdraw(address indexed user, uint256 amount);
    event DividendClaimed(address indexed user, uint256 amount);

    constructor() {
        owner = msg.sender;
        lastPayout = block.timestamp;
    }

    function deposit() public payable {
        require(msg.value > 0, "Amount should be greater than 0");
        totalMatic += msg.value;
        maticBalance[msg.sender] += msg.value;
        uint256 creatorFee = (msg.value * 5) / 100;
        uint256 treasuryFee = (msg.value * 95) / 100;
        payable(owner).transfer(creatorFee);
        treasuryPool += treasuryFee;
        emit Deposit(msg.sender, msg.value);
    }

    function withdraw(uint256 amount) public {
        require(amount <= maticBalance[msg.sender], "Insufficient balance");
        uint256 fee = (amount * 10) / 100;
        uint256 creatorFee = (fee * 5) / 10;
        uint256 treasuryFee = (fee * 5) / 10;
        uint256 withdrawAmount = amount - fee;
        payable(msg.sender).transfer(withdrawAmount);
        payable(owner).transfer(creatorFee);
        treasuryPool += treasuryFee;
        maticBalance[msg.sender] -= amount;
        totalMatic -= amount;
        emit Withdraw(msg.sender, amount);
    }

    function claimDividend() public {
        require(maticBalance[msg.sender] > 0, "No Matic balance to claim dividends");
        require(block.timestamp - lastDividendClaim[msg.sender] >= 1 days, "Dividend can only be claimed once a day");
        uint256 payoutAmount = (treasuryPool * 1) / 100;
        uint256 userDividend = (maticBalance[msg.sender] * payoutAmount) / totalMatic;
        payable(msg.sender).transfer(userDividend);
        lastDividendClaim[msg.sender] = block.timestamp;
        emit DividendClaimed(msg.sender, userDividend);
    }

    function payout() public {
        require(block.timestamp - lastPayout >= 1 days, "Payout available once a day");
        uint256 payoutAmount = (treasuryPool * 1) / 100;
        payable(address(this)).transfer(payoutAmount);
        treasuryPool -= payoutAmount;
        lastPayout = block.timestamp;
    }
}