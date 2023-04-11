/**
 *Submitted for verification at polygonscan.com on 2023-04-11
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract OpenaiToken {
    string public name = "OPENAI Token";
    string public symbol = "OPENAI";
    uint256 public totalSupply = 1000000;

    mapping(address => uint256) balances;

    constructor() {
        balances[msg.sender] = totalSupply;
    }

    function transfer(address _to, uint256 _value) external returns (bool success) {
        require(balances[msg.sender] >= _value);
        balances[msg.sender] -= _value;
        balances[_to] += _value;
        return true;
    }

    function balanceOf(address _owner) external view returns (uint256 balance) {
        return balances[_owner];
    }
}