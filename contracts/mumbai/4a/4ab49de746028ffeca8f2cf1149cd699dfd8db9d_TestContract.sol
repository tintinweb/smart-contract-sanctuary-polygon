// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;


contract TestContract {
    uint public uintSlot;
    bool public boolSlot;
    string public stringSlot;

    event Withdrawal(uint amount, uint when);
    event Deposit(uint indexed amount, uint when);

    function changeUint(uint x) public {
        uintSlot = x;
    }

    function changeBool(bool x) public {
        boolSlot = x;
    }

    function changeString(string calldata x) public {
        stringSlot = x;
    }

    function withdraw(bool x, uint amount) public {
        if (x) {
            emit Withdrawal(amount, block.timestamp);
        }
        else {
            emit Deposit(amount, block.timestamp);
        }
    }
}