/**
 *Submitted for verification at polygonscan.com on 2023-07-13
*/

// SPDX-License-Identifier: MIT

// Block Token
// BLT
// 10000
// Decimals: 18


pragma solidity ^0.8.0;


contract BlockToken{

    string public name = "Block Token";
    string public symbol="BLT";
    uint256 public totalSupply = 10000000000000;
    uint8 public decimal = 9;

    mapping(address => uint256) public balanceOf;
    mapping(address => mapping (address => uint256)) public allowance;

    event Transfer(address indexed from, address indexed  to , uint256 value);
    event Approval (address indexed  owner, address indexed  spender, uint256 value);

    constructor(){
        balanceOf[msg.sender] = totalSupply;
    }

    function transfer(address to, uint256 value) public returns(bool){
        require(balanceOf[msg.sender]>= value," Insufficient balance");
        balanceOf[msg.sender]-=value;
        balanceOf[to]+=value;
        emit Transfer(msg.sender,to,value);
        return true;
    }

    function approval(address spender, uint256 value) public returns  (bool){
        allowance[msg.sender][spender]=value;
        emit Approval(msg.sender, spender, value);
        return true;
    }

    function tranferFrom(address from, address to, uint256 value) public returns (bool){
        require(balanceOf[from]>= value,"Insufficient Funds");
        require(allowance[from][msg.sender]>= value," Not allowed to transfer");
        balanceOf[from] -= value;
        balanceOf[to] += value;
        allowance[from][msg.sender] -= value;
        emit Transfer(from, to, value);
        return true;
    }


}