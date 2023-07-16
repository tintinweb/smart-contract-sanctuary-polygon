/**
 *Submitted for verification at polygonscan.com on 2023-07-16
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

contract Vault {
    uint public unlockTime;
    address payable public owner;

    event Deposit(uint amount, uint when);
    event Withdrawal(uint amount, uint when);

    constructor(uint _unlockTime) {
        require(
            block.timestamp < _unlockTime,
            "Unlock time should be in the future"
        );
        unlockTime = _unlockTime;
        owner = payable(msg.sender);
    }

    function deposit() payable public {
        emit Deposit(msg.value, block.timestamp);

    }

    function withdraw() public {
        require(block.timestamp >= unlockTime, "You can't withdraw yet");
        require(msg.sender == owner, "you aren't the owner");

        emit Withdrawal(address(this).balance, block.timestamp);

        owner.transfer(address(this).balance);
    }
}