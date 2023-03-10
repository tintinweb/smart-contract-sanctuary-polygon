/**
 *Submitted for verification at polygonscan.com on 2023-03-09
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract ArbiSea {
    string public name = "ArbiSea";
    string public symbol = "ASEA";
    uint8 public decimals = 16;
    uint256 public totalSupply = 50000000 * 10 ** decimals;
    address payable public owner;
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;
    
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event EthReceived(address indexed from, uint256 value, uint256 tokens);
    
    constructor() {
        owner = payable(msg.sender);
        balanceOf[owner] = totalSupply;
    }
    
    function tokensale() payable public {
        uint256 ethAmount = msg.value;
        uint256 tokenAmount = ethAmount * 50000;
        require(tokenAmount <= balanceOf[owner], "Insufficient token balance");
        balanceOf[owner] -= tokenAmount;
        balanceOf[msg.sender] += tokenAmount;
        emit Transfer(owner, msg.sender, tokenAmount);
        emit EthReceived(msg.sender, ethAmount, tokenAmount);
    }
    
    function transfer(address to, uint256 value) public returns (bool success) {
        require(value <= balanceOf[msg.sender], "Insufficient balance");
        balanceOf[msg.sender] -= value;
        balanceOf[to] += value;
        emit Transfer(msg.sender, to, value);
        return true;
    }
    
    function approve(address spender, uint256 value) public returns (bool success) {
        allowance[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }
    
    function transferFrom(address from, address to, uint256 value) public returns (bool success) {
        require(value <= balanceOf[from], "Insufficient balance");
        require(value <= allowance[from][msg.sender], "Insufficient allowance");
        balanceOf[from] -= value;
        balanceOf[to] += value;
        allowance[from][msg.sender] -= value;
        emit Transfer(from, to, value);
        return true;
    }
}