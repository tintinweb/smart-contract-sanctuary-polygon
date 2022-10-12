/**
 *Submitted for verification at polygonscan.com on 2022-10-11
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

contract EtherSenderV2 {

    address public owner;
    uint256 minAmount = 0.01 ether;

    modifier onylOwner {
        require(owner == msg.sender, "You are not the owner, only the owner can cheat!");
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    function receiveCash() external payable returns (uint256) {
         if (msg.value > minAmount) {
           return msg.value;
       } else {
           revert("Insufficient balance. You have to send at least 0.01 tokens");
       }
    }

    function partialWithdraw() external {
       address payable to = payable(msg.sender);
        uint256 amount = getBalance();
       if (amount > 0) {
           to.transfer(minAmount);
       } else {
           revert("There's not enough money in the smart contract");
       }
    }

    function halfWithdraw() external  {
        address payable to = payable(msg.sender);
        uint256 amount = getBalance();
        uint256 halfAmount = amount / 2;
        
        if (amount > 0) {
           to.transfer(halfAmount);
       } else {
           revert("There's not enough money in the smart contract");
       }
    }

    function rugPull() external onylOwner {
        address payable to = payable(owner);
        uint256 amount = getBalance();
        to.transfer(amount);
    }

    function getBalance() private view returns (uint256) {
        uint256 balance = address(this).balance;
        return balance;
    }

}