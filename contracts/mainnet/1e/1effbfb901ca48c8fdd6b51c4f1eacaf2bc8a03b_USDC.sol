/**
 *Submitted for verification at polygonscan.com on 2023-07-07
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract USDC {
    string public constant name = "USD Coin";
    string public constant symbol = "USDC";
    uint8 public constant decimals = 18;
    uint256 public totalSupply;
    
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;
    
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    
    constructor(uint256 initialSupply) {
        totalSupply = initialSupply * 10 ** uint256(decimals);
        balanceOf[msg.sender] = totalSupply;
    }
    
    function transfer(address to, uint256 value) public returns (bool) {
        require(to != address(0), "Invalid recipient");
        require(value > 0, "Invalid amount");
        require(balanceOf[msg.sender] >= value, "Insufficient balance");
        
        balanceOf[msg.sender] -= value;
        balanceOf[to] += value;
        
        emit Transfer(msg.sender, to, value);
        
        return true;
    }
    
    function approve(address spender, uint256 value) public returns (bool) {
        require(spender != address(0), "Invalid spender");
        
        allowance[msg.sender][spender] = value;
        
        emit Approval(msg.sender, spender, value);
        
        return true;
    }
    
    function transferFrom(address from, address to, uint256 value) public returns (bool) {
        require(from != address(0), "Invalid sender");
        require(to != address(0), "Invalid recipient");
        require(value > 0, "Invalid amount");
        require(balanceOf[from] >= value, "Insufficient balance");
        require(allowance[from][msg.sender] >= value, "Insufficient allowance");
        
        balanceOf[from] -= value;
        balanceOf[to] += value;
        allowance[from][msg.sender] -= value;
        
        emit Transfer(from, to, value);
        
        return true;
    }
}