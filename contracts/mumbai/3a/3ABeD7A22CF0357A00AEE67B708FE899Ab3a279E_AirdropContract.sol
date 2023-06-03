/**
 *Submitted for verification at polygonscan.com on 2023-06-02
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface Token {
    function transfer(address to, uint256 amount) external returns (bool);
}

contract AirdropContract {
    address public owner;
    uint256 public claimFee;
    address public tokenAddress;

    struct Airdrop {
        uint256 tokensToClaim;
        bool isPermissioned;
    }

    mapping(address => Airdrop) public airdrops;

    event AirdropClaimed(address indexed _claimer, uint256 _amount);

    constructor(address _tokenAddress) {
        owner = msg.sender;
        claimFee = 0.01 ether; // Set the claim fee to 0.01 ETH (adjust as needed)
        tokenAddress = _tokenAddress;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only the contract owner can perform this action");
        _;
    }

    function setClaimFee(uint256 _fee) external onlyOwner {
        claimFee = _fee;
    }

    function grantPermission(address _address, uint256 _tokensToClaim) external onlyOwner {
        airdrops[_address].tokensToClaim = _tokensToClaim;
        airdrops[_address].isPermissioned = true;
    }

    function revokePermission(address _address) external onlyOwner {
        delete airdrops[_address];
    }

    function claimAirdrop() external payable {
        require(airdrops[msg.sender].isPermissioned, "You are not permitted to claim the airdrop");
        require(msg.value >= claimFee, "Insufficient payment for the claim fee");

        uint256 tokensToClaim = airdrops[msg.sender].tokensToClaim;

        // Transfer the tokens from the contract to the claimer
        Token token = Token(tokenAddress);
        require(token.transfer(msg.sender, tokensToClaim), "Token transfer failed");

        // Emit event
        emit AirdropClaimed(msg.sender, tokensToClaim);

        // Transfer any excess ETH back to the claimer
        uint256 refundAmount = msg.value - claimFee;
        if (refundAmount > 0) {
            payable(msg.sender).transfer(refundAmount);
        }
    }

    function withdrawFees() external onlyOwner {
        uint256 contractBalance = address(this).balance;
        require(contractBalance > 0, "No fees to withdraw");
        payable(owner).transfer(contractBalance);
    }
}