// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

contract Wallet {
    address payable public owner;
    uint256 public contractBalance;

    constructor() {
        owner = payable(msg.sender);
    }

    receive() external payable {}

    function sendMoney() public payable {
        contractBalance += msg.value;
    }

    function withdraw(uint256 _amount) external {
        require(msg.sender == owner, "caller is not owner");
        payable(msg.sender).transfer(_amount);
    }

    function getBalance() external view returns (uint256) {
        return address(this).balance;
    }
}