/**
 *Submitted for verification at polygonscan.com on 2022-07-04
*/

// SPDX-License-Identifier: MIT
// Mucha Plata Patrón
pragma solidity ^0.8.0;

contract Plata {
    
    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);

    uint public totalSupply = 220000; // * 10 ** 6
    address public minter;
    mapping (address => uint) public balances;
    mapping (address => mapping(address => uint)) public allowance;
    string public name = "Plata";
    string public symbol = "PLT";
    uint public decimals = 4;

    constructor() {
        balances[msg.sender] = totalSupply;
        minter = msg.sender;
    }

    function mint(address receiver, uint amount) public {
        require(msg.sender == minter);
        balances[receiver] += amount * 10000;
    }

    function send(address receiver, uint amount) public {
	    require(amount <= balances[msg.sender], "Insufficient Balance");
        balances[msg.sender] -= amount;
        balances[receiver] += amount;
    }

    function balanceOf(address owner) public view returns(uint) {
        return balances[owner];
    }

    function transfer(address to, uint value) public returns(bool) {
        require(balanceOf(msg.sender) >= value, 'balance too low');
        balances[to] += value;
        balances[msg.sender] -= value;
        emit Transfer(msg.sender, to, value);
        return true;
    }
    
    function transferFrom(address from, address to, uint value) public returns(bool) {
        require(balanceOf(from) >= value, 'balance too low');
        require(allowance[from][msg.sender] >= value, 'allowance too tow');
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