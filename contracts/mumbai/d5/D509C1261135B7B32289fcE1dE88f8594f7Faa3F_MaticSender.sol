/**
 *Submitted for verification at polygonscan.com on 2023-05-21
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract MaticSender {
    address owner;

    // (1)
    constructor() {
        owner = msg.sender;
    }

    function setOwner(address _owner) external {
        owner = _owner;
    }

    //3)
    modifier notOwner() {
        require(msg.sender != owner, "Sorry! owner not allowed");
        _;
    } 

    //4)
    modifier onlyOwner() {
        require(msg.sender == owner, "Sorry! You are not the owner");
        _;
    } 

    function getOwner() external view returns (address) {
        return owner;
    }

    function getBalance() public view returns (uint) {
        return address(this).balance;
    }

    function injectBalance() external payable notOwner returns (bool) {
        // 3)
        require(msg.value >= 0.0001 ether, "Min 0.0001 ether");
        return true;
    }

    function send001Matic() external onlyOwner returns  (bool) {
        // 2)
        require(getBalance() > 0.001 ether, "Sorry! Insufficient balance");
        (bool success, ) = msg.sender.call{value: 0.001 ether}("");
        return success;
    }

    function sendHalfOfBalance() external onlyOwner returns (bool) {
        uint256 halfOfBalance;
        // 2)
        require(getBalance() > 0 ether, "Sorry! Insufficient balance");
        unchecked  {
            halfOfBalance = getBalance() / 2;
        }
        (bool success, ) = msg.sender.call{value: halfOfBalance}("");
        return success;
    }

    function withdraw() external onlyOwner returns (bool)  {
        require(owner != address(0), "Zero Address not available.");
        // 2)
        require(getBalance() > 0 ether, "Sorry! Insufficient balance");
        uint256 contractBalance = getBalance();
        (bool success, ) = owner.call{value: contractBalance}("");
        return success;
    }
}