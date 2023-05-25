/**
 *Submitted for verification at polygonscan.com on 2023-05-25
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

contract SimpleCoin {
    string public constant name = "SimpleCoin";
    string public constant symbol = "SIC";

    uint public totalSupply = 100_000;
    mapping(address => uint) public balanceOf;

    constructor() {
        balanceOf[msg.sender] = totalSupply;
    }

    function transfer(address to, uint amount) public {
        require(balanceOf[msg.sender] >= amount, "Insufficient balance");
        require(msg.sender != address(0), "Invalid address");
        balanceOf[msg.sender] -= amount;
        balanceOf[to] += amount;
    }
}