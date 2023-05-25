/**
 *Submitted for verification at polygonscan.com on 2023-05-25
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

contract SimpleCoin {
    string public name = "SimpleCoin";
    string public symbol = "SIC";
    uint public totalSupply = 10_000;
    mapping(address => uint) public balanceOf;

    constructor() {
        balanceOf[msg.sender] = totalSupply;
    }

    function transfer(address _to, uint _amount) external {
        require(balanceOf[msg.sender] >= _amount, "Not enough tokens");
        balanceOf[msg.sender] -= _amount;
        balanceOf[_to] += _amount;
    }
}