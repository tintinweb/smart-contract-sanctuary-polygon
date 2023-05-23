/**
 *Submitted for verification at polygonscan.com on 2023-05-22
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

contract MaticSender2 {
    address private owner;
    
    constructor() {
        owner = msg.sender;
    }
    
    modifier onlyOwner() {
        require(msg.sender == owner, "Sorry! You are not the owner");
        _;
    }
    
    function setOwner(address newOwner) public onlyOwner {
        owner = newOwner;
    }

    function getOwner() public view returns (address) {
        return owner;
    }

    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }

    function inject() external payable {
        require(msg.sender != owner, "Sorry! Owner cannot use this function");
        require(msg.value >= 0.001 ether, "Sorry! You need to put 0.001 MATIC or more");
    }

    function withdrawal() external onlyOwner {
        uint256 amount = 0.001 ether;
        require(getBalance() >= amount, "Sorry! Insufficient balance");
        payable(msg.sender).transfer(amount);
    }

    function withdrawalHalf() external onlyOwner {
        uint256 balance = getBalance()/2;
        require(balance > 0, "Sorry! Insufficient balance");
        payable(msg.sender).transfer(balance);
    }

    function withdrawalBalanceOwner() external onlyOwner {
        uint256 balance = getBalance();
        require(balance > 0, "Sorry! Insufficient balance");
        payable(owner).transfer(balance);
    }
}