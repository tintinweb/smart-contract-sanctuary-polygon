/**
 *Submitted for verification at polygonscan.com on 2023-05-10
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract SlotMachine {
    uint256 constant public WINNING_PROBABILITY = 50; // 50% winning probability
    mapping(address => uint256) public userDepositAmount;
    mapping(address => uint256) public userWinnings;

    event Deposit(address indexed user, uint256 amount);
    event Play(address indexed user, uint256 amount, bool win);
    event Claim(address indexed user, uint256 amount);
    event CheckBalance(address indexed user, uint256 balance);

    function deposit() public payable {
        userDepositAmount[msg.sender] += msg.value;
        emit Deposit(msg.sender, msg.value);
    }

    function play(uint256 amountToPlay) public {
        require(userDepositAmount[msg.sender] >= amountToPlay, "Insufficient deposit amount for this address");

        userDepositAmount[msg.sender] -= amountToPlay;
    
        uint256 random = uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty))) % 100;
        bool win = random < WINNING_PROBABILITY;

        if (win) {
            uint256 payoutAmount = amountToPlay * 2;
            userWinnings[msg.sender] += payoutAmount;
        }

        emit Play(msg.sender, amountToPlay, win);
    }

    function claim() public {
        require(userWinnings[msg.sender] > 0, "No winnings to claim");

        uint256 payoutAmount = userWinnings[msg.sender];
        userWinnings[msg.sender] = 0;
        payable(msg.sender).transfer(payoutAmount);

        emit Claim(msg.sender, payoutAmount);
    }

    function checkBalance() public {
        uint256 balance = userWinnings[msg.sender];
        emit CheckBalance(msg.sender, balance);
    }
}