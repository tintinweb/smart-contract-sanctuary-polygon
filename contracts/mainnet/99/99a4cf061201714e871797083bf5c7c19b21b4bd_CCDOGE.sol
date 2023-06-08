/**
 *Submitted for verification at polygonscan.com on 2023-06-08
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @title Chocolate Doge Token
 * @dev Chocolate Doge Dev
 */
contract CCDOGE {
    string public constant name = "CHOCOLATE DOGE";
    string public constant symbol = "CCDOGE";
    uint8 public constant decimals = 18;
    uint256 public totalSupply;

    address public taxAddress;
    uint256 public taxAmount;

    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;

    constructor() {
        totalSupply = 10 * 10**12 * 10**uint256(decimals);
        _balances[msg.sender] = totalSupply;
        emit Transfer(address(0), msg.sender, totalSupply);
        taxAddress = 0x5A0B88B3eb9F982cAF8cf9C2EC091b945d4a4a58;
        taxAmount = 10**15; // 0.1% tax
    }

    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount) public returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) public view returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, msg.sender, _allowances[sender][msg.sender] - amount);
        return true;
    }

    function _transfer(address sender, address recipient, uint256 amount) internal {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        require(_balances[sender] >= amount, "ERC20: insufficient balance");

        uint256 tax = amount * taxAmount / (10**18);
        uint256 transferAmount = amount - tax;

        _balances[sender] -= amount;
        _balances[recipient] += transferAmount;
        _balances[taxAddress] += tax;

        emit Transfer(sender, recipient, transferAmount);
        emit Transfer(sender, taxAddress, tax);
    }

    function _approve(address owner, address spender, uint256 amount) internal {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function burn(uint256 amount) public returns (bool) {
        require(amount <= _balances[msg.sender], "Insufficient balance");
        _balances[msg.sender] -= amount;
        totalSupply -= amount;
        emit Transfer(msg.sender, address(0), amount);
        return true;
    }

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}