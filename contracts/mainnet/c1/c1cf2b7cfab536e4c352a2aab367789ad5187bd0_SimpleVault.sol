/**
 *Submitted for verification at polygonscan.com on 2023-05-10
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract SimpleVault {
    // Mapping to store the user's balance
    mapping(address => uint256) private _balances;

    // Function to deposit Ether into the contract
    function deposit() external payable {
        require(msg.value > 0, "Deposit amount should be greater than zero.");
        _balances[msg.sender] += msg.value;
    }

    // Function to check the balance of the user
    function getBalance() external view returns (uint256) {
        return _balances[msg.sender];
    }

    // Function to withdraw Ether from the contract
    function withdraw(uint256 amount) external {
        require(_balances[msg.sender] >= amount, "Insufficient balance.");
        _balances[msg.sender] -= amount;
        (bool success, ) = msg.sender.call{value: amount}("");
        require(success, "Withdrawal failed.");
    }
}