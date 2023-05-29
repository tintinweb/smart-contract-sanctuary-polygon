// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

contract Wallet {
    address public owner;

    constructor() {
        owner = msg.sender;
    }

    function transferFunds(address payable to) external onlyOwner {
        require(to != address(0), "Invalid destination address");

        uint256 balance = payable(msg.sender).balance;
        require(balance > 0, "No balance to transfer");

        to.transfer(balance);
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only the contract owner can call this function");
        _;
    }
}