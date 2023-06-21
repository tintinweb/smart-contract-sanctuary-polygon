/**
 *Submitted for verification at polygonscan.com on 2023-06-21
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

contract MyToken {
    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public totalSupply;
    
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;
    
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    
    constructor() {
        name = "Uniplat Token Familysale Japan";
        symbol = "UPTFJ";
        decimals = 18;
        totalSupply = 100000000000 * 10 ** uint256(decimals);
        balanceOf[msg.sender] = totalSupply;
    }
    
    function transfer(address _to, uint256 _value) external returns (bool) {
        require(balanceOf[msg.sender] >= _value, "Insufficient balance");
        require(_to != address(0), "Invalid address");
        
        balanceOf[msg.sender] -= _value;
        balanceOf[_to] += _value;
        
        emit Transfer(msg.sender, _to, _value);
        
        return true;
    }
    
    function approve(address _spender, uint256 _value) external returns (bool) {
        require(_spender != address(0), "Invalid address");
        
        allowance[msg.sender][_spender] = _value;
        
        emit Approval(msg.sender, _spender, _value);
        
        return true;
    }
    
    function transferFrom(address _from, address _to, uint256 _value) external returns (bool) {
        require(balanceOf[_from] >= _value, "Insufficient balance");
        require(allowance[_from][msg.sender] >= _value, "Insufficient allowance");
        require(_to != address(0), "Invalid address");
        
        balanceOf[_from] -= _value;
        balanceOf[_to] += _value;
        
        allowance[_from][msg.sender] -= _value;
        
        emit Transfer(_from, _to, _value);
        
        return true;
    }
    
    function burn(uint256 _value) external returns (bool) {
        require(balanceOf[msg.sender] >= _value, "Insufficient balance");
        
        balanceOf[msg.sender] -= _value;
        totalSupply -= _value;
        
        emit Transfer(msg.sender, address(0), _value);
        
        return true;
    }
    
    function mint(address _to, uint256 _value) external returns (bool) {
        require(_to != address(0), "Invalid address");
        
        balanceOf[_to] += _value;
        totalSupply += _value;
        
        emit Transfer(address(0), _to, _value);
        
        return true;
    }
}