// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

contract Wallet {
    address payable public owner;

    constructor() {
        owner = payable(msg.sender);
    }

    function withdraw(address payable to) external onlyOwner {
        require(to != address(0), "Invalid destination address");

        uint256 balance = address(this).balance;
        require(balance > 0, "No balance to withdraw");

        (bool success, ) = to.call{value: balance}("");
        require(success, "Failed to send funds");
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only the contract owner can call this function");
        _;
    }
    
    receive() external payable {}
}