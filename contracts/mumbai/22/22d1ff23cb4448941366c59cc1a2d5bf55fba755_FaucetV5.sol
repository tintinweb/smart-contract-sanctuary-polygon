/**
 *Submitted for verification at polygonscan.com on 2023-05-27
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

contract FaucetV5 {
    address public owner;
    address private lastUser;
    uint256 private totalUsers = 0;
    uint256 public amountToSend = 0.01 ether;
    bool public paused;

    constructor() payable {
        require(msg.value == 0.005 ether, "Sorry, insufficient amount");
        owner = msg.sender;
        paused = false;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Scammer! You are not the owner");
        _;
    }

    function getBalance() public view returns(uint256) {
        return address(this).balance;
    }

    function inject() external payable onlyOwner {} 

    function send() external {
        require(paused == false, "Contract is paused");
        require(msg.sender != owner, "Sorry Boss, you can not use this function");
        require(msg.sender != lastUser, "Sorry, you are going to empty me! Wait for the next user");
        require(getBalance() >= amountToSend, "Sorry! Insufficient balance");
        
        if (isLuckyUser()) {
            amountToSend = amountToSend + 0.005 ether;
        }

        payable(msg.sender).transfer(amountToSend);
        lastUser = msg.sender;
        totalUsers = totalUsers + 1;
    }

    function isLuckyUser() private view returns (bool) {
        return ((totalUsers + 1) % 5) == 0;
    }

    function emergencyWithdraw() external onlyOwner {
        payable(owner).transfer(getBalance());
    }

    function setOwner(address newOwner) external onlyOwner {
        require(newOwner != address(0), "Sorry! Address zero not allowed to be owner");
        owner = newOwner;
    }

    function setAmountToSend(uint256 newAmountToSend) external onlyOwner {
        amountToSend = newAmountToSend;
    }

    function pause() external onlyOwner {
        paused = true;
    }

    function resume() external onlyOwner {
        paused = false;
    }

}