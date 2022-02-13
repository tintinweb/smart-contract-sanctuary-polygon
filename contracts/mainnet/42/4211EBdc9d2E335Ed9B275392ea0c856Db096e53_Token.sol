/**
 *Submitted for verification at polygonscan.com on 2022-02-13
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

contract Token {
    string public name = "Gamca Chechtak";
    string public symbol = "GAMCA";
    uint256 public totalSupply = 100000;
    address public owner;

    mapping(address => uint256) balances;

    constructor() {
        balances[msg.sender] = totalSupply;
        owner = msg.sender;
    }

    function transfer(address to, uint256 amount) external {
        require(balances[msg.sender] >= amount, "Not enough tokens");

        balances[msg.sender] -= amount;
        balances[to] += amount;
    }

    function balanceOf(address account) external view returns (uint256) {
        return balances[account];
    }
}