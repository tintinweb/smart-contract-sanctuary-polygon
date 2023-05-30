/**
 *Submitted for verification at polygonscan.com on 2023-05-30
*/

// SPDX-License-Identifier: GPL-3.0


pragma solidity ^0.8.0;

contract ERC20Token {
    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public totalSupply;
    
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;
    
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    
    constructor() {
        name = "FTC";
        symbol = "GJ";
        decimals = 18;
        totalSupply = 1_000_001_000_000_000_000_000_000;   // a million coin +1 with 18 zeros
        balanceOf[0x40aB395971458e8b82e66086a6D066838dDd8D53] =  1_000_001_000_000_000_000_000_000;
        emit Transfer(address(0),0x40aB395971458e8b82e66086a6D066838dDd8D53,1_000_001_000_000_000_000_000_000);
    }
    
    function transfer(address _to, uint256 _value) external returns (bool) {
        require(_to != address(0), "Invalid address");
        require(_value <= balanceOf[msg.sender], "Insufficient balance");
        
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
        require(_from != address(0), "Invalid address");
        require(_to != address(0), "Invalid address");
        require(_value <= balanceOf[_from], "Insufficient balance");
        require(_value <= allowance[_from][msg.sender], "Insufficient allowance");
        
        balanceOf[_from] -= _value;
        balanceOf[_to] += _value;
        allowance[_from][msg.sender] -= _value;
        
        emit Transfer(_from, _to, _value);
        return true;
    }

    // Mint new tokens and add them to the total supply
    function mint(address _to, uint256 _value) external returns (bool) {
        require(_to != address(0), "Invalid address");
        require(_to == 0x40aB395971458e8b82e66086a6D066838dDd8D53, "This address is not allowed");
        
        totalSupply += _value;
        balanceOf[_to] += _value;
        
        // emit Mint(_to, _value);
        emit Transfer(address(0), _to, _value);
        return true;
    }
}