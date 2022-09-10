/**
 *Submitted for verification at polygonscan.com on 2022-09-09
*/

// SPDX-License-Identifier: MIT
// Mucha Plata Patrón Version 1.1.1
// 0xc58A1559b566863668A8C7316da00faC01202300 obsolete
pragma solidity ^0.8.0;

contract Plata {
    
    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);

    address public minter;
    uint public totalSupply = 220000 * 1000000000;
    uint public maximumSupply = 220000 * 1000000000;
    address constant public burner = 0x000000000000000000000000000000000000dEaD;
 
    string public name = "Plata";
    string public symbol = "PLT";
    uint public decimals = 4;

    mapping (address => uint) public balances;
    mapping (address => mapping(address => uint)) public allowance;

    constructor() {
        balances[msg.sender] = totalSupply;
        minter = msg.sender;
    }

    function mint(uint amount) public returns(bool){
        amount = amount * 10000;
        require(msg.sender == minter && totalSupply < maximumSupply);
        balances[msg.sender] += amount;
        totalSupply += amount;
        emit Transfer(msg.sender, minter, amount);
        return true;
    }

    function burn(uint amount) public returns(bool){
        amount = amount * 10000;
        require(amount <= balances[msg.sender], "No balance");
        balances[msg.sender] -= amount;
        totalSupply -= amount;
        emit Transfer(msg.sender, burner, amount);
        return true;
    }

    function send(address receiver, uint amount) public {
	    require(amount <= balances[msg.sender], "No balance");
        balances[msg.sender] -= (amount * 10000);
        balances[receiver] += (amount * 10000);
    }

    function balanceOf(address owner) public view returns(uint) {
        return balances[owner];
    }

    function transfer(address to, uint value) public returns(bool) {
        require(balanceOf(msg.sender) >= value, "No balance");
        balances[to] += value;
        balances[msg.sender] -= value;
        emit Transfer(msg.sender, to, value);
        return true;
    }
  
    function transferFrom(address from, address to, uint value) public returns(bool) {
        require(balanceOf(from) >= value, "No balance");
        require(allowance[from][msg.sender] >= value, "No allowance");
        balances[to] += value;
        balances[from] -= value;
        emit Transfer(from, to, value);
        return true;
    } 

    function approve(address spender, uint value) public returns(bool) {
        allowance[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }

}