/**
 *Submitted for verification at polygonscan.com on 2022-12-15
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

contract Token {
    address public minter;

    mapping(address => uint256) public balances;

    event Sent(address from, address to, uint amount);

    constructor() {
 
        minter = msg.sender;
 
    }
 
    function mint(address receiver, uint amount) public {
 
        if(msg.sender != minter) return;
        balances[receiver]+=amount;
 
    }
 
    function send(address receiver, uint amount) public {
        if(balances[msg.sender] < amount) return;
        balances[msg.sender]-=amount;
        balances[receiver]+=amount;
        emit Sent(msg.sender, receiver, amount);
 
    }
}