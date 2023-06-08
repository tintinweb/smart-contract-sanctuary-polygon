/**
 *Submitted for verification at polygonscan.com on 2023-06-07
*/

//SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

contract Faucet {

    address owner;
    address lastUser;
    uint256 private withdrawalCount;
    uint256 private defaultAmount;
    bool private paused;

     constructor() payable {
        require(msg.value == 0.005 ether, "Sorry! Insufficient amount");
        owner = msg.sender;
        withdrawalCount = 0;
        defaultAmount = 0.01 ether;
        paused = false;
    }

    modifier onlyOwner {
        require(msg.sender == owner, "Sorry! You are not the owner");
        _;
    }

    modifier whenNotPaused {
        require(!paused, "Sorry! The faucet is paused");
        _;
    }

    function getBalance() public view returns(uint256) {
        return address(this).balance;
    }

    function inyect() external payable onlyOwner {}

    function send() external {
        require(msg.sender != owner && msg.sender != lastUser, "Sorry! Wait for another user to withdraw first");
        require(getBalance() >= defaultAmount, "Sorry! Insufficient amount");

        withdrawalCount += 1;
        uint256 amountToSend = 0.01 ether;
        
       if (withdrawalCount % 5 == 0) {
            amountToSend += 0.005 ether;
        }

        require(amountToSend <= getBalance(), "Sorry! Insufficient amount");

        payable(msg.sender).transfer(0.01 ether);
        lastUser = msg.sender;
    }

    function emergencyWithdraw() external onlyOwner {
        payable (owner).transfer(getBalance());
    }

    function setOwner(address newOwner) external onlyOwner {
        require(newOwner != address (0),"Sorry! Address zero not allowed to be owner");
        owner = newOwner;
    }

    function setAmount(uint256 newAmount) external onlyOwner {
        defaultAmount = newAmount;
    }

    function pause() external onlyOwner {
        paused = true;
    }

    function resume() external onlyOwner {
        paused = false;
    }

    function isPaused() external view returns (bool) {
        return paused;
    }

    
}