/**
 *Submitted for verification at polygonscan.com on 2023-05-06
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.17;

contract Token {
    address public owner;
    string public name = "HARDHAT";
    string public symbol = "HHT";
    uint256 public totalSupply = 10000;

    constructor(){
        owner = msg.sender;
        balances[msg.sender] = totalSupply;
    }

    mapping(address=>uint256) balances;

    function transfer(address to, uint256 amount) external {
        require(balances[msg.sender] >= amount,"not enough balance");
        balances[msg.sender] -= amount;
        balances[to] += amount;
    }

    function balanceOf(address account) public view returns(uint256) {
        return balances[account];
    }
}