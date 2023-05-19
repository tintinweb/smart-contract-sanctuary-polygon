/**
 *Submitted for verification at polygonscan.com on 2023-05-18
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

contract MaticSenderV22 {
    address owner;

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Sorry! You are not the owner");
        _;
    }

    modifier insufficientBalance() {
        require(address(this).balance > 0, "Sorry! Insufficient balance");
        _;
    }

    function setOwner(address newOwner) public {
        owner = newOwner;
    }

    function getOwner() public view returns(address) {
        return owner;
    }

    function getBalance() public view returns(uint256) {
        return address(this).balance;
    }
    
    function inject() external payable {
        require(msg.sender != owner, "Sorry! The owner can not inject");
        require(msg.value >= 0.001 ether, "Sorry! You need to inject 0.001 Matic or more");

    }

    function withdrawal() external onlyOwner {
        require(address(this).balance >= 0.001 ether, "Sorry! Insufficient balance");
        payable(msg.sender).transfer(0.001 ether);

    }

    function withdrawalAllToOwner() external onlyOwner insufficientBalance {
        uint256 balance = getBalance();
        payable(owner).transfer(balance);
    }

    function withdrawalHalf() external onlyOwner insufficientBalance {
        uint256 balance = getBalance() / 2;
        payable(msg.sender).transfer(balance);
    }
    
}