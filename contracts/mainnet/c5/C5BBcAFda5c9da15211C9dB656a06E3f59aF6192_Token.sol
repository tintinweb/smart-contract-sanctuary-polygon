/**
 *Submitted for verification at polygonscan.com on 2023-06-01
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Token {
    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public TotalSupply;
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;
    
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);    
    
    
    constructor() {
        name = "Bumble Bee";   
        symbol = "BEE";
        decimals = 18;
        TotalSupply = 100000000000000000000000;
        balanceOf[msg.sender] = TotalSupply;
        emit Transfer(address(0), msg.sender, TotalSupply);
    }
    
    function transfer(address _to, uint256 _value) public returns (bool success){
        require(balanceOf[msg.sender] >= _value, "Sender does not have enough balance");
        balanceOf[msg.sender] -= _value;
        balanceOf[_to] += _value;
        emit Transfer(msg.sender, _to, _value);
        return true;
    }
    
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
       require(balanceOf[_from] >= _value, "Source account does not have enough balance");
       require(allowance[_from][msg.sender] >= _value, "Sender is not allowed to send that many tokens");
       allowance[_from][msg.sender] -= _value;
       balanceOf[_from] -= _value;
       balanceOf[_to] += _value;
       emit Transfer(_from, _to, _value);
       return true;
    }
    
    function approve(address _spender, uint256 _value) public returns (bool success){
        allowance[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }
}