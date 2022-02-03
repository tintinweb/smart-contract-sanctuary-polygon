/**
 *Submitted for verification at polygonscan.com on 2022-02-03
*/

// SPDX-License-Identifier: BSD-3-Clause
pragma solidity 0.8.9;

contract Pisscoin { 
    mapping(address => uint) private balances;
    mapping(address => mapping(address => uint)) private allow;

    string public name = "PissCoin";
    string public symbol = "PISS";
    uint public decimals = 5;
    uint public totalSupply = 111111 * 10 ** decimals;

    event Transfer(address indexed from, address indexed to, uint value);
    event Approve(address indexed owner, address indexed spender, uint value);

    // wtf web 3 is giving me trouble
    // Don't mess with piss
    constructor() {
        balances[msg.sender] = totalSupply;
    }

    function balanceOf(address zero) public view returns(uint) {
        return balances[zero];
    }

    function transfer(address to, uint value) public returns(bool){
        require(balanceOf(msg.sender) >= value, "piss can be sent better than this amount.");
        balances[to] += value;
        balances[msg.sender] = balances[msg.sender] - value;
        emit Transfer(msg.sender, to, value);
        return true;
    }

    function transferFrom(address from, address to, uint value) public returns(bool) {
        require(balanceOf(from) >= value, "u got no money");
        require(allow[from][msg.sender] >= value, "haha nope");
        balances[to] += value; 
        balances[from] -= value;
        emit Transfer(from, to, value);
        return true;
    }

    function approve(address spender, uint value) public returns(bool) {
        allow[msg.sender][spender] = value;
        emit Approve(msg.sender, spender, value);
        return true;
    
    }
    function allowance(address from, address spender) public view returns(uint) {
        return allow[from][spender];
    }
    }