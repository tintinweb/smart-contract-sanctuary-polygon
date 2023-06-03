/**
 *Submitted for verification at polygonscan.com on 2023-06-03
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Pennies {
    string public constant name = "Pennies";
    string public constant symbol = "CENT";
    uint8 public constant decimals = 0;
    uint256 public totalSupply = 10000000000; 
    mapping(address => uint256) balances;
    
    address public owner;

    event Transfer(address indexed from, address indexed to, uint256 value);

    constructor() {
        owner = msg.sender;
        balances[msg.sender] = totalSupply;
        emit Transfer(address(0), msg.sender, totalSupply);
    }

    function balanceOf(address _owner) external view returns (uint256 balance) {
        return balances[_owner];
    }

    function transfer(address _to, uint256 _value) external returns (bool success) {
        require(_to != address(0), "Cannot transfer to zero address");
        require(balances[msg.sender] >= _value, "Insufficient balance");
        
        balances[msg.sender] -= _value;
        balances[_to] += _value;
        
        emit Transfer(msg.sender, _to, _value);
        
        return true;
    }
    
   function renounceOwnership() external {
       require(msg.sender == owner, "Only the contract owner can renounce ownership");
       owner = address(0);
   }
}