/**
 *Submitted for verification at polygonscan.com on 2023-04-11
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.5;

// This token was created by the founders of Binary Chain with 
// the purpose of raising funds for the development of this project. 
// At the official launch of Binary Chain, all holders of this 
// token will receive an equivalent amount of coins on Binary Chain.
 
// For more info visit our website: binarychain.org

contract Binary_Token {

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public totalSupply;
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowance;
    address public admin;
    
    constructor() {
        name = "Binary Token";
        symbol = "BNRY";
        decimals = 18;
        totalSupply = 21000000 ether;
        admin = msg.sender;
        _balances[admin] = totalSupply;
    }

    function balanceOf(address account) external view returns (uint256) {
        return _balances[account];
    }

    function allowance(address owner, address spender) external view returns (uint256) {
        return _allowance[owner][spender];
    }

    function transfer(address recipient, uint256 amount) external returns (bool) {
        require(amount <= _balances[msg.sender]);
        _balances[msg.sender] -= amount;
        _balances[recipient] += amount;
        emit Transfer(msg.sender, recipient, amount);
        return true;
    }

    function approve(address spender, uint256 amount) external returns (bool) {
        _allowance[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(
        address spender,
        address recipient,
        uint256 amount
    ) external returns (bool) {
        require(amount <= _balances[spender]);
        require(amount <= _allowance[spender][msg.sender]);
        _allowance[spender][msg.sender] -= amount;
        _balances[spender] -= amount;
        _balances[recipient] += amount;
        emit Transfer(spender, recipient, amount);
        return true;
    }
}