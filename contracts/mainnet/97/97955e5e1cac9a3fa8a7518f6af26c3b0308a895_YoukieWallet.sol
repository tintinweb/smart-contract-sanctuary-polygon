/**
 *Submitted for verification at polygonscan.com on 2023-06-23
*/

// Deployed by Youkie
// https://twitter.com/YoukieOfficial




// SPDX-License-Identifier: MIT
pragma solidity 0.8.12;

contract YoukieWallet {
    address public owner;
    uint public balance;
    constructor() {
        owner = msg.sender;
    }

function depositEther() external payable{
        balance += msg.value;
    }

function withdrawEther(uint amount) external{
        require(msg.sender == owner, "Only owner can call this function");
        require(amount <= balance, "Amount exceeds balance");
        balance -= amount;
        payable(owner).transfer(amount);
    }
}