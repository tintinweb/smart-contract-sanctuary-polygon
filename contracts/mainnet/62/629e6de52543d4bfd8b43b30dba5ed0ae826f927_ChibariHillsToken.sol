/**
 *Submitted for verification at polygonscan.com on 2023-05-31
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract ChibariHillsToken {
    string public name = "Chibari Hills Token";
    string public symbol = "CHIT";

    uint256 public totalSupply;
    mapping(address => uint256) private balances;
    mapping(address => mapping(address => uint256)) private allowances; // Track "allowances" (allowed transfers) per owner and spender

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value); // Approval event

    constructor(uint256 _initialSupply) {
        totalSupply = _initialSupply;
        balances[msg.sender] = _initialSupply;
    }

    function decimals() public pure returns (uint8) {
        return 18;
    }

    function balanceOf(address tokenOwner) public view returns (uint) {
        return balances[tokenOwner];
    }

    function transfer(address _to, uint256 _value) public returns (bool success) {
        require(balances[msg.sender] >= _value, "Insufficient balance");
        balances[msg.sender] -= _value;
        balances[_to] += _value;
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    function approve(address _spender, uint256 _value) public returns (bool success) {
        allowances[msg.sender][_spender] = _value; // Set the allowance for this owner and spender
        emit Approval(msg.sender, _spender, _value); // Log the approval event
        return true; // Return a boolean to indicate success
    }

    function allowance(address _owner, address _spender) public view returns (uint256 remaining) {
        return allowances[_owner][_spender]; // Return the allowance for this owner and spender
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(allowances[_from][msg.sender] >= _value, "Insufficient allowance"); // Check if the sender has enough allowance
        require(balances[_from] >= _value, "Insufficient balance"); // Check if the sender has enough tokens
 
        balances[_from] -= _value; // Subtract from the sender
        balances[_to] += _value; // Add the same amount to the recipient
        allowances[_from][msg.sender] -= _value; // Subtract from the sender's allowance
 
        emit Transfer(_from, _to, _value); // Log the transfer event
        return true; // Return a boolean to indicate success
    }
}