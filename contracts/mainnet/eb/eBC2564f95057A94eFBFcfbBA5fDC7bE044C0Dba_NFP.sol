/**
 *Submitted for verification at polygonscan.com on 2023-05-22
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

contract NFP {
    mapping(address => uint) public balances;
    mapping(address => mapping(address => uint)) public allowed;
    uint public totalSupply_;
    string public name;
    string public symbol;
    uint public decimals;
    
    event Transfer(address indexed from, address indexed to, uint amount);
    event Approval(address indexed owner, address indexed spender, uint amount);
    event FundsReceived(address indexed sender, uint value); // Déclaration de l'événement FundsReceived;
    
    constructor() {
        totalSupply_ = 1000000000 * 10 ** 18;
        name = "NEFRIPANT";
        symbol = "NFP";
        decimals = 18;
        balances[msg.sender] = totalSupply_;
    }
    
    function totalSupply() public view returns (uint256) {
        return totalSupply_;
    }
    
    function balanceOf(address owner) public view returns(uint) {
        return balances[owner];
    }
    
    function allowance(address owner, address delegate) public view returns(uint) {
        return allowed[owner][delegate];
    }
    
    function transfer(address to, uint amount) public returns(bool) {
        require(balanceOf(msg.sender) >= amount, 'balance too low');
        balances[msg.sender] -= amount;
        balances[to] += amount;
        emit Transfer(msg.sender, to, amount);
        return true;
    }
    
    function transferFrom(address from, address to, uint amount) public returns(bool) {
        require(balanceOf(from) >= amount, 'balance too low');
        require(allowed[from][msg.sender] >= amount, 'allowance too low');
        balances[from] -= amount;
        allowed[from][msg.sender] -= amount;
        balances[to] += amount;
        emit Transfer(from, to, amount);
        return true;
    }
    
    function approve(address spender, uint amount) public returns (bool) {
        allowed[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }
    receive() external payable {
    emit FundsReceived(msg.sender, msg.value);
}

}