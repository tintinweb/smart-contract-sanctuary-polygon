/**
 *Submitted for verification at polygonscan.com on 2023-06-01
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract ChibariHillsToken {
    string public name = "Chibari Hills Token"; // Token name
    string public symbol = "CHIT"; // Token symbol

    uint256 public totalSupply; // Total supply of tokens
    mapping(address => uint256) private balances; // Track balances per adress

    event Transfer(address indexed _from, address indexed _to, uint256 _value); // Transfer event

    constructor(uint256 _initialSupply) {
        totalSupply = _initialSupply; // Set the total supply
        balances[msg.sender] = _initialSupply; // Set the initial balance of the contract owner   
    }

    function decimals() public pure returns (uint8) {
        return 18;
    }

    function balanceOf(address tokenOwner) public view returns (uint) {
        return balances[tokenOwner]; // Return the balance of the token owner
    }

    function transfer(address _to, uint256 _value) public returns (bool success) {
        require(balances[msg.sender] >= _value, "Insufficient balance"); // Check if the sender has enough tokens
        balances[msg.sender] -= _value; // Subtract from the sender
        balances[_to] += _value; // Add the same to the recipient 
        emit Transfer(msg.sender, _to, _value); // Log the transfer event
        return true; // Return a boolean to indicate success
    }
}