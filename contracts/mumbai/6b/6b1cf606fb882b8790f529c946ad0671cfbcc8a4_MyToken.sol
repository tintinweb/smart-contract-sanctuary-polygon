/**
 *Submitted for verification at polygonscan.com on 2023-05-01
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract MyToken {
    string public name = "BGT Token";
    string public symbol = "BGT";
    uint256 public totalSupply = 1000000000000000000000000;
    uint8 public decimals = 18;
    mapping(address => uint256) balances;
    
    constructor() {
        balances[msg.sender] = totalSupply;
    }
    
    function transfer(address _to, uint256 _amount) public {
        require(balances[msg.sender] >= _amount, "Insufficient balance");
        balances[msg.sender] -= _amount;
        balances[_to] += _amount;
    }
    
    function balanceOf(address _owner) public view returns (uint256 balance) {
        return balances[_owner];
    }
}