/**
 *Submitted for verification at polygonscan.com on 2022-12-19
*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract TestContract {
    mapping (address => uint) private balances;

  // Log the event about a deposit being made by an address and its amount
    event LogDepositMade(address indexed accountAddress, uint amount);


    /// @return The balance of the user after the deposit is made
    function deposit() public payable returns (uint) {
        balances[msg.sender] += msg.value;
        emit LogDepositMade(msg.sender, msg.value);
        return balances[msg.sender];
    }

    /// @return The balance remaining for the user
    function withdraw(uint withdrawAmount) public returns (uint) {
        // Check enough balance available, otherwise just return balance
        require (balances[msg.sender] >= withdrawAmount, "Insufficent Funds");
        balances[msg.sender] -= withdrawAmount;
        // msg.sender.transfer(withdrawAmount);
        msg.sender.call{value: withdrawAmount};
        return balances[msg.sender];
    }

    /// @return The balance of the user
    function balance() public view returns (uint) {
        return balances[msg.sender];
    }

    /// @return The balance of the all deposits
    function depositsBalance() public view returns (uint) {
        return address(this).balance;
    }
}