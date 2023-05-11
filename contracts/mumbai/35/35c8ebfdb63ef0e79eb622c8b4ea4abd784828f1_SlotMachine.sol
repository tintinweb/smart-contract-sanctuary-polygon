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

    function deposit() public payable {
        require(msg.value <= address(this).balance / 2, "Deposit amount exceeds half of the contract balance");

        userDepositAmount[msg.sender] += msg.value;
        emit Deposit(msg.sender, msg.value);
    }

    function play() public {
        require(userDepositAmount[msg.sender] > 0, "No deposit amount for this address");

        uint256 random = uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty))) % 100;
        bool win = random < WINNING_PROBABILITY;

        if (win) {
            uint256 payoutAmount = userDepositAmount[msg.sender] * 2;
            userWinnings[msg.sender] += payoutAmount;
        }

        userDepositAmount[msg.sender] = 0;
        emit Play(msg.sender, userWinnings[msg.sender], win);
    }

    function claim() public {
        require(userWinnings[msg.sender] > 0, "No winnings to claim");

        uint256 payoutAmount = userWinnings[msg.sender];
        userWinnings[msg.sender] = 0;
        payable(msg.sender).transfer(payoutAmount);

        emit Claim(msg.sender, payoutAmount);
    }

    function withdraw() public {
        require(userDepositAmount[msg.sender] == 0, "Withdrawal not allowed while there is a deposit amount");

        payable(msg.sender).transfer(address(this).balance);
    }
}