/**
 *Submitted for verification at polygonscan.com on 2023-03-05
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// ERC20 standard interface
interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
}

contract MyToken {
    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public totalSupply;
    mapping (address => uint256) public balanceOf;

    constructor(
        string memory _name,
        string memory _symbol,
        uint8 _decimals,
        uint256 _totalSupply
    ) {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;
        totalSupply = _totalSupply;
        balanceOf[msg.sender] = _totalSupply;
    }

    // Transfer tokens
    function transfer(address _to, uint256 _value) public returns (bool success) {
        require(balanceOf[msg.sender] >= _value);
        balanceOf[msg.sender] -= _value;
        balanceOf[_to] += _value;
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    // Airdrop tokens to multiple addresses
    function airdrop(address[] memory _addresses, uint256 _value) public returns (bool success) {
        require(balanceOf[msg.sender] >= _value * _addresses.length);
        for (uint i = 0; i < _addresses.length; i++) {
            balanceOf[_addresses[i]] += _value;
            emit Transfer(msg.sender, _addresses[i], _value);
        }
        balanceOf[msg.sender] -= _value * _addresses.length;
        return true;
    }

    // Update token name and symbol
    function updateTokenInfo(string memory _name, string memory _symbol) public returns (bool success) {
        require(msg.sender == owner());
        name = _name;
        symbol = _symbol;
        return true;
    }

    function owner() public view returns (address) {
        return msg.sender;
    }

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
}