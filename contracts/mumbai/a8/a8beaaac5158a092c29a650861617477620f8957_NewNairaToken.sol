/**
 *Submitted for verification at polygonscan.com on 2023-05-27
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract NewNairaToken {
    string private _name;
    string private _symbol;
    uint8 private _decimals;
    uint256 private _totalSupply;
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address => bool) private _blacklisted;
    address private _owner;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event AddressBlacklisted(address indexed account, bool isBlacklisted);

    constructor() {
        _name = "NEW Naira";
        _symbol = "NNGN";
        _decimals = 18;
        _totalSupply = 1000000000 * 10 ** _decimals;
        _balances[msg.sender] = _totalSupply;
        _owner = msg.sender;

        emit Transfer(address(0), msg.sender, _totalSupply);
        emit OwnershipTransferred(address(0), msg.sender);
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

    function allowance(address owner, address spender) public view returns (uint256) {
        return _allowances[owner][spender];
    }

    function isAddressBlacklisted(address account) public view returns (bool) {
        return _blacklisted[account];
    }

    function transfer(address recipient, uint256 amount) public returns (bool) {
        require(recipient != address(0), "Transfer to zero address");
        require(amount <= _balances[msg.sender], "Insufficient balance");
        require(!_blacklisted[msg.sender], "Sender is blacklisted");

        _balances[msg.sender] -= amount;
        _balances[recipient] += amount;

        emit Transfer(msg.sender, recipient, amount);
        return true;
    }

    function approve(address spender, uint256 amount) public returns (bool) {
        require(spender != address(0), "Approve to zero address");

        _allowances[msg.sender][spender] = amount;

        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public returns (bool) {
        require(recipient != address(0), "Transfer to zero address");
        require(amount <= _balances[sender], "Insufficient balance");
        require(!_blacklisted[sender], "Sender is blacklisted");

        _balances[sender] -= amount;
        _balances[recipient] += amount;
        _allowances[sender][msg.sender] -= amount;

        emit Transfer(sender, recipient, amount);
        return true;
    }

    function mint(address account, uint256 amount) external {
        require(msg.sender == _owner, "Only owner can mint");
        require(account != address(0), "Mint to zero address");

        _totalSupply += amount;
        _balances[account] += amount;

        emit Transfer(address(0), account, amount);
    }

    function burn(uint256 amount) external {
        require(amount <= _balances[msg.sender], "Insufficient balance");

        _balances[msg.sender] -= amount;
        _totalSupply -= amount;

        emit Transfer(msg.sender, address(0), amount);
    }

    function changeOwnership(address newOwner) external {
        require(newOwner != address(0), "Invalid new owner");
        require(msg.sender == _owner, "Only owner can change ownership");

        _owner = newOwner;

        emit OwnershipTransferred(msg.sender, newOwner);
    }

    function blacklistAddress(address account, bool isBlacklisted) external {
        require(msg.sender == _owner, "Only owner can blacklist");
        _blacklisted[account] = isBlacklisted;

        emit AddressBlacklisted(account, isBlacklisted);
    }
}