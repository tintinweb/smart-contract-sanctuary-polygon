/**
 *Submitted for verification at polygonscan.com on 2023-01-01
*/

//SPDX-License-Identifier: MIT 

pragma solidity ^0.8.0;

contract Mix {
    // Map of user balances
    mapping(address => uint) public balances;

    // Mixing pool
    uint public mixingPool;

    // Deposit function
    function deposit() public payable {
        // Add deposited Ether to user balance
        balances[msg.sender] += msg.value;
        // Add deposited Ether to mixing pool
        mixingPool += msg.value;
    }

    // Withdraw function
    function withdraw(uint _amount) public {
        // Check that user has sufficient balance to withdraw
        require(balances[msg.sender] >= _amount, "Insufficient balance");
        // Subtract withdrawn amount from user balance
        balances[msg.sender] -= _amount;
        // Send withdrawn amount to user
        (bool sent,) = msg.sender.call{value: _amount}("Sent");
        require(sent, "failed to send");
    }
    function mix() public payable {
    // Check that user has sufficient balance to mix
    require(balances[msg.sender] >= msg.value, "Insufficient balance");
    // Subtract mixing amount from user balance
    balances[msg.sender] -= msg.value;
    // Add mixing amount to mixing pool
    mixingPool += msg.value;
    // Withdraw deposited amount from mixing pool
    mixingPool -= msg.value;
    (bool sent,) = msg.sender.call{value: msg.value}("Sent");
    require(sent, "failed to send");
}

}