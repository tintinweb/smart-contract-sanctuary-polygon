/**
 *Submitted for verification at polygonscan.com on 2023-05-06
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

contract YourToken {
    string public name = "Debug Token";
    string public symbol = "DEBUG";
    uint256 public totalSupply = 1000000;
    mapping(address => uint256) public balanceOf;
    
    constructor() {
        balanceOf[msg.sender] = totalSupply;
    }
    
    function transfer(address _to, uint256 _value) public {
        require(balanceOf[msg.sender] >= _value, "Insufficient balance");
        balanceOf[msg.sender] -= _value;
        balanceOf[_to] += _value;
    }
    
    function transferFrom(address _from, address _to, uint256 _value) public {
        require(balanceOf[_from] >= _value, "Insufficient balance");
        balanceOf[_from] -= _value;
        balanceOf[_to] += _value;
    }
}