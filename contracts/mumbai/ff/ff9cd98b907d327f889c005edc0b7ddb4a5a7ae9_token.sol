/**
 *Submitted for verification at polygonscan.com on 2022-04-13
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract token {
    event logMint(address, uint256);

    mapping(address => uint256) public balances;
    mapping(address => mapping(address => uint256)) public allowances;
    string public tokenName;
    string public tokenSymbol;
    uint256 public decimals = 18;
    uint256 public totalSupply;

    constructor(string memory _tokenName, string memory _tokenSymbol, uint256 _mintAmount) {
        tokenName = _tokenName;
        tokenSymbol = _tokenSymbol;
        _mint(msg.sender, _mintAmount);
    }

    function _mint(address _dest, uint256 _amount) private {
        balances[_dest] += _amount;
        totalSupply += _amount;
        emit logMint(_dest, _amount);
    }

    function transfer(address _dest, uint256 _amount) public {
        require(balances[msg.sender] <= _amount, "not enough balance");
        balances[_dest] += _amount;
        balances[msg.sender] -= _amount;
    }

    function approve(address spender, uint256 _amount) public {
        require(balances[msg.sender] >= _amount, "not enough balance");
        allowances[msg.sender][spender] += _amount;
    }

    function transferFrom(address _source, address _dest, uint256 _value) external {
        require(balances[_source] >= _value, "not enough balance");
        require(allowances[_source][msg.sender] >= _value, "not approved");
        balances[_source] -= _value;
        balances[_dest] += _value;
        allowances[_source][msg.sender] -= _value;
    }
}