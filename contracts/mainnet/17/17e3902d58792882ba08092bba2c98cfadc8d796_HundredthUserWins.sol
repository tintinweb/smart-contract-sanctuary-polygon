/**
 *Submitted for verification at polygonscan.com on 2023-03-31
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract HundredthUserWins {
    address payable public owner;
    address payable public winner;
    uint256 public balance;
    uint256 public count;
    uint256 public constant MAX_DEPOSIT = 10 ether;

    constructor() {
        owner = payable(msg.sender);
        winner = payable(address(0));
        balance = 0;
        count = 0;
    }

    function deposit() public payable {
        require(msg.value == MAX_DEPOSIT, "Deposit amount must be exactly 10 MATIC");
        balance += msg.value;
        count++;
        if (count % 100 == 0) {
            winner = payable(msg.sender);
        }
        owner.transfer(msg.value / 100); // 1% commission to owner
    }

    function claimPrize() public {
        require(msg.sender == winner, "Only the winner can claim the prize");
        uint256 prize = balance;
        balance = 0;
        count = 0;
        winner.transfer(prize);
        winner = payable(address(0)); // reset winner address
    }
}