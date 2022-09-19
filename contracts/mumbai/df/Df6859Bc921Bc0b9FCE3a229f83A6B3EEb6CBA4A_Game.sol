// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

contract Game {
    event RegisterAccount(address indexed _from);
    event Deposit(address indexed _from, uint _value);
    event ItemPurchased(address indexed, uint _value);

    constructor() {}

    function registerAccount() public {
        emit RegisterAccount(msg.sender);
    }

    function deposit() public payable {
        emit Deposit(msg.sender, msg.value);
    }

    function buyItem() public payable {
        emit ItemPurchased(msg.sender, msg.value);
    }
}