/**
 *Submitted for verification at polygonscan.com on 2023-05-25
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract SimpleVault {
    // storage for balances
    mapping(address => uint256) balances;

    // deposit coin
    function deposti() public payable {
        balances[msg.sender] += msg.value;
    }

    // check balance
    function checkBalance(address addr) public view returns(uint256) {
        return balances[addr];
    }

    // withdraw coin
    function withdraw(uint256 amount) public {
        // TODO check the balance
        require(balances[msg.sender] >= amount, "Insufficient balance");

        // substract the amount from the balance
        balances[msg.sender] -= amount;

        // send the amount to the caller
        (bool success, ) = msg.sender.call{value: amount}("");

        // check that the send was successful
        require(success, "withdrawal failed.");
    }
}