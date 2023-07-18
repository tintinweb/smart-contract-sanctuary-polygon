/**
 *Submitted for verification at polygonscan.com on 2023-07-17
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract AirDrop {
    address private owner;
    uint256 public totalGasFee;
    uint256 public airdropAmount = 200 * 10**18; // Jumlah token yang diberikan setiap kali AirDrop diklaim
    uint256 public claimGasFee = 200000000000000000; // Biaya gas fee per claim (0.2 METIC dalam satuan WIE)

    mapping(address => bool) public claimedUsers;

    event Claim(address indexed user, uint256 amount);
    event Withdraw(address indexed recipient, uint256 amount);

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only the contract owner can call this function.");
        _;
    }

    modifier requireSufficientGasFee() {
        require(msg.value >= claimGasFee, "Insufficient gas fee.");
        _;
    }

    function claim() external payable requireSufficientGasFee {
        require(!claimedUsers[msg.sender], "AirDrop already claimed.");

        claimedUsers[msg.sender] = true;
        totalGasFee += claimGasFee;

        payable(msg.sender).transfer(airdropAmount);

        emit Claim(msg.sender, airdropAmount);
    }

    function withdrawGasFee() external onlyOwner {
        uint256 balance = totalGasFee;
        require(balance > 0, "No gas fee funds available for withdrawal.");

        totalGasFee = 0;

        (bool success, ) = payable(owner).call{value: balance}("");
        require(success, "Failed to withdraw gas fee funds.");

        emit Withdraw(owner, balance);
    }
}