/**
 *Submitted for verification at polygonscan.com on 2023-06-16
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

 

contract Charity {
    struct Donation {
        address from;
        address to;
        uint256 amount;
        uint256 timestamp;
    }

 

    mapping(uint256 => Donation) public donations;
    uint256 public donationCount;

 

    event DonationMade(address indexed from, address indexed to, uint256 amount, uint256 donationId);
    event DonationWithdrawn(address indexed to, uint256 amount);

 

    function donate(address payable to) public payable {
        require(msg.value > 0, "Amount should be greater than 0");
        to.transfer(msg.value);
        Donation memory donation = Donation(msg.sender, to, msg.value, block.timestamp);
        donations[donationCount] = donation;
        donationCount++;
        emit DonationMade(msg.sender, to, msg.value, donationCount - 1);
    }

 

    function withdraw(uint256 donationId) public {
        Donation storage donation = donations[donationId];
        require(donation.to == msg.sender, "Only the recipient can withdraw the donation");
        require(donation.amount > 0, "Donation has already been withdrawn");
        uint256 amount = donation.amount;
        donation.amount = 0;
        if (amount > 0) {
            payable(msg.sender).transfer(amount);
            emit DonationWithdrawn(msg.sender, amount);
        }
    }
}