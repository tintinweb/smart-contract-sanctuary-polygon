/**
 *Submitted for verification at polygonscan.com on 2023-06-19
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

contract CharityContract {
    struct Donation {
        address from;
        address to;
        uint256 amount;
        uint256 timestamp;
        bool withdrawn;
    }

    mapping(uint256 => Donation) public donations;
    uint256 public donationCount;

    mapping(address => uint256) public donatedBalances;

    event DonationMade(address indexed from, address indexed to, uint256 amount, uint256 donationId);
    event DonationWithdrawn(address indexed to, uint256 amount);

    function donate(address payable to) external payable {
        require(msg.value > 0, "Invalid donation amount");

        uint256 donationId = donationCount;
        donations[donationId] = Donation(msg.sender, to, msg.value, block.timestamp, false);
        donationCount++;

        donatedBalances[to] += msg.value;

        emit DonationMade(msg.sender, to, msg.value, donationId);
    }

    function withdraw() external {
        uint256 balance = donatedBalances[msg.sender];
        require(balance > 0, "No donated balance available");

        donatedBalances[msg.sender] = 0;
        payable(msg.sender).transfer(balance);

        emit DonationWithdrawn(msg.sender, balance);
    }
}