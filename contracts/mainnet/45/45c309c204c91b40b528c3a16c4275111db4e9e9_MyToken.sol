/**
 *Submitted for verification at polygonscan.com on 2023-04-24
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract MyToken {
    string public name = "PEPE";
    string public symbol = "PEPE";
    uint256 public totalSupply = 100000000 ether; // 100,000,000 MTK with 18 decimals
    uint8 public decimals = 18;
    uint256 public pool = 120000 ether; // $120,000

    mapping(address => uint256) public balanceOf;

    constructor() {
        balanceOf[msg.sender] = totalSupply;
    }

    function transfer(address _to, uint256 _value) external returns (bool success) {
        require(balanceOf[msg.sender] >= _value, "Not enough balance");
        require(_to != address(0), "Invalid recipient address");
        balanceOf[msg.sender] -= _value;
        balanceOf[_to] += _value;
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    function approve(address _spender, uint256 _value) external returns (bool success) {
        require(_spender != address(0), "Invalid spender address");
        allowance[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) external returns (bool success) {
        require(balanceOf[_from] >= _value, "Not enough balance");
        require(_to != address(0), "Invalid recipient address");
        require(allowance[_from][msg.sender] >= _value, "Not enough allowance");
        balanceOf[_from] -= _value;
        balanceOf[_to] += _value;
        allowance[_from][msg.sender] -= _value;
        emit Transfer(_from, _to, _value);
        return true;
    }

    function claim() external returns (bool success) {
        require(pool > 0, "No more pool available");
        require(balanceOf[msg.sender] == 0, "Already claimed");
        balanceOf[msg.sender] = pool;
        pool = 0;
        emit Transfer(address(0), msg.sender, pool);
        return true;
    }

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

    mapping(address => mapping(address => uint256)) public allowance;
}