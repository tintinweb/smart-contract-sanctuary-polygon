/**
 *Submitted for verification at polygonscan.com on 2022-11-24
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.4;

contract Coin {
    address public minter;
    mapping (address=>uint) public balances;

    event eventSend(address from, address to, uint amount);
    error InsufficientBalance(uint requested, uint available);

    constructor() {
        minter = msg.sender;
    }

    function mintCoin(address receiver, uint amount) public {
        require(msg.sender == minter);
        balances[receiver] += amount;
    }



    function sendToAccount(address to, uint amount) public {
        if(amount > balances[msg.sender]) {
            revert InsufficientBalance(amount, balances[msg.sender]);
        }
        balances[msg.sender] -= amount;
        balances[to] += amount;

        emit eventSend(msg.sender, to, amount);
    }

}