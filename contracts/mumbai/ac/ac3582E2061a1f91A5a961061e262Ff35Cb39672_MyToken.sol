/**
 *Submitted for verification at polygonscan.com on 2023-07-11
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract MyToken {
    string private _name;
    string private _symbol;
    uint256 private _totalSupply;
    mapping(address => uint256) private _balances;
    address private _owner;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event NameChange(string newName);
    event TickerChange(string newTicker);

    modifier onlyOwner() {
        require(msg.sender == _owner, "Only the owner can call this function");
        _;
    }

    constructor(string memory name, string memory symbol) { // Remove the memory
        _name = name;
        _symbol = symbol;
        _totalSupply = 200000000 * 10 ** decimals();
        _balances[msg.sender] = _totalSupply;
        _owner = msg.sender;
    }

    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }

    function decimals() public pure returns (uint8) {
        return 18;
    }

    function transfer(address recipient, uint256 amount) public returns (bool) {
        require(amount <= _balances[msg.sender], "Insufficient balance");

        _balances[msg.sender] -= amount;
        _balances[recipient] += amount;

        emit Transfer(msg.sender, recipient, amount);

        return true;
    }

    function burn(address account, uint256 amount) public onlyOwner {
        require(amount <= _balances[account], "Insufficient balance");

        _balances[account] -= amount;
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);
    }

    function changeTokenName(string memory newName) public onlyOwner {
        _name = newName;

        emit NameChange(newName);
    }

    function changeTokenTicker(string memory newTicker) public onlyOwner {
        _name = newTicker;

        emit TickerChange(newTicker);
    }
}