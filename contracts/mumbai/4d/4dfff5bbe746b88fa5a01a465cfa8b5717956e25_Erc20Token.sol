/**
 *Submitted for verification at polygonscan.com on 2023-01-06
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract Erc20Token {
    uint public totalSupply;
    string public name = "TOKEN";
    string public symbol = "TKN";

    mapping (address => uint) private balances;
    mapping (address => mapping (address => uint)) _allowance;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    constructor () {

    }
    
    function mint(address account, uint amount) public {
        totalSupply += amount;
        balances[account] += amount;
    }
    function burn(address account, uint amount) public {
        totalSupply -= amount;
        balances[account] -= amount;
    }
    function balanceOf(address account) external view returns (uint256) {
        return balances[account];
    }
    function transfer(address to, uint256 amount) external returns (bool) {
        balances[msg.sender] -= amount;
        balances[to] += amount;
        return true;
    }
    function allowance(address owner, address spender) external view returns (uint256) {
        return _allowance[owner][spender];
    }
    function approve(address spender, uint256 amount) external returns (bool) {
        _allowance[msg.sender][spender] = amount;
        return true;
    }
    function transferFrom(address from, address to, uint256 amount) external returns (bool) {
        if (_allowance[from][msg.sender] >= amount || from == msg.sender) {
            balances[from] -= amount;
            balances[to] += amount;
            if (from != msg.sender) _allowance[from][msg.sender] -= amount;
            return true;
        }
        return false;        
    }
}