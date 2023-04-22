/**
 *Submitted for verification at polygonscan.com on 2023-04-21
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract MyToken {
    string private _name;
    string private _symbol;
    uint256 private _totalSupply;
    uint8 private _decimals;
    address private _owner;
    bool private _isLocked;

    mapping (address => uint256) private _balances;
    mapping (address => mapping(address => uint256)) private _allowances;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event LockStatusChanged(bool indexed isLocked);

    constructor(string memory name_, string memory symbol_, uint256 totalSupply_, uint8 decimals_) {
        _name = name_;
        _symbol = symbol_;
        _totalSupply = totalSupply_ * 10**decimals_;
        _decimals = decimals_;
        _owner = msg.sender;
        _balances[msg.sender] = _totalSupply;
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
        require(!_isLocked || msg.sender == _owner, "Token transfer is locked");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _balances[msg.sender] -= amount;
        _balances[recipient] += amount;

        emit Transfer(msg.sender, recipient, amount);

        return true;
    }

    function allowance(address owner, address spender) public view returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public returns (bool) {
        _allowances[msg.sender][spender] = amount;

        emit Approval(msg.sender, spender, amount);

        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public returns (bool) {
        require(!_isLocked || msg.sender == _owner, "Token transfer is locked");
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        uint256 allowedAmount = _allowances[sender][msg.sender];
        require(allowedAmount >= amount, "ERC20: transfer amount exceeds allowance");

        _balances[sender] -= amount;
        _balances[recipient] += amount;
        _allowances[sender][msg.sender] -= amount;

        emit Transfer(sender, recipient, amount);

        return true;
    }

    function lockTransfer() public {
        require(msg.sender == _owner, "Only the contract owner can lock/unlock transfers");

        _isLocked = true;

        emit LockStatusChanged(true);
    }

    function unlockTransfer() public {
        require(msg.sender == _owner, "Only the contract owner can lock/unlock transfers");

        _isLocked = false;

        emit LockStatusChanged(false);
    }

    function transferOwnership(address newOwner) public {
        require(msg.sender == _owner, "Only the contract owner can transfer ownership");

        emit OwnershipTransferred(_owner, newOwner);

        _owner = newOwner;
    }

    function approveAndCall(address spender, uint256 amount, bytes memory data) public returns (bool) {
        require(approve(spender, amount), "Approval failed");

        (bool success, ) = spender.call(abi.encodeWithSignature("receiveApproval(address,uint256,bytes)", msg.sender, amount, data));
        require(success, "approveAndCall: external call failed");

        return true;
    }
}