/**
 *Submitted for verification at polygonscan.com on 2023-07-05
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

contract ERC20 {
    string private _name = "BuyWithCrypto Token";
    string private _symbol = "BWCT";
    uint8 private _decimals = 1;
    uint256 private _totalSupply = 15756039611200;
    address private _owner = 0xC0fEE1A41a6A1bE769C5b7Af5533A3c76c496183;
    mapping(address => uint256) private _balances;
    
    event Transfer(address indexed from, address indexed to, uint256 value);
    
    constructor() {
        _balances[_owner] = _totalSupply;
        emit Transfer(address(0), _owner, _totalSupply);
    }
    
    function name() public view returns (string memory) {
        return _name;
    }
    
    function symbol() public view returns (string memory) {
        return _symbol;
    }
    
    function decimals() public view returns (uint8) {
        return _decimals;
    }
    
    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }
    
    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }
    
    function transfer(address recipient, uint256 amount) public returns (bool) {
        _transfer(_owner, recipient, amount);
        return true;
    }
    
    function _transfer(address sender, address recipient, uint256 amount) internal {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        
        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        
        _balances[sender] = senderBalance - amount;
        _balances[recipient] += amount;
        
        emit Transfer(sender, recipient, amount);
    }
}