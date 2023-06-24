/**
 *Submitted for verification at polygonscan.com on 2023-06-23
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

contract AppleToken {
    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public totalSupply;
    
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;
    
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    constructor() {
        name = "Apple";
        symbol = "AP";
        decimals = 18; // You can choose any number of decimals you want (typically 18).
        totalSupply = 1000000 * (10 ** uint256(decimals)); // Initial supply of 1,000,000 tokens.
        balanceOf[msg.sender] = totalSupply; // Allocate initial supply to the contract deployer.
    }

    function transfer(address to, uint256 value) external returns (bool) {
        require(to != address(0), "Invalid recipient");
        require(value > 0, "Invalid transfer amount");
        require(balanceOf[msg.sender] >= value, "Insufficient balance");

        balanceOf[msg.sender] -= value;
        balanceOf[to] += value;

        emit Transfer(msg.sender, to, value);
        return true;
    }

    function approve(address spender, uint256 value) external returns (bool) {
        require(spender != address(0), "Invalid spender");

        allowance[msg.sender][spender] = value;

        emit Approval(msg.sender, spender, value);
        return true;
    }

    function transferFrom(address from, address to, uint256 value) external returns (bool) {
        require(to != address(0), "Invalid recipient");
        require(value > 0, "Invalid transfer amount");
        require(balanceOf[from] >= value, "Insufficient balance");
        require(allowance[from][msg.sender] >= value, "Insufficient allowance");

        balanceOf[from] -= value;
        balanceOf[to] += value;
        allowance[from][msg.sender] -= value;

        emit Transfer(from, to, value);
        return true;
    }
}