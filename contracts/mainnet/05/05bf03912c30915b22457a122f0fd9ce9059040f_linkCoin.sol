/**
 *Submitted for verification at polygonscan.com on 2022-02-23
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract linkCoin {

    mapping(address => uint256) public balances;
    mapping(address => mapping(address => uint256)) public allowance;
    uint256 public _totalSupply = 10000000 * 10 ** 18;
    string public name = "Link Coin";
    string public symbol = "LSB";
    uint8 public decimals = 18;
    
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
    
    constructor() {
        balances[msg.sender] = _totalSupply;
    }
    
    function balanceOf(address _owner) public view returns (uint256 balance) {
         return balances[_owner];
    }
    
    function transfer(address _to, uint256 _value) public returns(bool success) {
        require(balanceOf(msg.sender) >= _value, 'Balance too low.');
        balances[msg.sender] -= _value;
        balances[_to] += _value;
        emit Transfer(msg.sender, _to, _value);
        return true;
    }
    
    function transferFrom(address _from, address _to, uint256 _value) public returns(bool success) {
        require(balanceOf(_from) >= _value, 'Balance too low.');
        require(allowance[_from][msg.sender] >= _value, 'Not approved to spend.');
        balances[_from] -= _value;
        balances[_to] += _value;
        allowance[_from][msg.sender] -= _value; 
        emit Transfer(_from, _to, _value);
        return true;   
    }
    
    function approve(address _spender, uint256 _value) public returns (bool success) {
        allowance[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;   
    }
}