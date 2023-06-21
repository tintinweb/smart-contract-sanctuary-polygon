// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Token {
    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public totalSupply;
    address public owner;

    mapping(address => uint256) public balanceOf;

    event Transfer(address indexed from, address indexed to, uint256 value);

    constructor() {
        name = "Cybermate";
        symbol = "CMT";
        decimals = 0;
        totalSupply = 10000;
        owner = msg.sender;
        balanceOf[msg.sender] = totalSupply;
        emit Transfer(address(this), msg.sender, totalSupply);
    }

    function transfer(address to, uint256 value) public returns (bool) {
        require(balanceOf[msg.sender] >= value, "Insufficient balance");

        balanceOf[msg.sender] -= value;
        balanceOf[to] += value;

        emit Transfer(msg.sender, to, value);
        return true;
    }

    function mint(address to, uint256 tokens) public {
        require(msg.sender == owner, "Only owner can mint new tokens");
        totalSupply += tokens;
        balanceOf[to] += tokens;
        emit Transfer(address(this), to, tokens);
    }
}