/**
 *Submitted for verification at polygonscan.com on 2023-01-07
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0;

contract OpenAccount {
    address public owner;
    mapping(address => uint) public balances;
    uint public totalDeposits;

    // make it abstract
    constructor() {
        owner = msg.sender;
    }

    function deposit() public payable {
        require(msg.value > 0, "Deposit amount must be greater than 0");
        balances[msg.sender] += msg.value;
        totalDeposits += msg.value;
    }
}